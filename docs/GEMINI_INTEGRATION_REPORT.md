# Gemini integration report (Session 25, 2026-10-16)

The directive of this pass names nine Gemini artifacts and asks to run five simulators, implement 19 achievements from a specification and add a CI workflow from
another. This report is what was found, what was run instead and what was not done, with the proof of each line (`docs/artifacts/rc16/proofs/`).

The lines of the directive this report answers (it is the owner's message of the pass, not a file of the repository): G1.1 "Read all Gemini-created files:
tools/qa_sim/proofs_tolerance_audit.py, tools/qa_sim/achievement_reachability_sim.py, tools/qa_sim/save_migration_sim.py, tools/qa_sim/i18n_parity_audit.py,
tools/qa_sim/security_hmac_audit.py, data/i18n_glossary.json, docs/gemini/ACHIEVEMENT_50_SPEC.md, docs/gemini/CI_PIPELINE_SPEC.md,
docs/gemini/WORLD_CLASS_AUDIT_REPORT.md"; G1.2 "Verify each file exists and is non-empty; if missing -> report in RUN_STATE, skip that component, continue"; G2 "IMPLEMENT
MISSING 19 ACHIEVEMENTS (per docs/gemini/ACHIEVEMENT_50_SPEC.md)"; G3.2 "Copy the YAML to .github/workflows/world_class_audit.yml"; G4.3 "NEVER delete: main, master, develop,
release/*, v8.0.0-shipping, v8.1.0-premium (if exists)"; G5.4 "Tag v8.1.0-premium".

## 1. The named files (G1 steps 1 and 2)

`s25_gemini_check.out` (the script prints itself first): 2 of the 9 named paths are in the working tree; both were written in this repository (Session 23), and the Jules branch holds different files at the same two paths.

| Named path | In the tree | What it is |
|---|---|---|
| `tools/qa_sim/proofs_tolerance_audit.py` | absent | no such name on any ref or in any commit |
| `tools/qa_sim/achievement_reachability_sim.py` | absent | the purpose is held by `tools/qa_sim/achievements_sim.py` |
| `tools/qa_sim/save_migration_sim.py` | present, 116 lines | Session 23's version, which runs the real reader; the Jules version of the same path (184 lines) was not absorbed (`docs/ABSORB_PLAN.md` section 5) |
| `tools/qa_sim/i18n_parity_audit.py` | absent | the purpose is held by `tools/qa_sim/i18n_placeholder_fuzz.py`, `tools/qa_sim/i18n_truth_gate.py` and the parity gate of `tools/check.sh` |
| `tools/qa_sim/security_hmac_audit.py` | absent | the purpose is held by `scripts/security/attack_sim.gd`, `scripts/tools/_save_integrity_check.gd` and `tools/qa_sim/secret_scan.py` |
| `data/i18n_glossary.json` | present, 1,029 lines | Session 23's glossary (what `tools/qa_sim/i18n_placeholder_fuzz.py --write-glossary` writes, read by the fuzz); the Jules branch holds a 416-line file at the same path (`docs/ABSORB_PLAN.md` section 5) |
| `docs/gemini/ACHIEVEMENT_50_SPEC.md` | absent | see section 3 |
| `docs/gemini/CI_PIPELINE_SPEC.md` | absent | see section 4 |
| `docs/gemini/WORLD_CLASS_AUDIT_REPORT.md` | absent | `docs/CROSS_AUDIT.md` is the audit of this repository |

The search was wider than the tree: 75 refs (the remote branches with `main`, the heads of the 20 pull requests, 2 local branches and 38 tags) and the whole history of
every ref hold no path with any of the Gemini-only names (`s25_gemini_check.out`: "refs holding a Gemini-only name: 0", "paths with a Gemini-only name anywhere in the
history of any ref: 0"). A search of `TLS_Build` for the nine file names found none; Downloads and the Desktop hold only files with "gemini" in their names that belong to
other things (an installer, a shortcut and the `ecc` project's own `.gemini` folder), except `3_Gemini18m.txt` (1,510 bytes, 2026-10-13), which was not opened: its content is unknown and its size is too small for any of the nine files. The only agent output of this kind on origin was the Jules branch
(pull request 20, three commits of 2026-10-12): two workflows, a glossary, four simulations and four documents, classified file by file in
`docs/ABSORB_PLAN.md` section 5 (nothing absorbed: each has a fuller counterpart in `main` or reads the real code). Whether the directive's Gemini run produced
other files, they have not reached this repository: the action is the owner's (section 6).

## 2. The simulators (G1 steps 3 to 5)

Not executable as named. The five purposes were run through the files that serve them, each through `proof_run` (raw log and exit code; copies in
`.qa_logs/gemini_sims/`):

| Purpose | Command | Proof | Result |
|---|---|---|---|
| proofs audit | `python tools/qa_sim/proofs_audit_sim.py` | `s25_equiv_proofs_audit` | 220 closures, PASS 220, FAIL 0 |
| achievement reachability | `python tools/qa_sim/achievements_sim.py` | `s25_equiv_achievements` | 31 achievements, 0 findings (it checks that each has a trigger wired to an emitted signal, not the thresholds) |
| save migration | `python tools/qa_sim/save_migration_sim.py --static` | `s25_equiv_savemig` | SAVE_VERSION 3, BACKUP_DEPTH 3, 0 findings (the reader itself runs in the closeout gate, check SAVEMIG) |
| i18n parity | `python tools/qa_sim/i18n_placeholder_fuzz.py` and `python tools/qa_sim/i18n_truth_gate.py` | `s25_equiv_i18n_fuzz`, `s25_equiv_i18n_truth` | 1,560 keys and 497 calls, 0 findings; 12 of 12 locales PASS |
| security and HMAC | `python tools/qa_sim/secret_scan.py` | `s25_equiv_secret_scan` | 1,987 tracked text files, 0 findings (the signature checks run in the engine: Session 24's battery, `s24_all_8978194`, row 122) |

No defect was found, so no fix was made.

## 3. The 19 achievements (G2)

Not implemented. The specification the directive names is absent. The only expansion proposal in the repository is the Jules document
`docs/jules/ACHIEVEMENT_TRIGGER_SPEC.md` (19 proposals, `ach_21` to `ach_39`, "from 31 shipped to 50"), which sits on a branch that was never merged (now on
`refs/pull/20/head` and in the bundle of `docs/CLEANUP_LOG.md`). Its hook claims were checked at `HEAD` (`s25_ach_hooks.out`, G2 step 2.1) and re-derived by the verifier of
this pass:

- 6 of 19 name a signal that is declared in `scripts/events/event_bus.gd` and emitted outside the tools: `ach_29` and `ach_30` (`secret_found`, emitted once per pickup at
  `scripts/world/secret.gd:68`; 26 secrets in `content/secrets.json`), `ach_33` (`puzzle_solved`), `ach_37` (`streetlight_activated`), `ach_38` (`weather_changed`) and `ach_39`
  (`district_blackout`). Only `ach_29` and `ach_30` are clean fits. The signal of `ach_33` is also emitted on every repair step (`scripts/world/power_switch.gd:181`), so "5
  puzzles" would fall in the first district; the signal of `ach_38` fires once at start through `call_deferred` (`scripts/systems/weather_system.gd:21`), on a timer even when nothing changed (`:44`)
  and on a language change (`:38`), and "severe" is not defined; the signal of `ach_39`, `district_blackout` (`scripts/systems/random_events.gd:42`), is a one-shot notice, and the blackout itself is
  a timer in each streetlight (`scripts/world/streetlight.gd:18`), so there is no state to restore during it.
- 13 of 19 name an EventBus signal that does not exist (10 names: `item_crafted`, `battery_used`, `medkit_used`, `stealth_moved`, `enemy_killed_by_weapon` for three rows,
  `attack_dodged`, `daily_completed` for two, `radio_channel_tuned`, `skill_unlocked`, `coin_balance_changed`), and the cited lines do not hold the cited events (for example
  `scripts/ui/workbench.gd:95` is `_build_craft_panel()`, and `scripts/player/player_3d.gd:887` and `:910` are damage code, not medkit or battery use). Eight of the 13 have the
  capability under another name: `ach_22` and `ach_23` in `EventBus.item_consumed` (`scripts/inventory/inventory_manager.gd:169`), `ach_21` in the counter `ProgressTracker.crafted`
  (`scripts/crafting/workbench_logic.gd:46`), `ach_31` and `ach_32` in `DailyChallengeManager.completed` (`scripts/systems/daily_challenge_manager.gd:168`) and `streak_milestone`
  (`:163`), `ach_35` in `SkillTreeManager.skill_unlocked` (`scripts/systems/skill_tree_manager.gd:227`), `ach_36` in `EventBus.coin_changed` (`scripts/events/event_bus.gd:6`) and
  the poll that serves `ach_11` (`scripts/systems/achievements_manager.gd:362`), and `ach_34` only in `EventBus.voice_line` (`scripts/ui/radio.gd:177`). Five need a new
  emission point: `ach_24` (stealth distance) and `ach_25` to `ach_28` (kills by weapon, a perfect dodge): the kill signal carries no weapon
  (`scripts/enemies/base_monster.gd:768`) and `_handle_dodge` (`scripts/player/player_3d.gd:1297`) emits nothing.
- `ach_37` ("activate 50 streetlights") cannot be reached within one run: the signal fires once per district when it crosses into STREETS (`scripts/world/power_grid.gd:65`,
  `scripts/systems/achievements_manager.gd:380`) and there are 11 districts. A counter on it would persist across New Game runs (`PowerGrid.reset()`, called at
  `scripts/core/save_system.gd:415`, re-arms the signal, and nothing resets the achievements' progress), so it would take five playthroughs.
- No row is already satisfied by a shipped achievement (the nearest: `ach_36`, "10,000 coins", against `ach_11`, "5,000 coins", on the same poll; `ach_37` against `ach_01`, on
  the same signal).

`docs/GDD.md` section 21 asks for "ach_01 to ach_15+"; 31 ship, and `achievements_sim` reads all 31 as wired to an emitted signal (it does not evaluate thresholds). Nineteen
more is a feature-sized wave (five new emission points and fourteen re-uses of existing signals and counters, 494 locale strings in 13 locales, medal art, a save counter per
row, new frames of the achievements screen), which this repository's rule sends through spec-kit (`CLAUDE.md`: "For any new feature-sized wave of work, run `/speckit-specify`
..."), not through a closeout pass. The list above is the verification such a specification must start from. `achievements=0/19`.

## 4. The CI workflow (G3)

Skipped: `docs/gemini/CI_PIPELINE_SPEC.md` is absent, and `.github/workflows/world_class_audit.yml` would have nothing to copy. The repository already runs three
workflows (`static.yml`, `pr-sims.yml` with a job per simulation and the whole static battery, `weekly-full.yml`), checked by `actionlint` through
`tools/lint_changed.py`.

## 5. Cleanup, tag, bundle

The repository cleanup of G4 is in `docs/CLEANUP_LOG.md`. The bundle is unchanged (no runtime path differs from `ebc1acc`, `s24_runtime_diff_2`); no export and no
launch were due (`launches 0 of 15, exports 0 of 3`). The tag the directive names, `v8.1.0-premium`, already exists on origin (Session 24, on `53a5f83`) and is on
its own list of tags never to delete or move; this pass's tag is a new name (CORRECTION_LOG 263).

## 6. What the owner does

- To have the Gemini output integrated: push it to a `gemini/<name>` branch or a pull request of `maxxxxx55555/igra`, or say that the Jules proposal is the
  intended specification. Until then nothing in this repository depends on it.
- To expand the achievements to 50: start the spec-kit flow with section 3 and decide which of the 19 rows are worth their art and locale cost.
