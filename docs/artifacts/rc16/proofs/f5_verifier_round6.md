# F5 verifier, round 6: the agent's report, verbatim

Agent a79b4c8fda31c4ad8 (general-purpose, read-only), brief `docs/artifacts/rc16/proofs/f5_verifier_brief.md` and `docs/artifacts/rc16/proofs/f5_verifier_round6_note.md`, HEAD `b8455071ddbcfca7431d7ec6c2461e7be051cf67` (pushed, `git ls-remote` equal), 132 tool calls by the harness count, 2026-10-09. Below is the agent's final message as it reached the orchestrator, unedited; the session transcript indents every line of such a report and that indentation is removed here. The fixes are CORRECTION_LOG 138.

PASS=43 FAIL=2 UNVERIFIED=12

Subject: HEAD b8455071ddbcfca7431d7ec6c2461e7be051cf67 (b845507). Z1 passed: same HEAD, empty `git status`, remote main equal (`git ls-remote`), no v8.0.0-rc16 tag local or remote. I wrote nothing into the repository (nothing in it is newer than my start; the ignored .ruff_cache dates from 2026-10-03). No Godot, no tools/check.sh. About 150 tool calls.

FAIL A4 tools/qa_sim/af3_frame_check.py:193: the brief's A4/AF4 says a change of a gate's scan list needs a CORRECTION_LOG row with before, after and rationale. Row 124 (docs/CORRECTION_LOG.md:132) logs the rc16_f1 addition of fa6afc0. The same default-directory tuple also gained rc16_final in 26eef24 and rc16_gui in 924e3dd, and no row records either. Measured: `git show 26eef24 --format= -- tools/qa_sim/af3_frame_check.py` and the same for 924e3dd are one-line tuple edits. `awk '/^\| 1(0[1-9]|[12][0-9]|3[0-7]) \|/' docs/CORRECTION_LOG.md | grep -E 'rc16_final|rc16_gui'` finds row 124 only, and there as the "before" list. `grep -E '26eef24|924e3dd'` over rows 101-137 hits rows 106, 113 and 136, none about the list. The edits only widen the gate; the gap is the missing row.
FAIL K1 docs/RUN_STATE.md:32: the skill-log row "ponytail-review before the commit of the round 5 fix" says "the message in 77 instead of 118 characters". Measured: the message committed in 30363f8 at tools/check.sh:350 is 125 characters (113 inside the parentheses); the message it replaced is 79 (python len() of the string found by `sed -n 350p tools/check.sh` and `git show 30363f8 -- tools/check.sh`). 118 is neither. Only 77 is reproducible (a shortened variant). This is the row added after round 5, so no earlier round could have checked it.

UNVERIFIED D2: ledger heads with (uncommitted paths: N>0) at rows 12, 13, 15, 16, 19, 21, 22, 30 (N = 1, 1, 2, 4, 2, 56, 3, 3). No rc16 document states why (grep for "uncommitted" finds only proof_run's header line).
UNVERIFIED D4: rows 12 (1 process), 20 (check.sh --all, 33) and 24 (4 modes) have no banner-bearing log. The other 21 rows match their bullets and the sum 87 matches ORDER_PASS_REPORT.md:191.
UNVERIFIED T6: CI at HEAD (only the run on 599cd89 is recorded: success, 12 job entries = 8 steps + set-up + 2 post + complete; no network beyond ls-remote).
UNVERIFIED E1/E2: 18 proof logs have a `# cmd` that runs a script from the session scratchpad (S0 scan/install/verify, f5_*); they cannot be re-run from the repository. The log content itself was read.
UNVERIFIED E1/E2: "66 checks, 34 processes" (S8-BATTERY, RUN_STATE L9, report) is labelled derived and needs the engine.
UNVERIFIED A2: CORRECTION_LOG 108 and 127 (restored uifx assertions; audio-bus gate) are argued "by reading" with no logged fail-then-pass pair; the texts say so.
UNVERIFIED A3: that every stamped frame was "read once" and what the frames show (rule 3). S_credits identical to the rc15 frame was checked by git blob id only (708a67f9c838 for both).
UNVERIFIED K1: the skill-log header promises skills=<n> and no line states it (20 rows, 14 ok).
UNVERIFIED K2: "no other spawn in the window" and the transcript line numbers of CORRECTION_LOG 118-124 (f5_skill_order.out) come from the session transcript. The sizes 94/86/107, 1062 and "+1 line each" I recomputed.
UNVERIFIED H1: past push equalities (be84a29 ... 30363f8 and the 23 commits after 3f5556a) cannot be re-proved. All named commits are ancestors of HEAD, the 23 recount to 23, and present equality is G1.
UNVERIFIED I1: KNOWN_ISSUES.md:11 "no other untranslated literal that a player can reach" is a labelled reading (its 86 lines in 22 scenes I recomputed).
UNVERIFIED A4/K1 detail: the "12 lines ... net -10" of the first ponytail-review row and CORRECTION_LOG 118 (b4c1db0 shows finish_checks.gd 94 to 86 lines, +7/-15) and UTILITIES_REPORT.md:17 "16 findings at the start" (utilities_u0.out holds only the end state, findings=9). My shellcheck re-run on the old trees was refused by the harness's rm safety check (no rm in it); not worked around.

Round 5's finding, re-checked at its original place: FUNCTION_MATRIX.md:171 (row X45) now says "QS2, 5 checks"; `nocolor < s8_closeout_rc16_21c2046.attach.closeout_check.log | grep -c 'ok   QS2\|FAIL QS2'` = 5; SECURITY_REREAD_RC16.md:24 says "fifth check". Fixed.

Sweeps (round 6 note):
- "<id> N checks": 51 claims in 16 documents against the closeout logs. All match: CT7 9, QS2 5, E11 3, E13 2, S02 5, S04 18, G21 24, G25 22, G26 10, C03 2, and the totals 347, 365, 366, 56, 59, 64, 65, 67, 68, 51/44, 32/20. Ordinal "first..fifth check" hits: 5, consistent.
- Citations: 140 file:line citations in the lines added since e4bb4df, read in context with the cited line (RUN_STATE counted from Session 17 only). `af5_check.py --file` over every line of the 16 changed documents: 158 citations in 3542 lines, 6 findings, all in pre-e4bb4df lines (PERF_PASS.md 42/49/52/56/57, KNOWN_ISSUES.md:112), so not this pass.
- References: 712 path tokens, 408 hashes and 51 proof ids in the added lines of 19 documents. Unresolved ones are sha256 prefixes, two third-party pins, frames the text says were replaced, the deleted tools/patch_scenes.py and tool names.
- PROOFS vs closures.json: 47 rows, 0 differences. The 146 quoted lines are all in their logs or exist as frames. The ledger table has 35 rows, equal to the tsv.
- Closure commit cells: all 47 resolve and equal the head in their proof.

Measured with no finding: G1-G7 (G3: two tool files since 74f710b, af3_frame_check.py 1 line and tools/check.sh 1 line, message only; runtime paths 0 since 0ab9503; G4 74f710b, 21+/15-). D1, D3 (the four names printed are the verifier brief and reports quoting the pattern in prose; .qa_logs has no engine log after launch 24), D5-D8 (CORRECTION_LOG 101-137, 37 rows). T1 (140 citations in 733 lines, demo 5/0), T2 (50 frames, fail 0), T3 (12/12, one removed `import re`), T4 (49 gd, 18 py, 13 sh, none skipped, 0 findings), T5 (0/1, 0/1, 0/2 rc=1; 1/1, 2/1, 1/1 rc=0), T6 pins and identical=46, flow_check (56 checks) and scene_node_check (clean). E3 17/8/9 and the launch-24 arms; E5 proven=178 other=22; E6 numbers; A1, A5, A6, H1 ancestry, I2-I4. Open items (Arabic shop, bimodal audio, battery not re-run, rc15 AAB of 183257097 bytes) are present and uncontradicted.

Not counted, dated by its Evidence line (2e0ada0): docs/UTILITIES_REPORT.md:38 still lists autoplay_bot:11 and :37 among "9 findings in wrappers not changed in this pass"; autoplay_bot changed in 21c2046 (cd with `|| exit 2` is on line 12, the `districts` variable is gone). Round 5 left this note too.

The tag v8.0.0-rc16 may be created only with FAIL=0; this run reports FAIL=2.
