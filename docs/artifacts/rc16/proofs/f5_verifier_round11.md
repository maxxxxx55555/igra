PASS=41 FAIL=0 UNVERIFIED=10
UNVERIFIED D2: ledger rows 12, 13, 15, 16, 19 and 30 ran with 1, 1, 2, 4, 2 and 3 uncommitted paths, and no rc16 document says why. Rows 21 and 22 (56 and 3) are the AF2 file swap, by design.
UNVERIFIED D4: rows 12 (1 process), 20 (check.sh --all, 33 processes) and 24 (s8_playthrough_AVBS, 4 processes) have no log with an engine banner. The other 21 rows match their banner counts exactly. The RUN_STATE L1-L19 sum, 76, adds up.
UNVERIFIED T6: CI at HEAD is not recorded. The only record is ci_static_599cd89.json: head_sha 599cd89, 13 "success" conclusions, 12 `"number":` entries, which RUN_STATE:80 states as 8 workflow steps and 12 job entries. All three pins occur in s0_*.out. s0_install_verify.out has `identical=46 mismatches=0`.
UNVERIFIED E1: three closures run a `# cmd` from the session scratchpad, so they cannot be re-run from the repository. The two new proofs, f5_af3_old_gate and f5_duration_sweep, also run scratchpad scripts, but each prints its script.
UNVERIFIED E2: L9 "about 11 min": s8_check_all_a459b9c.out has a start utc and no end time.
UNVERIFIED A2: CORRECTION_LOG 108 ("holds by construction") and 127 argue AF2 by reading. There is no logged fail-then-pass pair, and the rows say so.
UNVERIFIED A3: that every frame was "read once", and what the frames show (rule 3: images not opened).
UNVERIFIED K2: these rest on the session transcript: the order of reviews and commits behind rows 118 to 124, "no other spawn in the window", and the harness tool-call counts that RUN_STATE gives for rounds 1 to 10 (for example "65 tool calls" for round 10).
UNVERIFIED H1: past push equalities cannot be re-proved. What can be checked holds. All 23 commits in 46b0606..HEAD^ appear with their full hash in docs/RUN_STATE.md:62. `git reflog show refs/remotes/origin/main` has a separate "update by push" entry for each of the 24 commits in 46b0606..HEAD. Remote main = HEAD (G1).
UNVERIFIED I1: (a) KNOWN_ISSUES:11 "no other untranslated literal that a player can reach" is a reading of f1_scene_literals.out, and it says so. (c) The report template that CORRECTION_LOG 139 to 144 say was edited in place is outside the repository: `git grep` finds no template in tools or scripts, and gen_proofs16.py has no "Status (" line. Round 10's I1 (b) is now decided: f5_duration_sweep.out:91 `commit ef34725 hits 56`, :93 `commit HEAD hits 50`.

Re-checks of round 10's three findings, at the original places with the original commands. All three are fixed:
- (1) AF3 figure. `grep -rn -a -F 'frames=8 fail=8' docs .qa_logs` now finds only CORRECTION_LOG:113 (row 105, left as written and corrected by row 144), row 144 itself, the round 10 report and the note. RUN_STATE:81 item 4 now says `af3 frames=16 fail=16` (af3_f5_fresh_clone_3f5556a.out:9) and `af3 frames=0 fail=0` on the 24 jpg frames (f5_af3_old_gate.out:31, against `frames=24 fail=0` from the gate at HEAD, :33). `git ls-tree 3f5556a docs/stills/polish` gives 16 frames, and the bca7d33 gate globs `*.png` only (its line 59).
- (2) Timing outputs. Row 144 matches timing_before_dev1 to dev4.out and timing_before.out line for line:
  - row 1, 557c9f3, 0 uncommitted paths: pistol 3.0000/3.1579/3.4952, keys=14 failures=5;
  - row 2: 3.3333 at 120 FPS, failures=3;
  - row 4, 37db979: failures=3, monster hits 0.9972 at 30 FPS against 0.0000 before;
  - row 6: keys=15 failures=4;
  - row 8: keys=15 failures=1.
  All headers match ledger rows 1, 2, 4, 6 and 8. 1ac9dd3 was committed after row 6.
- (3) Push records. The reflog shows daed698, 41186be, 77c5a22 and ad7f263 each pushed. The first three are in RUN_STATE:62 with full hashes, and HEAD ad7f263 = remote main.

Sweeps read:
- Gates run by me, each exit 0:
  - af5_check: `143 citation(s) in 661 doc line(s), 0 finding(s)`; demo `5 cases, 0 wrong`.
  - af3: `frames=50 fail=0`, which equals D7 (16 24 6 1 3).
  - i18n: `12/12 locales PASS`; the gate's diff since e4bb4df is only `-import re`.
  - lint_changed: `49 gd, 18 py, 13 sh, 1 workflow, skipped tools for: none, 0 finding(s)`, the same as lint_final.out.
  - bot_counter_check: 0/1, 0/1, 0/2 with rc=1 on f49a5cf; 1/1, 2/1, 1/1 with rc=0 on 21c2046.
- Loops and counts:
  - F1, F2 and F3 printed nothing.
  - Ledger: 36 lines, 24 rows of this pass, 35 in PROOFS. UTCs rise and no head is newer than its row.
  - The three `Godot Engine v` hits outside the ledger ids (D3) are brief and report texts, not logs.
  - 47 closures = 47 PROOFS rows.
  - CORRECTION_LOG 101 to 144: no duplicate id, and every commit hash in a cell resolves (the four non-resolving ids are blob ids of the af3 scope).
- Closures: 47 claims, all 104 quotes found by script in their logs. I checked every number in a claim that no log holds: CORRECTION_LOG row numbers, figures marked derived (322.5, 187.5, 34 and 66, 172 = `grep -c` 172/0), or arithmetic (65 = 68-3, 36 of 39 = the 3 Arabic cases outside).
- Closeout figures: every `checks=/fails=` pair in RUN_STATE, CORRECTION_LOG 101 to 144, PROOFS, the report, RESUME_NOTE, KNOWN_ISSUES and TZ_DECISIONS (11 distinct pairs) occurs in a `[closeout] DONE` log line.
- Launch bullets: 23 bullets for 24 launches, with the numbers after "Answer:" checked against their logs by script, and L8, L9, L12, L13, L14, L15, L16, L17, L22 and L24 read in full. The 40 px button minimum of L22 is in the TEXT1 line of f1_pre_b7aee72. The perf table in PERF_PASS:89-99 (1784 to 1061 nodes, 354 to 317 and 359 to 275 ms, 1.8/2.3 to 3.0/4.1 hitches, 144/150 to 150/147 ms) I recomputed from the two probe logs, and 130.0/159.6 MiB is in the after log.
- Audio: 17 readings, 8 CLIP-FAIL. The launch-24 arms are exactly +1.8/+0.6/-12.4 (A) and -10.5/+0.6/+0.7 (B). The 924e3dd reading is the 11th by UTC.
- Key=value sweep: 100 tokens in the 1319 document lines added since e4bb4df. The 28 not in any log are verifier verdicts, the brief's own commands, and two figures the documents themselves withdraw: `fail=8` (row 105, corrected by 144) and `frames=48` (row 129).
- Acceptance and gates: proven=178, other=22, `accept=178/200`, QS2 = 5 lines, PF3 withdrawn as OWNER, PF1/PF2/PF4 rc16 probe values under their thresholds. All 15 modified gate files read: the 8 with no row are a lint hook, prints or unused-variable and import removals, none a tuning.
- Rules and honesty:
  - U1 to U8: 8 rows, each ending in an owner sentence.
  - The 4 OWNER/NOT-VERIFIABLE rows are in the gap table.
  - The AF7 hits all name a row, or predate e4bb4df (KNOWN_ISSUES:772, 64b0353).
  - The NO-SPIN word grep found nothing.
  - I1: 63 hits; I read the new-line hits in full.
  - I3: "all gates green", "Arabic shop closed" and "rc16 bundle" do not occur; build/tls.aab = 183257097 bytes, Oct 2.
  - I4: the old stills paths appear only in commands and labelled rc15 comparisons.
- Skill log: 22 rows, 16 ok; the header states "22 rows, 16 ok". Cited outputs hold: `total 19`, `http_code=000`, `curl exit=7`, backup-rc16-pre-f4 = 40966b1 and not on the remote, finish_checks.gd 94/86/107 lines, screens.gd 1062 lines, b4c1db0 numstat 2/1 per runtime file (+1 net) and 7/15 for finish_checks. Every code commit in the window has a review row or row 117 (b7aee72 and 3766b13/fa6afc0 covered, 30363f8 covered).
- G checks:
  - Nothing outside docs and proofs changed since 41186be; `git diff --stat 41186be HEAD` prints nothing for the runtime paths and tools.
  - 74f710b..HEAD changes only tools/check.sh and af3_frame_check.py, 1 line each.
  - c3e79e5..HEAD runtime: screens.gd and skill_tree_ui.gd, 21 insertions and 15 deletions, last changed 74f710b.
  - The added lines have no print, TODO, FIXME, commented-out code or BOM.
  - Blobs match af3_f4_scope.tsv.
  - BTN_CLOSE has 13 distinct values; 13 files of 1525 keys.
  - rc15^{commit} = e4bb4df; 30 commits to c407e60; "109 commits" = e4bb4df..3bd8932^.
- Citations: 9 cited lines read by hand, all saying what their sentence claims: screens.gd:938 and :968, skill_tree_ui.gd:46, finale_director.gd:136, check.sh:400, pause_menu.gd:61, _rc16_probe_runner.gd:159 and :231 (plus af5's 143).

Z1: HEAD ad7f2635b52b7afbafdffcffbcc96473cd58d9d5 at the start and at the end, and `git status --porcelain` is empty both times. Remote main = HEAD. No v8.0.0-rc16 tag, locally or on the remote. Nothing was written into the repository; scratch files are only in the verifier_r11b scratchpad. About 55 tool calls.

Counting: PASS counts the 41 checks G1 to Z1, none with a finding. UNVERIFIED counts the 10 undecidable parts listed above. With FAIL=0 and Z1 passing, the brief's condition for creating v8.0.0-rc16 is met. The tag commands are in docs/RESUME_NOTE.md.
