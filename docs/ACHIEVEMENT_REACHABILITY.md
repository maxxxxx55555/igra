# Achievement reachability (Session 26, S1)

The 31 achievements of `scripts/systems/achievements_manager.gd` (20 numbered and 11 district ones), each followed from the code that decides it to the supply that can
satisfy it. `tools/qa_sim/achievements_sim.py` checks the wiring (a trigger exists and its signal is emitted); this table adds what that tool does not: the condition as the
code evaluates it, the supply of whatever the condition counts, the check of the engine that exercises it (`docs/artifacts/rc16/proofs/s24_all_8978194.attach.gate_closeout_check_scene.log`; the `ACHSIG` checks are new in this pass),
and what was found. It was read at `HEAD` of Session 26; the three rows that changed in this pass are marked.

| ID | Name | The condition as the code decides it | Supply | Engine check | Verdict |
|---|---|---|---|---|---|
| `ach_01` | First Light | on the first streetlight activation (`_check_unlock(&"ach_01", true)` at `scripts/systems/achievements_manager.gd:385`); `first_light` is also granted on the first solved puzzle (`scripts/systems/progress_tracker.gd:187`) | the signal fires once per district when it crosses into STREETS (`scripts/world/power_grid.gd:65`) | `ACHSIG1`; the unlock path also has a row of the attack sim (`scripts/security/attack_sim.gd:185`) | reachable |
| `ach_02` | Electrician | `_check_unlock(&"ach_02", true)` when a district is restored to FULL (`scripts/systems/achievements_manager.gd:370`) | 11 districts | `ACHSIG2` | reachable |
| `ach_03` | Beacon | `_check_unlock(&"ach_03", _all_districts_full())` (`scripts/systems/achievements_manager.gd:371`) | all 11 districts, the win condition itself | `ACHSIG3` | reachable |
| `ach_04` | Librarian | `_check_unlock(&"ach_04", _all_docs_collected())` (`scripts/systems/achievements_manager.gd:389`): found at least total, total above 0 (`scripts/systems/achievements_manager.gd:427-431`) | the total is built from the tables the loot placer reads (`scripts/core/endings.gd:15`) | `ACHSIG5` | reachable |
| `ach_05` | Shadow Hunter | on a kill of the monster id shadow (`_check_unlock(&"ach_05", 50)` at `scripts/systems/achievements_manager.gd:315`); the counter is profile-wide | 7 shadows in the base rosters of 6 districts (`scripts/enemies/enemy_pool.gd:28-33`), more in dark stages, and each district rebuild spawns them again | `ACHSIG4`, `the Shadow carries its own id` | reachable over a profile (several runs or visits), not in one quick run |
| `ach_06` | Quiet as a Mouse | `_check_unlock(&"ach_06", not _progress.has("seen_park"))` when the park is FULL (`scripts/systems/achievements_manager.gd:367`); the mark is set by `player_detected` while in the park (`scripts/systems/achievements_manager.gd:181`) | one run, no detection in the park | `ach_06` rows | **was lost for good after one detection in any run; the mark now starts empty in a New Game (this pass, ACHRUN1)** |
| `ach_07` | Combo Master | `_check_unlock(&"ach_07", COMBO_CHAINS)` after 10 chains with no break (`scripts/systems/achievements_manager.gd:347`) | combat | `ach_07` rows | reachable |
| `ach_08` | Overloaded | `_check_unlock(&"ach_08", _overload_sec >= OVERLOAD_SEC)`: over 39 kg for 300 s (`scripts/systems/achievements_manager.gd:361`) | the pack holds 40 kg (`scripts/inventory/inventory_stats.gd:4`) and 10 kg more with the backpack upgrade (`scripts/economy/upgrade_system.gd:8`) | `ach_08 five minutes over 39 kg` | reachable (1 kg of margin before the cap) |
| `ach_09` | Photographer | `AchievementManager.unlock` at the 50th photo (`scripts/systems/progress_tracker.gd:91-92`, table `scripts/systems/progress_tracker.gd:38`) | `photo_total()` = 203 | `G26 the 50th photo unlocks Photographer` | reachable |
| `ach_10` | Seeker | the 100th photo (same site) | 203 | `G26` | reachable |
| `ach_17` | Collector | the 200th photo (same site) | 203 of which 200 are needed: every secret, document, quest, monster kind, artifact, weapon and blueprint but 3 | `G26 the game can give 200 photos or more (203)` | reachable, with a margin of 3 |
| `ach_11` | Economist | `_check_unlock(&"ach_11", CoinWallet.get_coins() >= COINS_GOAL)`: a balance of 5,000 (`scripts/systems/achievements_manager.gd:362`) | 7,700 from the districts alone (`scripts/economy/rewards_manager.gd:3-8`), 1,300 from 26 secrets at 50 each (`scripts/economy/rewards_manager.gd:2`), 100 per achievement, kills, quests, dailies | `ach_11 5000 coins unlock Economist` | reachable |
| `ach_12` | Without a Scratch | `_check_unlock(&"ach_12", not _progress.has("hurt_school"))` when the school is FULL (`scripts/systems/achievements_manager.gd:369`); the mark is set by `player_damaged` in the school (`scripts/systems/achievements_manager.gd:182`) | one run, no damage in the school | `ach_12` rows | **same defect as `ach_06`, same fix (ACHRUN1)** |
| `ach_13` | The Architect | on the win (`_check_unlock(&"ach_13", true)` at `scripts/systems/achievements_manager.gd:395`) | the finale | `ach_16 / ach_18 a fast hardcore win unlocks` (asserts `ach_13` too) | reachable |
| `ach_14` | Truth | `_check_unlock(&"ach_14", true)` when `Endings.evaluate()` holds `truth` at the win (`scripts/systems/achievements_manager.gd:398`) | all documents, all districts, three secrets | `ach_14 a win with every document ... unlocks Truth` | reachable |
| `ach_15` | Darkness | on a death (`_check_unlock(&"ach_15", EndingsManager.get_ending() == &"dark")` at `scripts/systems/achievements_manager.gd:335`) | a death before the power station is restored, or with the whole grid restored; a death with the station restored and the rest unfinished is Survivor (`scripts/systems/endings_manager.gd:112-115`) | `ACH15` and `ACH15M` (this pass) | **paid on any death, including the Survivor ending that has its own title and art; now Dark only** |
| `ach_16` | Speedrunner | `_check_unlock(&"ach_16", ProgressTracker.time_played < SPEEDRUN_SEC)` at the win (`scripts/systems/achievements_manager.gd:399`) | a win under 4 hours | `ach_16 / ach_18` | reachable |
| `ach_18` | Iron Man | `_check_unlock(&"ach_18", GameManager.run_hardcore)` at the win (`scripts/systems/achievements_manager.gd:400`) | a Hardcore win | `ach_16 / ach_18` | reachable |
| `ach_19` | Midsummer Night's Dream | `_check_unlock(&"ach_19", true)` on `slept` (`scripts/systems/achievements_manager.gd:183`) | the bed in the suburbs (`scripts/gameplay/bed.gd:29`) | `ach_19 the bed stands in D1`, `sleeping in the bed heals and unlocks` | reachable |
| `ach_20` | Who's There? | on a heard hallucination (`_check_unlock(&"ach_20", 5)` at `scripts/systems/achievements_manager.gd:351`) | `RandomEvents` emits it (`scripts/systems/random_events.gd:56`); the counter is profile-wide | `ach_20 five hallucinations` | reachable |
| `ach_district_*` (11) | one per district | on a district restoration (`_check_unlock(StringName("ach_district_" + String(district_id)), true)` at `scripts/systems/achievements_manager.gd:375`) | the 11 district ids of the grid and of the catalog are the same list | `ACHSIG2` and `ACHSIG3` (hospital and power station), the touch probe for the suburbs (`scripts/tools/_touch_probe.gd:330`) | reachable |

## What was found

1. **`ach_06` and `ach_12` could be lost for good.** Their marks (`seen_park`, `hurt_school`) are kept in the profile-wide `achievements.cfg` so that a Continue inside
   the run keeps them, and nothing cleared them when a run began: `SaveSystem.reset_all()` resets the other systems of a New Game and left this one (the same class of gap as
   the TRUTH WAVE P0.2 for XP and skills). One detection in the park, in any run, forfeited "Quiet as a Mouse" for the profile. `AchievementManager.reset_run_marks()` is now
   called from `reset_all()`; the counters and what is unlocked are kept (`s26_checks.gd`, ACHRUN1 and ACHRUN2).
2. **`ach_15` paid on every death.** "Darkness" is the title of the Dark ending; a death with the power station restored and the grid not whole resolves to Survivor (`scripts/systems/endings_manager.gd:112-115`)
   and used to pay it too. It now needs the Dark ending (ACH15, both cases; ACH15M, `GameManager` hears `game_over` before `AchievementManager` does, so the ending is resolved when Darkness
   is asked). A death with every district restored (the finale) is Dark too and pays, as before.
3. **Three unlocks the catalog does not know (owner row).** `ProgressTracker` grants `district_one`, `shadow_slayer` and `secret_hunter` by
   `_grant("district_one")` (`scripts/systems/progress_tracker.gd:189`), `_grant("shadow_slayer")` (`scripts/systems/progress_tracker.gd:191`) and `_grant("secret_hunter")`
   (`scripts/systems/progress_tracker.gd:193`), through `AchievementManager.unlock`, whose map holds none of them, so they unlock ids that are not in the
   catalog: the player hears the fanfare and gets 100 coins each (`scripts/economy/rewards_manager.gd:13`) for an achievement that never appears in the list.
   Making them real is a content wave (three names, three descriptions, 13 locales, three medals); removing them takes 300 coins out of the economy. Neither was done.
4. **Thresholds are margins, not certainties.** `ach_17` needs 200 of 203 photos, `ach_08` needs 39 of a 40 kg pack. They are reachable and tested; a future change that
   removes one photo source or lowers the pack by 2 kg makes them unreachable with no gate telling: `G26` and `ach_08` are the gates.
