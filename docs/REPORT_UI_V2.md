# REPORT_UI_V2 — UI Skin V2 art pass (screens + chrome, VISUAL ONLY)

Scope: `assets/textures/screens_v2/**` (6), `assets/textures/ui_v2/**` (35). Additive only; no code/scene/data touched.
Canon: docs/ART_UI_STYLE.md tokens — bg-deep #0c1016, panel #141b24, panel-edge #2a3340, brass #c9a24a, brass-dim #8a7338, ember #b4452f, steel #aeb6bf, bone #d8d2c4, stamina #5f8a4e. No pure black/white; muted saturation.

DEFAULT_CHOICE marks (DESIGN LANGUAGE V2 block was not supplied with the brief):
- `panel_olive` = PANEL base tinted toward stamina green (fill #1f2a22, edge #3e4f40) — olive reading of canon darks
- `amber` bar/hex accent = derived muted #c08a2e (accent sat <60% rule)
- coin canvases 192×192; logo_grunge delivered as RGBA distress/stencil texture (brass tint) for overlay use
- 9-slice safe margin = 10px uniform transparent gutter on panels/buttons/tabs/slots/hexes

QA: 41/41 files PASS — dims per spec, all ≤500KB (screens quantized ≤64 colors, visually lossless at night values), zero pure-black/pure-white pixels, margins verified uniform, textless verified by construction + edge-density probe (0.015% high-frequency pixels on loading_street; no glyph clusters).

## T1 — Screen backgrounds (1920×1080, textless) → screens_v2/

| File | Size | Consumer hint |
|---|---|---|
| loading_street.png | 442KB | Loading screen bg (`scripts/ui/screens.gd` "Loading" / pre_loading.gd) |
| death_loom.png | 438KB | Death screen bg (`scripts/ui/death_screen.gd`, UIManager &"death") |
| menu_hero.png | 426KB | Main menu hero bg (`scripts/ui/main_menu.gd` + menu_background.gd) |
| character_dim.png | 497KB | Character/stats screen bg (`screens.gd` "Character"/"Stats") |
| journal_paper.png | 423KB | Journal paper texture (`scripts/ui/journal_ui.gd`, quest_journal.gd reader pane) |
| journal_photo.png | 464KB | Journal photo/polaroid slot (journal_ui.gd found-item viewer) |

## T2 — Panel/chrome kit → ui_v2/

| File | Size | Consumer hint |
|---|---|---|
| panel_olive_256.png | 0.8KB | 9-slice panel: settings/workbench/shop cards (`settings_screen.gd`, `screens.gd` build_*) |
| panel_small_128.png | 0.4KB | Small panel/dialog chrome (`pause_menu.gd`, toasts) |
| tab_normal_128x32.png / tab_active_128x32.png | 0.2KB | Settings tabs game/controls/graphics/audio/access (`settings_screen.gd`), shop tabs (`screens.gd`) |
| btn_primary_{normal,hover,pressed,disabled}_256x64.png | 0.3–0.5KB | Primary actions (menu Play, map travel, revive) |
| btn_secondary_{normal,hover,pressed,disabled}_256x64.png | 0.3–0.5KB | Secondary/back buttons |
| bar_track_256x8.png | 0.1KB | ProgressBar under-track (`hud_3d.gd` HP/Stam/Bat) |
| bar_fill_{green,amber,red,brass}_256x8.png | 0.1KB each | HP=red, stamina=green, battery=brass, warn=amber |
| hex_{green,amber,red,grey,locked}_128.png | 0.6–0.7KB | Status pips/bestiary met-count markers (`bestiary`, quest states) |
| slot_v2_72.png / quickslot_v2_72.png / equip_slot_v2_96.png | 0.3–0.4KB | Inventory grid, HUD quick wheel (`quick_wheel_ui.gd`), equip pane |
| flashlight_render_512.png | 8.9KB | Flashlight upgrade panel item render (shop/skill tree) |
| coin_{500,1200,2500,6000}.png | 0.7–2.8KB | Shop coin-pack tiers (`screens.gd` _populate_shop, `coin_hud.gd`) |
| weather_{rain,fog,storm,wind}_256x144.png | 0.9–5.5KB | Weather forecast widget (`scripts/ui/weather_overlay.gd`) |
| logo_grunge_512.png | 20KB | Title logo distress overlay (textless stencil texture, multiply/mask) |

## Integration notes
- All chrome is 9-slice safe: StyleBoxTexture margins = 12px recommended (10px clean gutter + 1px AA).
- Buttons ship full state quads; swap via theme normal/hover/pressed/disabled.
- Screens are palette-quantized PNG8 — import as-is, no mipmaps needed for full-screen use.
