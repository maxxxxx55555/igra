# HUD plan (internal, Session 22)

Scope: what is on screen while the player plays, what stays, what shows only while it matters, what goes. Visual and layout only: no
gameplay rule changes. Canon: `docs/ART_UI_STYLE.md` (tokens, "HUD - layout", flashlight panel, icons), `docs/STYLE_GUIDE.md` (palette),
`docs/UI_SPEC.md` (HUD_BATTLE). Evidence: the shipped frames `docs/stills/shipping/03_*` and `04_*` (hash 2e018d3), a runtime dump of every
visible HUD node taken in the BEFORE launch (`docs/artifacts/rc16/proofs/s22_hud_dump_before.txt`), and the AF3 frames of each batch.

## What the frames show (defects, read off the frame, not taste)

1. Two maps stacked in the top-right corner: the HUD radar (164 px, `scenes/ui/hud_3d.tscn` TopRight) and UIManager's city minimap
   (220 px, `scripts/ui/minimap.gd`), one ring inside the other. The "which top-right map wins" decision was pending since rc10.
2. "RADAR" is drawn on top of the ring; the minimap's "?" legend chip sits on the ring's lower-left edge.
3. The stat grid is not one grid: HEALTH/STAMINA/BATTERY captions are 12 px over bars that start at x 0, NOISE/VISIBILITY captions are
   16 px beside bars that start at x 88; the value ("100") is clipped at the bar's end.
4. Five rows always on (health, stamina, battery, noise, visibility) although three of them say "nothing" most of the time.
5. A "MELEE" caption bottom-right in a build whose default is no gun; an emoji glyph (map) and a plain "LOG" box under the stats, both
   persistent; a hexagon pause button on desktop, where Esc pauses.
6. Touch clusters are opaque panels (canon: the joystick is invisible at rest and shows a brass ring on touch).

## Principles and what this pass does with each

| Principle | Decision |
|---|---|
| Diegetic where possible | Not attempted: the low-HP vignette, the noise vignette and the heartbeat already carry health and noise in the world; a diegetic redesign is a visual project of its own. |
| Interact prompt only in range, fades | In range only already (`player_interact_available`); batch 2 adds the fade in and out. |
| Combat HUD hides about 5 s out of combat | Batch 2: ammo counter, crosshair and enemy bar fade 5 s after the last shot, hit or aim. |
| Health: arc or vignette, not big bars | The vignette exists (`_LOW_HP` 0.3). The bar becomes a slim contextual row: shown below full health or after a change, faded at rest. |
| Charges as compact pips | Battery becomes 8 segments (canon: "segmented scale", full brass, mid brass-dim, empty panel), value shown only when low. |
| Minimap toggleable | One map in play: the radar. The city minimap becomes a setting (`show_minimap`, off by default); the full map stays on the Map button / M. |
| Touch controls semi-transparent, edge-anchored, device-scaled | Batch 2: rest alpha 0.55 (full while pressed); anchoring stays; `button_size` already scales them. |
| One UI typeface, one hierarchy | The theme already is Bebas Neue (headings, buttons) / Roboto Condensed (text) / Share Tech Mono (numbers). The HUD's own labels fall to Roboto Condensed at two sizes (12 and 16); this pass sets caption 12 / value 13 / prompt 18 for every row. Numerals stay Roboto Condensed (a font swap is batch 3 if a launch is left). |
| Unified icon stroke | Only for the buttons this pass touches (map, pause): outline icons in brass, as the canon says. The others are not redrawn. |
| Zero debug text in release | Checked: no FPS, no coordinates, no developer strings in the HUD (grep of `scripts/ui`). |
| Settings: HUD opacity and scale | Opacity exists (0.5 to 1.0, `hud_opacity`). Batch 2 adds scale (`hud_scale`, 0.8 to 1.3). |

## Inventory: every persistent element

Class: KEEP (always, quiet), CONTEXTUAL (shows while it matters, fades at rest), REMOVE (gone), TOUCH (only where there is a touch screen).

| # | Element | Source | Class | Action | Batch |
|---|---|---|---|---|---|
| 1 | Health row (icon, track, fill, value, caption) | hud_3d.tscn TopLeft/HP | CONTEXTUAL | slim bar, caption dropped (the icon names it), value hidden; shown below 100 % or after a change, faded 3 s after full | 1 |
| 2 | Stamina row | TopLeft/Stam | CONTEXTUAL | shown below 100 %, faded 1.5 s after full | 1 |
| 3 | Battery row | TopLeft/Bat | KEEP | 8 pips, value only under 30 %, rest alpha 0.7 | 1 |
| 4 | Noise row | TopLeft/NoiseLabel, NoiseT, NoiseF | CONTEXTUAL | on the same grid; shown at noise >= 0.34 | 1 |
| 5 | Visibility row | TopLeft/VisibilityLabel, VisibilityT, VisibilityF | CONTEXTUAL | on the same grid; shown at visibility >= 0.15 | 1 |
| 6 | "RADAR" caption | TopRight/RadarLabel | REMOVE | hidden (the ring says it) | 1 |
| 7 | City minimap, its "?" chip and legend | scripts/ui/minimap.gd, UIManager overlay | CONTEXTUAL | a setting, off by default; the radar is the one map | 1 |
| 8 | Radar | TopRight/RadarFrame, scripts/ui/radar.gd | KEEP | none | - |
| 9 | Pause button | hud_3d.tscn BtnPause | TOUCH | hidden without a touch screen (Esc pauses) | 1 |
| 10 | Map button (emoji glyph) | hud_3d.gd `_add_map_button` | TOUCH | outline icon, touch only; M and the pause menu open the map | 1 |
| 11 | Ammo counter and "MELEE" caption | hud_3d.tscn AmmoCounter | CONTEXTUAL | hidden without a gun; with one, 5 s after the last shot | 2 |
| 12 | Crosshair | hud_3d.tscn Crosshair | CONTEXTUAL | shown with a gun or on an enemy in the aim cone, 5 s hold | 2 |
| 13 | Enemy name and bar, resist label | hud_3d.tscn EnemyName, EnemyHPBar | CONTEXTUAL | hold 2 s becomes 5 s | 2 |
| 14 | Interact prompt | hud_3d.tscn PromptLabel | CONTEXTUAL | fade in 0.12 s, out 0.2 s | 2 |
| 15 | Notice line | hud_3d.tscn NoticeLabel | CONTEXTUAL | fades out with the 3 s timer | 2 |
| 16 | Quick slots (6) | BottomCenter | KEEP | none | - |
| 17 | Log toggle | scripts/ui/toast_manager.gd LogToggle | CONTEXTUAL | rest alpha 0.4, full on a new entry | 2 |
| 18 | Joystick ring, four action buttons, four side buttons | BottomLeft, BottomRight, `_add_side_buttons` | TOUCH | rest alpha 0.55, full while pressed | 2 |
| 19 | Weight bar | hud_3d.tscn WeightBar | KEEP | no textures, draws nothing: no action | - |
| 20 | Status icons, quest tracker, district banner, toasts, tutorial card, vignettes, grain, flashes | various | KEEP | already contextual or transient: no action | - |
| 21 | HUD scale | new setting | - | `hud_scale` slider in Settings, applied to the stat block and the radar | 2 |

## Batches (each at most 3 items, one windowed launch, BEFORE and AFTER read)

- Batch 1, "quiet corner": rows 1 to 5 (one grid, contextual, battery pips); rows 6 and 7 (one map); rows 9 and 10 (touch-only buttons).
- Batch 2, "in play": rows 11 to 13 (combat hold), 14 and 15 (fades), 17 and 18 (rest alpha), 21 (scale).
- Kept or reverted by the frames, per batch, whole batch; the revert list is published in `docs/BEAUTY_RC16.md`.

## Frames (AF3, hash and UTC in the name)

Calm exploration (everything at rest), hurt (health below full, vignette), combat (gun, enemy bar), interact in range, and a touch layout at
a phone aspect (touch emulated with `input_devices/pointing/emulate_touch_from_mouse`, which `DisplayServer.is_touchscreen_available`
reads). Each is shot BEFORE (this commit) and AFTER each batch; the six release frames are re-shot once at the final code.

## Gates

`bash tools/check.sh --static` after each change; the closeout group `s22` (HUD checks: rows fade and wake, one map, touch-only buttons,
13 locales x 3 scales stay inside the screen and off each other); `bash tools/check.sh --all` once at the end; i18n 12 of 12 and the
hardcoded-text gate for the one new setting label. Perf is read windowed at the end (draw calls, p95), audio gate beside it.

## Not done, named

Diegetic redesign; redrawing the icon set; a font swap for numerals (unless a launch is left); a floating (touch-placed) joystick, which
would change input behaviour.
