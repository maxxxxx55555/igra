# NEW GAME+ (NG+) CARRY-OVER & MODIFIER MATRIX

This document details what state carries over versus resets across New Game+ cycles, derived from code truth in `scripts/systems/new_game_plus.gd`, `scripts/systems/progress_tracker.gd`, and `scripts/core/save_system.gd`.

---

## 1. Carry-Over vs Reset Matrix Per NG+ Cycle

| Game State / System | Behavior on NG+ Cycle Transition | Implementation / Source Code Truth |
|---|---|---|
| **NG+ Level & Active Modifiers** | **Carried Over** | Stored in `user://ng_plus_data.json` signed envelope (`NewGamePlus._save_save()`). |
| **Banked Runs Ledger** | **Carried Over** | Up to 64 `run_id` hashes banked in `NewGamePlus._banked_runs` to prevent double-dipping NG+ level grants from pre-boss saves. |
| **Player Coins & Shop Purchases** | **Carried Over** | `CoinWallet` and `ShopService` data preserved across NG+ transition (`NewGamePlusUI.gd:129` calls `activate_ng_plus()` without wiping wallet). |
| **Unlocked Weapons & Blueprints** | **Carried Over** | `ProgressTracker._weapons` and `_blueprints` preserved across cycles. |
| **Player Stats, Skills & XP** | **Carried Over** | `XpManager` and `SkillTreeManager` preserve purchased upgrades and player level. |
| **Lore Documents & Secrets** | **Carried Over** | `ProgressTracker._docs` and `_secrets` preserved across cycles. |
| **District Power Grid Stages** | **RESET to DARK (Stage 0)** | `PowerGrid.reset()` called on starting a new run. All 11 districts return to Stage 0. |
| **Quests & Story Progression** | **RESET** | `QuestManager.reset()` called on starting new cycle. All 19 quests reset to initial state. |
| **Inventory Scrap / Consumables** | **RESET** | `InventoryManager.from_dict({})` clears active inventory slots upon new cycle start. |
| **Player World Position & Vitals** | **RESET to District Spawn** | `SaveSystem._pending_player_pos` reset to `Vector3.INF` and vitals restored to full. |

---

## 2. NG+ Modifier Knobs Consumption & Status Audit

`content/ngp_modifiers.json` defines 11 modifier effect knobs. All 11 knobs are verified fully consumed in GDScript logic:

| Knob Name | Modifiers Using Knob | Target System / GDScript Consumer | File:Line Citation | Status |
|---|---|---|---|---|
| `battery` | `long_night` | `scripts/player/player_3d.gd` (Flashlight drain rate) | `scripts/player/player_3d.gd:867` | CONSUMED |
| `hunter_hearing` | `whisper` | `scripts/systems/noise_propagation.gd` & `base_monster.gd` | `scripts/systems/noise_propagation.gd:21` | CONSUMED |
| `loot` | `whisper` | `scripts/systems/new_game_plus.gd` & `base_monster.gd` | `scripts/systems/new_game_plus.gd:163` | CONSUMED |
| `extra_dark_districts` | `blackout_plus` | `scripts/systems/random_events.gd` (Blackout event scope) | `scripts/systems/random_events.gd:38` | CONSUMED |
| `lore` | `keepers_pact` | `scripts/systems/xp_manager.gd` (Document XP boost) | `scripts/systems/xp_manager.gd:44` | CONSUMED |
| `hints` | `keepers_pact` | `scripts/ui/hud_3d.gd` & `NewGamePlus.are_hints_enabled()` | `scripts/ui/hud_3d.gd:1303` | CONSUMED |
| `cycle` | `sprint` | `scripts/systems/day_night.gd` (Night cycle length) | `scripts/systems/day_night.gd:25` | CONSUMED |
| `rewards` | `sprint` | `scripts/economy/rewards_manager.gd` & `base_monster.gd` | `scripts/economy/rewards_manager.gd:15` | CONSUMED |
| `time_pressure` | `sprint` | `scripts/ui/daily_events_ui.gd` | `scripts/ui/daily_events_ui.gd:38` | CONSUMED |
| `crawlers_ignore` | `ghost` | `scripts/enemies/base_monster.gd` (Crawler aggro check) | `scripts/enemies/base_monster.gd:544` | CONSUMED |
| `achievements` | `ghost` | `scripts/systems/achievements_manager.gd` | `scripts/systems/achievements_manager.gd:243` | CONSUMED |

---

## 3. Findings Classification Summary

All 11 modifier knobs are actively consumed in code as of HEAD. There are zero unconsumed modifier knobs remaining in `ngp_modifiers.json`.
