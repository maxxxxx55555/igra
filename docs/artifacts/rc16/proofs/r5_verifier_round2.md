PASS=55 FAIL=4 GAME-AFFECTING=0 META=4 UNVERIFIED=4
FAIL META docs/RUN_STATE.md:18: "S18-G1 (no engine, at `8663aec` with no uncommitted path)"; measured: `v800_static_8663aec.out` reads `# head 8663aec (uncommitted paths: 0)`, but `v800_gates_8663aec.out` reads `# head 8663aec (uncommitted paths: 1)` (utc 20261011T001323Z). That run came 68 s after the static run, whose log was only committed in 19a7075. No runtime path differs, so the results of the gates stand. This is the same case as CORRECTION_LOG 155.
FAIL META docs/ORDER_PASS_REPORT.md:190: "Records: `docs/RUN_STATE.md` Session 18 and `docs/CORRECTION_LOG.md` 145 to 150"; measured: rows 151 to 159 also belong to this pass (151 was added at 63fda65, 152 to 159 at 8663aec, by `git log -S`). Lines 200 and 207 of the same section cite those rows and were updated at 8663aec, but `git blame` dates line 190 to d4fa2da. The note's own scope is rows 145 to 159. This is the stale-range case of check D8 in the brief.
FAIL META docs/KNOWN_ISSUES.md:14: "... and so do the other Screens cards (Bestiary, Events, Loading, Saves and the rest; not looked at in Arabic)"; measured: ledger row 46 (`r0_rtl_screens_b82bfef.out`, 20261010T220822Z) did measure them in Arabic: Saves 3 of 3, Bestiary 1 of 1, Events 4 of 4, plus five more cards. KNOWN_ISSUES.md:9 reports this. Only Loading (with PhotoMode, PuzzleCables, StoryScene and FinalNight) was left out (scripts/tools/rc16/finish_checks.gd:151). `git blame` dates the line to a4f2800, which ran before row 46.
FAIL META docs/RESUME_NOTE.md:23: "Session 18 ran it at `af5225d` (2 gates red, ...) and the fixed gates again at `18a2a2a`"; measured: only the closeout ran at 18a2a2a (row 54, `checks=379 fails=0`). The other fixed gate, the layout check, ran only at e13d3f9 (row 49, `[uilay] DONE fails=0`). Between e13d3f9 and 18a2a2a only scripts/tools/_closeout_check_runner.gd changed, so the layout result still holds, but the sentence is wrong as written. CORRECTION_LOG 158 has it right: "rows 49, 52 and 54".
UNVERIFIED skill calls and chat: these live in the session transcript and the owner's chat, not in the repository. They cover RUN_STATE.md:21-33 (the Skill tool calls and the cuts they report, including the R5 ponytail-review), RUN_STATE.md:16 ("51 tool calls", and the first spawn that was cut off), and the owner directives the records cite (CORRECTION_LOG 145, the R0 directive at KNOWN_ISSUES.md:9, the tag pre-authorization). Reading the transcript would decide them.
UNVERIFIED frame contents: RUN_STATE.md:7 and :14, ORDER_PASS_REPORT.md:195 and :205 ("read once", the title in one line, the Arabic shop inside its panel, six cards and the top of the seventh). By rule I did not open images; I checked names, hashes, UTC times and `af3 frames=21 fail=0`. Looking at the 21 frames would decide them.
UNVERIFIED actions outside the logs: none of these is in a log, though the clean tree and every result fit them. The session's shell history would decide them.
- `gradlew --stop` and the `default_bus_layout.tres` revert after both exports (RELEASE_ARTIFACTS.md:23 and :31).
- The hidden `Провалено: 1` (CORRECTION_LOG.md:156).
- The static battery and the D2 gates run "as plain shell commands" (CORRECTION_LOG.md:160).
- What the uncommitted paths held: rows 39-46, 49-53 and 55-57, plus 1 path in v800_gates and 2 in aab_verify_v800.
UNVERIFIED Play requirements quoted at release_checklist.md:8-9 and ORDER_PASS_REPORT.md:209: 320 to 3840 px, 1080 px for featuring, screenshots and feature graphic without alpha, a 32-bit icon. Checking them needs the Play Console help pages (network).
Re-checks of round 1's nine findings:
1. GAME-AFFECTING DESIGN_PREMIUM_PASS.md:28 (Android label): resolved. export_presets.cfg:19 now reads `package/name="Last Streetlight"` (63fda65, CL 151). I parsed base/resources.pb of build/tls.aab myself: "Last Streetlight" in 42 of 42 label entries; the rc17 and rc16 backups read "TLS" in 42 of 42. PASS.
2. ORDER_PASS_REPORT.md:201 (no static log): deferred by CL 152, and the row is correct. `grep -l '^# cmd .*check\.sh --static'` now also lists v800_static_8663aec.out (0 uncommitted, "Всё зелёное. Проверок пройдено: 40", EXIT=0). Report:201 and checklist:7 point there. Report:204 still cites "RUN_STATE S18, D2", whose figures v800_gates holds (12/12, MISSING: 0). PASS.
3. ORDER_PASS_REPORT.md:196 (boot title has no AF2 pair): deferred by CL 153, and the row is correct. boot_title still appears only in `_shot("00_boot_title")` (_final_frames_runner.gd:115), and the frame the row names exists. PASS.
4. release_checklist.md:8 (960 x 540): corrected (CL 154). Line 8 and report:209 now say 960 x 527 with alpha; the IHDR of the 6 release frames and 08_shop_ar reads 960 x 527, colour type 6. PASS.
5. RUN_STATE.md:14 (uncommitted paths): corrected (CL 155). It now says 0/3/20/22, which matches the `# head` lines of rows 54-57. PASS.
6. RUN_STATE.md:27, now :30 (reviews after the fact): deferred by CL 156, and the row is correct. `grep 'after the fact'` hits lines 125 and 164; the label fix was reviewed before its commit (RUN_STATE.md:31). PASS.
7. RESUME_NOTE.md:21: corrected (CL 157). It names the eight Screens cards and says the shop is fixed. PASS.
8. RESUME_NOTE.md:23: the row 48 part is corrected (CL 158), but the new text is wrong in another way: see the FAIL line above. FAIL, counted once.
9. store/listing.md fr title: corrected (CL 159). Line 293 reads "LE DERNIER RÉVERBÈRE", and my own Python compare finds 26 of 26 titles and taglines equal to menu_title/menu_subtitle. PASS.
Sweeps read:
- Checks counted: git 4, ledger and launches 2, RUN_STATE S18 15, CORRECTION_LOG 145-150 6, documents 12, code 5, tools 5, re-checks 9, Z1 1 = 59 (55 PASS, 4 FAIL). CORRECTION_LOG 151-159 are judged through the re-checks.
- Ledger: rows 37-58 (22 rows) against their proof headers: 0 utc/head/exit mismatches, 58 rows numbered in order, utc strictly rising, 0 heads newer than their row. Since d4fa2da the ledger only gained one line (row 58). Windowed launches 4 (rows 37, 48 with its windowed reimport, 55, 56); EXPORT runs 2 (rows 47, 58).
- Hidden launches: 5 files outside the ledger carry the engine banner, all rc16 verifier documents quoting it, none from Session 18. In .qa_logs, 5 files are newer than row 58's log (copies of the five no-engine proofs), none with a banner. The 21 guarded launches each read "0 file(s) snapshotted / 0 restored".
- Git: the bundle was built at 63fda65. 63fda65..HEAD touches 15 doc/proof paths plus store/listing.md (the fr title, 8663aec). The bundle has 0 `.md` entries, so that file does not ship; the repo-root store/ does ship 24 PNG import entries, none of which changed. The runtime diff 66e67b3..HEAD covers 23 paths: the merge's 21, plus boot_loading.gd and screens.gd. Runtime commits after the merge: a5bfe70, a4f2800, 63fda65. The merge has 0 combined-diff hunks and no colour lines. Merge paths changed since the merge: export_presets.cfg:19 (not a merge line) and store/listing.md:293.
- Bundle (build/tls.aab, read with Python zipfile):
  - 183290613 bytes, sha256 58a0242a…, 2891 entries.
  - base 26974685 compressed / 78462232 raw; asset pack 155283834 / 213749515.
  - 0 entries under docs/, tools/, scenes/tools/ or scripts/tools/.
  - 0 `Lcom/applovin/` and 0 billingclient references in the one dex; permissions DUMP, INTERNET, VIBRATE (no BILLING).
  - Label "Last Streetlight" in 42 of 42 entries.
  - Manifest: versionCode 1, versionName 1.0, minSdk 24, targetSdk 36.
  - The bundled i18n en/fr files match the working tree.
  - The rc17 backup is 183290597 bytes, sha256 6608a50a…; the rc16 backup is 183290294 bytes, sha256 428dd6df….
- Code:
  - 13 locale files × 1526 keys, 0 missing, 0 BOM; boot_title is "Last Streetlight" in all 13.
  - Added lines: 0 TODO/FIXME, 3 prints (all in scripts/tools, which the export excludes), no commented-out code.
  - 0 BOM and 0 signing secrets in the 115 changed paths; no key files are tracked.
  - No window-title setter outside tools. `cycle_language` has no caller outside tools, so a player changes language only in settings_screen.tscn. The screens.gd diff since rc16 is inside `_populate_shop` only.
  - Release-note figures match the data: 11 districts, 12 monsters, 5 endings, 13 languages.
- Gate edits: af3_frame_check.py:193 (d390826, d4fa2da) → CL 146; af3_f4_scope.tsv (c76442b, 63fda65) → 148 and 151, with blobs c97b3dc41876→9b24eec51e30 and 49f8a4e→79f400a matching git, and 0 frames matching *app_label*; SHOP2 → 147; English pin, _ui_layout_check and SH1 → 149.
- Logs: every quoted figure of S18-L1…G1 and CL 145-151 was found in its log. That includes SHOP2 ar/0-2 (header x 1433.333 vs content 913.3335), the eight RTL cards, `Провалено: 2, пройдено: 64`, SH1 1195<=1166, 1201<=1171, 1123<=1164, 1167<=1165, closeout 379/0, 15 distinct frame lines in the R2 log, audio -10.6 dB, and the snapshots 0 (new folder) vs 11 (old folder). U8: 18 Music-bus readings, 8 CLIP-FAIL, 10 ok, every value found. The function matrix recounts to 146 rows (WORKS 105, FIXED 31, CANNOT-TEST-HEADLESS 6, REMOVED 2, BY-DESIGN-LIMIT 2, BUG 0). The old user:// folder was last written 2026-10-08.
- Frames: rc17 has 15 (14 at a5bfe70, 212208Z-212241Z, plus 08_shop_ar at 18a2a2a); release has 6. All 21 fall inside the launch of their hash and are 960 x 527 RGBA. The store icon is 512 x 512 RGB, the feature graphic 1024 x 500 RGBA.
- Tools I ran:
  - af5_check: `150 citation(s) in 817 doc line(s), 0 finding(s)`; its demo: 5 cases, 0 wrong.
  - af3: `frames=21 fail=0`; its demo: OK.
  - i18n_truth_gate: `12/12 locales PASS`.
  - hardcoded_text_gate: `0 hit(s)`.
  - lint_changed: `54 gd, 18 py, 13 sh, 1 workflow, skipped tools for: none, 0 finding(s)` (RUFF_CACHE_DIR in scratch).
- Outside the note's scope, not counted:
  - UNVERIFIABLE_HERE.md:14 (U6) still says frames were captured "at 960 x 540"; an rc16_final frame measures 960 x 527.
  - RELEASE_RUNBOOK.md:21 says "The preset sets no target_sdk", but export_presets.cfg:29-30 carry `min_sdk=29`/`target_sdk=34`. The export does not use these keys: the bundle reads min 24 / target 36, as that runbook row expects.
Z1:
- HEAD was ff6ffe6bf5adebed2cdac2141cd4f34d6e66dc5e at start (2026-10-11T00:17:25Z) and at end (00:44:26Z).
- `git status --porcelain` was empty both times, and the ignored-file status was identical (1419 lines).
- Remote main = HEAD.
- Tags seen:
  - v8.0.0-rc17 → 03fd367 (tag object 58e2945), locally and on origin.
  - v8.0.0-rc16 → 66e67b3.
  - rc1 to rc15 present.
  - backup-rc17-pre-merge = 66e67b3, local only; no backup tag on origin.
  - No v8.0.0 locally or on origin.
- One slip: a diff copy went to /tmp/x by mistake and I deleted it at once. Nothing was written to the repository.
- 76 tool calls.
