# HUD plan (internal, Session 22)

Scope: what is on screen while the player plays, what stays, what shows only while it matters, what goes. Visual and layout only: no
gameplay rule changes. Canon: `docs/ART_UI_STYLE.md` (tokens, "HUD - layout", flashlight panel, icons), `docs/STYLE_GUIDE.md` (palette),
`docs/UI_SPEC.md` (HUD_BATTLE). Evidence: the shipped frames `docs/stills/shipping/03_*` and `04_*` (hash 2e018d3), a runtime dump of every
visible HUD control taken in the BEFORE launch (ledger row 84, `docs/artifacts/rc16/proofs/s22_hud_before.attach.hud_dump.txt`: calm, combat and touch states,
294 lines), the BEFORE frames (`docs/stills/shipping/hud/before/`, hash 8874bb9: calm, hurt, prompt, combat, touch layout) and the AF3 frames of each batch.

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
7. Found by the dump, not by eye: the quest tracker is drawn at x = -320 (`QuestHUDContainer|VBoxContainer|-320,252,300,200`). UIManager builds the
   overlay as a Control with no size and the panel anchors to that, so the objectives list has been off screen in every frame.
8. Found by the dump and the touch frame: the right action cluster is a 280 x 260 box whose children are laid out from its bottom-right corner (offsets
   -100, -180, ...), so the buttons sit about 300 px in from the screen edge on a wide phone and the four side buttons (jump, flash, strobe, wheel) overlap
   Attack and Stealth (`12_hud_touch_before_*`: Attack at x 1955, wheel at 2011, Stealth at 1975 to 2045, on a 2336 px wide canvas).
9. The staged "hurt" frame is a 12 HP hit (`take_damage` caps one hit at 12), not 45: it shows the state of a scratch, which is what the pairs compare.

## Principles and what this pass does with each

| Principle | Decision |
|---|---|
| Diegetic where possible | Not attempted: the low-HP vignette, the noise vignette and the heartbeat already carry health and noise in the world; a diegetic redesign is a visual project of its own. |
| Interact prompt only in range, fades | In range only already (`player_interact_available`); batch 2 adds the fade in and out. |
| Combat HUD hides about 5 s out of combat | Batch 2: ammo counter, crosshair and enemy bar fade 5 s after the last shot, hit or aim. |
| Health: arc or vignette, not big bars | The vignette exists (`_LOW_HP` 0.3). The bar becomes a slim contextual row: shown below full health or after a change, faded at rest. |
| Charges as compact pips | Battery becomes 8 segments (canon: "segmented scale", full brass, mid brass-dim, empty panel), value shown only when low. |
| Minimap toggleable | One map in play: the radar. The city minimap becomes a setting (`show_minimap`, off by default); the full map stays on the Map button (touch) and its key (`city_map_toggle`, K). |
| Touch controls semi-transparent, edge-anchored, device-scaled | Batch 2: rest alpha 0.55 (a press wakes a button to full for 0.4 s, the joystick ring stays full under the thumb); the cluster is re-anchored at its corner (row 23); `button_size` scales the action buttons, and the four side buttons with them since the verifier's round (CORRECTION_LOG 208). |
| One UI typeface, one hierarchy | The theme already is Bebas Neue (headings, buttons) / Roboto Condensed (text) / Share Tech Mono (numbers). The HUD's own labels fall to Roboto Condensed at two sizes (12 and 16); this pass sets every row's caption to 12 and its value to 13 (the prompt keeps the theme's size). Numerals stay Roboto Condensed (a font swap was batch 3, not built). |
| Unified icon stroke | Only for the buttons this pass touches (map, pause): outline icons in brass, as the canon says. The others are not redrawn. |
| Zero debug text in release | Checked: no FPS, no coordinates, no developer strings in the HUD (grep of `scripts/ui`). |
| Settings: HUD opacity and scale | Opacity exists (0.5 to 1.0, `hud_opacity`). A separate scale slider (`hud_scale`) was planned and not built: the Text Size setting is the UI scale (row 21). |

## Inventory: every persistent element

Class: KEEP (always, quiet), CONTEXTUAL (shows while it matters, fades at rest), REMOVE (gone), TOUCH (only where there is a touch screen).

This table is the plan as it was written before the work; the Outcome section below is what stands (row 9, the Pause button, is dimmed on a keyboard, not hidden; row 21 was not built).

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
| 10 | Map button (emoji glyph) | hud_3d.gd `_add_map_button` | TOUCH | outline icon, touch only; a keyboard has the map key (`city_map_toggle`, K) | 1 |
| 11 | Ammo counter and "MELEE" caption | hud_3d.tscn AmmoCounter | CONTEXTUAL | hidden without a gun; with one, 5 s after the last shot | 2 |
| 12 | Crosshair | hud_3d.tscn Crosshair | CONTEXTUAL | shown with a gun or on an enemy in the aim cone, 5 s hold | 2 |
| 13 | Enemy name and bar, resist label | hud_3d.tscn EnemyName, EnemyHPBar | CONTEXTUAL | hold 2 s becomes 5 s | 2 |
| 14 | Interact prompt | hud_3d.tscn PromptLabel | CONTEXTUAL | fade in 0.12 s, out 0.2 s | 2 |
| 15 | Notice line | hud_3d.tscn NoticeLabel | CONTEXTUAL | fades out with the 3 s timer | 2 |
| 16 | Quick slots (6) | BottomCenter | KEEP | none | - |
| 17 | Log toggle | scripts/ui/toast_manager.gd LogToggle | CONTEXTUAL | rest alpha 0.4, full on a new entry | 2 |
| 18 | Joystick ring, four action buttons, four side buttons | BottomLeft, BottomRight, `_add_side_buttons` | TOUCH | rest alpha 0.55; a press wakes a button to full for 0.4 s (the joystick ring stays full under the thumb) | 2 |
| 19 | Weight bar | hud_3d.tscn WeightBar | KEEP | no textures, draws nothing: no action | - |
| 20 | Status icons, quest tracker, district banner, toasts, tutorial card, vignettes, grain, flashes | various | KEEP | already contextual or transient: no action | - |
| 21 | HUD scale | new setting | - | `hud_scale` slider in Settings, applied to the stat block and the radar | 3 |
| 22 | Quest tracker | scripts/ui/quest_tracker_hud.gd, UIManager overlay | CONTEXTUAL | anchored to the screen (it was off screen); shown 8 s after an objective changes, faded at rest | 1 |
| 23 | Touch action cluster (Attack, Interact, Sprint, Stealth) | hud_3d.tscn BottomRight | TOUCH | anchored at the corner so the offsets mean what they say; no overlap with the side buttons | 2 |

## Batches (each at most 3 items, one windowed launch, BEFORE and AFTER read)

- Batch 1, "quiet corner": rows 1 to 5 (one grid, contextual, battery pips); rows 6, 7, 9 and 10 (one map, touch-only buttons); row 22 (the tracker).
- Batch 2, "in play": rows 11 to 13 (combat hold), 14 and 15 (fades), rows 17, 18 and 23 (touch cluster re-anchored, rest alpha).
- Batch 3, only if launches are left: row 21 (scale slider, one new label in 13 locales), numerals in the mono face.
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

## Outcome (Session 22)

Three launches of frames (BEFORE `8874bb9`, batch 1 `51e2265`, batch 2 `ccf61ee`), each read; both batches kept, nothing reverted. The frames:
`docs/stills/shipping/hud/before/`, `.../hud/after1/`, `.../hud/after2/` (calm, hurt, prompt, combat, touch layout), and the six release frames of batch 2 in
`docs/stills/shipping/`. The plan's own claims about the old HUD were checked against the BEFORE dump (two more defects than the plan had when it was written: the
objective list off screen, the touch cluster mis-anchored). Batch 3 was not run: no launch was left to read it. The frames of `.../hud/after1/` were shot at `51e2265` and are the record of batch 1: batch 2 changed the runtime, so `af3_frame_check.py --dir docs/stills/shipping/hud/after1` reports F4 by design (the gated sets are the default set and `.../hud/after2/`; CORRECTION_LOG 209).

| Row | Result | Evidence |
|---|---|---|
| 1 Health | contextual: faded at full health (alpha 0.00), up at once when hurt, 3 s after full; value shown with the row | HUDP1; frames 03 and 10 |
| 2 Stamina | contextual, 1.5 s; value never shown | HUDP1 |
| 3 Battery | first row, eight segments behind seven gaps, value only at 30 % or less | HUDP2; frame 03 |
| 4, 5 Noise, visibility | one grid with the others (a 12 px caption over a bar of the same size), contextual (0.34 and 0.15), placed under the battery | frames 03, 10, 04 |
| 6 RADAR caption | removed (hidden in the scene) | HUDP3 |
| 7 City minimap | the setting `show_minimap`, off by default; its "?" chip goes with it; Settings > Controls > Minimap, 13 languages | HUDP3 |
| 8 Radar | kept; it now fills its frame (it sat 16 px off) | HUDP3 |
| 9 Pause button | kept (the loop runner clicks it); rests at alpha 0.5 on a keyboard | HUDP5 |
| 10 Map button | touch only, text from `MAP_TITLE` (the emoji glyph is gone) | HUDP5; frame 12 |
| 11 Ammo counter | caption hidden without a gun; 5 s hold | frame 03 against 04 |
| 12 Crosshair | rests faded, wakes on a shot, a hit, an ammo change or an enemy in the aim, 5 s | HUDP7; frames 03 and 04 |
| 13 Enemy bar | hold 2 s becomes 5 s | code |
| 14 Prompt | fades in 0.12 s, out 0.2 s, then hidden | HUDP8; frame 11 |
| 15 Notice | fades out before its 3 s timer clears it | code |
| 17 LOG toggle | rests at 0.45, full for 4 s after a new entry | frames |
| 18 Touch controls | rest at 0.55 and wake to full for 0.4 s on a press; the joystick ring rests at 0.55 and is full under the thumb, and fades only the HUD's ring (the first-run calibration dialog hosts a joystick in a container that keeps its alpha) | HUDP10; frame 12 |
| 22 Objective list | on the screen (it was at x = -320), lets every click through, shown for 8 s when an objective changes (by code it does not show at the very start of a first run: the start hook needs a list that a refresh has already made visible; CORRECTION_LOG 209, KNOWN_ISSUES) | HUDP4; frame 03 |
| 23 Touch action cluster | anchored at its corner; Attack, Sprint, Stealth, Interact and the four side buttons clear of each other at Button Size 1.0 (HUDP9) and from 0.8 to 1.5 (HUDP11: the side buttons are children of the right cluster, so the size slider scales all eight) | HUDP9, HUDP11; frame 12 |
| 16, 19, 20 | no action (quick slots, the weight bar that draws nothing, the status icons and the other transient elements) | |
| 21 HUD scale | not built: the Text Size setting is the UI scale (0.85, 1.0, 1.2 of the window) and the layout holds at the three sizes in 13 languages (HUDP6) | CORRECTION_LOG 206 |

Not done, named: diegetic health, a redrawn icon set, numerals in the mono face, a floating joystick, a separate HUD scale slider. Counts: the visible
controls of the calm frame, 39 before and 25 after (alpha above 0; the quick slots, the full-screen overlays and the whole objective list left out; counted by script over the three dumps, CORRECTION_LOG 209).
