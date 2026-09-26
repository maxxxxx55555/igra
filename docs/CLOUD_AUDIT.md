# Cloud cross-audit: v8.0.0-rc13 (`ce782f8`)

Read-only static audit from a cloud session, 2026-09-26. No Godot, no code edits; this file is the only change.

- **Candidate:** `origin/main` = `ce782f8`, tagged `v8.0.0-rc13` (the latest rc). `v8.0.0-rc12` = `b8abb2e`, so rc13 is one commit on top of it (the round-12 fixes). Everything below is checked at `ce782f8`.
- **Workdir:** the session's fresh clone of `origin`, unshallowed (`git fetch --unshallow`, 677 commits). On the initial 50-commit shallow clone, 37 of the 47 ARENA hashes looked "missing". All 47 resolve after unshallowing.
- **Absent inputs:** `docs/STAGNATION_ANALYSIS.md` and `docs/PERF_PASS.md` do not exist on any branch (`git log --all` is empty for both). Perf figures were taken from ORDER_PASS_REPORT, TZ_COMPLIANCE P01, CORRECTION_LOG #13/#38 and FUNCTION_MATRIX X24.
- **Rubric:** FAKE = claim false. PARTIAL = claim true only in part, or its own evidence or rules contradict it. CONFIRMED = holds at HEAD. Nit = stale or loose wording that does not change the claim (not counted).

---

## LOOP STATUS: LOOP

| Count | Value |
|---|---|
| Rounds total | 12 committed (r1 on rc1 `27ba1d5` … r12 on rc12 `b8abb2e`), 2026-09-25 09:10 → 2026-09-26 13:51. Round 13 is the NEXT-ROW (`docs/RUN_STATE.md:5`) |
| PARTIAL/FAKE rows, all rounds | 95 (92 PARTIAL, 3 FAKE). Per round: 10, 6, 14, 12, 4, 10, 3, 3, 4, 3, 15, 11 |
| Unique finding IDs (source + item) | 93 across 24 topics |
| Items stuck in loop (PARTIAL/FAKE in ≥ 2 consecutive rounds) | **9 topics** (below). Exact-ID repeats: 2 (`MATRIX / Status legend` r9→r10, `Fix / 5cf3b27 guard around QA runs` r10→r11), plus 1 explicit re-find (r12: "Round 11 flagged exactly this", the DR-1 label at `ORDER_PASS_REPORT.md:49`) |
| FAKE | 0 since round 2. No game-code defect found since round 3 |

| Topic | Rows | Rounds | Longest run | Live at rc13? |
|---|---|---|---|---|
| Report drift (ORDER_PASS rows, counts, candidate line) | 17 | 2, 3, 4, 5, 6, 8, 12 | 5 | **yes** (H2, H3, PARTIAL 4, nits) |
| Profile guard (user_data_guard → in-process snapshot → refusals → wrapper → QaLaunchGuard) | 16 | 4, 5, 6, 7, 10, 11, 12 | 4 | **yes** (PARTIAL 1) |
| DR labels + V05-mobile | 12 | 3, 9, 10, 11, 12 | 4 | **yes** (PARTIAL 3) |
| Flashlight upgrades (G12b, respawn, Stability, drain) | 6 | 1, 2, 3, 4 | 4 | no |
| C06 tier fog at load | 6 | 2, 3, 4, 12 | 3 | no (fixed in code; the run itself can't be checked here) |
| FUNCTION_MATRIX legend and rows | 6 | 1, 2, 9, 10, 11 | 3 | no |
| S03 evidence wording | 5 | 1, 5, 6, 7, 11 | 3 | nit only |
| TZ citations and counts | 6 | 1, 4, 8, 9, 12 | 2 | no |
| ARENA B7 defer and open-defers list | 2 | 6, 7 | 2 | no |

Why this is a loop and not progress: the game-side findings converged by round 3. Since round 4, every fix commit has added new QA-guard code or new report rows, and the next round audits that new surface. The PARTIAL count bottoms out at 3–4 on docs-only rounds and jumps back to 15 and 11 as soon as new tooling lands (r11, r12). The exit rule "loop until FAKE=0 PARTIAL=0" (`RUN_STATE.md:5`) was never met in 12 rounds. The three biggest topics (45 of the 95 rows) each still have a live instance at rc13, so round 13 cannot come back 0/0. The loop is not STALLED: its last round was today.

## FAKE items (0)

None. Every ARENA closure, all 10 sampled MET rows, and every re-runnable number hold at HEAD.

## PARTIAL items (4)

1. **QaLaunchGuard, round-12 sub-item (5) still open.** `scripts/core/qa_launch_guard.gd:46-50`: when the startup restore fails on a normal (non-QA) launch, `_block(false, …)` only warns (`:68-70`) and the game runs and saves on a half-restored profile. The copy is kept, so the next launch's retry runs `restore()` (`:131`), which deletes unlisted files (`:144`) and writes the old copy over everything saved in that session. The r12 verifier listed this as item (5) (`docs/CLOSURE_VERIFICATION_INTERNAL.md:102`). `ce782f8` fixes items (1)–(4) only, and CORRECTION_LOG #40 (`docs/CORRECTION_LOG.md:48`) does not mention (5). This only affects the dev machine: release builds exclude `tools/` scenes (`export_presets.cfg:3`), so a release build never creates a copy. But the dev machine holds the owner's real profile.
2. **R-08 is deferred as "inherent", but its own spec says part of it can be fixed.** `docs/ARENA_CLOSURE.md:49` and `:100` call R-08 an inherent client limit. `docs/SECURITY_PATCH_SPEC.md:372-373` says **"Partly yes"** for same-session elapsed time: use a monotonic tick clock, cap the per-frame delta, and flag rollback or forward jumps. Neither is implemented (`scripts/systems/daily_challenge_manager.gd:90` uses only `Time.get_unix_time_from_system()`), and the item is not recorded as a scoped defer the way R-02 is. The cross-launch half is inherent; the same-session half is not.
3. **G08 range and energy are labelled NEEDS-EYES, which bypasses the DR rules.** The GDD specifies 8 m and energy 2.0 (`docs/GDD.md:76-77`); the scene ships 16 m and 24 (`scenes/player/player_3d.tscn:184`, `:180`). The legend defines NEEDS-EYES as "subjective look or feel only" (`docs/TZ_COMPLIANCE.md:14`). Yet `docs/TZ_DECISIONS.md:25` itself calls halving the range "a real gameplay/visibility change", with no measurement behind it. `docs/EXEC_PLAN.md:70` (DR-4) covers exactly this case: a TZ number the code contradicts, with no DR-1..3 reason → apply the GDD value and run the IRON RULE bot. It is the same class of finding that r10–r11 made Local fix for V05-mobile, D03 and E05. The energy value could honestly be DR-2 (renderer units), but it is not recorded that way. Row: `docs/TZ_COMPLIANCE.md:44`.
4. **The honest-residual table leaves out the unmeasured rows.** `docs/ORDER_PASS_REPORT.md:75-93` matches every ARENA open defer (`ARENA_CLOSURE.md:100-102`) and every TZ GAP-OWNER row: V03, G22, G28/D04, N01 and I02 directly, and T01 through the AAB and Play Console rows. It has no row for P02 (particles < 500, RAM/VRAM; NEEDS-MEASUREMENT, `TZ_COMPLIANCE.md:75`), the V05 on-device mobile cost that row points to (`:34`), or the G08 NEEDS-EYES half (`:44`).

## CONFIRMED items: 95

| Area | Confirmed | Notes |
|---|---|---|
| ARENA_CLOSURE: 57 table rows + 4 summary claims | 60 | R-08 is PARTIAL 2 |
| TZ_COMPLIANCE: 10 sampled MET rows | 10 | |
| Static gates matching a documented claim | 8 | |
| Round-12 PARTIAL rows closed at HEAD | 10 of 11 | The guard-safety row is PARTIAL 1 |
| ORDER_PASS honesty checks | 7 | |

### 1. ARENA_CLOSURE

**Hashes.** All 47 cited hashes exist and are ancestors of HEAD. For each hash I counted how many of its added non-doc code lines (at least 4 characters, not comments) are still present verbatim at HEAD (scratch script, not committed). 40 hashes are at 100%. Every miss is a later rewrite that keeps the fix:

| Commit | Lines at HEAD | What changed |
|---|---|---|
| `fe7ef0e` | 68/71 | NG+ test writes moved to `attack_sim.gd:200` |
| `a36ac8b` | 55/57 | P2m check rewritten (`_qa_headless_suite_runner.gd:571`) |
| `8c99689` | 40/42 | P2p check rewritten (`:660-685`) |
| `fe3007a` | 20/22 | Phase-8 check now goes through UIManager (`_game_test_3d.gd:256`) |
| `5257745` | 117/118 | Hand-written HSV replaced by PIL's (`363add0`, SLOP 13) |
| `24ceb68` | 36/39 | Literal 25 became `BATTERY_PER_SKILL_LVL` (`player_3d.gd:1182-1186`) |
| `8f48faf` | 32/35 | Flat reward replaced by the GDD curve (`balance_sim.py:285-290`) |
| `21c6563`, `c2dbeb4`, `4e7560e` | i18n misses | Trailing comma added, or a later native-quality value; `new_game_plus_ui.gd:55` extended `at_cap` |

`24116c4` (48/97) is the retracted R0 "fix" (CORRECTION_LOG #1), not a closure.

**Deferral reasons that hold:**
- B7 legacy half: `achievements_manager.gd:206-217`, locked by `attack_sim.gd:33, :89`.
- P-05 clock part: `SECURITY_PATCH_SPEC.md:179-182`.
- R-02: `integrity_guard.gd:83` covers non-finite position and y ≤ −50 only.
- D-01 and D-02: inherent to a client-only game.
- D-03: `release_export_check.py:37-39` fails on a committed key.
- CHALLENGE-02: X21 is still BUG in FUNCTION_MATRIX.
- RENDERING_DIAGNOSIS (d): tier effects live in `assets/config/visual_quality.tres:9-12`.
- MISSED-00..05: AL35, AL50, AL55 and AL57 are WORKS (smoke), IN89 is WORKS.

R-08 does not hold (PARTIAL 2).

**Summary claims that hold:** 17/17 closed, 15/15 + §2 closed, the open-defers list is complete, and no P0 is deferred. R0 is the only P0 and it is closed. The single "P0" in the arena's `REDTEAM_CHALLENGE.md:66` is a cross-reference to another doc.

### 2. TZ_COMPLIANCE sample

There are 16 MET rows. The sample is `random.seed("ce782f8"); random.sample(met, 10)`.

| ID | GDD | Code at HEAD | Result |
|---|---|---|---|
| A02 | `:359` crossfade 2 s | `music_manager.gd:118` `FADE_TIME 2.0`, used at `:209`, `:262-263` | ✓ |
| C04 | `:379` Crawler → «слепые собаки» | `hud_3d.gd:653-657` swaps the name via `_display_monster_id`; the key is in all 13 locales | ✓ (nit N4) |
| D03 | `:108`, `:110`, `:111` | `world_env_setup.gd:17-27` has 0.03/0.12, 0.11/0.25, 0.16/0.40 | ✓ |
| G02 | `:45` head-bob 0.1 | `camera_follow_3d.gd:22`, `:83-84` | ✓ |
| G03 | `:46` FOV 80, +5 on sprint | `main_3d.tscn:57`; `camera_follow_3d.gd:24`, `:91` | ✓ |
| G08 (MET half) | `:76` 45°, `#c9a24a` | `player_3d.tscn:179` (0.788, 0.635, 0.29) = `#c9a24a`, `:182` 45° | ✓ (other half is PARTIAL 3) |
| G34 | `:350` docs + audio + photos + bunker | `endings_manager.gd:117`; `progress_tracker.gd:118-122` treats audio and photos as part of all documents, which the row discloses. Photos are a LORE item type (`GDD.md:466`). 22 audio logs and 24 photos exist, and all 46 ids are in `district_loot.gd` | ✓ |
| S03 | `:213` ember edge pulse | `post_process_overlay.gd:141` keeps `COLOR.rgb`, ember edge at `:35`, probe check `_tz_verify_runner.gd:132` | ✓ (nit N3) |
| V02 | `:280` no `#000`/`#fff`, no neon | Brass hit flash with restore, `base_monster.gd:663-683`; boss light `#c9a24a`, `boss_3d.gd:293`. The only white albedos are rain and dust (`vfx_*.tscn:21`), where they are multipliers over a vertex colour (`:15`, `:20`) | ✓ |
| V05 | `:317` moon shadow 2048², on | `project.godot:297` = 2048 with no `.mobile` key; `main_3d.tscn:47` `shadow_enabled` | ✓ |

### 3. Static gates

Python and bash only. The container needed `pip install pillow numpy`; nothing in the repo changed.

| Gate | Result | Matches the docs? |
|---|---|---|
| `i18n_truth_gate.py` | rc 0, "12/12 locales PASS". The gate checks the 12 translations against `en`, which is the reference and not itself tested. Separately, 13/13 locale files have 1301 keys each | ✓ ORDER_PASS:15, TZ I02 |
| `balance_sim.py` | rc 0, PASS. Districts 11 × 200..1200 = 7700; battery budget 12.8 min against a 12.6 min need | ✓ TZ E05, G10; ORDER_PASS:27 |
| `hardcoded_text_gate.py` (+ `--demo`) | 0 hits, rc 0; demo OK | ✓ |
| `user_data_guard.sh --demo` | demo OK, rc 0, no `tls_udg*` left in temp | ✓ |
| `TLS_SKIP_REIMPORT=1 check.sh --static` | "Всё зелёное", 24 passed, tree clean | ✓ "static 24" |
| `visual_truth_gate.py`, 14 tzverify frames + known-bad frame | 12/14 PASS (0.14–0.46%). G03 0.79% = 0.51% hue-band (98.1% of it at the frame edge) + 0.29% saturation outliers. S03 1.02%, 87.9% at the edge. V02 0.37% (hue-only 0.008%). D03 0.24 / 0.31 / 0.46%. Known-bad 13.19% | ✓ ORDER_PASS:32, :68; ARENA:62 |
| `endings_sim.py` / `drawcall_estimate.py` | PASS, all 5 endings reachable / PASS | ✓ |

`flow_check` and `scene_node_check` are also clean.

### 4. Round-12 PARTIALs re-checked at rc13

Closed:
- D03 citation: `TZ_COMPLIANCE.md:36`, `world_env_setup.gd:17`, `_tz_verify_runner.gd:155`.
- The fog-at-load probe now loads on the High tier (`ce782f8` diff).
- Autopilot is now matched: any `.tscn`/`.gd` under `tools/`, `qa_launch_guard.gd:75-81`.
- A real lifecycle end-to-end gate exists: `check.sh:329-347` runs with `env -u TLS_UDG_GUARDED` and covers write, die, guarded keep, recovery, profile hash and damaged-copy abort.
- CORRECTION_LOG #8 is corrected by #40.
- ORDER_PASS rows fixed: C4 (`:11`), battery (`:23`, `:28`, `:33`), visual (`:32`), round-10 label (`:49`), round-11 scope (`:50`).

Open: guard sub-item (5), PARTIAL 1.

### 5. ORDER_PASS_REPORT honesty

Confirmed:
- All 19 cited frames exist (9 in ORDER_PASS, 10 in TZ_COMPLIANCE).
- The round figures for r1–r12 equal each committed CLOSURE_VERIFICATION_INTERNAL totals line (79/7/3 … 132/11/0).
- Tags rc1–rc13 point to the cited hashes.
- The 40 corrections and their per-round split are right.
- The check counts add up: 21 `run_gate` calls at both rc12 and rc13, so 24 + 1 + 19 + 1 = 45 at rc12, and one more for the lifecycle gate = 46 at rc13.
- Perf (246/253), bot (rc12 2/3) and coins (8718–8975) are consistent across ORDER_PASS, TZ_COMPLIANCE, TZ_DECISIONS, CORRECTION_LOG and FUNCTION_MATRIX X24.
- The residual list matches the ARENA open defers and the GAP-OWNER rows (apart from the omission in PARTIAL 4).

**Can't be verified from the cloud:** check.sh full 46, GOLD MASTER `fails=0` ×3, tz_verify 19 `fails=0`, bot 2/3, D1 draw calls 246/253, audio dB, and the lifecycle mutation results. All of these need Godot, and `.qa_logs/` is gitignored with 0 files committed. The report does say its logs are local only (`:4`).

## HONESTY VIOLATIONS (3)

- **H1. The rc13 tag says "C8 round-12 partials closed", and `RUN_STATE.md:12-14` reads the same way.** Round 12's guard row had five sub-items (`CLOSURE_VERIFICATION_INTERNAL.md:102`). `ce782f8` closes four, and CORRECTION_LOG #40 (`:48`) lists only those four, so (5) was dropped without a record (PARTIAL 1).
- **H2. "Tools and docs only" (`ORDER_PASS_REPORT.md:51`, and the `ce782f8` message).** The commit rewrites 116 lines of `scripts/core/qa_launch_guard.gd`. That file is the first autoload (`project.godot:56`), it ships (`export_presets.cfg:3` excludes only `scenes/tools` and `scripts/tools`), and it runs on every launch. A QA guard doesn't need the IRON RULE bot, but "tools and docs only" hides a change to shipped code.
- **H3. The report header says "Every number below was produced by a run in this pass" (`ORDER_PASS_REPORT.md:4`), but "GUI exploration 19 PASS, 0 BUG, all 13 locales" (`:31`) is older.** It is Session 6's result (`RUN_STATE.md:1566-1574`, commit `75720e4`, 2026-09-22), which predates the pass base `c73cf7c` (2026-09-24). Sessions 10–12 contain no GUI-exploration run, and the locale files have changed since (`43c9ecd`, `21c6563`, `ad051fc`).

Nits (not counted):
- **N1.** "13/13 with en" (`:15`): the gate prints 12/12. The substance holds (13 files × 1301 keys).
- **N2.** The battery table says Music −19.3 dB (`:29`, from `27ba1d5`), but the round-10 row reports −20.3 dB from the rc11 run (`:49`).
- **N3.** The TZ S03 row (`TZ_COMPLIANCE.md:65`) quotes the rc2 run's edge warmth, 0.066. The committed rc12 frame reads −0.015 → 0.168 using the probe's own metric. The figure understates the result; the claim holds.
- **N4.** ru "Слепые псы" vs the GDD's «слепые собаки»: a synonym. en "Blind Dogs" matches exactly.
- **N5.** The TZ-verify battery row (`:28`) stops at rc12, while the `ce782f8` message reports an rc13 run (19 checks, `fails=0`).

## RECOMMENDATION

Fix these 7 first (the 4 PARTIALs and H1–H3: one code change in the failed-restore path of `qa_launch_guard.gd`, six doc edits). Then end C8 with one final round scoped to game code and shipped autoloads, and sign off, instead of looping on QA tooling and report wording.
