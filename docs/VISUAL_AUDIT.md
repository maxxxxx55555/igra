# Visual audit — "make it stop looking cheap"

Screenshot-driven pass over UI theme, district lighting, and default-grey
props. Findings are grouped P0 (fixed this session, verified) / P1 (real,
documented, not fixed — scope or risk) / P2 (minor / cosmetic).

Screenshots: `docs/shots/before_menu.png` (main menu before any fix in
this pass), `docs/shots/after_menu.png` (after — note a leftover ad popup
from stale save-state, see the caveat at the bottom; the background behind
it is the fixed one), `docs/shots/diag_0Xs.png` (frame-by-frame boot
diagnostic used to catch the tiling seam and the theme bug).

## P0 — fixed and verified (compile + signal-arity + i18n + asset gates
green after every change, `bash tools/check.sh --static` green)

1. **UI theme fonts never actually loaded.** `theme_provider.gd` (used by
   ~13 screens: pause, inventory, achievements, codex, encyclopedia, city
   map, journal, quest journal, settings, stats, win/death screens) built
   fonts via `SystemFont.new()` with OS family names ("Rajdhani",
   "Saira Condensed") — a pre-canon font set the GDD's 2026-08-10 summit
   explicitly retired in favor of Bebas Neue / Roboto Condensed. On any
   machine without those exact fonts installed (i.e. basically everywhere,
   definitely on Android), it silently fell back to the engine default —
   the GDD explicitly bans that fallback. Now loads the real files from
   `assets/fonts/`, same as `theme_setup.gd` already did for the root
   theme. `scripts/ui/theme_provider.gd`.

2. **Main menu background didn't cover the screen.** `menu_background.gd`
   built exactly 2 copies of a 640px parallax tile — 1280px total, so
   anything wider than that (1920px, any modern desktop res) showed a
   hard seam with flat color to the right. Tile count is now computed
   from the actual viewport width. Also stopped the menu rolling a random
   1-in-3 chance of booting into the DAY or GENERATOR background variant
   — the GDD is explicit the game has no day. `scripts/ui/menu_background.gd`.

3. **Main menu had a permanent warm-amber wash.** `main_menu.tscn`'s
   `Flicker` ColorRect sat at `color.a = 0.15` with zero code anywhere
   touching it — a flat 15%-alpha brass overlay on literally everything,
   all the time (this is what `before_menu.png` shows: a brown/khaki menu
   instead of near-black). The pre-existing comment ("между BG и Flicker")
   makes clear this was meant to animate. Now flickers irregularly between
   2-7% alpha, like a dying streetlamp — thematically apt for a game about
   restoring streetlights. `scripts/ui/main_menu.gd`.

4. **3D world lighting was a bright pastel daytime palette.**
   `district_themes.gd`'s sky/fog/ambient colors were things like
   `sky = #b0c8a0` — a light, cloudy-day sage green — in a game whose
   entire premise is permanent night (GDD §11.1: "Дня нет"). Every
   district's sky/ambient darkened to the bg-deep neighborhood; fog
   unified to the single GDD-canon depth-fog color (`#1a2133`) instead of
   11 different pastel fog tints. `scripts/world/district_themes.gd`.

5. **"Darkness → restored power" never actually changed the lighting.**
   `district_grading.gd` set `ambient_light_energy` to a flat `0.4`
   regardless of the district's power stage, and only re-applied on
   *entering* a district, never on restoring power in the one you're
   already standing in. This is the game's stated "main visual reward"
   (GDD §11.1) and it wasn't wired. Now scales 0.03/0.06/0.11/0.16 by
   `DistrictData.Stage` and reacts live to `district_stage_changed`.
   `scripts/world/district_grading.gd`.

6. **Default-grey/flat street props despite real textures existing.**
   `street_props.gd` (poles, lamps, benches, trees, cones — spawned in
   every district) and `streetlight_spawner.gd` (a second, road-following
   streetlight system, also live in every district) built
   `StandardMaterial3D`s with only `albedo_color` set — no roughness,
   no metallic, no texture — even though `assets/textures/surfaces/
   streetlight_metal_512.png` and `bench_wood_512.png` already existed
   unused. `hiding_spot.gd`'s "dumpster" hiding spot ignored
   `dumpster_metal_512.png` the same way. All three now wire the real
   textures plus deliberate roughness/metallic; trees/cones (no matching
   texture exists) at least get real PBR roughness instead of the engine
   default. `scripts/world/street_props.gd`, `streetlight_spawner.gd`,
   `scripts/gameplay/hiding_spot.gd`.

7. **Rounded UI corners** (GDD bans them — "chamfer, radius 0") in
   `hud_3d.tscn`/`hud_3d.gd` (inventory slot), `quest_tracker_hud.gd`,
   `weapon_compare_ui.gd`, `tutorial_system.gd`, `craft_station.gd` — all
   set to 0. Left `hud_3d.tscn`'s `style_joystick` (radius 80) alone —
   that one's deliberately circular, it's the mobile joystick base.

8. **Non-canon hardcoded colors** on visible, frequently-seen UI: pure
   white/saturated-red/saturated-gold in `inventory_system.gd` (stack
   count label, weight-overload bar), `district_banner.gd` (shown on
   every district transition), `ui_manager.gd` (global toast text) —
   replaced with the real palette tokens (brass/bone-text/ember).

9. **Minimap: all 11 district names drawn at once, always overlapping.**
   `minimap.gd` labeled every district dot at font size 9 inside a 180px
   circle — with district centers ~20px apart, the text was guaranteed to
   overlap into an illegible smear (visible in every `docs/shots/diag_*`
   frame and the loading-screen shots). Full names already live in the
   tap-to-open city map; the minimap now only labels the player's current
   district.

10. **Real gameplay HUD bug: "ember #shadow" instead of a monster name.**
    `hud_3d.gd`'s `_on_monster_spotted()` had an `if typeof(monster_id) ==
    TYPE_INT` branch that could never be true (`EventBus.monster_spotted`
    always sends `StringName`) and fell through to printing
    `"ember #" + str(monster_id)` literally — in every language, every
    time a monster was spotted. Now resolves the real `MONSTER_*` i18n
    name (the same keys the encyclopedia already uses).

11. **i18n hard-rule violations** (CLAUDE.md: every user-facing string
    must be localized): `hud_3d.gd`'s monster name (above, #10),
    `new_game_plus_ui.gd` (raw English literals on the reachable
    victory-screen → New Game+ flow — 10 new `NG_PLUS_*` keys added
    across all 13 locales), and the interstitial-ad mislabel (#12 below).

12. **Interstitial ad showed the wrong title.** `ad_service.gd`'s
    `show_interstitial()` reused `ad_popup.gd`'s hardcoded "Rewarded ad"
    title even though an interstitial grants no reward — confusing/wrong
    copy on every district-change ad break. `ad_popup.gd` now takes a
    `title_key`; interstitial gets its own `AD_TITLE_INTERSTITIAL` key
    (13 locales).

## P1 — real, documented, not fixed this pass (scope/risk)

- **Two full streetlight systems run simultaneously in every district.**
  `street_props.gd` spawns pole+lamp pairs along roads, and
  `streetlight_spawner.gd` *also* spawns pole+lamp pairs along roads,
  independently, in the same scenes. Likely double geometry/double
  light sources per intersection — a real perf and possibly visual
  (double bloom) concern given GDD's draw-call budget (<200 D1). Not
  touched: picking which system is canonical and removing the other
  needs someone to actually walk a district and see which placement
  logic reads better, not a blind code deletion.
- **A third, distinct streetlight implementation exists and is dead**
  (`scenes/props/streetlight_3d.tscn` + `streetlight.gd`) — only reached
  from dev-tool probes, not any live scene. Left alone (not proven
  dead-and-safe-to-delete beyond "no live scene references it" — see
  CLAUDE.md's own `hiding_spot.gd` lesson about the cost of guessing).
- **~7 UI screens never adopted `ThemeProvider`/the root theme
  consistently** and instead redeclare their own local color constants:
  `screens.gd`, `workbench.gd`, `radio.gd`, `puzzle_cables.gd`,
  `character_screen.gd`, `weapon_compare_ui.gd`, `stats_screen.gd`. Not
  necessarily wrong (some may intentionally diverge) but worth a
  deliberate pass rather than a blind `theme =` insertion.
- **`daily_events_ui.gd`** has raw English literals and is NOT wired
  into `UIManager`'s screen registry (unlike `new_game_plus.tscn`, it
  has no reachable open() call anywhere) — confirmed dead/unreachable,
  consistent with this project's existing dead-code findings
  (`proc_audio.gd`, `wave_manager.gd`). Left as-is; fixing i18n inside
  unreachable code has no player-facing effect.
- **`city_decorator.gd`** — a second, entirely separate "grey box city
  prop" placeholder system (`CityDecorator._make_box_mesh`) — not
  referenced by any scene or spawner. Dead code, not deleted (same
  never-delete-without-certainty rule).
- Several dead/unused scenes render grey by construction if ever wired
  up (no material at all): `door.tscn`, `exploding_barrel.tscn`, the 4
  old `pickups/*.tscn` (superseded by `item_pickup_3d.tscn`, which *is*
  textured), and the `effects/*.tscn` VFX scenes (superseded by their
  procedural runtime equivalents). Not touched — none are on a live path.

## P2 — minor / cosmetic, not addressed

- `settings_manager.gd:313` builds its own `ThemeProvider.build_theme()`
  instance for a font-size preview — harmless, just duplicate work.
- A handful of `Color(r,g,b)` float literals in `hud_3d.gd`/`screens.gd`
  that numerically equal canon tokens but aren't written as the named
  `ThemeProvider.COLOR_*` constants — cosmetic drift risk, not a visible
  bug today.

## Caveat: automated gameplay screenshots and stale save state

Getting a clean *in-district* screenshot through `shot_tool.gd`'s new
`--shot-scenario=` flags surfaced a real timing bug in the tool itself
(documented and fixed in the `shot_tool.gd` commit — it was racing
`_bootstrap.gd`'s splash-screen fallback path). After fixing that, a
*separate*, non-code issue remained: this dev machine's shared Godot
`user://` save profile for this project has, after many hours of this
session's automated engine-driven test runs (gates, autopilot, earlier
smoke tests), already reached a full-victory state (`victory.cfg` exists
in the save directory) — so simply booting the game now shows an
"all districts restored"-style banner and an ad prompt regardless of
which scenario is requested. This is dev/test save-state carryover, not
a product bug; a real player's first launch has no save file and none of
this triggers. Clearing that save data is outside this repo (it lives in
the OS user profile, not `user://` inside the project) and needs explicit
owner confirmation rather than being done unilaterally — flagging it here
instead. `docs/shots/after_menu.png`'s ad popup is this artifact, not a
new bug; the near-black background visible behind/around it confirms the
menu fix independently of this.
