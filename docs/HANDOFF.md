# Handoff

Read `docs/PRODUCTION_BIBLE.md` first — canon reference (pillars,
visual/audio canon, budgets, checklist) for any new wave of work.

Full detail: `docs/SESSION_REPORT_RESCUE.md` (latest phase — real-window
launch bug, night sky + district ambience wiring, boss stings, perf
measurement), `docs/SESSION_REPORT_TRUTH.md` (launch-readiness gate,
real bug sweep, store copy), `docs/VISUAL_AUDIT.md` (screenshot-driven
visual/UI/lighting pass), `docs/SESSION_REPORT_FINAL.md` (audio,
shaders, bug sweep, cleanup, ads, release prep) and `docs/
SESSION_REPORT.md` (the earlier 19-task build phase). This file is the
short version for picking the project back up.

## Latest phase: RESCUE WAVE — real-window launch bug + visual pass (see docs/SESSION_REPORT_RESCUE.md)

HEAD = `f368631`, fully pushed to `origin/main`. All mandatory gates +
static + boot-flow + footstep gates green.

The TRUTH WAVE pass verified launch only headlessly. This pass ran the
game in a real `--windowed` process and found the actual player-facing
blocker: `scenes/main_3d.tscn` embeds an `EndingScreen` node
(`ending_screen.gd`) whose `_ready()` unconditionally built and faded in
a full-screen "All districts powered!" win overlay on *every* load of
the gameplay scene — nothing ever called its real trigger. A fresh New
Game was instantly covered by a fake victory screen. Fixed (commit
`d8637ab`); the real menu itself was always fine.

Also this pass: wired the footstep surface×speed mapper for ox alpha's
18 delivered files (walk/jog/sprint per surface — "jog" stays unused,
no game state maps to it); wired the night-sky panorama into
`WorldEnvironment` (it was being silently overridden every district
entry by `district_grading.gd`, now only on LOW graphics tier as the
intended perf fallback); wired the 11 district ambience beds into
`MusicManager` (replacing a handful of generic tracks reused across
districts) with live power-restoration reactivity; converted both
boss-intro stings from WAV (over the 1MB budget) to OGG and wired them
to the Architect/Tvar encounters; built a real draw-call perf-guard tool
and measured **370 draw calls** (over the GDD's <200/<350 budgets) with
the root cause identified (`streetlight_3d.tscn` has no MultiMesh
batching) but not fixed — real regression risk to the streetlight-
reactivity mechanic fixed last session if rushed.

**Not attempted this pass**: status-FX HUD, hit/death VFX particles.
**Blocked, not skipped**: UI chrome kit (waiting on OpenCode B's
delivery), map/minimap district crests (no crest assets exist yet).
Full self-audit, DEFAULT_CHOICE log, and a GUI-automation reliability
note worth reading before trusting any future click-based verification
in this sandbox: `docs/SESSION_REPORT_RESCUE.md`.

## Previous phase: TRUTH WAVE — launch-readiness (see docs/SESSION_REPORT_TRUTH.md)

HEAD = `7c8e475`, fully pushed to `origin/main`. All 4 mandatory gates +
static + the new permanent `boot_check_scene.tscn` gate green.

Built a permanent boot-flow gate (`scenes/tools/boot_check_scene.tscn`,
wired into `tools/check.sh`): real menu → New Game → 60s sustained
gameplay → save → quit → load, all must not crash; also enforces "no ad
before first player input" as a live regression check. Building it
surfaced three real, previously-unknown bugs, all fixed: `SaveSystem
.reset_all()` never actually reset XP/skill-tree state (New Game kept
the last playthrough's level); `integrity_guard.gd`'s watchdog could
force-quit to the main menu from a single-tick false positive; two new
texture assets were wired into props but never had `.import` files
generated, so they silently failed to load outside the editor. Also
found and fixed: the game's namesake "darkness → restored power"
streetlight mechanic didn't actually exist in gameplay (the live prop
system built non-reactive flat decals; a complete, correct
`streetlight_3d.tscn` implementation existed but was never
instantiated anywhere — now wired in, old decals kept behind
`legacy_streetlights=false`). Added a "Reset Progress" button to
Settings. Rewrote both store listings and wrote `docs/PRODUCTION_BIBLE.md`.
Full self-audit, DEFAULT_CHOICE log, and what-wasn't-attempted section:
`docs/SESSION_REPORT_TRUTH.md`.

**Not attempted this pass**: the P2 visual/design wave (night-sky
panorama, district ambience-bed wiring, status-FX HUD, UI
StyleBoxTexture chrome kit, minimap size bump, automated perf guard) —
deliberate scope cut once P0 turned up real save-correctness bugs worth
fixing properly. Pick this up next, starting from `docs/
PRODUCTION_BIBLE.md`.

## Previous phase: visual polish (see docs/VISUAL_AUDIT.md for full detail)

Started as an 8-step "make it stop looking cheap" mission (atmosphere,
materials, UI theme, JUICE, VFX integration, perf guard). What actually
got done, screenshot-verified, gate-verified, pushed:

- Real UI theme fonts (theme_provider.gd was silently falling back to
  the OS default font on every one of ~13 screens — never loaded the
  actual Bebas Neue/Roboto Condensed files).
- Main menu: fixed a background-tiling seam, a random day/generator boot
  variant contradicting "no day" canon, and a static 15%-alpha overlay
  that washed the whole menu brown (see before/after in docs/shots/).
- District 3D lighting: `district_themes.gd`'s sky/fog/ambient were a
  bright pastel *daytime* palette in a permanent-night game — darkened
  to canon, fog unified to the GDD hex. `district_grading.gd` now
  actually scales ambient by district power stage (DARK→FULL), which
  GDD calls the game's main visual reward and previously did nothing.
- Textured/PBR'd several default-grey street props (poles, benches,
  dumpster) that had real textures sitting unused in assets/.
- Zeroed out several rounded-corner UI violations (GDD bans them) and a
  handful of non-canon hardcoded colors.
- Minimap: was drawing all 11 district names inside a 180px circle
  (guaranteed overlap/illegible) — now only labels the current district.
- Real HUD bug: monster-spotted name showed literal "ember #<id>" in
  every language, every encounter — now resolves the real i18n name.
- Interstitial ad mislabeled "Rewarded ad" — now has its own title.
- i18n hard-rule gaps closed on the reachable New Game+ screen (10 new
  keys × 13 locales) and the monster-name bug above.

**Not done** (honest gap, not attempted this pass): full project-wide UI
StyleBoxTexture chrome, hit-vignette/hitmarker/micro-shake JUICE, pickup
fly-to-HUD tweens, integrating ox alpha's newest VFX/grading assets
(several arrived mid-session — see untracked files under `assets/` at
time of writing), draw-call perf guard (<200), desktop/Steam export. A
material audit found two full streetlight systems running simultaneously
in every district (`street_props.gd` + `streetlight_spawner.gd`) — real
duplication, not fixed, needs an in-editor look to pick which is
canonical rather than a blind deletion.

**A test-environment thing, not a product bug**: this dev machine's
Godot `user://` save profile for this project has already reached a
full-victory state from this session's own automated test runs
(`victory.cfg` exists) — booting the game now shows a restoration
banner/ad prompt immediately regardless of input. A fresh player save
never triggers this. Lives outside the repo; needs explicit confirmation
to clear, not something to do unilaterally.

## State right now (as of this line, checked directly)
- HEAD = `1bc8052`, fully pushed to `origin/main`. Working tree clean
  except files that belong to the parallel asset-agent session
  (`docs/REPORT_ASSETS.md` and a batch of new files under `assets/` —
  new surface textures, lit tileset variants, monster SFX, store keyart —
  not reviewed or touched this pass, not mine to commit; wiring some of
  the new surface textures is exactly the kind of follow-up
  `docs/VISUAL_AUDIT.md`'s P1 list points at).
- All 4 mandatory gates green (re-verified after every commit this
  session). `tools/check.sh --static` green (10/10).
- `game_test_3d_scene.tscn`'s long-standing "hangs forever, no output"
  mystery from the previous phase is now explained, not by a project bug:
  it genuinely got as far as `[3dtest] phase1 combat: damage Shadow` and
  then sat idle — the *process* never exited on its own even after that.
  Found via `tasklist`: several `godot.exe`/`Godot_v4.7-*.exe` processes
  from earlier hung runs (this phase and the previous one) were still
  alive, never having been cleaned up. Once killed directly
  (`taskkill /F /IM godot.exe`), the stuck task immediately reported
  "completed, exit code 0". Root cause still not nailed down (why the
  process itself doesn't exit after finishing its printed checks), but
  it's a process-lifecycle issue in this environment, not evidence the
  gate/game logic is broken — worth checking `tasklist` for leftover
  `godot*.exe` before assuming any future "stuck" gate run is a real bug.

## Do this first in the next session
```bash
bash tools/check.sh
```
If the combined run hangs again (it did twice this session, on the
engine-check portion), fall back to running each `res://scenes/tools/
*_check_scene.tscn` individually with the Godot binary directly — that
worked every time the combined script didn't. Worth investigating why
`tools/check.sh`'s engine-check loop hangs when the same scenes run fine
standalone (environment/subprocess issue, not a project bug as far as
this session could tell).

## Open threads (none are blockers, all are deliberate scope cuts)

1. **AppLovin ads need a human.** Code is real and gated (interstitial +
   rewarded revive/battery both wired to actual gameplay now), but nothing
   has touched a real device, real SDK key, or Android Studio. Full list:
   `docs/store/HUMAN_CHECKLIST.md`.
2. **`extra_battery` ad reward has no UI trigger.** `revive` got one (death
   screen button); `add_battery` reward consumption is wired in
   `GameManager._on_ad_reward()` but nothing calls
   `AdService.show_rewarded(&"extra_battery")` yet. Needs a HUD button —
   follow `scripts/death_screen.gd`'s `_add_revive_button()` pattern.
3. **`destroyer_3d.gd`'s streetlight-breaking check is dead** — no script
   joins the `"streetlights"` group or defines `force_lit()`. Would need a
   real per-lamp override mechanic (streetlight state is currently driven
   entirely by district power stage, see `streetlight_3d.gd`), not a
   one-line fix. Not confirmed as GDD-mandated, unlike the melee
   knockback/backstab bug this session did fix.
4. **A parallel background session** was running on my earlier "clean up
   touch_controls" suggestion using a narrower prompt (code-only grep, no
   GDD check) at the same time I was doing the real fix with full context.
   I don't have visibility into whether it acted before or after my
   commit (`7efdee7`) landed. Worth a quick look if that session is still
   around.
5. **Desktop/Steam export preset doesn't exist yet** — only Android is
   configured in `export_presets.cfg`. Not started, see `docs/store/
   steam.md`'s build-steps section.

## Things NOT to redo
Everything in CLAUDE.md's "Already done" list, plus (from the first
build-out phase) T1-T4 and T11, which were verified already-correct
against the GDD rather than rebuilt — don't redo those without checking
current state first. From this phase: the audio/shader/tilesets wiring in
Steps 1-2, and the AppLovin provider scaffolding in Step 5 — check
`ad_service.gd`'s `_default_provider()` before assuming ads need
wiring from scratch.
