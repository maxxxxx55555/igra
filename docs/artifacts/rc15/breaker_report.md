# Breaker report (rc15 R5), code reading only

A read-only subagent searched the tree at `f941bfa` for five new exploits. Its findings are reproduced here with the
verdict the orchestrator reached by reading the code itself and the check that now guards each one. Nothing below was
run by the subagent; every "closed" row has a `closeout_check` assertion that fails on the code before the fix
(`closeout_mutation_batch9.txt`).

| ID | Severity | Finding | Verdict | Guard |
|---|---|---|---|---|
| B1 | P0 | `FinaleDirector._triggered` is set only by the `district_restored` event of the last district; a game loaded with all eleven FULL never arms the final night, so the Architect never comes (and `reset_all()` never clears the flag, so a new game in the same process spawns him early). `finale_director.gd`, `power_grid.gd` | CONFIRMED, closed (`_begin_final_night` follows `PowerGrid.all_restored()`, cleared on `game_started`) | FIN1 |
| B2 | P0 | District loot is marked "looted" when it spawns: whatever is left on the street at a death, Continue or trip to another district never comes back, repair parts included (the first district gates every other). `district_loot.gd`, `progress_tracker.gd` | CONFIRMED, closed (per-pickup keys, taken keys skipped, positions still drawn from the seeded sequence) | LOOT2 |
| B3 | P0 | The Difficulty screen's pick starts a new game and wipes the save with no confirm (only Play asks). `difficulty_screen.gd` | CONFIRMED, closed (a pick is a setting and returns to the menu) | DIFF1 |
| B4 | P1 | The `inventory_space` skill's extra slots vanish on every load and the items in them are deleted (`from_dict` sizes the pack to the base slots). `inventory_manager.gd`, `skill_tree_manager.gd` | CONFIRMED, closed (`ensure_slots`, capped at 64) | INV2 |
| B5 | P1 | Hardcore is read live: unticking it mid-run cancels the wipe, ticking it before the last boss grants Iron Man (+100 coins). `game_manager.gd`, `settings_screen.gd`, `achievements_manager.gd` | CONFIRMED, closed (`run_hardcore`, box locked in a running game) | HC1 |
| E1 | P2 | The cached New Game+ screen stays "activated" for the session; nothing marks a run won, so the boss can be fought again from the pre-boss save to bank New Game+ levels | first half closed (fresh per visit, SCR1); second half DEFERRED (owner decision) | SCR1 |
| E2 | P2 | `PuzzleSystem._solved` is neither saved nor reset: the cable box pays 200 coins once per launch, and is dead after a New Game in the same session | CONFIRMED, closed | PUZ1 |
| E3 | P2 | The shop's "backpack slots" raise `base_slots` but the live pack grows only at the next load | CONFIRMED, closed | UPG1 |
| E4 | P2 | The four blueprints lying in the districts name upgrades that do not exist (`blueprint_x` vs `upgrade_x`): they never apply | CONFIRMED, closed | UPG1 |
| E5 | P2 | The daily "30 s in the dark" counts lit time: nothing announces that the light starts on | CONFIRMED, closed (the player announces its light in `_ready`) | DAILY1 |
| E6 | P2 | AppLovin `on_ad_hidden` never reports failure: closing a rewarded ad early leaves the service "in flight" for the session | CONFIRMED by reading (SDK glue, not runnable here), closed | none possible without the SDK |
| E7 | P2 | A Continue/Retry overwrites the preferences chosen in the menu with the save's copy, and nothing but the Difficulty screen wrote the config file | CONFIRMED, closed | SET1 |
| E8 | P2 | Import Save is reachable in a running game: `load_all()` swaps the state under a live world | CONFIRMED, closed (the button is disabled outside the menu) | HC1 |
| E9 | P2 | A dead player stays controllable behind the death screen | CONFIRMED, closed | DEAD1 |
| E10 | P3 | The strobe cone is `cos(0.45 * PI)`, an 81 degree half angle, not the 26 the constant says | CONFIRMED, closed | STROBE1 |
| E11 | P3 | Collect quests count `item_picked_up` events (refunds from failed crafts inflate them); a full pack leaves a one-shot reward open | DEFERRED (owner decision, TZ_DECISIONS `DEFERRED-P3`) | |
| E12 | P3 | `_write_atomic` never verifies the write, so ~3 failing autosaves on a full disk overwrite all backups | CONFIRMED, closed (the temp file is read back before it rotates) | SAVE2 (positive path only: a short write cannot be injected here) |
| E13 | P3 | The battery does not drain while a blocking screen is open, but the player can walk | DEFERRED (the inventory is real time; owner decision) | |
| E14 | P3 | `InventoryManager.from_dict` never clears equipment; `_parse_player_pos` does not type-check its elements; unsigned achievements JSON is trusted | positions and equipment closed; the achievements file is a client-side limit (SECURITY_THREAT_MODEL) | SAVE3 |

Ruled out by the subagent (checked, not reported): the ad stub in a release build (null provider outside debug), slot
swap and `.bak` tampering (slot id is in the signed payload; the slot UI is unreachable), the NG+ cap and forged
modifiers (clamped and re-gated), saving while dead (vitals are `{}` at 0 health; the respawn is consumed once), language
switch mid-dialog (31 screens subscribe to `language_changed`), battery bounds (every writer clamps), the daily clock
(read once, delta capped).
