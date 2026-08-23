# Handoff

Full detail: `docs/SESSION_REPORT_FINAL.md` (this phase — audio, shaders,
bug sweep, cleanup, ads, release prep) and `docs/SESSION_REPORT.md` (the
earlier 19-task build phase). This file is the short version for picking
the project back up.

## State right now
- All 4 mandatory gates green, `tools/check.sh --static` green, plus
  `autoload_api_check_scene.tscn` individually confirmed green (found and
  fixed a real stale-comment failure — see SESSION_REPORT_FINAL.md).
  `game_test_3d_scene.tscn` result: see the addendum at the bottom of
  `SESSION_REPORT_FINAL.md`, added after this file was written.
- All work pushed to `origin/main`, latest commit `299a4d7`.

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
