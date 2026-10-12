# Session 21 verifier, round 1 (read-only subagent; its report as delivered, the harness's indentation removed)

Provenance: a general-purpose subagent given a read-only brief (no Godot, no `check.sh`, no edits, no secrets). The usage limit stopped its first session after it found the stale bundle rows of
`docs/STORE_SUBMISSION.md` section 1 (fixed in `e5a2fd5`); it was resumed and delivered the report below at HEAD `e5a2fd5`. Dispositions of every FAIL: `docs/CORRECTION_LOG.md` row 204.
The report is the subagent's text, not the orchestrator's: the orchestrator re-read the code for B5 and re-ran the control-character scan for H1 before acting on them.

```
SESSION 21 VERIFIER, round 2 (read-only: no Godot, no check.sh, no edits; .signing never opened). HEAD = origin/main = e5a2fd5, tree clean, tag v8.0.0-shipping absent (local and remote). 26d3f51..e5a2fd5 = docs/RESUME_NOTE.md + docs/STORE_SUBMISSION.md only, 0 runtime paths.

RE-CHECK OF e5a2fd5 (your fix)
R1 PASS  STORE_SUBMISSION s1 now: built from abbf91d / ledger row 82 (proof head abbf91d, 0 uncommitted), "seven fixes" = 4 (S20) + 3 (S21), asset pack 108,573,521 (= zip infolist), s21_aab_check and s21_aab_scan proofs exist, line 223 current, and `git diff --name-only e241597 HEAD -- export_presets.cfg android project.godot` prints nothing (I ran it).
R2 PASS  RESUME_NOTE "Next (owner first)" item 1 now 136,501,580 bytes / abbf91d.
R3 PASS  grep e241597|136,500,858|eadfc1d8|four fixes|6f6d643 over STORE_SUBMISSION, release_checklist, RESUME_NOTE, RELEASE_RUNBOOK, docs/store/*.md. Current and correct: STORE_SUBMISSION l.17-28, l.223, l.243; release_checklist l.5 (bar the garbled path, H1); RESUME_NOTE l.5-21 and l.56. Labelled history: RESUME_NOTE l.23-70 (`## History` header, l.32 "Superseded by Session 21"), STORE_SUBMISSION l.3 (draft provenance) and l.18 (names the e241597 manifest, says not re-read), RELEASE_ARTIFACTS older sections ("superseded"). No mention in RELEASE_RUNBOOK, RELEASE_NOTES, docs/store/*.md. Stale and unlabelled: H1, H6, H7 below.

A REPOSITORY FACTS
A1 PASS  git rev-parse HEAD == git ls-remote origin refs/heads/main == e5a2fd5; git status --short prints nothing (before and after all my runs).
A2 PASS  git log a83d99b..HEAD --oneline | wc -l = 25 (24 at 26d3f51 + e5a2fd5).
A3 PASS  git show --stat: 107db81 = inventory_manager.gd; 85fece8 = quest_manager.gd, workbench_logic.gd, workbench.gd; adf0f6b = game_manager.gd, pause_menu.gd; each matches its message.
A4 PASS  runtime diff vs a83d99b (scripts minus tools, scenes, assets, data, project.godot, export_presets.cfg, android, localization) = exactly 7 files: game_manager, quest_manager, workbench_logic, inventory_manager, workbench, pause_menu, main_menu; the six fix files = 63 ins / 12 del (as ORDER_PASS_REPORT says); no residue of the reverted glow outside docs (grep lamp_halo|LampHalos|HALO1 finds nothing).
A5 PASS  68 added runtime lines: 0 TODO, FIXME, print(; the only added comments are `##` prose; no BOM or control character.

B FIXES READ IN THE CODE
B1 PASS  InventoryManager.remove: has() first, then take; remove(5) of 3 takes nothing and answers false (row 174); amount<=0 unchanged; every caller passes 1, a counted stack, or checks first; the LAN _request_remove now gets no excess.
B2 PASS  QuestManager: _complete keeps the B14 reward pre-check (now _reward_fits); _on_inventory_changed pays a pending quest only while GameManager.is_playing() and only if the reward fits; q.done is set before paying so the nested inventory_changed cannot double pay; recursion bounded by the quest count (every quest has at most 1 reward item); load_all fills the pack before quests, never while playing; P2g and the suite stay green.
B3 PASS  WorkbenchLogic.salvage + workbench._do_salvage: parts first, item last, parts already given are removed again if a part is refused (try_add's own toast says why), item kept; the UI returns on false. Same order as the old code, so no new weight edge.
B4 PASS  restart_from_save: has_save -> continue_game (load, PLAYING, game_started), else start_new_game; then unpauses; pause_menu._restart reloads only on true. Edges: has_save() true but load_all() fails => NO_SAVE toast and the button does nothing (state stays PAUSED); no save => a fresh new game.
B5 FAIL GAME-AFFECTING (narrow; read from code, not exercised)  85fece8 makes craft() non-atomic: each remove() emits inventory_changed synchronously and the state stays PLAYING while the workbench/inventory screens are open (pause_game is called only by ui_manager.gd:138 and hud_3d.gd:1446), so a stuck quest pays its reward into the slot the first component just freed; try_add(result) then fails and the refund try_add(...,false) (result ignored, workbench_logic.gd:51-53) can fail too: materials lost (e.g. lockpick = exact stack of 2 metal, full 12-slot pack, one stuck quest). The old code paid only on a quest's own events. No check runs a craft (QST1/SLV1 do not). Options: call_deferred the payout in _on_inventory_changed (re-gate, re-export) or record an accepted-limit row like 170/171.
B6 UNVERIFIED  the scene reload after restart_from_save and the new player's vitals/position are run by no check (CORRECTION_LOG 199 admits the reload). By code, _pending_vitals/_pending_player_pos are consumed only by the new scene's WorldRuntime._place_player, so it should equal Continue.

C AF2
C1 PASS  `af2_both_ways.py --analyze --base a83d99b --only s21 --tag s21` prints "AF2 verdict=PASS ids=5 bad=0", post run DONE checks=8 fails=0, 5 BITES (HALO1 QST1 RMV1 RST1 SLV1); read-only in source and in effect.
C2 PASS  HALO1 belongs to the glow: `git show 7734ade --stat` deletes lamp_halos.gd, lamp_halo.gdshader, the street_props wiring and the HALO1 lines of ship_checks.gd (-24).
C3 PASS  RMV1 (ship_checks.gd:38), QST1 (:64), SLV1 (:85), RST1 (:102) exist, plus guard QST2 (:60) and RST1b (:106); wired in _closeout_check_runner.gd (CLOSEOUT_ONLY=s21 and the end of _rc16_checks).
C4 PASS  s21_af2_pre.out FAIL lines carry the quoted values (RMV1 "0 metal left at 1.5 of 1.5 kg", QST1 "coins 0 of 150, blueprint 0", SLV1 "enhanced battery 0 of 1", RST1 "state 3, tree paused true, coins 1200 of 700", DONE checks=8 fails=6); what RST1's values mean: H3.

D ENGINE-FREE GATES (rerun at e5a2fd5 where docs matter)
D1 PASS  af5_check: 217 citation(s) in 1380 doc line(s), 0 finding(s).
D2 PASS  af3_frame_check default set: frames=6 fail=0; the old sets (--dir docs/stills/rc17 --dir docs/stills/release) read frames=21 fail=21, every one F4 "7 runtime path(s) differ" = CORRECTION_LOG 202.
D3 PASS  lint_changed: 64 gd, 20 py, 14 sh, 1 workflow, skipped tools for: none, 0 finding(s).
D4 PASS  timing_inventory --gate: open 0, stale 0, PASS.
D5 PASS  aab_check --demo OK.
D6 PASS  aab_check build/tls.aab: 136501580 bytes, sha256 f8f62d2cc0897e1f9c659005d790c69368219a729128a8cec31a6dae3edbbee7 (= RELEASE_ARTIFACTS = sha256sum), jar verified, signer_match=yes, adsdk 0. Against the e241597 bundle (136,500,858 bytes, sha eadfc1d8..., recomputed): 0 gone, 0 new, 15 changed = 3 META-INF + 2 caches + pack index + 9 .gdc = exactly the 9 runtime scripts that changed since e241597. release_export_check --aab: 0 packed files that are not the game, PASS.

E BATTERY
E1 PASS  s21_all_d4fa997.out: final summary line (Russian text) reads passed: 66, # EXIT=0, head d4fa997 with 0 uncommitted; 126 OK lines, 0 FAIL, 2 skip lines.
E2 PASS  closeout log: DONE checks=396 fails=0 (396 ok lines; 390 at S20 + 6); the six s21 lines RMV1, guard QST2, QST1, SLV1, RST1, RST1b are ok (lines 416-421).
E3 PASS  suite "[qa] DONE fails=0"; COMPILE_GATE bad=0; TIMING_EQUIV verdict=PASS keys=15 failures=0; engine ERROR lines are shutdown leaks plus the deliberate truncated New Game+ JSON of guard EX5 (also in the S19 and S20 logs).
E4 PASS  perf and audio gates skipped in the attached logs ("[perf] SKIP ... draw_calls=0", "[audio-truth] SKIP DUMMY_AUDIO"): no draw call, p95 or audio reading exists for this pass.
E5 PASS  every document that mentions perf or audio for the pass says so (CORRECTION_LOG 203, RUN_STATE S21-B1 and NEXT-ROW, ORDER_PASS_REPORT "Not done", RESUME_NOTE step 1, PROOFS S21-NO-WINDOWED); the PERF_PASS numbers row 203 cites (D1 175, D11 165, p95 28.8/30.0) are really there.

F HONESTY AND CONSISTENCY
F1 PASS  ledger rows 70-82 consecutive: 12 launches (70-81) + export 82; each proofs/<id>.out exists; head, utc, exit and cmd equal the proof headers (rows 72/73 carry the tool's own "# proof af2_pre/af2_post", documented in CORRECTION_LOG 200); no unrecorded engine log among the .qa_logs files of the pass.
F2 PASS  rc16 af2_both_ways.txt has blob db0b69ad... at a83d99b and at HEAD (a plain cmp differs only by the CRLF checkout); proofs/af2_pre.out and af2_post.out blobs equal too.
F3 PASS  six shipping frames: AF3 clean; code hash 2e018d3 (22:52:40+03) is before the captures 19:53:08-19:53:25Z; runtime diff 2e018d3..HEAD empty; 960x527 (boss 960x540), RGBA 8-bit, alpha min=max=255, 397-834 KiB, as STORE_SUBMISSION l.42 says.
F4 PASS  I viewed all six frames: no flat square or other artefact; the combat frame's white capsule (6.1 % of pixels >=240) and its dim monster bar are the disclosed hit flash; the recorded defect frame (halo_defect/04_combat_after_36632b4) does show the squares, so the revert was right.
F5 PASS  CORRECTION_LOG 198-203 vs code: cited lines 157/57/155/77/138 and daily_challenge_manager.gd:174-188 are right; the remove/quest/salvage/restart statements match the code (RST1 nuance in H3); row 177's premise holds (scenes/ui/death_screen.tscn is loaded by nothing, the live screen is scripts/ui/death_screen.gd).
F6 PASS  all backticked paths in the added doc lines resolve (110 distinct; the 20 unresolved are prose file names, a brace form, user:// or non-paths). S21-V1 numbers re-derived from the git-ignored .qa_logs/sweep: menu >=225 8.80 % -> 0.06 / 0.01 %; night >=240 1.12 % -> 0.08-0.11 %; day 2.11 % -> 1.14-1.55 %; staged combat 4.60 %; committed menu 8.77 % -> 0.06 % (a clone cannot reproduce the ignored frames).
F7 PASS  PROOFS.md: 14 S21 rows = 14 new closures (116 vs 102, no baseline closure altered); all 116 cited sha256 prefixes match the working-tree files.

G BUNDLE AND SECRETS
G1 PASS  RELEASE_ARTIFACTS numbers = tool/zip output: size, sha, 2,684 entries (2,681 outside META-INF), label count 19, base 26,974,685 and pack 108,572,798 -> 108,573,521 compressed, signer 4F:6B:E6:41..., previous bundle hash recomputed.
G2 PASS  git status --short empty after every tool I ran (each read in source first: all read-only).
G3 PASS  secrets, COUNTS only, over the 91 files the pass changed: 67 lines carry the words password or keystore (prose, variable names, paths); 0 lines carry an assignment-like secret value; 0 token-shaped strings; 40 high-entropy candidates, all mangled C++ type names in engine logs.

H OTHER FALSE, MISSING OR OVERCLAIMED (8)
H1 FAIL META  garbled backup path in docs/RELEASE_ARTIFACTS.md:26 and docs/release_checklist.md:5: `..\_BACKUPS\2026-10-11_23-03\build\tls.aab` holds U+0082, a backspace and a TAB (the heredoc-backslash lesson in memory); introduced by eba200d, still at e5a2fd5 (RUN_STATE and RESUME_NOTE have the right path); no static gate scans docs for control characters (check.sh --static was green at eba200d).
H2 FAIL META  "label in 19 entries of the manifest and resources" (RELEASE_ARTIFACTS:24, RUN_STATE S21-E2, ORDER_PASS_REPORT, STORE_SUBMISSION after e5a2fd5): aab_check counts any entry <5 MB outside META-INF = 1 resource table (base/resources.pb) + 13 i18n json + 4 exported scenes + project.binary, so its label check cannot fail on a wrong manifest label alone. The fact stands: base/resources.pb and the manifest are CRC-identical to the S19-verified bundle.
H3 FAIL META  RST1's "defect values" (state 3, tree paused true, coins 1200 of 700) are the check's own staged values: on a83d99b restart_from_save does not exist, so RST1 fails with "answered false"; the old bare reload was never run, yet CORRECTION_LOG 199, PROOFS S21-AF2-PRE and ORDER_PASS_REPORT present them as measured Restart defects.
H4 FAIL META  the AF2 command is documented without --tag s21 (CORRECTION_LOG 199, RUN_STATE S21-J1, PROOFS S21-AF2-PRE/POST): run as written it overwrites rc16 af2_both_ways.txt and proofs/af2_* again, the slip of CORRECTION_LOG 200.
H5 FAIL META  PROOFS.md hashes are of the CRLF working tree: 70 of 116 differ from the committed blobs; the regeneration changed the two rc16 rows AF2-PRE/AF2-POST from LF hashes (0342ae0b, eac90435) to CRLF ones (0558de1b, b58a351f) with no note; an LF checkout cannot re-verify them.
H6 FAIL META  stale "open decision" lists: release_checklist.md step 7 ("E11 second half", "CORRECTION_LOG 168 to 174 and 177 to 180" left open) and RESUME_NOTE `Next (owner first)` item 3 ("E11 second half stays unpaid, the fix breaks P2g"): E11 second half = row 169, fixed in S21 with P2g green; 168/178-180 closed in S20; item 1 of that list was refreshed, item 3 was not.
H7 FAIL GAME-AFFECTING (wrong number in a store-facing doc; one-line doc fix)  docs/release_checklist.md:9 says the six frames "are 960 x 527 PNG"; the new boss frame is 960 x 540 (the old set was all 527; STORE_SUBMISSION l.42 has it right). Also STORE_SUBMISSION caption 2 "a restored district by day" sits beside a night-sky frame (S20 wording, META).
H8 UNVERIFIED  the skill-log rows (ponytail-review, godot-style, backup-first) and "gradlew.bat --stop printed 1 Daemon stopped" leave no repository trace (the export proof has no daemon line).

Notes, not counted: RESUME_NOTE, RELEASE_NOTES and release_checklist already say the tag v8.0.0-shipping exists (true only after tagging, expected). The 3-seed bot ran on 40096f7 with the glow; its diff to HEAD is exactly the glow's 3 files (78 deletions), disclosed in the docs.
TAG WAITS BECAUSE: B5 (a stuck quest can pay into the slot a craft just freed, so a failed craft can lose its materials, and no check covers it: fix it with a deferred payout or record it as an accepted limit) and H7 (one wrong frame size in docs/release_checklist.md); H1 and H6 are two-line doc fixes to make in the same commit.
VERDICT PASS=37 FAIL=8 GAME-AFFECTING=2 META=6 UNVERIFIED=2
```
