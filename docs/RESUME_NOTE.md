# Resume note (2026-10-08, rc16 sign-off)

State: `main` is the rc16 sign-off (the tag `v8.0.0-rc16` goes on the commit that records the last verifier round). Nothing is in flight. Three finished agent worktrees remain under
`.claude/worktrees/` (`agent-a2d98b0eb4e6daa56`, `agent-a9d93688011f12bdb`, `agent-ac5abdf50f70def2b`); their branches are merged, `git worktree remove` clears them when convenient.
Numbers and proofs: `docs/ORDER_PASS_REPORT.md` (rc16 final section), `docs/PROOFS.md` (rc16 section, one row per closure with its raw log), `docs/ACCEPTANCE_CHECKLIST.md` (178 of 200 proven, gap table),
`docs/ARENA_CLOSURE.md`, `docs/CORRECTION_LOG.md` (rows 101 to 128 are this pass), `docs/RUN_STATE.md` (Session 17: every launch with its question and answer), `docs/UNVERIFIABLE_HERE.md` (what only a phone or an ear can say).

## What rc16 did
Two sessions. Session 16 built wave 1 with agents in their own worktrees (perf, content, uifx, sec, audio) and the evidence harness; Session 17 merged and finished it, ran wave 2 (beauty, i18n, content),
the utilities pass and the verification; the RC16 FINISH directive (2026-10-08) then installed the skill stack, closed the two rc15 UI defects and traced the open questions (24 launch rows of a budget of 24, the amendment is CORRECTION_LOG 111, each a row of `docs/artifacts/rc16/launch_ledger.tsv`).
Streaming and pooling (nodes 1784 to 1061, cold load 354 to 317 ms), frame-independent timing (15 of 15 quantities agree at 30, 60 and 120 FPS), tier-gated UI motion and post-fx, pinch zoom and
quick-slot drag, one New Game+ level per run (signed run name and ledger), distant 3D sounds low-passed with a reverb that follows the walls, six beauty changes kept (grain, damage vignette, LUT warm
highlights, blur copy), three GDD deviations found by reading (toast time, menu day palette, attack button under 5 stamina), gdparse/gdlint/ruff/shellcheck/actionlint on changed files with a pre-commit hook and a CI workflow.
The 36 ids of `docs/artifacts/rc16/af2_both_ways.txt` (`tools/qa_sim/af2_both_ways.py`, run at `8cb22ba`) each have a check that fails on the code before the fix and passes at HEAD; the fixes outside that run (the F1 Close button and shop, the bot counter, `e32fa77`, `7c49500`, the timing check) have their own before and after logs, one row each in `docs/PROOFS.md`; a closure that is a record has no pair.

## Next (owner first)
1. Release: `build/tls.aab` is the rc15 bundle (183,257,097 bytes, built from `8ad0b93`). Rebuild it from the `v8.0.0-rc16` tag with the one command of `docs/RELEASE_RUNBOOK.md`, run `jarsigner -verify`, install it on a phone
   (T01), then the Play Console steps. The frame rate, heat and memory on a phone, the feel of pinch and drag and the look of the rc16 effects on a phone GPU are unmeasured (U1, U5, U6).
2. Listen: how the reverb, the low-pass and the mix sound, and whether the music clips in a fight (U3, U8). The windowed audio gate is bimodal on one code tree: the final audio code at HEAD read -11.6, -11.7, +1.8, +0.6 and -12.4 dB against a ceiling of -1.5 dB, and with the reverb-fade fix `7c49500` reverted alone the split is the same (CORRECTION_LOG 114): a failing run at HEAD is not by itself a regression, and the cause of the high readings is not isolated. The gate prints the music context (mood, combat hold, nearest monster) next to the reading.
3. Decide: E11 second half (a quest reward that does not fit in a full pack stays unpaid; the obvious fix breaks the pinned regression P2g), D1 `apply_stun` (no caller; the fix changes the boss fight and needs the 3-seed bot),
   beauty X4 to X7 (`docs/BEAUTY_RC16.md`), the Arabic shop (its content is drawn outside the panel, an older defect found by the F1 frame read, `docs/KNOWN_ISSUES.md`: the fix to try and the check to extend are written there), G22, H3.18, F1 when a lobby gets an opener.
4. Assets: `docs/ASSET_SHOPPING_LIST.md`, now with rows 18 (per-speed footsteps for asphalt, puddle, glass) and 19 (radio voice lines); music per `docs/OWNER_HANDOFF.md`.
5. Run `bash tools/check.sh --all` once after pulling: the engine battery was not re-run after the F1 edits (the launch budget was spent); read a red audio gate in it as the known flake (CORRECTION_LOG 114).
6. Tools on the owner's machine: `python -m pip install gdtoolkit==4.5.0 ruff==0.16.9 shellcheck-py==0.11.0.1 actionlint-py==1.7.12.25`, then `pre-commit install` for the hook; CI needs nothing.

## Rules that still hold
- Never run two Godot processes at once; QA launches are muted (`QaLaunchGuard`); never delete `<profile>.qa_snapshot`; tools that start the game go through the user-data guard (`tools/qa_sim/guarded_windowed`, `guarded_headless`, `playthrough`, `tools/check.sh`).
- The profile's onboarding flag changes what a run measures: every tool runner that starts a game calls `SaveSystem.mark_onboard_done()` first (CORRECTION_LOG 90, 93).
- After a `class_name` change run `godot --editor --quit --path .` once, then revert `default_bus_layout.tres` (the editor rewrites its uid and drops defaults; it did so again in rc16) and `docs/artifacts/content-depth/i18n_only_texts.md`; never the `.import` files.
- Static-green is not parse-green: the engine compile gate (`COMPILE_GATE bad=0`) is the parse proof. A gate that passes on a paused or empty scene proves nothing: assert the mechanism, not only the outcome.
- An autoload script must not name a world class (`DistrictSceneFactory` inside `MusicManager` did): it moves the compile order and a `preload`ed scene came out empty (172 engine errors in the loot check, `e32fa77`; CLAUDE.md, Hard rules).
- A freed Object compares equal to null in GDScript: read what a check needs before the waits that free it (the TO1 check bug of `4c9b3fd`).
- Evidence (AF1 to AF7): a launch is `tools/qa_sim/proof_run --launch [--attach LOG] <id> -- <command>` (raw log, exit code, ledger row); a fix without a check that fails on the old code is not a fix (`af2_both_ways.py` reads the attached full log, not the wrapper's filtered stdout: CORRECTION_LOG 103);
  frames are stamped `<state>_<label>_<hash>_<UTC>` (`tools/qa_sim/stamp_frames.py`) and judged by `tools/qa_sim/af3_frame_check.py` (a committed frame by its commit time, a new one by its file time; a clone or pull rewrites file times: CORRECTION_LOG 105;
  `tools/qa_sim/fresh_clone_check.sh <command>` runs any gate in a fresh clone); every file:line citation in the documents is checked by `tools/af5_check.py`; `docs/PROOFS.md` is generated from `docs/artifacts/rc16/closures.json` by `tools/qa_sim/gen_proofs16.py`.
- Batch the runtime fixes before the capture runs: a change to a runtime path after the frames are stamped fails AF3 F4 for every stamped frame. A reviewed change that reaches only some frames can be declared in `tools/qa_sim/af3_f4_scope.tsv` (path, blob before, blob after, frame glob; CORRECTION_LOG 113), and the frames it does reach are re-shot.
- Read the frame of a right-to-left language: a layout check against the card's own children passed in Arabic while the whole shop was drawn outside its panel. Controls placed by `.position` before they have a parent land one parent width off under the right-to-left layout (launches 22 and 23).
- Working copies are CRLF (`core.autocrlf`): a Python patch helper must read bytes and keep `\r\n`. The Bash tool's heredocs lose backslashes (`\b`, `\n`): write patch scripts with the Write tool or use the Edit tool.
- The bot is nondeterministic run to run: judge stalls over several seeds, and record them (IRON RULE: at least one win over seeds 1 to 3, else revert).
