Read docs/HANDOFF.md and docs/SESSION_REPORT_FINAL.md for full context on
the last session (audio/shader wiring, a real melee-combat bug fix,
AppLovin ads integration, Android release prep — all gated, pushed to
origin/main at commit 299a4d7, possibly later if the game_test_3d_scene
addendum in SESSION_REPORT_FINAL.md added more commits after this file
was written).

Run `bash tools/check.sh` first. If it hangs on the engine-check portion
(it did twice last session), run each `res://scenes/tools/*_check_scene.tscn`
individually with the Godot binary instead — that worked every time.

Then pick up one of docs/HANDOFF.md's "Open threads" — none are blockers:
1. AppLovin ads need a human for account/SDK-key/device-build steps —
   docs/store/HUMAN_CHECKLIST.md has the full list.
2. The extra_battery ad reward has no HUD button yet (revive does) —
   follow scripts/death_screen.gd's _add_revive_button() pattern.
3. destroyer_3d.gd's streetlight-breaking check is dead code (no
   force_lit()/group membership anywhere) — real feature work if pursued,
   not a quick fix.
4. Check whether a parallel background session already touched
   touch_controls before this session's fix (7efdee7) landed.
5. No desktop/Steam export preset exists yet if that's ever prioritized.

Or take a new task from the owner directly. Gates after every change,
commit small, push every 2-3 commits, same as always.
