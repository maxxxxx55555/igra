# Final source pass — 2026-10-28

The deliverable is one PowerShell file. It contains the source delta, the AI
handoff, the Play Console checklist and the transport verification report.
The source pass is complete for the changes below; engine and device acceptance
are separate work and have no invented PASS status.

## Game behavior

| Change | Live consumer | Regression to run in Godot |
|---|---|---|
| First Light unlocks when streetlights actually turn on; no duplicate puzzle grant | `ProgressTracker`, `AchievementManager`, `PowerGrid` | attack simulator: PARTIAL puzzle, STREETS transition, repeat event |
| Truth achievement uses the ending’s eligibility API and the actual bunker | `Endings.evaluate`, matching `EndingsManager` | TRUTH1/2: other secrets cannot substitute for the bunker |
| Milestone autosaves wait for progress and reward signal consumers | `SaveSystem` | SECRETSAVE1/2: collect → persisted secret/counter/item/wallet |
| Daily claim persists the reward and claim together before notifications | `DailyChallengeManager`, `SaveSystem` | DAILYSAVE1/2: entire reward persisted; repeated claim pays nothing |
| Wheel uses the six saved bindings, preserves Pause and blocking screens | `QuickWheelUI`, HUD quick-slot dispatch | WHEEL1/2/3: rebound medkit, backpack order, pause |
| Warmth follows district power: cold, cool, warm | `PowerGrid.get_thermal_comfort`, HUD badge | THERMAL1: DARK/PARTIAL/STREETS/FULL; no new damage or timer |
| First HUD frame reads saved HP/stamina and upgraded battery capacity | `HUD._ready` | VITALS1: 40/100 HP, 60/200 stamina, 75/150 battery |
| Quality changes reapply district grading in the same order as boot | `WorldEnvSetup` | GRADE1: Low/Ultra preserve the district post-processing |

`CLOSEOUT_ONLY=final` runs the new completion group, daily and ending checks.
The normal full closeout includes the same new group. These new engine checks
were parsed/linted here; they still require actual execution.

## Visual implementation

- A newly authored night-street illustration puts the small warm streetlight
  on the right and leaves dark space for the controls on the left. The source
  is `assets/ui/menu_city.svg`; the game uses its 1920×1080 PNG rasterization.
  No lettering is baked into the art. The old hero asset is retained.
- The menu uses a reading column, directional scrim, heading font and thin
  outline. Its artwork covers the viewport while retaining its aspect ratio.
  Buttons and the daily card reflow on resize and language change. Existing
  parallax, fog and comfort settings remain connected.
- Shop panel bounds follow the viewport. Its catalog switches between one
  and two columns; item names wrap, icons are 42 px, body text 20 px and Buy
  controls at least 220×44 px in design coordinates.
- HUD captions/values are 18 px with a 40 px row pitch. Objectives use a 22 px
  heading, 20 px body and panel padding. The warmth badge shares the status row.
  The wheel uses item icons, slot numbers and a single readable selected name.
- Toasts are hidden over blocking screens and in Trailer Mode. New entries
  queue until the HUD returns; the history remains available.

All dimensions above are design-space values: the project's canvas is
1920×1080 and scales to the device. Fresh captures must check the actual result
at 1280×720, 1920×1080, wide aspect ratios and all supported text sizes. The
existing SHOP1, HUDP4/layout, Trailer and menu-parallax checks remain in use.
The caption-width assertion now uses the actual 220 px design width.

The illustration is original project art created in this pass, with no
third-party images, logos, generated lettering or borrowed franchise assets.
Its PNG was rendered from the SVG with CairoSVG 2.9.1 at the native dimensions
and visually inspected at 1280×720. That inspection verifies the artwork only;
it is not a new gameplay screenshot or evidence of a Godot/GPU run.
Optional reproduction: `cairosvg assets/ui/menu_city.svg -o assets/ui/menu_city.png`.
The PNG avoids dependence on importer support for SVG patterns; Godot documents
limited SVG support at https://docs.godotengine.org/en/latest/tutorials/assets_pipeline/importing_images.html.

## Scope and acceptance

GDD §25.2 is a historical checklist, not a current inventory of missing code.
The existing source already supplies the enemy roster, equipment, rarity,
weapon comparison, damage/status HUD, blueprints and photo album. Settings use
five populated tabs per the decision recorded in Appendix V; the manual save
picker remains archived per `PLAN.md` / `TZ_COMPLIANCE.md`. This pass does not
reverse those decisions or add empty screens. The world's permanent night
remains the Production Bible's lighting rule.

The earlier release-tool fixes are retained: unknown achievement ID audit,
mandatory loop seams, six real locales, strict signed-AAB audits and complete
proof logs. The new `-CheckGame` mode runs the full battery twice, bots and
windowed GPU/audio probes without exporting. `-Android` builds the signed AAB;
`-PlayChecklist` prints the owner actions without GitHub login.

No existing store frame is relabeled as new. No runtime, GPU, device, music-rights,
signing or Play Console result is claimed by this source pass. A publisher-sized
quality claim needs the actual rendered game, playtesting and production work;
the delivered changes are described above by their behavior and files.
