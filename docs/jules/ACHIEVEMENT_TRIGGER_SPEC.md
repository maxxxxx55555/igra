# ACHIEVEMENT TRIGGER SPECIFICATION (EXPANSION TO 50+)

This document specifies 19 new genuine achievement specs (ach_21 through ach_39) to expand the roster from 31 shipped achievements to 50 total per GDD §21 recommendations.

No GDScript code edits are made in this spec pass. All proposals cite file:line event triggers, precise unlock conditions, numeric thresholds, and complete i18n key expansion plans across all 13 supported locales (`en`, `ru`, `fr`, `de`, `es`, `it`, `pt_BR`, `tr`, `ja`, `ko`, `zh`, `zh_TW`, `ar`).

---

## 1. Specification Table (19 New Achievements)

| ID | Title Key | Description Key | Signal / Source Event | File:Line Source | Threshold / Condition | Secret |
|---|---|---|---|---|---|---|
| `ach_21` | `ACH_21_NAME` | `ACH_21_DESC` | `EventBus.item_crafted` | `scripts/ui/workbench.gd:95` | Craft 20 items at workbench | False |
| `ach_22` | `ACH_22_NAME` | `ACH_22_DESC` | `EventBus.battery_used` | `scripts/player/player_3d.gd:910` | Recharge flashlight 30 times | False |
| `ach_23` | `ACH_23_NAME` | `ACH_23_DESC` | `EventBus.medkit_used` | `scripts/player/player_3d.gd:905` | Use 15 medkits | False |
| `ach_24` | `ACH_24_NAME` | `ACH_24_DESC` | `EventBus.stealth_moved` | `scripts/player/player_3d.gd:420` | Move 500m in stealth crouch | False |
| `ach_25` | `ACH_25_NAME` | `ACH_25_DESC` | `EventBus.enemy_killed_by_weapon` | `scripts/weapons/weapon_pistol.gd:50` | Kill 30 enemies with Pistol | False |
| `ach_26` | `ACH_26_NAME` | `ACH_26_DESC` | `EventBus.enemy_killed_by_weapon` | `scripts/weapons/weapon_shotgun.gd:62` | Kill 25 enemies with Shotgun | False |
| `ach_27` | `ACH_27_NAME` | `ACH_27_DESC` | `EventBus.enemy_killed_by_weapon` | `scripts/weapons/weapon_rifle.gd:58` | Kill 20 enemies with Rifle | False |
| `ach_28` | `ACH_28_NAME` | `ACH_28_DESC` | `EventBus.attack_dodged` | `scripts/player/player_3d.gd:580` | Perfect dodge 25 enemy attacks | False |
| `ach_29` | `ACH_29_NAME` | `ACH_29_DESC` | `EventBus.secret_found` | `scripts/world/district_loot.gd:180` | Find 10 district secrets | False |
| `ach_30` | `ACH_30_NAME` | `ACH_30_DESC` | `EventBus.secret_found` | `scripts/world/district_loot.gd:180` | Find all 26 district secrets | True |
| `ach_31` | `ACH_31_NAME` | `ACH_31_DESC` | `EventBus.daily_completed` | `scripts/systems/daily_challenge_manager.gd:75` | Complete 7 daily challenges | False |
| `ach_32` | `ACH_32_NAME` | `ACH_32_DESC` | `EventBus.daily_completed` | `scripts/systems/daily_challenge_manager.gd:80` | Reach 30-day challenge streak | True |
| `ach_33` | `ACH_33_NAME` | `ACH_33_DESC` | `EventBus.puzzle_solved` | `scripts/systems/puzzle_system.gd:45` | Solve 5 district power puzzles | False |
| `ach_34` | `ACH_34_NAME` | `ACH_34_DESC` | `EventBus.radio_channel_tuned` | `scripts/props/radio.gd:65` | Listen to 5 radio broadcasts | False |
| `ach_35` | `ACH_35_NAME` | `ACH_35_DESC` | `EventBus.skill_unlocked` | `scripts/systems/skill_tree_manager.gd:110` | Max out 1 skill tree branch | False |
| `ach_36` | `ACH_36_NAME` | `ACH_36_DESC` | `EventBus.coin_balance_changed` | `scripts/monetization/coin_wallet.gd:35` | Accumulate 10,000 coins | False |
| `ach_37` | `ACH_37_NAME` | `ACH_37_DESC` | `EventBus.streetlight_activated` | `scripts/world/power_grid.gd:66` | Activate 50 streetlights | False |
| `ach_38` | `ACH_38_NAME` | `ACH_38_DESC` | `EventBus.weather_changed` | `scripts/systems/weather_system.gd:90` | Experience 10 severe weather events | False |
| `ach_39` | `ACH_39_NAME` | `ACH_39_DESC` | `EventBus.district_blackout` | `scripts/systems/random_events.gd:70` | Restore power during a blackout | True |

---

## 2. i18n Localization Plan (38 Keys per Locale x 13 Locales = 494 Strings)

### Sample Key Mappings (EN / RU Reference):
- `ACH_21_NAME`: "Master Crafter" / "Мастер на все руки"
- `ACH_21_DESC`: "Craft 20 items at any workbench." / "Создайте 20 предметов на верстаке."
- `ACH_22_NAME`: "Energized" / "Энергетик"
- `ACH_22_DESC`: "Recharge flashlight battery 30 times." / "Замените батарейку фонарика 30 раз."
- `ACH_23_NAME`: "Field Medic" / "Полевой медик"
- `ACH_23_DESC`: "Use 15 medical kits." / "Используйте 15 аптечек."
- `ACH_24_NAME`: "Shadow Walker" / "Идущий в тени"
- `ACH_24_DESC`: "Crouch-walk 500 meters undetected." / "Пройдите 500 метров на корточках незамеченным."
- `ACH_25_NAME`: "Gunslinger" / "Стрелок"
- `ACH_25_DESC`: "Eliminate 30 enemies with the Pistol." / "Уничтожьте 30 врагов из пистолета."
- `ACH_26_NAME`: "Close Quarters" / "Ближний бой"
- `ACH_26_DESC`: "Eliminate 25 enemies with the Shotgun." / "Уничтожьте 25 врагов из дробовика."
- `ACH_27_NAME`: "Sharpshooter" / "Снайпер"
- `ACH_27_DESC`: "Eliminate 20 enemies with the Rifle." / "Уничтожьте 20 врагов из винтовки."
- `ACH_28_NAME`: "Evasive" / "Уклонение"
- `ACH_28_DESC`: "Perform 25 perfect dodges against enemy attacks." / "Совершите 25 идеальных уклонений от атак."
- `ACH_29_NAME`: "Curious Explorer" / "Любопытный исследователь"
- `ACH_29_DESC`: "Find 10 hidden secrets across districts." / "Найдите 10 секретов в районах города."
- `ACH_30_NAME`: "Master Seeker" / "Искатель истины"
- `ACH_30_DESC`: "Find all 26 hidden secrets in the city." / "Найдите все 26 секретов в городе."
- `ACH_31_NAME`: "Routine" / "Рутина"
- `ACH_31_DESC`: "Complete 7 daily challenges." / "Выполните 7 ежедневных испытаний."
- `ACH_32_NAME`: "Dedicated" / "Преданный делу"
- `ACH_32_DESC`: "Maintain a 30-day streak in daily challenges." / "Поддерживайте 30-дневную серию испытаний."
- `ACH_33_NAME`: "Grid Engineer" / "Инженер сетей"
- `ACH_33_DESC`: "Solve 5 power grid puzzles." / "Решите 5 головоломок электросети."
- `ACH_34_NAME`: "On The Air" / "В эфире"
- `ACH_34_DESC`: "Listen to 5 distinct radio broadcasts." / "Прослушайте 5 радиопередач."
- `ACH_35_NAME`: "Specialist" / "Специалист"
- `ACH_35_DESC`: "Unlock all skills in a single skill tree branch." / "Откройте все навыки в одной ветке."
- `ACH_36_NAME`: "Wealthy" / "Богач"
- `ACH_36_DESC`: "Accumulate 10,000 total coins." / "Накопите 10 000 монет."
- `ACH_37_NAME`: "Lightbringer" / "Несущий свет"
- `ACH_37_DESC`: "Activate 50 streetlights." / "Зажгите 50 уличных фонарей."
- `ACH_38_NAME`: "Storm Survivor" / "Сквозь бурю"
- `ACH_38_DESC`: "Survive through 10 severe weather cycles." / "Переживите 10 циклов непогоды."
- `ACH_39_NAME`: "Overcoming Pitch Black" / "Побеждая тьму"
- `ACH_39_DESC`: "Restore a district's power during an active blackout." / "Восстановите питание района во время блэкаута."

---

## 3. Implementation Blueprint for Future Code Waves
When code modifications are authorized in future waves, `scripts/systems/achievements_manager.gd` should add these 19 dict entries to `ACHIEVEMENTS` constant and register listeners for the respective `EventBus` signals. All 13 translation files in `data/i18n/*.json` will receive the 38 key-value pairs listed above.
