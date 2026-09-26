# Merge plan: `cloud/audit-ce782f8` → `main`

For Local. One branch, one merge. The branch starts at `ce782f8` (`v8.0.0-rc13`). On 2026-09-26
`main` was still `ce782f8`, so today the merge is conflict-free.

## 1. What the branch carries (oldest first)

| Commit | Kind | Files | What |
|---|---|---|---|
| `2452d2d` | docs | `docs/CLOUD_AUDIT.md` | Cross-audit of rc13 |
| `a6f4fdb` | **code** | `scripts/core/qa_launch_guard.gd`, `tools/check.sh`, `docs/FUNCTION_MATRIX.md` | Any launch over an unrestorable QA copy aborts, normal play included (round-12 guard item 5). Release exports skip the guard. New `qa_guard_e2e` case |
| `c2e9b86` | **code** | `scripts/systems/daily_challenge_manager.gd`, `scripts/security/attack_sim.gd` | R-08 same-session half: wall clock read once per launch, `<=` replay floor, frame deltas capped. New `attack_sim` check |
| `7f13092` | docs | `docs/TZ_COMPLIANCE.md`, `docs/TZ_DECISIONS.md`, `docs/ARENA_CLOSURE.md` | G08 NEEDS-MEASUREMENT, S03 0.168, G15 cite, R-08 split |
| `326fda1` | docs | `docs/ORDER_PASS_REPORT.md`, `docs/CORRECTION_LOG.md` | Numbers recomputed or tagged RECONFIRM-AT-SIGNOFF, GUI row dropped, residuals, CORRECTION_LOG 41–43 |
| `b8f965b` | docs | `docs/STAGNATION_ANALYSIS.md` | Loop analysis and anti-loop rule |
| `8d07b29` | docs | `docs/PERF_PASS.md` | Static perf numbers and re-measure list |
| `5ed64c7` | docs | `docs/SLOP_REPORT_V2.md` | Slop fix table (spec only) |
| `0cedacc` | docs | `docs/SECURITY_SWEEP_V2.md` | Security fix table (spec only) |
| `4e1e39e`, `b2db6ac` | docs | `docs/I18N_TABLE_V2.md` | 79 i18n rows (spec only) |
| `7985a85` | docs | `docs/RELEASE_RUNBOOK.md` | Owner Play Console runbook |
| *this commit* | docs | `docs/MERGE_PLAN.md`, `docs/CLOUD_AUDIT.md` | This plan, and audit status plus addendum |

## 2. How to merge

```bash
git fetch origin cloud/audit-ce782f8
git checkout main && git merge --no-ff origin/cloud/audit-ce782f8
```

**Merge; don't cherry-pick.** `docs/ARENA_CLOSURE.md` (R-08), `docs/CORRECTION_LOG.md` (41, 43),
`docs/ORDER_PASS_REPORT.md` and `docs/CLOUD_AUDIT.md` cite `a6f4fdb` and `c2e9b86` by hash. If you
must cherry-pick, replace those two hashes in the four files afterwards.

## 3. Conflict hotspots (only if `main` moves before the merge)

**Rule: prefer this branch for every hunk it touched, then re-apply Local's additions on top.**

| File | This branch did | Resolution |
|---|---|---|
| `scripts/core/qa_launch_guard.gd` | Release gate first in `_enter_tree`; `_block(why)` always aborts; no warn path for a damaged, live-pid or failed-restore copy | Keep this branch's function bodies. Re-apply any new Local logic inside them, keeping two invariants: release builds return at once, and every "copy can't be restored" branch calls `_block` |
| `scripts/systems/daily_challenge_manager.gd` | `_day`, `MAX_FRAME_DELTA`, `_roll_for_day()`, `<=`, `_complete()` stores `_day` | Take this branch. Any new caller of the old `_roll_for_today()` becomes `_roll_for_day(_today_index())` |
| `docs/ORDER_PASS_REPORT.md` | Header provenance line, battery rows (RECONFIRM tags), no GUI row, round-12 wording, cloud line under the C8 table, "43 entries", 4 residual rows | Take this branch, then append Local's new round rows after the cloud line and recount the corrections |
| `docs/CORRECTION_LOG.md` | Removed the blank line before #40; appended #41–#43 | If Local also appended, renumber this branch's rows after Local's last number, and update "41-43" in ORDER_PASS and CLOUD_AUDIT |
| `tools/check.sh` | One extra line in `qa_guard_e2e` | Keep it |
| `docs/TZ_COMPLIANCE.md`, `docs/TZ_DECISIONS.md`, `docs/ARENA_CLOSURE.md`, `docs/FUNCTION_MATRIX.md` | Rows G08, S03, the tz_verify line, G13/G15, R-08, open defers, AL59 | Take this branch's rows |
| `docs/RUN_STATE.md` | Not touched | Local writes the post-merge state (§6) |

## 4. Local MUST re-verify with Godot after the merge, in this order

1. `bash tools/check.sh` full, with the windowed reimport. Expect 46 green. The new `qa_guard_e2e`
   case "normal launch ran over an unrestorable copy" must pass; it fails on the old warn-only
   guard. `attack_sim` must print `OK daily: a clock set back after a claim does not reopen an
   earlier day`.
2. GOLD MASTER suite, three direct runs, `fails=0`.
3. `tools/qa_sim/tz_verify`: 19 checks, `fails=0`.
4. IRON RULE bot, 3 seeds. Sign-off floor ≥ 1/3 (EXEC_PLAN §8). Compare stall types against X21.
5. Windowed frames: re-capture tzverify and run `visual_truth_gate.py`. Then `perf_check` on D1
   **and** D11, and audio truth (`docs/PERF_PASS.md` §2).
6. Release path (`docs/RELEASE_RUNBOOK.md` §0–§2): enable ETC2/ASTC and reimport, set the AAB
   format, export the AAB, `jarsigner -verify`, fingerprint check, then read the size against the
   200 MB cap.
7. After the i18n rows: `i18n_truth_gate.py` 12/12, plus one `gui_explore_scene` run (the
   13-locale sweep has not been re-run since 2026-09-22).
8. On an export: the boot log shows no "Failed to instantiate an autoload" (after SLOP C1), and no
   ad offer appears when no AppLovin key is set (after SECURITY #2).

## 5. Tables to apply after the merge, in this order

1. **`docs/SECURITY_SWEEP_V2.md` #2** (debug ad stub). It gates every release build, so do it first.
2. **`docs/RELEASE_RUNBOOK.md` B1 and B2** (ETC2/ASTC import, AAB export format): editor steps;
   commit the `.import` and `export_presets.cfg` changes.
3. **`docs/I18N_TABLE_V2.md`**: apply the 79 JSON rows, check each OLD value first, keep file
   formatting, and gate 12/12.
4. **`docs/SLOP_REPORT_V2.md`**: sections in its own "Order to apply" (deletions, local refactors,
   multi-file, C1, S-table quarantine, D1).
5. **`docs/SECURITY_SWEEP_V2.md` #3** (quarantine the three LAN autoloads) together with the SLOP
   S-table quarantine. #4 goes in when `ach_18` is wired; #5 goes in with SLOP A3's
   `write_signed` helper.

## 6. After the merge: one final C8 round, then stop

Per `docs/STAGNATION_ANALYSIS.md` §5, write in `RUN_STATE.md`:

> NEXT-ROW: C8 final round on the merge commit. Frozen scope: game code and shipped autoloads
> changed since rc13, every GDD verdict once, data safety, security claims. Exit when FAKE = 0,
> PARTIAL-G = 0 and PARTIAL-S = 0. PARTIAL-D items are batch-fixed without a new round.

## 7. Owner decisions this branch surfaced

| Decision | Options | Where |
|---|---|---|
| Ads at launch | A: none (hide offers) / B: AppLovin MAX with consent | `docs/RELEASE_RUNBOOK.md` B3, §6, §8 |
| G08 flashlight range and energy | Measure, then DR-4 (8 m / 2.0) or DR-3 (keep 16 m / 24 with evidence) | `docs/TZ_DECISIONS.md` G08 |
| 10 achievements with no grant path (ach_06, 07, 08, 11, 12, 16, 17, 18, 19, 20) | Wire them, or hide them from the list | `docs/SECURITY_SWEEP_V2.md` #4 note; FUNCTION_MATRIX AL33 WORKS covers `get_all` only |
| LAN prototype | Quarantine the 3 autoloads, or finish LAN with the #3 fixes | `docs/SECURITY_SWEEP_V2.md` #3 |
| 13 UNCERTAIN scripts | Keep or quarantine each | `docs/SLOP_REPORT_V2.md` S-table |
| ko register, zh title term | 해라체 (as tabled) or -세요; 街灯 vs 路灯 | `docs/I18N_TABLE_V2.md`, `docs/RELEASE_RUNBOOK.md` §9 |
