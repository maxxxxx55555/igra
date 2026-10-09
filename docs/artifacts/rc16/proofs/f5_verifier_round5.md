# F5 verifier, round 5: the agent's report, verbatim

Agent a06839a5fca135a00 (general-purpose, read-only), brief `docs/artifacts/rc16/proofs/f5_verifier_brief.md` and `docs/artifacts/rc16/proofs/f5_verifier_round5_note.md`, HEAD `0ab9503c5fd38a8a48a867587a98f69e67a25513` (pushed, `git ls-remote` equal), 146 tool calls by the harness count, 2026-10-09. Below is the agent's final message as it reached the orchestrator, unedited; the session transcript indents every line of such a report and that indentation is removed here. The fix is CORRECTION_LOG 137.

PASS=40 FAIL=1 UNVERIFIED=11

HEAD 0ab9503c5fd38a8a48a867587a98f69e67a25513, git status clean, remote main equal (G1), no rc16 tag local or remote. Z1 passed: HEAD, status and remote were the same at the end. I wrote nothing into the repository (scratch only in the given folder; RUFF_CACHE_DIR pointed there). I launched no Godot and ran no tools/check.sh. About 140 tool calls.

FAIL E5 docs/FUNCTION_MATRIX.md:171: row X45 says "`closeout_check` QS2, 4 checks". Measured: `sed 's/\x1b\[[0-9;]*m//g' docs/artifacts/rc16/proofs/s8_closeout_rc16_21c2046.attach.closeout_check.log | grep -a -c -E '\[closeout\] (ok  |FAIL) +QS2 '` = 5. The f1_pre_b7aee72 and f1_post_a41d4b3 attach logs also give 5. `grep -n '"QS2' scripts/tools/rc16/uifx_checks.gd` gives five `_ok` lines (165-169). Only logs before 21c2046 have 4 (CORRECTION_LOG 108 restored the fifth). ACCEPTANCE_CHECKLIST.md:206 was corrected to "5 checks" and this row was not. It was found by a mechanical sweep of every "<id> N checks" claim in the documents changed since e4bb4df against the closeout logs: CT7 9, QS2 5, E11 3, E13 2, S04 18, S02 5, G21 24, G25 22, G26 10, C03 2 all match, except this row.

UNVERIFIED D2: ledger heads with "(uncommitted paths: N>0)" at rows 12, 13, 15, 16, 19, 21, 22, 30; no rc16 document states the reason (grep for "uncommitted" finds none).
UNVERIFIED D4: rows 12 (1 process), 20 (check.sh --all, 33) and 24 (4 modes) have no banner-bearing log. The other 21 rows match their bullets, and the sum 87 matches the report (ORDER_PASS_REPORT.md:191).
UNVERIFIED T6: CI at HEAD. Only the run at 599cd89 is recorded (success; 12 job entries = 8 steps + set-up + 2 post + complete, matching static.yml). No network beyond ls-remote.
UNVERIFIED E1/E2: 16 proof logs whose `# cmd` runs a script from the session scratchpad (S0 scan/install/verify, f5_*) cannot be re-run from the repository.
UNVERIFIED E1/E2: "66 checks, 34 processes" (S8-BATTERY; RUN_STATE L9 gives it without the word "derived") is arithmetic on an unrun command and needs the engine.
UNVERIFIED A2: CORRECTION_LOG 108 and 127 (restored assertions, audio bus gate) are argued "by reading", with no logged fail-then-pass pair. The texts say so.
UNVERIFIED A3: that every stamped frame was "read once", and the frame descriptions (rule 3 forbids opening images).
UNVERIFIED K1: the skill-log header promises `skills=<n>` and no line states it (13 of 19 rows are ok).
UNVERIFIED K2: "no other spawn in the window" and the transcript line numbers of CORRECTION_LOG 118-124 (f5_skill_order.out) come from the session transcript. The commit sizes in the rows (94/86/107 lines, +1 each, 1062) I recomputed.
UNVERIFIED H1: past push equalities (be84a29 ... 6ca31b3 and the 23 commits after 3f5556a, CORRECTION_LOG 125) cannot be re-proved. I recomputed the 23 commits and that all are ancestors of HEAD; f5_push_state.out runs a scratchpad script.
UNVERIFIED I1: KNOWN_ISSUES.md:11 "no other untranslated literal that a player can reach" is a reading, labelled as such. I recomputed its 86 lines in 22 scenes.

Round 4 finding (V05 and V05-mobile), re-checked with the original commands: fixed. TZ_DECISIONS.md:27 and :54 cite GDD.md:326. `sed -n 326p docs/GDD.md` is "Moon shadow 2048²", line 317 is the monster-sprite line, and `grep -rn 'GDD.md:317' docs` finds nothing.

Citations (T1 and the round 5 note): I read all 140 citations of the gate's scope.
- Gate: `python tools/af5_check.py` printed 140 citation(s) in 730 doc line(s), 0 finding(s); `--demo` printed 5 cases, 0 wrong.
- No claim before the citation (85): I tested each against the cited line at HEAD. 28 share no number or word with the cited line, and I read their sentences; all hold.
- With a claim (55): skimmed.
- Other forms: 9 shorthand `:NNN` continuations and 14 extension-less `name:N` tokens, all checked against HEAD.
- Drift: I compared each citation's lines at the first commit that held it with HEAD. Six differ: ACCEPTANCE:334 to TZ:20, ACCEPTANCE:343 to TZ:28, TZ:16 to GDD:22, RUN_STATE:64 workbench.gd:401, RUN_STATE:65 menu_background.gd:139 and toast_manager.gd:27. None is wrong: the TZ and GDD rows hold at HEAD, workbench.gd:401 is the same edited line, and the two RUN_STATE:65 lines are dated ("Wave 2 spawned at 15c2c19", where the lines read `_theme = (_theme + 1) % 3` and `HOLD = 3.5`).

Other measured facts:
- G3: only tools/qa_sim/af3_frame_check.py (1 line) since 74f710b, and nothing in code or tools since 2dbfa25.
- G4: screens.gd and skill_tree_ui.gd only, 21+/15-, last change 74f710b. G5: no print, TODO or BOM. G6: 13 distinct BTN_CLOSE values, 13 files x 1525 keys.
- D1 and F1-F3 print nothing. D5: 24 used, 0 left everywhere, and the old paragraph is marked superseded. D6: 47 closures = 47 rows. D7: 16+24+6+1+3 = 50. D8: 36 rows (101-136), no duplicate, the documents say "101 to 136".
- PROOFS: I regenerated all 47 rows in memory from closures.json and the logs, with 0 differences against PROOFS.md.
- T2-T6: af3 frames=50 fail=0, i18n 12/12, lint_changed 49 gd, 18 py, 13 sh, 0 findings, bot counter 0/1, 0/1, 0/2 with rc=1 and 1/1, 2/1, 1/1 with rc=0. flow_check (56 checks) and scene_node_check also exit 0.
- E3: 17 audio readings, 8 CLIP-FAIL, 9 under; launch 24 arm A +1.8, +0.6, -12.4, arm B -10.5, +0.6, +0.7.
- E5: proven=178, other=22. The baseline at e4bb4df is 176, and only CT7, QS2 and I9.7 were added and PF3 withdrawn.
- E6: BEAUTY X1 LUT colours verified from the LUT images: old white (216,239,208), new (240,232,213), brass (166,158,87) to (196,153,65). The round 4 UNVERIFIED on this is closed.
- A4: _audio_bus_check.gd now has CORRECTION_LOG 127. SHOP1 got stricter after its first run (`cases > 0`). The other gate edits are import-only or print-only.
- I3: AAB is rc15 (183257097 bytes, Oct 2). The Arabic shop, bimodal audio and battery-not-re-run items are present and uncontradicted.

Notes, not counted:
- docs/UTILITIES_REPORT.md:38 lists `autoplay_bot:11` and `tools/qa_sim/autoplay_bot:37` among "9 findings in wrappers not changed in this pass". autoplay_bot changed in 21c2046 (line 11 is now `set -uo pipefail`, `cd ... || exit 2` is on line 12). The report states its evidence head 2e0ada0, so it is dated.
- tools/check.sh's af5_check step says "every file:line citation added to docs/ since e4bb4df holds at HEAD". That overstates the gate: it tests the claim only when a backticked claim stands before the citation, and does not parse extension-less `name:N`. It also reads TZ_DECISIONS.md lines 85 and later shifted by 4, because four lines end in CR CR LF (no citation sits there). FINAL-AF5 states these limits.
- D3: `comm` prints f5_verifier_brief and round1 to round3. They quote the needle in prose; their anchored engine-banner count is 0, and .qa_logs has no engine log after launch 24.
- G7: the "tree" grep also matches the "street" frames, which are district frames and not of the shop or skill-tree screens.
- A1: s0_skill_bootstrap.out and s0_skill_install2.out lack the proof header (disclosed in CORRECTION_LOG 132). af3_f5_fresh_clone_3f5556a.out pipes each gate through `tail -3`, but the claim (16/16, 42/0, 43/2) is visible in the summary lines.
