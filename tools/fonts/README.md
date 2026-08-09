# Vendored icon font

`SymbolsNerdFontMono-Regular.woff2` — the icon source for `tools/gen-layout-html.py`.
It supplies the Nerd Font glyphs used by custom labels in `config/layout-view.json`.

Vendored rather than CDN-linked or read from the system so the generated page is
byte-identical everywhere and builds offline, on machines with no Nerd Font installed.
Only a subset of the icons actually used is inlined into `output/layout.html` (a couple of
KB), so this 1.1 MB file never ships to the page.

## Provenance

Symbols-only Nerd Font v3.4.0 (10410 icons), converted from TTF to woff2 with fontTools
to cut it from 2.4 MB:

```bash
curl -sLO https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v3.4.0/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf
python3 -c "from fontTools.ttLib import TTFont; f=TTFont('SymbolsNerdFontMono-Regular.ttf'); f.flavor='woff2'; f.save('SymbolsNerdFontMono-Regular.woff2')"
```

Upstream: <https://github.com/ryanoasis/nerd-fonts> (MIT). Re-run the above with a newer tag
to pick up icons added since v3.4.0.
