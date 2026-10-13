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
| 4 graphics tiers | the Settings screen | `GRAPHICS_TIERS` in `scripts/systems/settings_manager.gd:306` | 4 rows: holds |
| 7 onboarding cards | `docs/FIRST_5_MINUTES.md` | `PANELS` in `scripts/ui/onboarding_overlay.gd:9` | 7: holds |
| the signed bundle is 136,508,347 bytes | `docs/RELEASE_ARTIFACTS.md` | `stat build/tls.aab` | 136,508,347: holds **for the bundle of `v8.0.0-shipping`**; the code has changed since, so it is rebuilt at the ship step and the number replaced |
| D1 142 draw calls, p95 28.79 ms | `docs/PERF_PASS.md:19` | the windowed perf gate | measured at `v8.0.0-shipping`; **re-measured at the final hash** (`docs/PERF_PASS.md` section of Session 23) |

No claim of the sample was false at HEAD. The two that are true of an older tree are the bundle and the D1 numbers, and both are re-measured by the last steps of the pass.
