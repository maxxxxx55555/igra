# Interface consistency (Session 23, CON1)

What is measured here is read from the sources by `python tools/qa_sim/consistency_check.py` (a static gate of `tools/check.sh --static`: it fails on an off-canon
font, an icon outside the brass family, a font size the ladder below does not hold, an odd margin, a facade colour over 25 % chroma). What needs a frame of a real
screen on a real device is named as an owner row at the end; nothing below claims a look that only a frame could show.

## 1. Typeface: one family of three roles (a decision)

The directive asks for one UI typeface. The canon of the project is three faces with fixed roles (GDD 11.3): the body is Roboto Condensed
(`font_body`, `scripts/ui/theme_provider.gd:63`), the headings, the buttons and the tabs Bebas Neue emboldened (`font_heading`, line 64), the text fields Share Tech
Mono (`font_mono`, line 68). Every screen takes its theme from `ThemeProvider.build_theme()`, which the autoload `ThemeSetup` sets window-wide
(`scripts/theme_setup.gd`), so no screen picks a face of its own. The consistency gate finds exactly five font files named by shipped sources: the three above,
Rajdhani (the base of the engine's fallback font, with the system font behind it for the glyphs the shipped faces lack, CJK and Arabic: `UI_FONT_PATH` in
`scripts/i18n/localization_manager.gd:26`) and OpenDyslexic (the Dyslexia Font option; the file is not shipped, the owner supplies it: `scripts/systems/settings_manager.gd:441`). Decision (TZ row CON-23): keep the canon of
three roles, not a second pass that would redraw every screen in one face; the roles are the hierarchy.

## 2. The size ladder

The sizes in px of the 1920 x 1080 canvas that the UI scenes and scripts pin (`window/size/viewport_width` and `_height`, `window/stretch/mode="canvas_items"`:
`project.godot:92-95`); the theme's own are 16 for the body (`FONT_SIZE_BODY`, `scripts/ui/theme_provider.gd:21`) and 22 for a title (`FONT_SIZE_TITLE`, line 23):

| Size | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 16 | 18 | 20 | 22 | 24 | 28 | 32 | 36 | 44 | 64 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Files | 2 | 1 | 7 | 7 | 8 | 3 | 11 | 6 | 5 | 7 | 6 | 2 | 5 | 1 | 1 | 1 | 1 |

17 distinct sizes, 4 of them under 12 px (19 files). A modular scale would hold six or seven. It is **not collapsed in this pass**: every size sits in a layout
that was fitted in 13 locales and 3 text scales (the shop at 39 of 39 cases, the close buttons in 13 locales: `docs/RUN_STATE.md`, row L24), and a collapse
changes widths in all of them without a frame to prove none overflows. The gate is a ratchet: a new size is a decision, then a value of `SIZE_LADDER` in the tool.
The text-scale option moves every size together (`TEXT_SCALE`, `scripts/systems/settings_manager.gd:419`: 0.9, 1.0, 1.15).

**Owner row U-1 (phone legibility, also U13 of `docs/UNVERIFIABLE_HERE.md`).** On a phone in landscape (2400 x 1080) the canvas scales by 1.0, so the 16 px body is 16
device pixels: about 5 dp at 400 dpi, 1.5 % of the screen height. A PC game at 1080p reads at that size; a phone may not. Executable action: install the signed AAB on a
phone, read the HUD, the inventory and the settings; if the text is small, raise the Large step of `TEXT_SCALE` for touch devices (the layouts were fitted up to
1.15, so a larger step needs the shop and the close-button checks re-run at the new value).

## 3. Spacing

Every margin and separation a UI scene pins is even: 4, 6, 10, 12, 14, 16 and 20 (the gate fails on an odd one). The panels of the theme take 12 as their content
margin and the buttons 10 (`scripts/ui/theme_provider.gd`, `build_theme`). The corner radius of the theme's panel and button is 0 (the chamfer of the style guide).

## 4. Colour

91 hex literals in the UI scripts and scenes, 27 distinct: 69 (76 %) are the ten tokens of `docs/STYLE_GUIDE.md` section 2 (brass `#c9a24a` is the most used:
`COLOR_AMBER` in `scripts/ui/theme_provider.gd:14`). The 22 others are listed by the tool: 0d0f12 15181d 1b232e 20242b 2f4a22 3a2a22 3a3226 3a3f47 5a2a2a 7a5a23 7fc4d9
8c8a82 c98a2e e6cf6e e8a13a f2c879 ff3030 ff5050. Two of them are the subtitle colour options (yellow `e6cf6e` and cyan `7fc4d9`, an accessibility feature, G1), the
rest belong to the asset registry, the visual-style helper that draws the player's marker (`asset_registry.gd`, `visual_style.gd`), the joystick and the minimap. Pure black appears
only as the fade-to-black of a transition (`scripts/ui/fade_transition.gd:29`) and pure white only as the neutral modulate that tints nothing (`Color.WHITE`), never as a surface. Not changed in this pass: a retint of those shades changes how a
screen reads and needs the frames; listed as owner row U-2 (collapse the 18 shades into the ten tokens, screen by screen, a frame each).

## 5. Icons: one brass family (changed in this pass)

Ten icons live in `assets/ui`. Five were the placeholder style of the first HUD: a green battery, a red cross, a yellow bullet, a white torch, and a white E in a
circle whose letter was an SVG text node (the importer draws no text, so the letter never showed). They were redrawn as outline icons in the family of the key and the
backpack: one colour, the brass token `#c9a24a` (the five that already were brass said `#C8A24A`, one level off the token, now aligned), a 64 x 64 box, strokes of 4 with
round caps and joins, and no byte order mark (the five old files carried one). The table is the tool's own: all ten read `#c9a24a`, `0 0 64 64`, stroke 4 or fill-only.
The live HUD shows the heart (`ui_heart.svg`), the battery and the touch interact button (`scenes/ui/hud_3d.tscn`); the other three are used by the older `hud.gd`.

## 6. Micro-interactions

| Interaction | Feedback | Where |
|---|---|---|
| a button under the mouse or the focus | grows to 1.05 in 0.12 s, settles back (not on touch, not with Reduce UI Motion) | `HOVER_SCALE` and `HOVER_SEC`, `scripts/theme_setup.gd:14-15` |
| a press | scales to 0.95 and clicks | `PRESS_SCALE`, `scripts/systems/uisfx.gd:122` |
| a screen opens or closes | a short slide and fade, hidden at once with Reduce UI Motion | `_animates`, `scripts/ui/ui_manager.gd:239` |

Checks POL1 and POL2 hold the press and the screen fade (`docs/POLISH.md`).

## 7. What this pass cannot show (owner rows)

- **U-1** the phone legibility above.
- **U-2** the 18 off-palette shades.
- **U-3** the matrix of every screen in 13 locales at 3 text scales on a device: the shop and the close buttons are proved in the engine, the rest is held by the string
  length heuristic (`tools/qa_sim/overflow_check.py`: 0 of 6 candidates at a fixed width), which cannot measure a rendered width.
