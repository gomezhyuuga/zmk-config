# ZMK Keycode Reference

Sourced directly from `moergo-sc/zmk`'s `dt-bindings/zmk/keys.h` (vendored in `headers/` alongside this file — **the exhaustive, offline ground truth**). Every name below is a `#define` usable as a `&kp`/`&mt`/`&sk`/`LS()` argument. Names separated by `/` are aliases for the same code.

**When a code isn't listed here, grep the vendored header instead of the web:**

```
grep -i -B1 'define.*<term>' .claude/skills/zmk-keymap/headers/keys.h
```

Each define is preceded by a `/* description */` comment, so grepping the description text works too (e.g. `grep -B0 -A1 'Volume Up' headers/keys.h`).

## Letters & numbers

`A`–`Z` (one code per letter; Shift produces uppercase). Numbers: `N1`/`NUMBER_1` … `N0`/`NUMBER_0`.

## Symbols & punctuation

Shifted symbols have dedicated codes (they expand to `LS(base)`), so prefer them over writing `LS(...)` by hand.

| Symbol | Code (aliases) | Base key |
|---|---|---|
| `!` | `EXCL` / `EXCLAMATION` / `BANG` | `N1` |
| `@` | `AT` / `AT_SIGN` | `N2` |
| `#` | `HASH` / `POUND` | `N3` |
| `$` | `DLLR` / `DOLLAR` | `N4` |
| `%` | `PRCNT` / `PERCENT` | `N5` |
| `^` | `CARET` | `N6` |
| `&` | `AMPS` / `AMPERSAND` | `N7` |
| `*` | `STAR` / `ASTRK` / `ASTERISK` | `N8` |
| `(` | `LPAR` / `LPRN` | `N9` |
| `)` | `RPAR` / `RPRN` | `N0` |
| `-` `_` | `MINUS` → `UNDER` / `UNDERSCORE` | |
| `=` `+` | `EQUAL` → `PLUS` | |
| `[` `{` | `LBKT` → `LBRC` / `LEFT_BRACE` | |
| `]` `}` | `RBKT` → `RBRC` / `RIGHT_BRACE` | |
| `\` `\|` | `BSLH` / `BACKSLASH` → `PIPE` | |
| `;` `:` | `SEMI` / `SEMICOLON` → `COLON` | |
| `'` `"` | `SQT` / `APOS` → `DQT` / `DOUBLE_QUOTES` | |
| `` ` `` `~` | `GRAVE` → `TILDE` | |
| `,` `<` | `COMMA` → `LT` / `LESS_THAN` | |
| `.` `>` | `DOT` / `PERIOD` → `GT` / `GREATER_THAN` | |
| `/` `?` | `FSLH` / `SLASH` → `QMARK` / `QUESTION` | |

Non-US: `NUHS` (Non-US `#`/`~`), `NUBS` (Non-US `\`/`|`), `TILDE2`, `PIPE2`.

## Control, whitespace, navigation, editing

- `ESC`, `TAB`, `SPACE`/`SPC`, `RET`/`ENTER`, `BSPC`/`BACKSPACE`, `DEL`/`DELETE`, `INS`/`INSERT`
- `CAPS`/`CAPSLOCK`, `PSCRN`/`PRINTSCREEN`, `SLCK` (Scroll Lock), `PAUSE_BREAK`
- Arrows: `LEFT`, `RIGHT`, `UP`, `DOWN` (aliases `LARW`/`RARW`/`UARW`/`DARW`)
- `HOME`, `END`, `PG_UP`/`PGUP`, `PG_DN`/`PGDN`
- `K_APP`/`K_CMENU` (context-menu key)
- Dedicated editing codes (rarely mapped by apps — prefer OS shortcuts via `KEYMAP_OS`): `K_UNDO`, `K_REDO`/`K_AGAIN`, `K_CUT`/`CUT`, `K_COPY`/`COPY`, `K_PASTE`/`PSTE`, `K_FIND`

## Function keys

`F1` … `F24`.

## Modifiers (as keycodes)

`LCTRL`/`LCTL`, `LSHIFT`/`LSHFT`/`LSFT`, `LALT`, `LGUI`/`LCMD`/`LWIN`/`LMETA` — and `R*` variants. These are ordinary keycodes for `&kp`/`&mt`/`&sk` params. (The `MOD_*` bitmask constants and `LS()/LC()/LA()/LG()` wrapper functions live in `headers/modifiers.h` — see zmk-reference.md § Modifiers.)

## Keypad (numpad)

`KP_N0`–`KP_N9`, `KP_DOT`, `KP_ENTER`, `KP_PLUS`/`KPLS`, `KP_MINUS`/`KMIN`, `KP_MULTIPLY`/`KMLT`, `KP_DIVIDE`/`KDIV`, `KP_EQUAL`, `KP_COMMA`, `KP_NUM`/`KP_NUMLOCK`, `KP_LPAR`, `KP_RPAR`.

## Media & consumer (the ones that matter)

Consumer-page codes (`C_*`) are what modern OSes actually listen to; the `K_*` keyboard-page duplicates (`K_VOL_UP`, `K_MUTE`, `K_PP`, ...) are legacy — prefer `C_*`.

- Volume: `C_VOL_UP`, `C_VOL_DN`, `C_MUTE`
- Playback: `C_PP` (play/pause), `C_NEXT`, `C_PREV`, `C_STOP`, `C_FF`, `C_RW`, `C_EJECT`
- Screen brightness: `C_BRI_UP`/`C_BRI_INC`, `C_BRI_DN`/`C_BRI_DEC`, `C_BRI_AUTO`
- Power: `C_PWR`, `C_SLEEP`; system page: `SYS_PWR`, `SYS_SLEEP`, `SYS_WAKE`
- macOS Globe key: `GLOBE`
- App launch (`C_AL_*`): `C_AL_CALC`, `C_AL_MAIL`, `C_AL_WWW` (browser), `C_AL_MY_COMPUTER`, `C_AL_LOCK` (lock screen/screensaver), `C_AL_FILES`, `C_AL_MUSIC`, ...
- App control (`C_AC_*`): `C_AC_SEARCH`, `C_AC_HOME`, `C_AC_BACK`, `C_AC_FORWARD`, `C_AC_REFRESH`, `C_AC_ZOOM_IN`/`C_AC_ZOOM_OUT`, `C_AC_COPY`/`C_AC_CUT`/`C_AC_PASTE`/`C_AC_UNDO`, `C_AC_DESKTOP_SHOW_ALL_WINDOWS` (Mission Control-ish), ...

Full `C_AL_*`/`C_AC_*`/`C_MEDIA_*` inventory (~150 codes): grep `headers/keys.h`.

## International & language

`INT1`–`INT9` (JIS: `INT_RO`, `INT_KANA`, `INT_YEN`, `INT_HENKAN`, `INT_MUHENKAN`), `LANG1`–`LANG9` (`LANG_HANGEUL`, `LANG_HANJA`, `LANG_KATAKANA`, `LANG_HIRAGANA`, `LANG_ZENKAKUHANKAKU`).

## Mouse (from `headers/pointing.h`)

- Buttons for `&mkp`: `MB1`/`LCLK`, `MB2`/`RCLK`, `MB3`/`MCLK`, `MB4`, `MB5`
- Movement for `&mmv`: `MOVE_UP`, `MOVE_DOWN`, `MOVE_LEFT`, `MOVE_RIGHT`, or explicit `MOVE_X(n)` / `MOVE_Y(n)` / `MOVE(x,y)` (default speed constant 600)
- Scroll for `&msc`: `SCRL_UP`, `SCRL_DOWN`, `SCRL_LEFT`, `SCRL_RIGHT` (default 10), or `MOVE_X/Y(n)` for custom amounts — this keymap uses `&msc MOVE_Y(35)` etc.

## Behavior parameters (not keycodes)

- **Bluetooth** (`&bt`, from `headers/bt.h`): `BT_SEL n`, `BT_DISC n`, `BT_NXT`, `BT_PRV`, `BT_CLR`, `BT_CLR_ALL`
- **Output** (`&out`, from `headers/outputs.h`): `OUT_USB`, `OUT_BLE`, `OUT_TOG`
- **RGB underglow** (`&rgb_ug`, from `headers/rgb.h`): `RGB_TOG`, `RGB_ON`/`RGB_OFF`, `RGB_HUI`/`RGB_HUD`, `RGB_SAI`/`RGB_SAD`, `RGB_BRI`/`RGB_BRD`, `RGB_SPI`/`RGB_SPD`, `RGB_EFF`/`RGB_EFR`, `RGB_COLOR_HSB(h,s,v)`, and **`RGB_STATUS`** (MoErgo fork only — battery/connectivity indication; not in upstream ZMK)
