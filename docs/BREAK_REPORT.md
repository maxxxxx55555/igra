# BREAK REPORT — THE LAST STREETLIGHT

Hostile static pass. No engine run. Each item was read at the cited lines before it was listed. Unproven items are `QUESTION`, not guesses.

Labels: `CONFIRMED-STATIC` = the bad state follows from the code as written. `NEEDS-RUNTIME-CONFIRM` = the mechanism is in the code; whether a frame actually dies needs a probe. `QUESTION` = the log does not identify the fault.

Ranked by what a player (or a save editor) can do with it. Minimal-fix hint is the root cause, not a patch.

## Critical

### B1 — Finale boss is spawned into the district that is about to be freed
- Severity: critical. Label: `CONFIRMED-STATIC`.
- Where: `scripts/world/finale_director.gd:56-68` and `:70-75`; `scripts/world/world_runtime.gd:48-52` and `:59-66`; `scripts/world/district_scene_factory.gd:22`.
- Repro: restore all 11 districts while not standing in `power_station` (the toast tells you to go there). Open the city map and Travel to the station.
- Expected: Architect spawns in the station and his death calls `trigger_win()`.
- Actual: `transition_to` emits `district_entered`. FinaleDirector (autoload, connected first) `call_deferred`s `_spawn_boss`. WorldRuntime (scene node, connected later) `call_deferred`s `load_district`. On the next idle frame the boss is parented to WorldRuntime's current last child — the district `load_district` then `queue_free`s. `DistrictSceneFactory.build` re-emits `district_entered` in that same idle frame, while `is_instance_valid(_boss)` is still true (queued, not freed yet), so the re-emit returns without scheduling another spawn. End of frame deletes the only boss. Win never fires.
- The path that works is repairing the station while already standing in it (`finale_director.gd:48-51`). Leaving and coming back hits B1.
- Riskiest assumption: a node stays `is_instance_valid` until end-of-frame after `queue_free`, and both deferred calls run in connect order on one idle frame.
- Root cause: spawn and rebuild are both deferred from the same signal, spawn runs first against the dying district, and the "boss already exists" guard treats a queued-free node as alive.

Runtime probe: after that Travel, print `get_nodes_in_group("boss").size()`, `is_instance_valid` on FinaleDirector's boss, and `boss.get_parent().is_queued_for_deletion()` before and after the idle frame.

### B2 — Document pickups never record an id, so document endings cannot be earned
- Severity: critical. Label: `CONFIRMED-STATIC`.
- Where: `scripts/world/district_loot.gd:260-267`; `scripts/document_pickup.gd:24-32`, `:66-67`, `:75-76`; `scripts/core/endings.gd:47-55`.
- Repro: enter any district, walk into a lore note or the district document, then open the journal / win the game.
- Expected: `ProgressTracker.unlock_doc(id)` runs, the note does not respawn, Light and Truth can be reached by collecting the catalog.
- Actual: `_spawn_document` calls `add_child` (which runs `_ready`) and only then `set("document_id", ...)`. `_ready` bails out of `_load_from_catalog` because the id is still `""`, and the "already unlocked → queue_free" check never sees the real id. `_collect` skips `unlock_doc` on an empty id, shows "Untitled", and frees the node. Next visit `populate` spawns it again because nothing was recorded. `get_total_documents()` counts every `DOCUMENTS` + `LORE_DOCS` id. Light and Truth both require that full count. They are unreachable from world pickups. Only the two event docs (`doc_engineer_log`, `doc_family_letter`) can ever land.
- Riskiest assumption: `add_child` on an in-tree parent runs `_ready` before the next line. District root is added to WorldRuntime before `populate`.
- Root cause: the id is applied after the node has already decided it has no document.

Runtime probe: on the pickup, print `document_id` in `_collect` and `ProgressTracker.count_docs()` after. Expect a catalog id and count +1. Actual: `""` and count unchanged.

### B3 — Skill bonuses mutate the shared player resource and replay on every player `_ready`
- Severity: critical. Label: `CONFIRMED-STATIC`.
- Where: `scenes/player/player_3d.tscn:4` and `:120` (`stats` is `player_stats.tres`, not local-to-scene); `scripts/systems/skill_tree_manager.gd:268-277` and `:296-300`; `scripts/player/player_3d.gd:253-254`; `scripts/core/routes.gd:49-50`; `scripts/ui/pause_menu.gd:60`; `scripts/ui/death_screen.gd:54`.
- Repro: buy `move_speed` or `max_health` once. Pause → Restart, or die → retry. Repeat. Then New Game in the same process.
- Expected: one rank is +20 HP / ×1.1 speed / +5 slots, once. Restart and New Game start from the `.tres` bases (walk 170, HP 100, 12 slots).
- Actual: `_apply_skill_effect` does `max_hp += 20`, `stamina_max += 30`, `walk_speed *= 1.1`, `run_speed *= 1.1`, `InventoryManager.add_slots(5)` on the live objects. `player_3d._ready` calls `reapply_all_effects()` every time the scene loads. `restart_game()` only `goto`s the game scene — it does not `reset()` skills or reload the resource. Each Restart multiplies speed again and appends more slots onto the autoload inventory. `reset_all()` clears the skill dictionary but does not restore `player_stats.tres`, so the next New Game keeps the inflated HP/speed with zero skills. Continue (`main_menu.gd:35-38` → `goto(GAME)`) loads the same ranks and reapplies on top of the already-mutated resource.
- `load_data` clamps `skill_points` to 0–9999 and does not clamp per-skill level (`skill_tree_manager.gd:323-328`). A save with `move_speed: 50` replays ×1.1 fifty times on one load, then again on each Restart.
- Riskiest assumption: an `ExtResource` without `resource_local_to_scene` is the same Resource instance across scene loads in one process. That is the engine default, and nothing duplicates it.
- Root cause: push-once effects write through a shared Resource and are replayed from stored ranks with no base snapshot.

Runtime probe: print `player.stats.walk_speed` and `InventoryManager.slots.size()` before and after one Restart with `move_speed` at rank 1. Expect 187 and base+5. Actual: 205.7 and another +5.

## High

### B4 — A checksum envelope with no `progress_hmac` is a trusted save
- Severity: high. Label: `CONFIRMED-STATIC`.
- Where: `scripts/core/save_system.gd:174-179` (checksum branch) and `:202-204` (missing `progress_hmac` is returned as-is); clamps that do not cover the forged fields: `scripts/world/power_grid.gd:144` (stage assigned raw), `scripts/inventory/inventory_manager.gd:211` (count unclamped), `scripts/systems/skill_tree_manager.gd:323-328` (rank unclamped). Coins are clamped (`coin_wallet.gd:36-37`, ceiling 999999, enough to clear the shop).
- Repro: write `user://tls_savegame.save` as `{"checksum": <sha256 of data_json>, "data_json": <body>}` and omit `progress_hmac`. Put `power.stages` at 3, a full inventory, and finished quests in the body. Continue.
- Expected: a save that is not HMAC-signed is rejected, or at least power/progress are wiped the way a bad `progress_hmac` is.
- Actual: the no-`hmac` branch accepts `body.sha256_text() == checksum`. `_verify_progress` returns immediately when `progress_hmac` is absent. Wallet, stages, inventory, quests, XP, and skills load. Map locks open because `is_unlocked` only checks parent stage. This is the documented compat path; it is also a complete progression skip that does not need the client key.
- Riskiest assumption: Continue reads `SAVE_PATH` through `_read_validated` → `_read_envelope`. It does (`load_all`, `save_system.gd:280-282`).
- Root cause: the authenticity check is optional on the legacy field name, and the progress signature is optional on the same files.

### B5 — NG+ level and exclusive modifiers are an unsigned file, and one victory can bank all three levels
- Severity: high. Label: `CONFIRMED-STATIC`.
- Where: `scripts/systems/new_game_plus.gd:109-117` and `:187-208`; `scripts/ui/new_game_plus_ui.gd:111-114`; `scripts/ui/win_screen.gd:63`; `scripts/core/save_system.gd:522-528` (`wipe_all_saves` does not delete `user://ng_plus_data.json`).
- Repro (file): write `user://ng_plus_data.json` with `ng_plus: 3`, `active: true`, `modifiers: ["sprint","whisper","keepers_pact","ghost"]`. Play. Sprint and Whisper are an exclusive pair in `content/ngp_modifiers.json`; `can_select` is never called on load.
- Repro (UI, no file edit): win once, open the NG+ screen, press Activate three times. The button stays enabled until `ng >= 3` (`new_game_plus_ui.gd:46-48`). Each press increments and saves. Three modifier slots unlock without playing NG+1 or NG+2. `activate_ng_plus` does not check that this run was a win.
- Expected: one level per completed run, exclusive pairs rejected, Reset Progress clears the counter.
- Actual: level is clamped to 3, modifier ids are appended as strings, exclusivity is UI-only, and the file survives Reset Progress. `reset_all` deliberately does not clear NG+, so Play starts that run.
- Riskiest assumption: `get_modifier_multiplier` multiplies every loaded id that has the knob. It does (`new_game_plus.gd:88-94`); an unknown id contributes 1.
- Root cause: the NG+ file is not part of the signed envelope, and load does not run the selector's rules.

### B6 — Today's daily reward can be claimed again by deleting one unsigned file
- Severity: high. Label: `CONFIRMED-STATIC`.
- Where: `scripts/systems/daily_challenge_manager.gd:107-128` and `:132-145` and `:160-171`; `scripts/core/save_system.gd:395-402`.
- Repro: finish today's challenge (coins land in `CoinWallet`). Delete `user://tls_daily.json`. Restart the app. The same calendar day is incomplete again (`_last_completed_day` stays -1 when the file is missing). Complete it again. Repeat. `increment_daily_streak` only resets the streak if the system clock jumped more than 48h; completions inside that window keep incrementing, so the 7/30/100 bonuses (150/750/3000) pay out from repeated same-day clears. Rolling the clock forward also selects a different template and, past 48h, resets then re-grows the streak.
- Expected: one payout per calendar day, streak only for distinct days, stored with the signed save.
- Actual: the completion flag is a plain JSON file. The streak lives in the save and trusts `Time.get_unix_time_from_system()`.
- Riskiest assumption: a missing file leaves `_last_completed_day` at its default -1. `_load_state` returns before assigning it (`daily_challenge_manager.gd:161-163`).
- Root cause: "already claimed today" is not in the signed save.

### B7 — Legacy `achievements.cfg` is trusted, and every bus unlock pays coins
- Severity: high. Label: `CONFIRMED-STATIC`.
- Where: `scripts/systems/achievements_manager.gd:191-196`; `scripts/economy/rewards_manager.gd:19-21`; `scripts/systems/progress_tracker.gd:70-72`.
- Repro: replace `user://achievements.cfg` with plain JSON `{"unlocked":{"ach_13":true,"ach_14":true,...}}` (no `hmac` key). Relaunch. Separately, any `EventBus.achievement_unlocked` emit pays 100 coins with no id check — `ProgressTracker._grant` emits short ids (`first_light`, …) that are not the `ach_*` rows, so those payouts are a second tap on the same wallet.
- Expected: an unsigned trophy file is rejected the way a bad HMAC is (`achievements_manager.gd:186-188`). Coin rewards only follow a real, signed unlock.
- Actual: a Dictionary without `hmac` is loaded and then re-saved signed, which launders the forge. The project documents this as compat. It is still an achievement replay.
- Riskiest assumption: `_load` runs on autoload `_ready` before any UI, so the forged map is live for the session. It does.
- Root cause: the legacy branch treats "not yet migrated" as "authentic".

### B8 — Kills do not pay the wallet, and the coin HUD displays the kill roll as the balance
- Severity: high. Label: `CONFIRMED-STATIC`.
- Where: `scripts/enemies/base_monster.gd:687`; `scripts/ui/coin_hud.gd:6-10`; `scripts/ui/screens.gd:934`; `scripts/economy/coin_wallet.gd:9-12` (own signal, not the bus).
- Repro: note the real balance (`CoinWallet.get_coins()`). Kill one enemy.
- Expected: 5–15 coins added to the wallet, HUD shows the new total.
- Actual: `_die` emits `EventBus.coins_changed` with the roll, and never calls `CoinWallet.add`. The HUD's only listener is that bus signal, and it prints the argument as the total. After the first kill the label reads `5 mon`–`15 mon` until something else emits the bus. Shop and quests use the real wallet, so the player is looking at a number the shop will not honor. Kill income does not exist.
- Riskiest assumption: nothing else emits `EventBus.coins_changed`. Repo grep: only `base_monster.gd:687`.
- Root cause: the kill path emits the display signal instead of the wallet API, and the HUD subscribed to the display signal.

### B9 — A secret is consumed even when the backpack rejects the reward
- Severity: high. Label: `CONFIRMED-STATIC`.
- Where: `scripts/world/secret.gd:55-64`; `scripts/inventory/inventory_manager.gd:53-82`; `scripts/systems/progress_tracker.gd:32-40`; `scripts/world/district_loot.gd:200-204`.
- Repro: fill all 12 slots (or the weight cap). Interact with `secret_power_station_02` (`ancient_key`) or `secret_industrial_02` (`backpack_l1`). Leave the district and come back.
- Expected: a failed `try_add` leaves the secret in the world.
- Actual: `interact` sets `_taken`, calls `try_add` and ignores the bool, then emits `secret_found` and `queue_free`s. ProgressTracker records the id. The next visit skips it. The item is gone. `try_add` also commits a partial stack and then returns false (`inventory_manager.gd:68-74`) — `secret_substation_01` is 5 cable into `max_stack` 8, `secret_warehouses_01` is 5 metal. Some of the stack can land, the rest is deleted with the secret, and `secret_found` still pays the 50-coin wallet reward (`rewards_manager.gd:11-14`).
- `secret_park_02` grants item `coin` ×60 (`content/secrets.json`). That item is not the wallet (`data/items/coin.tres`, not consumable, no converter). The 60 never become spendable coins. The 50-coin bus reward is the only payout.
- Riskiest assumption: `ancient_key` is not granted by any other live spawn. Grep: the secret row, plus unused loot/shop JSON. Losing the secret loses the only world source.
- Root cause: found-state is committed before the inventory transaction succeeds.

### B10 — District-enter autosave runs before the player is moved
- Severity: high. Label: `CONFIRMED-STATIC` for the write; `NEEDS-RUNTIME-CONFIRM` for how bad the restored coordinate is.
- Where: `scripts/world/district_scene_factory.gd:22` (emit inside `build`); `scripts/world/world_runtime.gd:29-31` (that signal calls `save_all`); `scripts/world/world_runtime.gd:64-66` (`_place_player` runs only after `build` returns); `scripts/core/save_system.gd:414-418`.
- Repro: stand somewhere that is not the spawn point. Travel. Quit on the next frame. Continue.
- Expected: the save for the new district contains the spawn position `load_district` just applied.
- Actual: the factory emit is synchronous inside `build`, so `save_all` reads `global_position` from before `_place_player`. Continue feeds that stale vector back through `consume_pending_player_pos` (`world_runtime.gd:79-81`) and skips the spawn point.
- Riskiest assumption: the player node is still the previous district's transform at the emit. `_place_player` is the next statement after `build` returns, so yes.
- Root cause: the enter signal is fired as a side effect of construction, and a saver is connected to it, before the teleport.

Runtime probe: print `player.global_position` inside the `district_entered` save lambda and again after `_place_player`. Continue and print the applied position.

## Medium

### B11 — District locks are enforced only by the map button
- Severity: medium. Label: `CONFIRMED-STATIC`.
- Where: `scripts/district_manager.gd:60-66`; `scripts/ui/city_map.gd:186-191` (button disabled) and `:201-208`; `scripts/tools/_qa_autoplay_runner.gd:398-416`.
- Repro (player): the Travel button is disabled while `is_unlocked` is false. A click cannot skip. Repro (harness, and any other caller): `_travel_to` falls through to `DistrictManager.transition_to` when the Travel button is missing or disabled. That call does not check `is_unlocked`. `EventBus.district_entered` does not either. WorldRuntime will build the district.
- Expected: an unlocked parent at FULL is required to enter, not only to enable a button.
- Actual: the lock is UI. The bot's spine proof can skip it whenever the button isn't clickable. Walking triggers cannot skip: every `scenes/districts/*.tscn` trigger emits its own id, and WorldRuntime ignores a same-id enter.
- Riskiest assumption: no second player-facing caller of `transition_to` exists. Grep: city map, the bot fallback, and `set_stage` (debug). The player click path holds today.
- Root cause: the rule lives on the button, not on the transition.

### B12 — `streetlight_activated` fires again when a district reaches FULL
- Severity: medium. Label: `CONFIRMED-STATIC`.
- Where: `scripts/world/power_grid.gd:60-63`; `scripts/systems/daily_challenge_manager.gd:42` and `:107-114`; `scripts/systems/achievements_manager.gd:297-298`.
- Repro: on a `light_streets` day, repair one district from PARTIAL to STREETS, then to FULL.
- Expected: one streetlight event per district, at the STREETS crossing. `ach_01` is safe only because `_unlock` is idempotent.
- Actual: the emit condition is `new_stage >= STREETS`, so the FULL repair emits again. The daily counter has no per-district latch. Two ticks per district.
- Riskiest assumption: both repairs go through `advance_district`. The live switch does (`power_switch.gd:174`).
- Root cause: the signal means "stage is at least STREETS", not "stage just became STREETS".

### B13 — Import does not load, and the 30s autosave is not what Continue reads
- Severity: medium. Label: `CONFIRMED-STATIC`.
- Where: `scripts/core/save_system.gd:55-62` and `:84-89` and `:280-282`; `scripts/ui/settings_screen.gd:114-121`.
- Repro: mid-run, pause → Settings → Import Save (notice says it worked). Travel, or pick up a secret (both call `_save`). Then Continue from the menu.
- Expected: import replaces the live session, or at least the imported file is what Continue loads later. The 30s timer protects a crash.
- Actual: import copies onto `SAVE_PATH` and does not call `load_all`. The next `district_entered` / secret / puzzle / purchase calls `_save()` and overwrites the import with the live session. The 30s timer writes slot 4 (`save_slot(4)`). Continue never reads slot 4. A crash rolls back to the last event save, not to 30 seconds ago.
- Riskiest assumption: slot UI cannot load slot 4 in the shipping game. `save_system.gd:448-451` says that UI is archived. Continue is `load_all` only.
- Root cause: two save targets, and import writes the one the live session immediately clobbers.

### B14 — Quest item rewards are marked paid before the backpack accepts them
- Severity: medium. Label: `CONFIRMED-STATIC`.
- Where: `scripts/core/quest_manager.gd:140-155`.
- Repro: fill the backpack. Finish `q_secrets_3` or `q_restore_district2` (blueprint rewards) or `q_connect_cables` (scrap ×4, and scrap `max_stack` is 3).
- Expected: the quest stays open, or the items stay in a claim box, if `try_add` returns false.
- Actual: `done = true` is set first. `try_add`'s bool is ignored. A partial scrap add can commit and still return false (B9). The quest will not pay again. World blueprints also exist for the flashlight ones, so this is lost loot, not a hard lock, unless the backpack was the only copy the player could carry to a crafter.
- Riskiest assumption: those quests can complete while the bag is full. Nothing checks free slots in `_complete`.
- Root cause: completion and the item grant are one function, and the grant cannot fail the completion.

### B15 — Player is teleported onto a district whose floor does not exist yet
- Severity: medium. Label: `NEEDS-RUNTIME-CONFIRM`.
- Where: `scripts/world/street_builder.gd:51` (`call_deferred("build")` — collision is created in `_fill_roads`); `scripts/world/world_runtime.gd:64-88`; `scripts/player/player_3d.gd:343-354`.
- Repro: windowed, not headless. New Game, or Travel, on a machine that hitches between `add_child` and the deferred `build`. Print `y` and `is_on_floor` each physics frame until `streets_ready`.
- Expected: spawn waits until road collision exists, or a miss teleports back to a known floor.
- Actual: `_place_player` runs in `load_district` before the deferred `build`. Fall recovery returns immediately if `_last_grounded_pos` is still `Vector3.ZERO` (never grounded this scene — true on the first spawn). A hitch long enough to fall past y=0 before the boxes exist leaves the player under the floor with no recovery. A later Travel has a previous grounded pos, so recovery should fire after 3s; that pos is in the old district's coordinates (see B10) and may itself miss the new collision.
- This is not the `(inf, inf, inf)` log. A fall is a large negative Y. See Q1.
- Riskiest assumption: a windowed hitch can outrun one deferred call. Headless completing suburbs does not disprove that.
- Root cause: collision is deferred, placement is not, and the safety net refuses to run until the player has already stood on a floor.

### B16 — Offline player treats a default peer as a live network
- Severity: medium. Label: `NEEDS-RUNTIME-CONFIRM`.
- Where: `scripts/player/player_3d.gd:248` and `:424-429`. Contrast `scripts/inventory/inventory_manager.gd:19-26`, which already treats `OfflineMultiplayerPeer` as not networked. `base_monster.gd` does too.
- Repro: single-player, watch the debugger on the first physics frame. Also print `is_multiplayer_authority()` and `_net_active`.
- Expected: no RPC, movement runs locally.
- Actual: `multiplayer_peer != null` is true for the default offline peer, so `_net_active` is set. If the node is authority, `_sync_broadcast` RPCs every physics frame (the error inventory already documented: "RPC on yourself is not allowed"). If it is not authority, `_sync_remote` lerps toward `_remote_pos` (starts at `ZERO`) and returns before movement. Which branch offline play takes was not executed here.
- Riskiest assumption: Godot's default peer is non-null in this 4.7 build. The inventory comment in this repo says it is.
- Root cause: the player copied the check the other systems already rejected.

## Question

### Q1 — Park heartbeat `ppos=(inf, inf, inf)` is not evidence the transform is INF
- Label: `QUESTION`.
- Where: `scripts/tools/_qa_autoplay_runner.gd:156` sets the heartbeat position to `Vector3.INF` when `not _player_ok()`. The softlock line (`:498`) prints `?` when the node is invalid, and the known log quoted the heartbeat, not that line.
- What was checked and does not explain a real INF position: every district scene has a `DistrictTrigger` of its own id (no sequence-skip reload); none of the 11 scenes has a `PlayerSpawn`, and suburbs uses the same `_place_player` formula and completes; `Vector3.INF` as a saved sentinel is consumed and replaced, not applied (`world_runtime.gd:79-81`); park.tscn matches suburbs.tscn (StreetBuilder + switch + trigger).
- Probe: on the first heartbeat after suburbs→park, print `is_instance_valid`, `is_inside_tree`, and each component of `global_position` with `is_finite`, from the player node, not from the heartbeat fallback. If the node is invalid, the bug is "who freed the player", not a NaN transform. B15 is the nearby floor race if Y is finite and negative.

## Checked, not listed

- District-trigger sequence skip. All 11 triggers emit their own id; same-id enter returns early.
- `puzzle_base.gd:18` `toggle_district` (FULL→DARK re-farm). The script is Area2D. `scenes/props/puzzle.tscn` is not instanced by any district. The live switch does not call `toggle_district`.
- Shop `bundle_contents` cycle. `bundle_starter.tres` points at a skin and an upgrade, not at itself. No recursive grant in the catalog.
- `district_blackout`. Only `scripts/world/streetlight.gd` (PointLight2D) listens. The 3D streets do not. Random events emit a signal nothing in the 3D world applies. Not a progression break.
- Locale switch mid-interaction. Pause → Settings can change language. `interactor.gd` emits the prompt only when the target node changes, and the switch Label3D is set once in `_build_visual`. Result is a stale string, not a null ref or a dead state. `settings_screen.gd` `queue_free`s its children from `language_changed`; `queue_free` is deferred, so that is not a use-after-free by itself.
- IntegrityGuard is not an autoload. Nothing in the live tree watches the park position.

## Runtime scenarios for the lead

| id | seed / setup | input | pass looks like | fail looks like |
|---|---|---|---|---|
| B1 | all districts FULL, player in suburbs | city-map Travel to power_station | one boss, parent not queued for deletion, `boss_defeated` reachable | boss group empty after the idle frame |
| B2 | fresh suburbs | walk into the first document | `document_id` set before `_ready` logic, `count_docs` increments, no respawn on re-enter | id `""`, count unchanged, note is back next visit |
| B3 | one rank of `move_speed` | pause → Restart, twice | walk_speed stays 187 | 187 then 205.7 then 226 |
| B8 | wallet at 0 | one kill | wallet ≥ 5, HUD equals wallet | wallet 0, HUD shows 5–15 |
| B9 | 12/12 slots | interact `secret_industrial_02` | secret remains, `is_secret_found` false | secret gone, id recorded, no `backpack_l1` |
| B10 | move off spawn, travel, quit | Continue | player at the new spawn | player at the pre-travel coordinate inside the new district |
| B15 | windowed New Game | log Y until `streets_ready` | `is_on_floor` before Y < 0 | Y past the road, `_last_grounded_pos` still ZERO, no teleport |
| Q1 | windowed, QA_SEED=1, travel to park | split validity from position | finite position, node valid | node invalid (the heartbeat INF) or finite negative Y (B15) |
