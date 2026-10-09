# F5 verifier, round 4: the agent's report, verbatim

Agent a93b506ce4e511f60 (general-purpose, read-only), brief `docs/artifacts/rc16/proofs/f5_verifier_brief.md` and `docs/artifacts/rc16/proofs/f5_verifier_round4_note.md`, HEAD `2dbfa259435d394a9ef4acbe323455f349dad4a1` (pushed, `git ls-remote` equal), 153 tool calls by the harness count, 2026-10-09 (a first start of this round, agent a21ee092787546b2d, ended after 3 tool calls on an API usage limit and delivered nothing). Below is the agent's final message as it reached the orchestrator, unedited; the session transcript indents every line of such a report and that indentation is removed here. The fix is CORRECTION_LOG 136.

F5 verifier round 4. HEAD 2dbfa259435d394a9ef4acbe323455f349dad4a1 (git status clean, remote main equal, no rc16 tag local or remote). Z1 passed: same HEAD and clean status at the end. Nothing written in the repository. No Godot, no tools/check.sh. About 150 tool calls.

PASS=38 FAIL=1 UNVERIFIED=11

FAIL T1/A5 (AF5) docs/TZ_DECISIONS.md:27 and :54 (rows V05 (correction) and V05-mobile): the rows say "Stays 2048 (GDD.md:317)" and "`GDD.md:317` has no mobile exception"; measured: `sed -n 317p docs/GDD.md` is the monster-sprite line ("Watcher ... Босс 1024²)") with no 2048; `grep -n 2048 docs/GDD.md` gives 326 ("Moon shadow 2048² (вкл)", the shadow-atlas decision of CORRECTION_LOG #4) and 402; `git show c46d8a3:docs/GDD.md | sed -n 317p` was the Moon shadow line on 09-25, so the cited line moved 9 lines before e4bb4df (e4bb4df already has the monster line at 317). The rows were rewritten in a459b9c with the stale citation. `python tools/af5_check.py` still prints 0 findings (no backticked claim stands before the citation), and CORRECTION_LOG 133/135 and the FINAL-AF5 closure ("the others were read by hand and compared with HEAD") did not catch it. Fix: cite GDD.md:326.

Round 3's two findings, re-checked at their places: both hold.
- docs/UTILITIES_REPORT.md:37 now cites runner :1191, character_screen :281, hud_3d :1527, puzzle_cables :204. gdtoolkit `parser.parse` on the four files stops at 1191 col 25, 281 col 56, 1527 col 92, 204 col 73, and the lines hold the described constructs.
- docs/RUN_STATE.md:56 now says "other 39 `after` frames". `ls docs/stills/{polish,rc16_playthrough,rc16_final,rc16_gui} | grep -c _after_` = 39. `grep -n 'other 41'` only hits rows 129/135 and RUN_STATE:62, which describe the old error.

Citations: I read all 140 in the gate's scope (lines added since e4bb4df, newest RUN_STATE block).
- 85 have no claim before them: read by hand against the cited line at HEAD.
- 55 have a claim: skimmed.
- Also read: 8 shorthand `:NNN` continuations, and TZ_DECISIONS at true line numbers (the file has four CR CR LF at lines 85-88, so the gate reads later TZ lines shifted by 4; the only citations after line 80 are at :86 and :88, both correct).
- My own drift script (blame commit of each sentence against HEAD) flags 5, the five named in CORRECTION_LOG 135: ACCEPTANCE_CHECKLIST:334 -> TZ:20, :343 -> TZ:28, TZ:16 -> GDD:22, RUN_STATE:64 menu_background.gd:139 and toast_manager.gd:27. They are rows whose tail text changed or pre-patch lines; the sentences still hold or are dated.
- `af5_check --all` finds 109 in old documents, as the report says.

Gates run by me, all exit 0 except the expected rc=1 of the dead-counter check:
- af5_check: 140 citation(s) in 728 doc line(s), 0 finding(s); `--demo` 5 cases, 0 wrong.
- af3_frame_check: frames=50 fail=0 (= D7: 16+24+6+1+3).
- i18n_truth_gate: 12/12; its diff vs e4bb4df is one removed `import re`.
- lint_changed: 49 gd, 18 py, 13 sh, 1 workflow, skipped tools for: none, 0 finding(s) in 10 s (same as lint_final).
- bot_counter_check: f49a5cf logs 0/1, 0/1, 0/2 with rc=1; 21c2046 logs 1/1, 2/1, 1/1 with rc=0.
- flow_check 56 checks and scene_node_check "Всё чисто".

Main measured facts:
- G1: remote main = HEAD.
- G2: v8.0.0-rc15^{commit} = e4bb4df, e4bb4df..c407e60 = 30, the report's "102 commits" = e4bb4df..31750a6 (parent of 2dbfa25) = 102.
- G3: since 74f710b only af3_frame_check.py (1 line).
- G4: since c3e79e5 only screens.gd and skill_tree_ui.gd (21+/15-), last change 74f710b.
- G5: no print, TODO, FIXME, commented-out code or BOM in the F1 diff.
- G6: 13 distinct BTN_CLOSE, 13 x 1525 keys.
- G7: scope tsv and blob hashes as declared; only the three 74f710b frames for shop and skill tree.
- F1, F2 and F3 loops print nothing.
- D1: ledger 36 lines, 24 rows from 12, 35 rows in PROOFS.
- D6: 47 closures = 47 rows.
- D8: CORRECTION_LOG 101-135 = 35 rows, no duplicates, commit cells resolve, documents say "101 to 135".
- D5: 24 used, 0 left everywhere; the "19 of 20 ... 1 in reserve" paragraph is marked superseded.
- E3: 17 windowed readings, 8 CLIP-FAIL; launch 24 arm A +1.8, +0.6, -12.4, arm B -10.5, +0.6, +0.7; both modes inside arm A.
- E5: proven=178 other=22; the e4bb4df baseline is 176/24; only CT7, QS2 and I9.7 -> PASS(closeout) and PF3 -> OWNER changed; the QS2 log holds 5 checks, CT7 holds 9 in both cited logs; PF1/PF2/PF4 quote probe values inside their limits.
- E2/E1: all 104 quotes of the 47 closures are found in their raw logs; every `[closeout] DONE` figure in the documents matches a log; numbers absent from the logs are labelled derived.
- A2: af2_both_ways.txt tail, HEAD 8cb22ba and 36 BITES are as expected; c3e79e5..b7aee72 runtime diff (excluding tools) is empty.
- K1: 19 skill rows, 13 ok; finish_checks.gd is 94/86/107 lines at b7aee72/b4c1db0/HEAD; screens.gd is 1062 lines.
- K2: all 7 code commits in the window have a review row or a CORRECTION_LOG reason (117-124); `tools/patch_scenes.py` was deleted in 37db979 (before the window); I verified it does not parse (SyntaxError) and nothing referenced it.
- H1: all recorded push hashes are ancestors of HEAD; CORRECTION_LOG 125 and f5_push_state tell the truth (23 commits to 46b0606).
- I3: Arabic shop, bimodal audio, battery not re-run and AAB = rc15 (183257097 bytes, Oct 2) are all present and uncontradicted.
- A6: no banned praise words, and every admitted error names a row.

UNVERIFIED D2: ledger heads with "(uncommitted paths: N>0)" at rows 12, 13, 15, 16, 19, 21, 22, 30; no document states the reason.
UNVERIFIED D4: rows 12, 20 (check.sh --all: 33 processes in the run, 34 derived for the plain command, documented) and 24 have no banner-bearing log; the other 21 rows match their bullets.
UNVERIFIED T6: CI at HEAD. Only the run at 599cd89 is recorded (success, 12 job entries = 8 steps + set-up, 2 post, complete). The CI inputs are unchanged since 599cd89, and I ran its four steps locally with exit 0.
UNVERIFIED E1(b): 15 proof logs whose `# cmd` runs a scratchpad script (S0 scan/install/verify, f5_* proofs) cannot be re-run from the repository.
UNVERIFIED E6: BEAUTY_RC16 X1 LUT colour values (white 216,239,208 -> 240,232,213, brass) have no log. The hue, grain, node, MiB, hitch and settle numbers are verified.
UNVERIFIED A2: CORRECTION_LOG 127 (audio bus gate follows the reverb design) is argued, not a logged fail-then-pass pair.
UNVERIFIED A3: that every frame was "read once" and the frame descriptions (rule 3 forbids opening images).
UNVERIFIED K1: the skill-log header still promises `skills=<n>` and no line states it (F6 pending).
UNVERIFIED K2: "no other spawn in the window", the transcript line numbers of CORRECTION_LOG 118-124 and the tool-call counts come from the session transcript.
UNVERIFIED H1: past push equalities (be84a29 ... 31750a6 and the 23 commits after 3f5556a) cannot be re-proved; present equality holds.
UNVERIFIED I1: KNOWN_ISSUES.md:11 "no other untranslated literal that a player can reach" is a reading, not a logged check (f1_scene_literals: 86 lines in 22 scenes recomputed).

Notes, not counted:
- D3: `comm` prints f5_verifier_brief, round1, round2 and round3. They are .md files quoting the needle in prose, not engine banners; `.qa_logs` has no engine log after launch 24.
- A1: s0_skill_bootstrap.out and s0_skill_install2.out have no `# proof`/`# cmd` header (disclosed in CORRECTION_LOG 132); pre-21c2046 logs have no `# env` (CORRECTION_LOG 109). af3_f5_fresh_clone_3f5556a.out pipes each gate through `tail -3`, so the gates' own exit codes are masked, but the three summary lines it claims are visible.
- docs/UTILITIES_REPORT.md:31/:38 (evidence head 2e0ada0) lists autoplay_bot:11 and :37 among "9 findings in wrappers not changed in this pass". autoplay_bot changed in 21c2046 and both findings are gone. Not counted: the report states its evidence head.
- CORRECTION_LOG 120 says af3_frame_check.py "+38 lines"; `git show --numstat 3766b13` gives 33 insertions and 5 deletions (38 only as insertions of the .py and the .tsv together, or as 33+5).
- TZ_DECISIONS.md:16 (I02) still says "owner amends the GDD line"; GDD.md:22 already reads 1525 keys per locale.
- I2: the S8-AUDIO row says "passes on unmodified HEAD" and does not say "before the F1 edits". Only UI and gate files changed since 924e3dd, and the row carries its commit and the 8-of-17 caveat.
