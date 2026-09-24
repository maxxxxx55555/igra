# EXEC_PLAN — C4 → C9 (studio-lead pass, post-compaction)

Written 2026-09-24 at HEAD `c73cf7c` (C3 close-out, pushed and verified). Plan only. Nothing in
this file has been executed.

## 0. Ground truth at plan time

| Item | State | Source |
|---|---|---|
| C1 BREAK-CLOSE | DONE. B1–B16 + Q1 closed. | `docs/RUN_STATE.md` (Session 9) |
| C2 SEC-CLOSE | DONE. Closable items closed. R-02, R-05/C-06, P-08 and D-01/02/03 are honest defers. | `docs/RUN_STATE.md`, `docs/SECURITY_THREAT_MODEL.md` |
| C3 SLOP-CLEAN | DONE. 15 items plus the §2 threshold. | `docs/RUN_STATE.md` top section |
| R0 magenta, R1 void-A/B, arena merges | SETTLED. Do not re-open. | `docs/RUN_STATE.md` |
| TZ | `docs/GDD.md`, canon v4, 844 lines. | `docs/TZ_COMPLIANCE_AUDIT.md:5` |
| TZ audit | Summary-table totals: 20 MET, 49 GAP-DEV, 5 GAP-OWNER (G28, D04, N01, I02, T01), 3 BY-DESIGN. | `docs/TZ_COMPLIANCE_AUDIT.md:23-36` |
| `docs/TZ_DECISIONS.md` | **Does not exist.** Created in C4. | `ls` |
| `docs/CORRECTION_LOG.md` | **Does not exist.** Created in C4 (first entry), filled in C7. | `ls` |
| `docs/ARENA_CLOSURE.md` | **Does not exist.** Created in C7. | `ls` |
| `docs/DESIGN_DECISIONS.md`, `docs/I18N_VOICE_FIXES.md`, `docs/CLOSURE_VERIFICATION.md` | **Do not exist.** Re-check at the start of each phase that consumes them. | `ls` |
| DECISION-RULE | **No definition exists anywhere in the repo.** `rg -i "decision.rule"` returns 0 hits. §2 defines it here. CLAUDE.md is the authority for doing so: "Decide design questions yourself and justify in docs." | grep |
| FUNCTION_MATRIX | 113 rows. A recount of the last column gives 61 WORKS, 40 UNTESTED, 5 BUG, 2 FIXED, 2 PARTIAL, 2 CANNOT-TEST, 1 BY-DESIGN. The footer says 58 WORKS and 43 UNTESTED, so the footer is stale. That is the first C5 fix and a CORRECTION_LOG entry. | `docs/FUNCTION_MATRIX.md` |
| Static gates | 20/21. The only FAIL is `i18n_truth_gate`, at 4/12 locales. | `docs/RUN_STATE.md:89-91` |
| Bot baseline | 3 seeds. Seeds 1 and 2 have each won on different runs. A boss-phase softlock is pre-existing and intermittent. | `docs/RUN_STATE.md:150-151, :692` |

## 1. Standing commands (every phase)

```bash
G="/c/Users/Maxsim/Desktop/TLS_Build/godot_extracted/Godot_v4.7-stable_win64_console.exe"
# static battery, after EVERY change (use python, not python3 - launcher broken here)
bash tools/check.sh --static
python tools/flow_check.py
python tools/scene_node_check.py
# engine gates (120 s each)
timeout 120 "$G" --headless --path . res://scenes/tools/compile_gate_scene.tscn
timeout 120 "$G" --headless --path . res://scenes/tools/attack_sim_scene.tscn          # DONE fails=0
QA_SOAK_SEC=20 timeout 120 "$G" --headless --path . res://scenes/tools/qa_headless_suite_scene.tscn  # 124 + no FAIL lines = clean
timeout 120 "$G" --headless --path . res://scenes/tools/craft_check_scene.tscn
timeout 170 "$G" --headless --path . res://scenes/tools/game_test_3d_scene.tscn        # phase 8 = X22, known
# IRON RULE (behavior/balance). Run in background; 3 x <=1200 s
QA_SEEDS="1 2 3" bash tools/qa_sim/autoplay_bot        # need >=1 WIN, no new softlock signature
# full re-baseline (C5 X21 only): 10 seeds, 900 s per seed
# sims
python tools/qa_sim/balance_sim.py ; python tools/qa_sim/endings_sim.py ; python tools/qa_sim/puzzle_economy_sim.py
python tools/qa_sim/i18n_truth_gate.py
# windowed only (not headless). Readback is REBACK_UNVERIFIED
timeout 120 "$G" --path . --rendering-method gl_compatibility res://scenes/tools/capture_stills_scene.tscn
python tools/qa_sim/visual_truth_gate.py docs/stills/<frame>.png
timeout 60  "$G" --path . --rendering-method gl_compatibility res://scenes/tools/audio_truth_gate_scene.tscn
timeout 120 "$G" --path . res://scenes/tools/perf_check_scene.tscn
```

**After every Godot run, revert the run artifacts. Never commit them:**
`git checkout -- docs/artifacts/content-depth/i18n_only_texts.md default_bus_layout.tres docs/stills/gui/results.txt` and the `*.import` noise. The one exception is A01, which edits `default_bus_layout.tres` on purpose and commits only that deliberate diff.

**PUSH PROTOCOL.** Push every 2–3 commits. After each push, `git rev-parse main` must equal field 1 of `git ls-remote origin main`. On a TLS error, retry once.

**RUN_STATE.** After every commit, prepend a section to `docs/RUN_STATE.md`. Report each phase in one line: `PHASE N DONE: <hash> <gate-summary>`.

**A/B discipline for every fix that has a test.** Run `git stash push -- <file>`, then the test, which must FAIL. Then run `git checkout -- <file> && git stash pop`, then the test, which must PASS.

## 2. DECISION-RULE (DR). Applied to every ambiguous TZ row

Apply the rules in this order. The first one that fits decides the row.

| DR | Criterion | Outcome |
|---|---|---|
| **DR-1 REJECTED-LIST** | The TZ value would require a change on the directive's REJECTED list: PICKUP_TOUCH tightening, or a NavigationAgent3D nav change. | No code. Record it in `TZ_DECISIONS.md`. Verdict BY-DESIGN (rejected-list). |
| **DR-2 TZ-CONFLICT** | Two GDD sentences conflict, or the TZ leaves a case undefined. | The more specific or later sentence wins (`GDD.md:3-6`: the file wins over its appendices). An undefined case keeps the current behavior. Record it. Verdict BY-DESIGN. |
| **DR-3 RECORDED-REJECTION** | The code or KNOWN_ISSUES records a *measured* reason the TZ value was rejected (a frame, a bot run, a metric). Opinion does not count. | Keep the code. Record the evidence path in `TZ_DECISIONS.md`. Verdict BY-DESIGN (dev decision, owner may overturn). |
| **DR-4 VERBATIM** | The TZ gives a number or behavior, the code contradicts it, and none of DR-1..3 applies. | Change the code to the GDD value verbatim. Behavior or balance → IRON RULE. Fails IRON RULE after one retune attempt → revert, then DR-3 with the bot log as the evidence. |
| **DR-5 SCOPE-CEILING** | Needs new content that does not exist in-tree: models, 200 photo spots, new creature scenes, new badge art, samples. | Implement the data/wiring part that existing assets support. The rest is an honest residual with the exact missing asset. It is not counted MET. |
| **DR-6 OWNER-ONLY** | Needs a physical or account action: keystore, device, Play Console, music composition, or a TZ text amendment. | Record it in the §9 residual with the exact owner action. Verdict GAP-OWNER. |
| **DR-7 STALE-CLAIM** | Re-reading the code contradicts the audit's own evidence. | Re-score from the live file:line. Log it in `CORRECTION_LOG.md` as an audit correction. |

## 3. C4 TZ-CLOSE

**Outputs:**
- `docs/TZ_COMPLIANCE.md`: the live ledger. Columns: ID | quote + `GDD.md:line` | status | evidence | verdict | commit | DR.
- `docs/TZ_DECISIONS.md`: every DR-1/2/3/5/6 row, with its justification.
- `docs/TZ_COMPLIANCE_AUDIT.md` stays read-only as the source.

**Commit format:** `feat(tz): <IDs>` (or `fix(tz)`). Each commit cites its row IDs.

**Step 0.** Run a baseline 3-seed bot at `c73cf7c` in the background. Save the softlock signatures to `.qa_logs/baseline_*`. Every IRON RULE comparison afterwards diffs against these, so "no new softlock" is measurable.

### Group T0: no behavior change, no bot run. Static gates plus the named probe.

| ID | DR | Target | Change | Check |
|---|---|---|---|---|
| A02 | DR-4 | `scripts/systems/music_manager.gd:118` | `FADE_TIME = 2.0` | static |
| V02 | DR-4 | `scripts/enemies/boss_3d.gd:283`, `scripts/systems/wow_director.gd:19` | Boss emission becomes the ember token `#b4452f`, not neon. The explosion colour becomes the palette colour at alpha 0, not `Color.WHITE`. | static + windowed boss frame `visual_truth_gate` |
| V03 | DR-4 if `BebasNeue-Bold.ttf` is in-tree, otherwise DR-6 (a font download needs owner OK) | `assets/ui/theme_tls.tres` | Wire the Bold file. | `theme_unify_probe_scene` |
| V05 | DR-4 | `project.godot:306` | Shadow atlas 2048. Keep the `.mobile` override at 1024 (GDD:316 mobile clause). | `perf_check` (windowed) |
| G02 | DR-4 | `scripts/core/camera_follow_3d.gd` | Head-bob while RUN, amplitude 0.1. Gated by `reduce_ui_motion`. | `a11y_probe_scene` + one new suite assert |
| G03 | DR-4 | same file | Sprint FOV +5°, lerped. Composes additively with the `wow_director.gd:81-86` offsets. | suite assert |
| S03 | DR-4 | `scripts/ui/hud_3d.gd:85` | Drive the ember vignette pulse from the noise level (`NoisePropagation`), not a number. Gated by `reduce_flash`. | `a11y_probe_scene` |
| C03 | DR-4 | `scripts/weapons/*` fire path | When `auto_aim` is on, bias the aim toward the nearest enemy inside a small cone. Off by default. | new `a11y_probe` case |
| C04 | DR-4 | `scripts/core/settings_manager.gd:416-427` + encyclopedia name lookup | Swap the Crawler name key to "blind dogs". **New key in 13 locales.** | `i18n_check_scene` + `a11y_probe` |
| C06 | DR-4 | `scripts/core/settings_manager.gd:262-267` | Add `fog_mult` and `particle_ratio` (0.5 / 0.75 / 1.0 / 1.5) per preset. Apply via `GPUParticles3D.amount_ratio` and the fog density. | `settings_persist_probe_scene` |
| G17 | DR-4 | death path (`scripts/core/game_manager.gd`) | If hardcore is on, delete the main save and slots via `SaveSystem`. | suite phase P2q on scratch slot 94 |
| E03/T02 | DR-4 | `scripts/monetization/ad_service.gd:23,27` | `COOLDOWN_SEC = 3600`. Add a Skip action: −100 coins, clamped at 0 through the `CoinWallet` validator. Confirm the PC simulation provider path exists; if it does not, add it behind the same API. **Skip label in 13 locales.** | suite assert + `attack_sim` (wallet cannot go negative) |
| G01 | DR-2 | none | FPS is the default via `fps_mode=true`. The `player_fps.tscn` filename is an implementation detail. TPS is optional (`GDD:17` says «опция»). | record only |
| G04 | **DR-1** (read `scripts/player/interactor.gd` first) | none | If interaction is proximity-based, a 3 m camera ray would narrow pickup, which is PICKUP_TOUCH tightening (REJECTED). If it is already a ray, set it to 3 m (DR-4 + bot). | record, or one-liner |
| D02 | **DR-2** | none | Verified at plan time: every `powered_by` parent comes earlier in the D01 order (suburbs→park/residential, park→police/gas, residential→school/hospital, hospital→warehouses, warehouses+police→industrial→substation→power_station). The TZ never states a linear chain. | record |
| D03/V01 | **DR-3** | none | `scripts/world_env_setup.gd:5-8` records that 0.01/0.03 black was rejected as unplayable. R0 evidence frames exist. Latent-daytime half: one DR-4 guard in `scripts/systems/day_night.gd` so it can never lerp above the night values, plus a suite assert. | record + guard |
| A04 | **DR-2 / DR-7** | none | `assets/audio/ambience/` holds `ambient_dark/lit`, `threat_high` and `action_sting` loops, which GDD:359-362 names as **music** layers. Re-measure with `du` by role, not by folder. If music ≤100M and SFX ≤50M, the row is MET. | `du` table in the ledger |
| A03 | **DR-7 first** | `scenes/tools/footstep_check_scene.tscn` exists ("footstep mapper surface × speed") | Re-audit the audit's "no surface match" claim. Fill any missing surface/sample slots via `gen_sfx_scene` (SFX, not music). A missing downward-ray surface id is DR-4. | `footstep_check_scene` |
| P01/P02 | DR-7 then DR-4 | `tools/qa_sim/drawcall_estimate.py` (X24 already WORKS) | Add static particle-sum (<500) and poly/light (<50K / <8) asserts to the same script. RAM/VRAM → CANNOT-TEST-HEADLESS residual. | `--demo` + static |

### Groups T1–T6: behavior or balance. One IRON RULE bot run per group. If a group fails, bisect it.

| Grp | IDs | DR | Target files | Change |
|---|---|---|---|---|
| **T1 battery** | G09, G10, G12b | DR-4 | `scripts/player/player_3d.gd:96`, `data/items/battery.tres`, `data/balance/flashlight_stats.tres`, stability branch in `scripts/systems/flashlight_upgrade_manager.gd` | Drain 0.5%/s (1% per 2 s). Delete the unused duplicate `drain_per_sec`: one source. Battery item +25. Flicker threshold 20. `stability` L5 clears it. |
| **T2 movement** | G06, G07, G15-capsule | DR-4 | `data/balance/player_stats.tres`, `player_3d.gd:87-89,538`, `scenes/player/player_3d.tscn:8-9` | `run_speed = walk*1.6`. Wire the unread `CROUCH_NOISE_MULT` and `CROUCH_VISIBILITY_MULT`. Capsule 1.6. Crouch capsule 1.2 only with an uncrouch ceiling `ShapeCast3D`; without one, a stuck-under-ceiling softlock is possible. |
| **T3 combat/noise** | G13, G15-attackbox, S01 | DR-4 | `player_3d.gd:79-81,296`, noise emit sites | Damage 8/12/20. Attack box 0.6×0.4×1.2. Emit hit noise 5 m/1.0 and dodge noise 3 m/0.4 through `NoisePropagation`. Run `balance_sim.py` before the bot. |
| **T4 stealth** | S02, S04-search | DR-4. S04's bush/dark-corner spot types are DR-5. | `scripts/enemies/base_monster.gd` vision modifiers, search state | Cone +100%, dark 3 m, run +20% (wall 0% = existing LOS). After losing the player, search 10 s within 5 m. **Do not touch `hiding_spot.gd` structure** (CLAUDE.md lesson). "Monster vision vs visibility" is on the already-done list: adjust modifiers only. |
| **T5 flow** | G16, G24 | DR-4. If G24 fails the bot → DR-3. | `game_manager.gd:59-69` (reuse `world_runtime._place_player`), `scripts/district_manager.gd transition_to` | Respawn at the district entry, HP 50%, battery unchanged. After entering substation (D10), refuse transitions to D1–D9. One confirm prompt on entry. **Key in 13 locales.** |
| **T6 roster/boss** | G18, G19, G20 | DR-4 for stat rows of existing ids. **DR-2** for types the TZ itself lists as open milestones (`GDD.md:680-685`, Appendix V `[M1]-[M4]`). G19 Shadow: DR-5 if no shadow scene is in-tree (grep `shadow` in `scenes/enemies`). `progress_tracker.shadow_kills` already exists. | `scripts/enemies/enemy_roster_data.gd:13-17,73-79,119-120`, `boss_3d.gd:49` | Fix the alias/stat mismatches against the GDD:160-175 table. Boss phase-2 threshold 0.30. Summon Shadow ×3 only if G19 lands. **Stop-condition:** the boss-phase softlock rate must not rise above baseline. |

### Group T7 endings. `endings_sim.py` + `craft_check_scene`; bot only if the win path changes.

| ID | DR | Decision |
|---|---|---|
| G31 | **DR-2** | The TZ defines hope as <50% docs and light as all docs. 50–99% is undefined, so keep the current behavior (hope). Record it. |
| G32 | **DR-2** | "Only D11" alive is unreachable, because D02 requires substation→industrial→… FULL first. Keep the death-path reading. Record it. |
| G33 | **DR-2** | No alive-and-unrepaired terminal state exists outside death. Current behavior = TZ. Record it. |
| G34 | DR-4 where separate counters exist (`SaveSystem.get_photos()` exists, audio-log ids: grep `audio_log`). Bunker: DR-5 if there is no bunker node in `power_station`. | `scripts/systems/progress_tracker.gd:104-114` + `endings_manager.gd`. Split the aliased counters. |

### Group T8 content/UI. DR-5 heavy.

| ID | DR | Plan |
|---|---|---|
| G21 | DR-4 for recipes whose input and output item ids exist in `data/items/`. DR-5 for the rest (transformer / reinforced battery / L2 blueprint items, if absent). | `scripts/ui/workbench.gd:14-23`. Blueprint names in 13 locales. |
| G22 | Read the archive reason at `save_system.gd:427-428` first. A measured reason → DR-3. Otherwise DR-4: re-wire the archived slot UI via `Routes` and re-check `boot_check_scene`. **Cross-ref C2 P-06**: slot_id binding assumed no slot UI. Re-state that in `SECURITY_THREAT_MODEL.md`. | |
| G25 | DR-4 if weapon/grenade ids exist in `scripts/weapons/` and `data/items/`, else DR-5. | `scripts/ui/hud_3d.gd:7` `_SLOT_ITEMS` |
| G26 | DR-5. Count the in-tree photo spots. If fewer than 200, the 50/100/200 achievements would be unreachable, which is a bug, so do not add them. Record the count. | `achievements_manager.gd:67` |
| G27 | Re-read `GDD.md:50-60` first (verify the audit's quote), then DR-4. | `player_3d.gd:387` + `touch_probe_scene` |
| C04/E03/T5 keys | 13-locale keys added in the same commit as the code. | `i18n_check_scene` |

### GAP-OWNER rows

| ID | DR | Recorded default |
|---|---|---|
| G28/D04 | **DR-2** | §6.3/§12.3 (boss required, later and more specific) win over §4 GDD:119. Current code already routes through `FinaleDirector`. Owner may amend GDD:119. |
| N01 | **DR-6** | A status checkbox, not a rule. No carryover spec. Owner writes one, or accepts the current `content/ngp_modifiers.json`. |
| I02 | **DR-6** | "198 keys" is a stale census. Do not delete keys. Owner amends GDD:22 to 1291 (1290 after `BTN_ONE_MORE_RUN` was removed; recount at C4). |
| T01 | **DR-6** | Keystore, signed AAB, device test: owner-only. |

**TZ-VERIFY.** For each implemented row, capture one windowed frame with `capture_stills_scene` or `gui_explore_scene` and put the path in the ledger. Headless cannot do this. Where a windowed run is impossible, write `VERIFY: CANNOT-TEST-HEADLESS` on the row. Never mark it silently.

**C4 exit:** 0 GAP-DEV in `TZ_COMPLIANCE.md` (each row MET, BY-DESIGN, DR-5 residual, or GAP-OWNER). Every IRON RULE group has a logged bot result. Static 20/21, with only i18n allowed red.

## 4. C5 MATRIX SWEEP → 0 UNTESTED / 0 BUG

Target: `docs/FUNCTION_MATRIX.md`, `scripts/tools/_qa_headless_suite_runner.gd` (new phases P2q+). Commit per fix: `fix(<area>): <row>`.

1. **Recount first.** Fix the stale footer (58/43 → live count). Add a `CORRECTION_LOG` entry. Make `gen_function_matrix.py` print status counts so the footer can never drift again. That is one-line reuse, no new tool.
2. **UNTESTED AL rows (≈40).** Map each to an existing probe first: `autoload_api_check_scene`, the GOLD MASTER phases, `light_check_scene`, `music_probe_scene`, `ui_dump_scene`. Only if no probe exercises the row, add one assert to a new suite phase. A row becomes WORKS only when something *calls* it and asserts the result. Existence alone does not count.
3. **CANNOT-TEST-HEADLESS (honest):** AL06 LANNetwork, AL42 LANDiscovery, AL43 NetworkManager (need two peers; sender-binding half already recorded in C2). X09 (stealth, visual).
4. **Dead input mappings IN67 `shop_toggle`, IN84 `close_screen`, IN86 `settings`.** If `GDD.md` names the key → wire it (DR-4). If not → remove it from `project.godot [input]`, re-run `gen_function_matrix.py`, and confirm the spine count drops by the same number.
5. **X22 death screen when boot is bypassed.** Root-cause `screen_flow_manager.gd _screens` registration. Fix, then `game_test_3d_scene` must pass phase 8.
6. **X20 park inf-position.** Use the live `IntegrityGuard` logs across 10 seeds (background, 900 s each). Stop after 3 root-cause attempts, then an honest residual with the raw logs.
7. **X21 residential.** 10-seed re-baseline at 900 s. Record the honest win rate as a number, not "rarer".
8. **Bot ≥1/3 for sign-off.** Investigate *why* seeds lose (B3-era observation), separately from the boss softlock. Anything more than a log read → IRON RULE.

**C5 exit:** 0 UNTESTED, 0 BUG. PARTIAL rows carry a named residual.

## 5. C6 I18N-FINAL → `i18n_truth_gate` 12/12 non-base PASS (13/13 locales incl. `en` base)

1. `ls docs/I18N_VOICE_FIXES.md`. If it has landed, apply it first.
2. Reconcile arena `origin/arena/01a0c589-igra` `docs/I18N_DEFECTS.md` (159 value edits, **not on main**, per `RUN_STATE.md:1313-1319`). Run `git diff main origin/arena/01a0c589-igra -- data/i18n/`. Take *value* edits only, via a JSON-aware script (the same method as C3 item 12). No blind merge.
3. Apply the Keeper-voice list in `TZ_COMPLIANCE_AUDIT.md:175-192` (ja Keeper term unification, ru ты/вы, Latin-in-ru ACH_05/06/18, NGP_SETUP_ACTION ru/ja).
4. Burn down the overflow flags per locale (fr=52 is the worst) by shortening translations, **not** by loosening `LENGTH_RATIO_MAX`/`SHORT_STRING_RATIO_CAP`. Threshold fudging is a STOP condition.
5. Regression gate for hardcoded visible `Control.text`. Check whether `i18n_check_scene` already covers it; if not, add one scan to it.
6. Gates: `python tools/qa_sim/i18n_truth_gate.py` = 12/12 PASS, `i18n_check_scene`, `overflow_check.py`.

Commit: `fix(i18n): <locale>: <n> overflow/voice`.

## 6. C7 SIGN-OFF v8

1. **`docs/ARENA_CLOSURE.md`.** Every P0/P1 item from each report maps to a closed commit hash or an honest defer with a reason:
   - A = `docs/BREAK_REPORT.md`
   - B = `docs/SECURITY_PATCH_SPEC.md`
   - C = arena `01a0c589` `RENDERING_DIAGNOSIS.md` + `REDTEAM_CHALLENGE.md` + `I18N_DEFECTS.md` (read via `git show origin/arena/01a0c589-igra:docs/<f>`)
   - D = `docs/SLOP_REPORT.md`, plus `DESIGN_AUDIT_ARENA.md`, `INTERIM_BREAK.md`, `INTERIM_SLOP.md`

   No P0 is deferred without an owner-visible reason.
2. **`docs/CORRECTION_LOG.md`** (old claim | new fact | commit). Seed entries:
   - CLAUDE.md TRUTH WAVE `reset_all`
   - the stale "Not built yet" perf-guard note
   - RUN_STATE "a handful" → fr=52
   - R1 SSR edit on a zero-load-site `.tres` (void)
   - the `d06fe48` message mislabelling item 7 as 6
   - the FUNCTION_MATRIX footer
   - every DR-7 audit correction from C4

   Harvest the rest with `rg -n "was claimed|stale|VOID|contradict|corrected" docs/RUN_STATE.md`.
3. **Battery.**
   - static 12/12 (the target: i18n now green)
   - all engine gates
   - GOLD MASTER clean
   - `attack_sim` + `a11y_probe` + `_sec_probe` exit 0
   - windowed visual/audio truth gates PASS
   - `TZ_COMPLIANCE` 0 GAP-DEV
   - MATRIX 0 BUG / 0 UNTESTED
   - `balance_sim` PASS
   - bot ≥1/3
   - `gui_explore_scene` pass
4. **`docs/ORDER_PASS_REPORT.md`.** Per-phase deltas, ≥3 frame paths, truth-gate output verbatim, the CORRECTION_LOG, the residual.
5. Commit `chore: studio sign-off`. Run `git tag v8.0.0-rc1`, then `git push origin main v8.0.0-rc1`. Verify both refs with `ls-remote`. Update memory (`project_v7_release_state.md` → a v8 memory). **STOP.**

## 7. C8 VERIFIER LOOP

- **Precondition:** `docs/CLOSURE_VERIFICATION.md` exists. It is written by an external verifier, not by me. If it is absent, **STOP and report "awaiting verifier"**. Never self-author it.
- **Loop:** for each FAKE or PARTIAL item, apply the DR rules, fix, and re-verify with the item's own gate. Then add a CORRECTION_LOG entry, commit, re-tag `v8.0.0-rc2`, `rc3`, …, push, and verify.

## 8. C9 FINAL MESSAGE

Only after C8 has a verifier pass with 0 FAKE. Print the directive's exact block: RENDER / TZ / ARENA CLOSURE / TRUTH GATES / MATRIX / SLOP / CORRECTIONS / FRAMES / RESIDUAL / TAG ON ORIGIN. Every number is copied from a gate output in the same message. An "ALL GREEN" without that evidence is forbidden.

## 9. Stop-conditions (any one halts the current phase)

1. An IRON RULE group fails twice (after one retune): revert the same turn, then DR-3, then continue with the next group.
2. A truth gate is unpassable after 3 root-cause attempts: STOP with the raw numbers and the 3 causes. **No threshold loosening.**
3. A Godot timeout: kill it, log it, fix the harness before continuing (120 / 600 / 900 / 1200 s bot).
4. A push mismatch (`rev-parse` ≠ `ls-remote`): STOP and report.
5. A zone violation, if `docs/AGENT_ZONES.md` exists by then.
6. Any action on the owner-excluded list below: record it as a residual and never attempt it.
7. `CLOSURE_VERIFICATION.md` is absent at C8: STOP.
8. A new scope not traceable to TZ, a matrix row, an arena finding or a gate failure: record it as a QUESTION in RUN_STATE and do not build it.

## 10. Owner-excluded (never attempted; always listed in RESIDUAL)

| Item | Owner action |
|---|---|
| **Music**: composition, new music assets, the by-ear check of A05 «без мелодичных тем» | Listen or approve; supply tracks. |
| **Play Console button-presses**: upload, listing, content rating, release rollout | Owner, in Play Console. |
| Keystore, signed AAB, device test (T01) | Owner, locally. |
| AppLovin MAX real SDK key | `docs/store/HUMAN_CHECKLIST.md` |
| **Optional `gh`**: PR or GitHub Release creation | Optional. Tags push via plain `git`. `gh` is never required for sign-off. |
| TZ text amendments (G28/D04 GDD:119, I02 GDD:22, N01 NG+ spec) | Owner edits `GDD.md`, or accepts the `TZ_DECISIONS.md` default. |
| Font or asset downloads from outside the repo (V03 if Bold is not in-tree) | Owner supplies the file. |
| Windowed eye-check of saved frames (REBACK_UNVERIFIED) | Owner confirms a live frame matches the PNG. |

## 11. REJECTED (never retry)

- PICKUP_TOUCH tightening (this is also why G04 is DR-1).
- NavigationAgent3D nav change for bot movement.
