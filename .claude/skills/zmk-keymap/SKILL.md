---
name: zmk-keymap
description: Setup, configure, and code ZMK keymaps for the MoErgo Go60 keyboard in this repo. Use when editing config/go60.keymap or config/go60.conf, adding/changing ZMK behaviors (hold-taps, tap-dances, mod-morphs, macros, combos, sticky keys), remapping keys, building or flashing firmware, or answering ZMK syntax/configuration questions.
---

# ZMK Keymap Development (MoErgo Go60)

This skill covers ZMK keymap work in this repo: the ZMK framework itself and the MoErgo Go60 specifics layered on top of it.

## Reference files (load on demand)

- **`zmk-reference.md`** — ZMK framework: keymap/devicetree anatomy, behavior quick-table, full property references for hold-tap, tap-dance, mod-morph, macros, sticky-key, combos, modifier functions vs `MOD_*` constants, and a curated doc-URL map.
- **`go60-moergo.md`** — Go60/MoErgo specifics: the `moergo-sc/zmk` fork and why the **v0.3 docs** apply, build/flash paths, physical layout and `POS_*` naming, this keymap's architecture (TailorKey HRM layers, `KEYMAP_OS` toggle, custom behaviors), and repo conventions.

Also in the repo (don't duplicate, reference): `docs.md` (build system deep-dive), `wiki/keymap-behaviors.md` (hand-authored behaviors log), `/layout` command (ASCII position diagram).

## Critical rules

1. **Use the v0.3 ZMK docs** — `https://v0-3-branch.zmk.dev/docs/...` — not current `zmk.dev`. The firmware builds against the `moergo-sc/zmk` fork, which lags upstream; features documented only on current `zmk.dev` may not exist in the fork.
2. **Ground truth is the keymap file, not cached docs.** Layer names, position defines, and behavior inventories in `CLAUDE.md`/`docs.md` go stale. Before relying on a layer index or position number, grep the `#define LAYER_` / `#define POS_` blocks in `config/go60.keymap` (~lines 60–230).
3. **Always use symbolic defines** — `LAYER_Cursor` not `11`, `POS_RH_C5R3` not raw integers — in bindings, combos, and `hold-trigger-key-positions`.
4. **OS-sensitive shortcuts go through the `KEYMAP_OS` layer**, never raw `LG(...)`/`LC(...)`. Use the existing `OS_*` semantic constants (`OS_COPY`, `OS_WORD_LEFT`, ...) or add new ones to that block (~line 158).
5. **Never hand-edit `go60.uf2`** (build output) and never edit `config/info.json` for firmware purposes (visualizer metadata only).

## Workflow

1. **Locate** — grep `config/go60.keymap` for the layer block or behavior node. Use the `/layout` command or `tools/key-id.py` to map a physical key to its `POS_*` name.
2. **Read** the exact region before editing (the file is ~1900 lines; use offset/limit).
3. **Edit** with targeted edits, following the file's existing patterns (see `go60-moergo.md` § keymap architecture).
4. **Verify** — balanced `{} <> ;`, correct `#binding-cells` count vs. arguments passed at the call site, behavior references exist. For preprocessor-heavy changes, a standalone `gcc -E` check of the macro logic catches expansion bugs cheaply.
5. **Draw** — `make draw` (or `./draw.sh`) regenerates `keymap-drawer/`; a watcher may regenerate it automatically. Commit regenerated artifacts together with the keymap change.
6. **Build** — `make build` (Docker, skips git fetch) or `./build.sh [zmk-ref]`. Output: `go60.uf2` at repo root. CI builds on every push.
7. **Flash** — `./flash.sh` builds then copies to the bootloader drive (note: its mount detection is macOS-centric; see `go60-moergo.md` § flashing). Bootloader mode: Magic layer → `&bootloader` key.
