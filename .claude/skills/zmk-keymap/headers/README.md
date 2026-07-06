# Vendored ZMK dt-bindings headers

Copied verbatim from `moergo-sc/zmk@main` (`app/include/dt-bindings/zmk/`), fetched 2026-07-06. MIT-licensed. These are the exact headers the firmware compiles against — grep them for keycodes and behavior-parameter defines instead of fetching docs.

Refresh (rarely needed; these change very little):

```sh
cd .claude/skills/zmk-keymap/headers
for f in keys.h modifiers.h pointing.h rgb.h bt.h outputs.h; do
  curl -sfL "https://raw.githubusercontent.com/moergo-sc/zmk/main/app/include/dt-bindings/zmk/$f" -o "$f"
done
```
