# ZMK Framework Reference

Core ZMK knowledge for keymap work. Verified against the **v0.3 docs** (`v0-3-branch.zmk.dev`), which match the `moergo-sc/zmk` fork this repo builds against.

**Resolve questions offline first**: keycodes and behavior parameters are in `keycodes.md` and the vendored fork headers in `headers/` (grep those — they are exact ground truth). Only fetch a URL from the map at the bottom when the local files genuinely don't cover the topic — and then always the v0-3-branch host.

## Keymap file anatomy

A `.keymap` file is devicetree source with a C preprocessor pass on top (`#include`, `#define`, `#if` all work and are heavily used in this repo).

```dts
#include <behaviors.dtsi>              // built-in behavior nodes (&kp, &mt, ...)
#include <dt-bindings/zmk/keys.h>      // keycodes + LS()/LC()/LA()/LG() functions
#include <dt-bindings/zmk/modifiers.h> // MOD_LSFT etc. bitmasks (for mod-morph `mods`)
#include <dt-bindings/zmk/bt.h>        // BT_SEL, BT_DISC, BT_CLR ...
#include <dt-bindings/zmk/rgb.h>       // RGB_TOG, RGB_BRI ...
#include <dt-bindings/zmk/outputs.h>   // OUT_USB, OUT_BLE
#include <input/processors.dtsi>       // pointing-device input processors
#include <dt-bindings/zmk/pointing.h>  // mouse buttons/movement codes

/ {
    behaviors { /* custom behavior nodes */ };
    macros    { /* macro nodes */ };
    combos    { compatible = "zmk,combos"; /* combo nodes */ };
    keymap {
        compatible = "zmk,keymap";
        layer_Name {            // layers are numbered by ORDER of appearance, 0-based
            bindings = < ... >; // one behavior binding per physical key position
        };
    };
};
```

**Layer semantics:** layer 0 is the default/base layer; when a key is pressed, the *highest-indexed currently active* layer that has a non-transparent binding at that position wins. `&trans` falls through to the next active layer below; `&none` swallows the press.

**Bindings:** `&behavior [param1] [param2]` — the number of params must match the behavior's `#binding-cells`. Even when an inner behavior ignores a parameter (e.g., a 0-cell mod-morph wrapped in a 2-cell hold-tap), the call site must still supply the syntactic argument count of the *outer* behavior.

## Built-in behaviors quick table

| Binding | Purpose |
|---|---|
| `&kp KC` | key press |
| `&mt MOD KC` | mod-tap (hold = modifier, tap = keycode) |
| `&lt LAYER KC` | layer-tap (hold = layer, tap = keycode) |
| `&mo LAYER` | momentary layer while held |
| `&to LAYER` | switch to layer (deactivates others except default) |
| `&tog LAYER` | toggle layer on/off |
| `&sl LAYER` | sticky layer (active until next keypress) |
| `&sk MOD` | sticky key/modifier (held until next keypress) |
| `&kt KC` | key toggle |
| `&caps_word` | caps until a non-continue key |
| `&key_repeat` | repeat last keycode |
| `&gresc` | built-in mod-morph: Esc, or grave when Shift/GUI held |
| `&trans` / `&none` | fall through / swallow |
| `&bt BT_SEL n` / `BT_DISC n` / `BT_CLR` | Bluetooth profile actions |
| `&out OUT_USB` / `OUT_BLE` / `OUT_TOG` | output routing |
| `&rgb_ug RGB_*` | RGB underglow control |
| `&mkp MB1` / `&mmv` / `&msc` | mouse button / move / scroll |
| `&sys_reset` / `&bootloader` | reboot / enter flash bootloader |

## Hold-tap (`zmk,behavior-hold-tap`)

Resolves to a "hold" or "tap" binding based on timing and interrupting keys. `&mt` and `&lt` are pre-built instances.

```dts
my_ht: my_ht {
    compatible = "zmk,behavior-hold-tap";
    #binding-cells = <2>;
    tapping-term-ms = <200>;
    flavor = "tap-preferred";
    bindings = <&kp>, <&kp>;   // <hold behavior>, <tap behavior>
};
// usage: &my_ht LSHIFT A
```

| Property | Default | Meaning |
|---|---|---|
| `tapping-term-ms` | 200 | held longer than this → hold |
| `flavor` | `"hold-preferred"` | interrupt strategy (below) |
| `quick-tap-ms` | off | re-press within this window → always tap (enables tap-then-hold key repeat) |
| `require-prior-idle-ms` | off | if any key was pressed within this window before, resolve as tap (kills rolls misfiring as holds) |
| `hold-trigger-key-positions` | off | hold only allowed if the interrupting key is in this position list (bilateral/cross-hand HRM) |
| `hold-trigger-on-release` | false | evaluate the position list on interrupt release, not press (lets same-hand mods combine) |
| `hold-while-undecided` | false | press hold behavior immediately, retract if it resolves to tap |
| `retro-tap` | false | released with no interrupt after tapping-term → send tap anyway |

Flavors: **hold-preferred** (hold on timeout OR any interrupt press), **balanced** (hold on timeout OR interrupt press+release), **tap-preferred** (hold only on timeout), **tap-unless-interrupted** (inverted: tap on timeout, hold only if interrupted).

The `bindings` entries are behavior *references without params*; params flow in from the call site. To make a hold-tap whose tap side is a 0-param behavior (macro, mod-morph), reference it directly — the call site still passes a placeholder for that cell.

## Tap-dance (`zmk,behavior-tap-dance`)

```dts
td0: td0 {
    compatible = "zmk,behavior-tap-dance";
    #binding-cells = <0>;
    tapping-term-ms = <200>;
    bindings = <&kp N1>, <&kp N2>, <&kp N3>;  // 1 tap, 2 taps, 3 taps
};
```

Resolves when `tapping-term-ms` elapses after the last tap, when interrupted by another key (fires the binding for the current count immediately), or instantly on reaching the max count. Bindings can be hold-taps or layer behaviors.

## Mod-morph (`zmk,behavior-mod-morph`)

```dts
quote_flip: quote_flip {
    compatible = "zmk,behavior-mod-morph";
    #binding-cells = <0>;
    bindings = <&kp DQT>, <&kp SQT>;      // <default>, <when mods held>
    mods = <(MOD_LSFT|MOD_RSFT)>;
    // keep-mods = <(MOD_LSFT)>;          // optional: don't strip these when morphing
};
```

Any single modifier in `mods` triggers the morph. **The matched modifiers are suppressed** while the morphed binding fires (unless listed in `keep-mods`) — this is what lets Shift+key emit an *unshifted* code (e.g., this repo's `semi_colon_morph`: plain tap → `LS(SEMI)` = `:`, Shift+tap → plain `;`).

## Macros

Three compatibles by param count: `zmk,behavior-macro` (0, `#binding-cells = <0>`), `-one-param` (1), `-two-param` (2).

Control bindings inside `bindings`:

- `&macro_tap` / `&macro_press` / `&macro_release` — set activation mode for subsequent entries (default tap)
- `&macro_pause_for_release` — split press-half / release-half of the macro
- `&macro_wait_time N` / `&macro_tap_time N` — timing overrides mid-sequence; node-level `wait-ms` / `tap-ms` set them globally
- `&macro_param_1to1` / `1to2` / `2to1` / `2to2` — forward the macro's Nth param into the *next* binding's 1st/2nd slot; use `MACRO_PLACEHOLDER` (or `0`) in that slot

```dts
lm: lm {   // hold layer + modifier together, parameterized
    compatible = "zmk,behavior-macro-two-param";
    wait-ms = <0>; tap-ms = <0>;
    #binding-cells = <2>;
    bindings = <&macro_param_1to1>, <&macro_press &mo MACRO_PLACEHOLDER>,
               <&macro_param_2to1>, <&macro_press &kp MACRO_PLACEHOLDER>,
               <&macro_pause_for_release>,
               <&macro_param_2to1>, <&macro_release &kp MACRO_PLACEHOLDER>,
               <&macro_param_1to1>, <&macro_release &mo MACRO_PLACEHOLDER>;
};
```

## Sticky key (`zmk,behavior-sticky-key`)

```dts
skq: skq {
    compatible = "zmk,behavior-sticky-key";
    #binding-cells = <1>;
    bindings = <&kp>;
    release-after-ms = <1000>;
    quick-release;      // release on next key PRESS, not release (no leak into 2nd key)
    // lazy;            // don't press the mod until the next key arrives
    // ignore-modifiers;// let other sticky mods stack
};
```

## Combos

```dts
/ { combos {
    compatible = "zmk,combos";
    combo_esc {
        timeout-ms = <50>;               // all keys within this window
        key-positions = <POS_LH_C6R1 POS_LH_C5R1>;  // use POS_* defines
        bindings = <&kp ESC>;
        layers = <LAYER_HRM_macOS LAYER_Typing>;    // optional; default = all
        require-prior-idle-ms = <150>;   // optional roll protection
        // slow-release;                 // hold combo output until all keys released
    };
}; };
```

## Conditional layers (`zmk,conditional-layers`)

Activate a layer automatically whenever a set of other layers is active (tri-layer):

```dts
/ { conditional_layers {
    compatible = "zmk,conditional-layers";
    tri_layer {
        if-layers = <LAYER_Cursor LAYER_Symbol>;  // when ALL of these are active...
        then-layer = <LAYER_Keypad>;              // ...this one activates too
    };
}; };
```

The `then-layer` should be *higher-numbered* than every `if-layers` entry so it wins binding lookups. Conditional layers can chain (a then-layer may satisfy another rule's if-layers).

## Mouse emulation (`&mkp` / `&mmv` / `&msc`)

Requires `CONFIG_ZMK_POINTING=y`, `#include <dt-bindings/zmk/pointing.h>`, `#include <input/processors.dtsi>`. Parameter constants in `keycodes.md` § Mouse (buttons `MB1`–`MB5`, `MOVE_*`, `SCRL_*`, custom `MOVE_X/Y(n)`).

Tune speed/acceleration by overriding the built-in behavior nodes at file top level:

```dts
&mmv { time-to-max-speed-ms = <300>; acceleration-exponent = <1>; };
&msc { time-to-max-speed-ms = <40>;  acceleration-exponent = <0>; };
```

This keymap also overrides `&mmv_input_listener` / `&msc_input_listener` (~line 244–270 of `go60.keymap`) with per-layer input processors — e.g. scaling the move speed on the MouseSlow/MouseFast layers via `zmk,input-processor-scaler`.

## Caps word & key repeat tweaks

Override the built-in nodes to change what keeps caps-word alive, or which HID pages key-repeat captures:

```dts
&caps_word { continue-list = <UNDERSCORE MINUS BSPC>; };  // defaults: alphas, numbers, UNDER, BSPC, DEL
&key_repeat { usage-pages = <HID_USAGE_KEY HID_USAGE_CONSUMER>; };
```

## Bluetooth, output & RGB behaviors

- `&bt BT_SEL n` selects BLE profile *n* (0-based); `BT_DISC n` disconnects one; `BT_NXT`/`BT_PRV` cycle; `BT_CLR` unpairs the **active** profile; `BT_CLR_ALL` unpairs everything. Selecting a profile doesn't switch output — pair with `&out OUT_BLE` (this keymap's `bt_0`–`bt_3` tap-dances do both).
- `&out OUT_USB` / `OUT_BLE` / `OUT_TOG` routes HID output.
- `&rgb_ug <cmd>` — full command list in `keycodes.md` § Behavior parameters, incl. the fork-only `RGB_STATUS`.

## Modifiers: functions vs constants

- **`LS()/LC()/LA()/LG()` (+ `RS/RC/RA/RG`)** wrap a *keycode* with a modifier — used anywhere a keycode goes: `&kp LC(LS(TAB))`. They nest. Rollover-safe: the implicit mods release when another key is pressed.
- **`MOD_LSFT`, `MOD_LCTL`, `MOD_LALT`, `MOD_LGUI` (+ `R` variants)** are *bitmask constants* from `dt-bindings/zmk/modifiers.h` — used only in bitmask properties like mod-morph's `mods`/`keep-mods`, OR-ed together: `<(MOD_LSFT|MOD_RSFT)>`.
- Bare modifier keycodes (`LSHIFT`, `LCTRL`, `LALT`, `LGUI`, ...) are ordinary keycodes for `&kp`/`&mt`/`&sk` params.
- Many shifted symbols have pre-built keycodes (`DQT` = `LS(SQT)`, `COLON` = `LS(SEMI)`, `DLLR` = `LS(N4)`) — prefer them for readability. Full table in `keycodes.md`; exact definitions in `headers/modifiers.h`.

## Kconfig (`.conf`)

One `CONFIG_X=y` (or `=<n>`) per line; passed to the Zephyr build. Common: `CONFIG_ZMK_SLEEP=y`, `CONFIG_ZMK_IDLE_SLEEP_TIMEOUT=<ms>`, `CONFIG_BT_CTLR_TX_PWR_PLUS_8=y`, `CONFIG_ZMK_RGB_UNDERGLOW_*`, `CONFIG_ZMK_POINTING=y`, `CONFIG_ZMK_MACRO_DEFAULT_WAIT_MS/TAP_MS`, `CONFIG_ZMK_BEHAVIORS_QUEUE_SIZE`. Full list: config docs URL below.

## Doc URL map (last resort — always the v0-3-branch host)

Fetch only when this file, `keycodes.md`, and the `headers/` files don't answer the question.

| Topic | URL |
|---|---|
| Keymaps overview | https://v0-3-branch.zmk.dev/docs/keymaps |
| Behaviors index | https://v0-3-branch.zmk.dev/docs/keymaps/behaviors |
| Hold-tap | https://v0-3-branch.zmk.dev/docs/keymaps/behaviors/hold-tap |
| Tap-dance | https://v0-3-branch.zmk.dev/docs/keymaps/behaviors/tap-dance |
| Mod-morph | https://v0-3-branch.zmk.dev/docs/keymaps/behaviors/mod-morph |
| Macros | https://v0-3-branch.zmk.dev/docs/keymaps/behaviors/macros |
| Sticky key | https://v0-3-branch.zmk.dev/docs/keymaps/behaviors/sticky-key |
| Layers | https://v0-3-branch.zmk.dev/docs/keymaps/behaviors/layers |
| Mouse emulation | https://v0-3-branch.zmk.dev/docs/keymaps/behaviors/mouse-emulation |
| Combos | https://v0-3-branch.zmk.dev/docs/keymaps/combos |
| Conditional layers | https://v0-3-branch.zmk.dev/docs/keymaps/conditional-layers |
| Modifiers | https://v0-3-branch.zmk.dev/docs/keymaps/modifiers |
| Keycode list (prefer `keycodes.md` / `headers/keys.h`) | https://v0-3-branch.zmk.dev/docs/keymaps/list-of-keycodes |
| Input processors | https://v0-3-branch.zmk.dev/docs/keymaps/input-processors |
| Kconfig reference | https://v0-3-branch.zmk.dev/docs/config |
