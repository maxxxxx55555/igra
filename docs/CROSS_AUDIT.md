# Cross audit of the shipped claims (Session 23, S2)

A claim of a document is checked against the code at HEAD two ways: every citation of every document is re-read (section 1), and a sample of the numbers the game and its store
listing give are re-derived from the sources (section 2). A stale citation is a row here, never a silent edit.

## 1. Every citation of every document (`python tools/af5_check.py --all`)

1,605 citations (a `path:line` with a claim before it) in 36,150 lines of the documents at HEAD: **104 stale** after this pass (111 before). The rule of the gate: a cited
line must exist, and the identifier of the claim before it must still stand in the cited lines.

| Fixed in this pass (re-pointed, the code is unchanged) | Cause |
|---|---|
| `docs/PERF_PASS.md` rows 5, 12, 15, 19 and 20 (five citations) | `project.godot` lost its duplicated input actions (`83276c6`) and the renderer, shadow, MSAA and LOD settings moved up to lines 272 to 280; the particle ratio code of `settings_manager.gd` moved to 516 to 524 |
| `docs/KNOWN_ISSUES.md` (the renderer line) | the same move |
| `docs/QA_SWARM_FINDINGS.md` P2 | the same move |

| Left as written: dated reports of the code of their day | Stale citations |
|---|---|
| `docs/SLOP_REPORT_V2.md` | 28 |
| `docs/SECURITY_PATCH_SPEC.md` | 13 |
| `docs/TZ_COMPLIANCE_AUDIT.md` | 10 |
| `docs/SPINE_SOFTLOCK_AUDIT.md` | 10 |
| `docs/QA_MATRIX.md` | 7 |
| `docs/CLOSURE_VERIFICATION_INTERNAL.md` | 7 |
| `docs/SLOP_REPORT.md` | 6 |
| `docs/DESIGN_AUDIT_ARENA.md` | 6 |
| `docs/GAME_AUDIT.md`, `docs/EXEC_PLAN.md`, `docs/CLOUD_AUDIT.md` | 3 each |
| `docs/RUN_STATE.md` (one row of Session 17, one of Session 8) | 2 |
| `docs/STATIC_AUDIT.md`, `docs/SIZE_BUDGET.md`, `docs/SECURITY_SWEEP_V2.md`, `docs/ROAD_TO_POLISH.md`, `docs/BREAK_REPORT.md`, `docs/AUDIO_MIX_AUDIT.md` | 1 each |

Why they stay: each is an audit or a log written for a commit that it names (`Slop report v2: sweep at ce782f8`, `Audit date: 2026-09-21`); its citations describe that code and
are history, not a claim about HEAD, and rewriting them would falsify the record. The gate's default scope is the lines a pass adds (`python tools/af5_check.py`), and it reads 0
findings at the end of this pass; the full scan is informational and is the number above. A reader who needs the code of a dated report checks out its commit.

## 2. A sample of shipped numbers, re-derived at HEAD

| Claim | Where it is made | Derivation at HEAD | Result |
|---|---|---|---|
| 13 languages | `store/listing.md:132`, `docs/RELEASE_NOTES.md:15` | the files of `data/i18n`: ar, de, en, es, fr, it, ja, ko, pt_BR, ru, tr, zh, zh_TW | 13: holds |
| 11 districts | `store/listing.md:74` | `DISTRICTS` in `scripts/world/district_scene_factory.gd:4` | 11: holds |
| 31 achievements | `store/listing.md:62` | `python tools/qa_sim/achievements_sim.py` | 31, each with a trigger: holds |
| 60 daily challenges | `store/listing.md:62` | `content/daily_challenges.json`, `python tools/qa_sim/daily_sim.py` | 60 templates (CORRECTION_LOG 224 had fixed the 30): holds |
| 5 endings | `store/listing.md:56`, `docs/RELEASE_NOTES.md:13` | `python tools/qa_sim/endings_sim.py` | all 5 reachable: holds |
| 26 secrets | `tools/qa_sim/balance_sim.py` section 7 ("all secrets x reward: 26 x 50") | the ids of `content/secrets.json` | 26: holds |
| 12 monster records | `docs/FIRST_5_MINUTES.md` and `docs/DIFFICULTY_CURVE.md` read them | the files of `data/monsters` | 12 (ten of the rosters, the boss and the Tvar): holds |
| 203 photos | the album screen, check G26 | `[closeout] ok G26 the game can give 200 photos or more (203)` of launch 109 | 203: holds |
| 4 graphics tiers | the Settings screen | `GRAPHICS_TIERS` in `scripts/systems/settings_manager.gd:282` | 4 rows: holds |
| 7 onboarding cards | `docs/FIRST_5_MINUTES.md` | `PANELS` in `scripts/ui/onboarding_overlay.gd:9` | 7: holds |
| the signed bundle is 136,508,347 bytes | `docs/RELEASE_ARTIFACTS.md` | `stat build/tls.aab` | 136,508,347: holds **for the bundle of `v8.0.0-shipping`**; the code has changed since, so it is rebuilt at the ship step and the number replaced |
| D1 142 draw calls, p95 28.79 ms | `docs/PERF_PASS.md:51` | the windowed perf gate | measured at `v8.0.0-shipping`; **false at the final head**: launch 24 (`a4acbb5`, the quality manager off) reads D1 150 draw calls with a p95 of 35.00 ms and D11 140 with 38.63 ms against the budget of 33 ms: the windowed gate is RED (`docs/PERF_PASS.md:19`, section 0b) |

One claim of the sample is false at the final head: the D1 numbers (read again in launch 24, red: the row above). The other that is true of an older tree is the bundle's size, which the second export replaces.


## 3. Re-read at the head of Session 26 (`v9.0.0-universe`)

The claims of the sample that depend on code the pass touched, and the ones the pass's directive named, re-derived at `HEAD`. A claim that is false is a row, never a silent edit.

| Claim | Where it is made | Derivation at HEAD | Result |
|---|---|---|---|
| saves are HMAC-signed and recover from a backup | `store/press-kit.md:39`, `store/listing.md:61` | `_HMAC_KEY` and `hmac_digest` in `scripts/core/save_system.gd`; `python tools/qa_sim/save_migration_sim.py` (`s26_s2_savemig`): "SAVE_VERSION 3, BACKUP_DEPTH 3, 18 case(s) read, 0 finding(s)" | holds |
| 31 achievements, each with a trigger | `store/listing.md:62` | `python tools/qa_sim/achievements_sim.py`: 31 and 0 findings; `docs/ACHIEVEMENT_REACHABILITY.md` reads each one against the code and the supply | holds as a count; **two were not as described**: Darkness paid on every death and Quiet as a Mouse and Without a Scratch could be lost for good (CORRECTION_LOG 267 to 269), fixed |
| 60 daily challenges | `store/listing.md:62` | `content/daily_challenges.json` (60 templates); the selector of `scripts/systems/daily_challenge_manager.gd` | 60 as authored, **58 offered**: `streets_12` and `streets_16` need more lit districts than a run has (11) and the selector walks past them (CORRECTION_LOG 266); a day's progress stays with its day (`progress_day`, check DAILY3; the walk-past had made 2026-10-17 to 19 share a template and its progress, CORRECTION_LOG 277); the listing's number is the authored one, an owner row |
| 13 languages, 12 of 12 translated locales | `store/listing.md:132` | `python tools/qa_sim/i18n_truth_gate.py`: "12/12 locales PASS"; `python tools/qa_sim/i18n_placeholder_fuzz.py --check` (`s26_s3_fuzz`): 1,560 keys, 497 calls, 0 findings | holds |
| the touch layer is checked | `docs/GEMINI_HANDOFF.md` ("34 checks, 0 fails") | `.qa_logs/gate_touch_probe_scene.log` of the final battery: 34 lines `[touch-probe] OK`, `[touch-probe] DONE fails=0` | 34 of 34 holds (an earlier brief's 23 of 23 is the count of an older probe) |
| the perf budgets D1 < 200 and D11 < 350 draw calls | `docs/PRODUCTION_BIBLE.md:114` | the windowed gate (`s26_windowed_ccc7669`): D1 152, D11 142, p95 17.48 and 19.05 ms, `DONE fails=0` | holds at this head; the Session 23 reading (RED) is not reproduced and stays in `docs/PERF_PASS.md` |
| the audio never clips (ceiling -1.5 dB on every bus) | `tools/qa_sim/audio_truth_gate.gd` | two windowed runs read the Music bus at +1.3 and +1.9 dB (24 readings on record, 10 over the ceiling and 14 under it, `s26_audio_readings`; CORRECTION_LOG 114); with the limiter of `default_bus_layout.tres` one run reads -2.0 dB (`s26b_mutations`) and the check AUD6 holds the layout | **false before; true of the Music bus after, shown for no other bus**: the gate reads Master (muted), Music, SFX (-67.3 dB) and Ambient (-27.3 dB), and the other eight buses carry no limiter (CORRECTION_LOG 276 and 278) |
| the frames show the code that ships | `tools/qa_sim/af3_frame_check.py` | 8 frames at `ccc7669`, F4 holds against `HEAD` through three scope rows (`default_bus_layout.tres`, `export_presets.cfg`, `scripts/systems/daily_challenge_manager.gd`) | holds |
| the signed bundle is 136,645,015 bytes, version code 3 | `docs/RELEASE_ARTIFACTS.md` | `stat build/tls.aab`, `sha256`, `aab_check` (`s26_aab_check_4b4fee0`) | 136,645,015 and `bb61ce937b71`: holds for the bundle of `4b4fee0`; the first bundle of the pass (`f8224aa`) is superseded |
| the dead code is gone | `docs/CLEANUP_LEDGER.md` section 12 | `s26_c3_deadfuncs_after`: 26 candidates named by no document, each with a citation | 58 functions were left by Sessions 24 and 25 and are deleted (CORRECTION_LOG 270) |
