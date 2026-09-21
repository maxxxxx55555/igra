# TZ compliance audit

Date: 2026-09-21. Static read only. No engine, no gate run, no stills.

**TZ** is `docs/GDD.md` (канон v4). `PLAN.md:4` names it «ТЗ, 844 строки, канон механик/чисел». Header (`docs/GDD.md:3-6`) says this file wins over appendices. A row is scored only against a sentence in that file. Anything this pass believes should be in the TZ but is not, is **EXTRA**, not a verdict.

§25.1 checkboxes are self-claims, not evidence. Old `docs/GDD_CONFORMANCE.md` (2026-08-08, Windows paths) was not reused.

## Legend

| Verdict | Meaning |
|---|---|
| MET | Quoted sentence matches current file:line. |
| GAP-DEV | Code or content contradicts the quote. A dev can change it without an owner rewrite of the TZ. |
| GAP-OWNER | Owner must amend the TZ, sign a device/keystore, or pick between two TZ sentences that conflict. |
| BY-DESIGN | A later sentence in the same TZ authorizes the deviation. |
| EXTRA | Not a TZ requirement. Listed so it is not mistaken for one. |

Line numbers are the file on this branch. Quotes are verbatim.

## Summary

| Area | MET | GAP-DEV | GAP-OWNER | BY-DESIGN |
|---|---:|---:|---:|---:|
| Gameplay | 6 | 27 | 1 | 1 |
| Stealth | 2 | 4 | 0 | 0 |
| NG+ | 0 | 0 | 1 | 0 |
| Districts | 3 | 2 | 1 | 0 |
| Economy | 2 | 2 | 0 | 1 |
| Audio | 0 | 4 | 0 | 0 |
| Visual | 2 | 4 | 0 | 1 |
| i18n | 1 | 0 | 1 | 0 |
| Accessibility | 3 | 3 | 0 | 0 |
| Store | 0 | 1 | 1 | 0 |
| Security | 1 | 0 | 0 | 0 |
| Perf / size | 0 | 2 | 0 | 0 |

Keeper-voice defects are a quality list under i18n. They are not TZ verdicts: the TZ has no Keeper-voice spec.

Riskiest wrong assumption, corrected in the same pass: that `district_grading.gd` or `DayNight` paints the live sky. Neither binds a `WorldEnvironment` (no `world_environment` group; `DayNight` also looks for `Main/WorldEnvironment`, and the play scene is `Main3D`). The live writer is `scripts/world_env_setup.gd`.

---

## Gameplay

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| G01 | `FPS — канон, TPS — опция` — `player_fps.tscn` (основной, камера в глазах), `player_3d.gd` (вид от третьего лица, опционально) | 17 | No `scenes/player/player_fps.tscn` (`scenes/player/` is `player.tscn`, `player_3d.tscn` only). Live camera is a sibling `Camera3D` on `scenes/main_3d.tscn:54-62` with `fps_mode = true`, `fov = 80.0`, `fps_eye_height = 1.7`. `scripts/core/camera_follow_3d.gd:58-64` places it at eye height when `fps_mode` is true. | GAP-DEV |
| G02 | Хедбоб: лёгкое покачивание при беге (0.1, не выше — укачивание). | 45 | No `headbob` / `head_bob` / `bob` in `scripts/player/` or `scripts/core/camera_follow_3d.gd`. | GAP-DEV |
| G03 | FOV 80° (base), кратковременно +5° при спринте. | 46 | Base FOV is 80 on `scenes/main_3d.tscn:57`, copied into `fov_deg` because it is not 75 (`scripts/core/camera_follow_3d.gd:35-36`). No sprint `+5` FOV. `wow_director.gd:81-86` adds FOV only on scripted beats, and subtracts it. | GAP-DEV |
| G04 | RayCast3D от камеры (длина 3 м) — взаимодействие с объектами. | 48 | Only ray on the player scene is `GroundRay` `target_position = Vector3(0, -2, 0)` (`scenes/player/player_3d.tscn:216-218`). `scripts/player/interactor.gd` has no 3 m length. | GAP-DEV |
| G05 | Coyote time 0.1 s, jump buffer 0.1 s. | 67 | `scripts/player/player_3d.gd:16-17` exports both at `0.1`. | MET |
| G06 | Спринт: скорость ×1.6, шум выше (см. §7). | 68 | `data/balance/player_stats.tres` `walk_speed = 170.0`, `run_speed = 300.0` (×1.76). `player_3d.gd:667-674` uses those speeds directly. No ×1.6 multiplier. | GAP-DEV |
| G07 | Crouch: скорость ×0.4, шум ×0.3, видимость ×0.5, высота капсулы 1.2 м. | 69 | Speed ×0.4 is applied (`player_3d.gd:87`, `:538`). `CROUCH_NOISE_MULT` / `CROUCH_VISIBILITY_MULT` are declared at `:88-89` and never read. Capsule in scene is `height = 1.8` (`scenes/player/player_3d.tscn:8-9`), not a 1.2 m crouch capsule. | GAP-DEV |
| G08 | конус 45°, дальность 8 м, цвет `#c9a24a`, energy 2.0, shadow 1024² (опц. на mobile — без теней). | 76-77 | Shipped light: `scenes/player/player_3d.tscn:179-185` `light_color = Color(1.0, 0.82, 0.48)`, `spot_angle = 35.0`, `spot_range = 16.0`, `light_energy = 24.0`, `shadow_enabled = false`. Runtime sets 45° / 8 m only inside `apply_flashlight_upgrades()` (`player_3d.gd:1104-1136`), which returns immediately if `levels` is empty (`:1098-1099`). Mobile may drop shadows (`:241-243`); desktop still starts from the scene's `shadow_enabled = false`. | GAP-DEV |
| G09 | Расход: 1%/2 с (конус включён), 0 в выключенном. | 83 | `player_3d.gd:96` `BATTERY_DRAIN_PER_SEC = 100.0 / 450.0` (1% per 4.5 s). `data/balance/flashlight_stats.tres` `drain_per_sec = 2.2` is a second, unused-by-that-const drain. | GAP-DEV |
| G10 | Батарейка (предмет): +25% заряда. | 84 | `data/items/battery.tres` `effect_value = 35.0`. | GAP-DEV |
| G11 | L1…L5 … Цена 100 / 250 / 500 / 1000 / 2000. Максимум: 19 250 монет на все ветки L5. | 90-95 | `scripts/systems/flashlight_upgrade_manager.gd:32-36` uses that column on all five branches. | MET |
| G12 | Стробоскоп (чертёж): двойной тап по кнопке фонарика — STUN врагов в конусе 1.5 s, кд 10 s. | 80 | `player_3d.gd:840-841` `STROBE_COOLDOWN = 10.0`, `STROBE_STUN = 1.5`. | MET |
| G12b | Мерцание при заряде <20% (убирается апгрейдом «Стабильность» L5). | 79 | `data/balance/flashlight_stats.tres` `flicker_battery_threshold = 30.0`. No reader of an L5 stability upgrade clears that threshold on the live drain path. | GAP-DEV |
| G13 | 1 Jab … 8 … / 2 Cross … 12 … / 3 Slam … 20 … knockback 1.5 м. Окно комбо 1.2 s. | 129-132 | Timings and window match (`player_3d.gd:79-83`). Damage is 14 / 21 / 35 (`:79-81`). Knockback 1.5 matches. Flashlight +25% and backstab ×1.5 are at `:974` and `:980`. | GAP-DEV |
| G14 | 15 стамины. I-frames 0.35 s, кд 0.8 s. | 138 | `player_3d.gd:84-86` `DODGE_COST = 15.0`, `DODGE_IFRAMES = 0.35`, `DODGE_COOLDOWN = 0.8`. | MET |
| G15 | Capsule (r 0.3, h 1.6). Атака: Box 0.6×0.4×1.2 м перед камерой | 141 | Capsule radius 0.3 matches, height is 1.8 (`player_3d.tscn:8-9`). Attack box is `Vector3(1.4, 0.8, 3.4)` (`player_3d.gd:296`). | GAP-DEV |
| G16 | Респавн: на последний активный фонарь/вход района, HP 50%, батарея не восстанавливается. | 147 | `scripts/core/game_manager.gd:59-69` restores 50% HP in place, and the comment says it does not move the player to a lamp. Battery non-restore was not contradicted in that function. | GAP-DEV |
| G17 | Hardcore (настройка): 1 жизнь, смерть = удаление сейва. | 148 | Toggle is stored (`settings_manager.gd:71`, `settings_screen.gd:95`). No reader in `scripts/core/`, `scripts/player/`, or the death scripts deletes a save. | GAP-DEV |
| G18 | Канонический ростер = **11 вражеских типов + 1 босс** (Architect). | 160 | `scripts/enemies/enemy_roster_data.gd:13-17` aliases `hunter→runner`, `destroyer→armored`, `watcher→sniper`, `crawler→dog`, `boss→beast`. There is no `&"shadow"` key. `&"sniper"` is commented as Watcher stats (hp 80 / damage 12) at `:73-79`; `&"sharpshooter"` holds the Sniper numbers (`:119-120`). | GAP-DEV |
| G19 | Shadow \| 30 \| 15 \| 1.2× \| 0 м (слух 15 м) | 170 | No Shadow row in `enemy_roster_data.gd`. The alias map does not include it. | GAP-DEV |
| G20 | Фаза 2 (70–30%): невидим в темноте (виден только в конусе), призыв Shadow ×3. | 191 | `scripts/enemies/boss_3d.gd:49` uses `ratio > 0.33`, not 0.30. Phase-2 dark-invisibility is at `:216`. Emission is `Color(1.0, 0.3, 1.0)` (`:283`) — V02. | GAP-DEV |
| G21 | Усиленная батарея \| 2 батарейки + 1 кабель … Стробоскоп \| 2 предохранителя + 1 трансформатор … Батарея L2 \| … \| D9 цех | 237-241 | Live bench is `scripts/ui/workbench.gd:14-23`: medkit, battery (1 cable + 1 fuse), noise_bomb, lockpick, repair_kit, firework, molotov, makeshift_lamp. None of the five §9 blueprints. District notes record the same absence (`content/districts/police/item_spawns.json` comment: no strobe blueprint id; industrial note: no `blueprint_battery_l2`). | GAP-DEV |
| G22 | Слоты: 3 ручных + 1 автосейв. Формат: `.tres` … или JSON. | 247 | Slot API writes `user://tls_savegame_slot%d.save` (`save_system.gd:89`, `:414-415`) as JSON (`:122-128`). Comment at `:427-428` says the slot UI is archived and unreachable. Format "or JSON" allows JSON, so the format half is not a gap. Reachable 3+1 UI is. | GAP-DEV |
| G23 | `damage` 25 (переопределяемый); `fire_rate` 0.15 s; `range` 50 м; `max_ammo` 30; `reload_time` 2.0 s; `spread` 0.02; `recoil` 0.5 | 485-491 | `scripts/weapons/weapon_base.gd:9-15` matches those seven numbers. | MET |
| G24 | Точка невозврата: вход в D10. | 341 | No `no_return` / point-of-no-return gate in `scripts/world/power_grid.gd` or `finale_director.gd`. | GAP-DEV |
| G25 | 6 слотов на HUD … Слоты: оружие×2, батарея, аптечка, граната, особый предмет. Клавиши ПК: 1–6 | 595-598 | Input actions `quick_slot_1`…`6` exist (`project.godot`, FUNCTION_MATRIX IN75–IN80). Contents are hardcoded `&"flashlight", &"battery", &"medkit", &"key", &"cable", &"fuse"` (`scripts/ui/hud_3d.gd:7`), not the weapon/grenade loadout. | GAP-DEV |
| G26 | Коллекция: 200 фото … «Фотограф» за 50, «Искатель» за 100, «Коллекционер» за 200. | 601 and §24.2 | `scripts/ui/photo_album.gd` shows whatever `SaveSystem.get_photos()` returns. Achievement condition found is `photos_10` (`achievements_manager.gd:67`), not 50/100/200. | GAP-DEV |
| G27 | Левая половина экрана \| Drag = поворот камеры | 53 | `player_3d.gd:387` `JOY_ZONE_RATIO = 0.35`, not a half-screen drag zone. Double-tap dodge exists (`:448-449`). Pinch zoom is marked `(опц.)` at TZ:59, so its absence is not a gap. | GAP-DEV |
| G28 | Все 11 районов FULL → `GameManager.trigger_win()` → концовка (§12.4). | 119 | `power_grid.gd:76-87` refuses to call `trigger_win()` when the last district hits FULL, so the Architect fight is not skipped. `trigger_win()` still exists (`game_manager.gd:142`) as a fallback if `FinaleDirector` is missing. Conflicts with G20 / §12.3 (the boss is required). | GAP-OWNER |
| G29 | Пиныч (двумя пальцами) \| Зум камеры (опц.) | 59 | Optional. Not required. | BY-DESIGN |
| G30 | Свет (хорошая) \| 11 районов FULL + все документы | 346 | `endings_manager.gd:122-123` returns `light` when `full >= total and all_docs`. | MET |
| G31 | Надежда \| 11 районов FULL, <50% документов | 347 | Same function returns `hope` for any missing docs once the grid is full (`:125-126`), including 51–99%. | GAP-DEV |
| G32 | Выживший \| только D11 | 348 | Survivor is returned only on the death path, and only if the station is FULL and the grid is not (`:111-113`). A living "only D11" ending is not reached; the comment at `:120-121` says the win path fires after `all_restored()`. | GAP-DEV |
| G33 | Тьма (плохая) \| смерть/не починена сеть | 349 | Death before the grid is whole returns `dark` (`:114`). An unrepaired grid with the player still alive does not resolve to this ending. | GAP-DEV |
| G34 | Истина (секрет) \| все документы + аудио-логи + фото + бункер D11 | 350 | `progress_tracker.gd:104-114` aliases audio-logs and photos to "all documents", and the bunker to `power_station` FULL. Three counters are one counter. | GAP-DEV |

---

## Stealth

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| S01 | Источники шума: бег 8 м/0.8, удар 5 м/1.0, dodge 3 м/0.4, перегруз (>35 кг) +30%. | 210 | Run radius 8.0 is set (`player_3d.gd:531`). Walk is 3.0, crouch 0.5, stealth 1.0 (`:529-532`). No hit 5 m or dodge 3 m branch. Overload +0.3 when `weight_ratio > 0.875` against a 40 kg cap (`:508-510`) matches >35 kg and +30%. The `0.8` is used as a noise intensity (`:515`), not a duration. | GAP-DEV |
| S02 | Видимость: в конусе фонарика +100%, в тьме 3 м, за стеной 0%, бег +20%. | 212 | Not implemented as those four modifiers. Crouch visibility constant is unread (G07). | GAP-DEV |
| S03 | Индикатор: пульсация ember-виньетки по краю (не число). | 213 | Vignette exists (`hud_3d.gd:85` connects it to `player_health_changed`, a damage flash), not to noise. | GAP-DEV |
| S04 | Hiding spots: шкафы, кусты, багажники, тёмные углы. … монстр ищет 10 s в радиусе 5 м | 214-215 | `scripts/gameplay/hiding_spot.gd:8-16` types are locker / dumpster / car / crate. No bush, no dark corner, no 10 s / 5 m search. `enter_radius = 2.0`. | GAP-DEV |
| S05 | бег 8 м | 210 (radius half of S01) | `player_3d.gd:531` `State.RUN: noise_radius = 8.0`. Scored separately so the one matching number is not buried. | MET |
| S06 | перегруз (>35 кг) +30% | 210 | `player_3d.gd:508-510`. | MET |

---

## NG+

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| N01 | `[x] LAN discovery/multiplayer, New Game+, tutorial` | 652 | This is a status checkbox, not a rule. `scripts/systems/new_game_plus.gd` exists and is an autoload. The TZ never states carryover, modifier list, or difficulty curve. | GAP-OWNER |

EXTRA: modifier knobs in `content/ngp_modifiers.json` and `new_game_plus.gd:84-138` (including a night-cycle multiplier consumed by `day_night.gd:22-23`) are not TZ requirements. Do not treat a missing knob as a TZ gap, and do not treat a shipped knob as compliance.

---

## Districts

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| D01 | `suburbs → residential → park → school → hospital → gas_station → police → warehouses → industrial → substation → power_station` | 102-103 | `scripts/world/power_grid.gd:8-18` preloads that order. Eleven `data/districts/district_*.tres` files exist. | MET |
| D02 | Район открыт, если все его пререквизиты (`powered_by`) в FULL — иначе `FIRST_RESTORE`-подсказка. | 114 | `power_grid.gd:36-37` and `:52-54` refuse advance and emit `FIRST_RESTORE` when a parent is not FULL. The graph does not match D01: `district_park.tres` `powered_by = [&"suburbs"]`; `district_police.tres` `powered_by = [&"park"]`; `district_warehouses.tres` `powered_by = [&"hospital"]`. | GAP-DEV |
| D03 | DARK … ambient 0.03, луна 0.12 … STREETS … ambient 0.11, луна 0.25 … FULL … ambient 0.16, луна 0.40 | 108-111 | Live path `scripts/world_env_setup.gd:17-24` and `:111-127`: DARK/PARTIAL share ambient 0.12 / moon 0.09; STREETS 0.20 / 0.14; FULL 0.30 / 0.20. File comment `:5-8` says the old 0.01/0.03 black was rejected as unplayable. `district_grading.gd:19` still holds `[0.03, 0.06, 0.11, 0.16]` but its environment export is never set (`world_env_setup.gd:211-216`). | GAP-DEV |
| D04 | Все 11 районов FULL → `GameManager.trigger_win()` → концовка (§12.4). | 119 | Same conflict as G28. Counted here because this sentence is the district rule. | GAP-OWNER |
| D05 | Мир \| Единая карта из 11 районов. НЕ процедурный, НЕ бесконечный | 20 | Eleven authored district resources, fixed preload list. No procedural generator on that path. | MET |
| D06 | Переключатели `PowerSwitch` и пазлы: `toggle_district` = STREETS ↔ DARK. | 116 | `scripts/world/power_grid.gd:94` `toggle_district()` switches STREETS and DARK. | MET |

---

## Economy

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| E01 | НЕТ голода, НЕТ pay-to-win. Донат = только пополнение монет. | 223 | No live hunger consumer. `scripts/ui/inventory_system.gd:21-23` defines `can_food` effect `hunger` and `water` effect `thirst`, but `inventory_panel.tscn` is not instanced from any other scene. Shop prices are coins (`coin_wallet.gd`). Ads add coins (E03), which the same sentence allows. | MET |
| E02 | голод/жажда — OUT на любой майлстоун | 224 | Authorizes E01. The dead panel must not be wired. | BY-DESIGN |
| E03 | «Смотреть рекламу» (+100 монет) или «Пропустить» (−100 монет). … Кулдаун: 1 реклама в час. | 614-616 | `scripts/monetization/ad_service.gd:23` `bonus_coins = 100`. No skip penalty of −100. `COOLDOWN_SEC = 900.0` (`:27`), 15 minutes, not one hour. | GAP-DEV |
| E04 | L1…L5 prices 100/250/500/1000/2000, sum 19 250 | 90-95 | Same evidence as G11. | MET |
| E05 | Кривая: 0–200 монет D1 → 8000+ к D11 | 214 | Not re-measured this pass (no play). Not scored MET. No static curve table was found that states those two endpoints. | GAP-DEV |

---

## Audio

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| A01 | Шины: `Master → Music \| SFX (Footsteps, Combat, UI, Environment) \| Voice`. | 358 | `default_bus_layout.tres:15-53`: Master, Music, SFX, Voice, Ambient, UI. UI and Ambient are siblings of SFX, not children. No Footsteps / Combat / Environment buses. | GAP-DEV |
| A02 | адаптивные слои (crossfade 2 s): Ambient_Dark … Ambient_Lit … Threat_Low … Threat_High … Action_Sting | 359-362 | Five layer files are wired (`scripts/systems/music_manager.gd:96-100`). `FADE_TIME = 2.2` (`:118`), not 2.0. | GAP-DEV |
| A03 | Футстепы: 6 поверхностей × 3 скорости (афальт/бетон/дерево/металл/лужа/стекло), RayCast3D вниз определяет поверхность. | 366-367 | No surface match on those six names in `player_3d.gd` or `audio_manager.gd`. The only downward ray is `GroundRay` at −2 m (`player_3d.tscn:216-218`), ground contact, not a surface id. | GAP-DEV |
| A04 | Объём: <50 МБ SFX, <100 МБ музыка. | 371 | `assets/audio/music` 38M (under 100). `sfx` 6.6M + `ambience` 47M + `one_shots` 1.1M ≈ 55M, over the 50M SFX cap if ambience counts as non-music. `assets/audio/_pre_norm` is 162M and is in `export_presets.cfg` `exclude_filter`, so it is not in the package. | GAP-DEV |
| A05 | без мелодичных тем, только слои, дроны, ударные биения и шумовые текстуры. | 363-364 | Five named layer files are wired (A02). They were not listened to this pass, so style is not scored MET. Presence of the layer set is what A02 scores. This sentence's "без мелодичных тем" is unverified by ear and is not upgraded. | EXTRA |
| A06 | Tonemap is visual. Music bus playback is not a TZ sentence. | — | `FUNCTION_MATRIX` AL34 records a Music-bus probe. Not a TZ row. | EXTRA |

---

## Visual

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| V01 | Дня нет. … DARK: почти pitch-black (ambient 0.03, луна 0.12) | 261-263 | Live numbers are V-contradicted by D03. `DayNight` (`day_night.gd:36-42`) would lerp the sky toward `Color(0.55, 0.70, 0.90)` and ambient up to 0.60, but it never finds an environment (no group, wrong node path). It is latent, not the current frame. | GAP-DEV |
| V02 | Запрет: чистые `#000`/`#fff`, неон, кислотные цвета | 280 | Boss mesh emission `Color(1.0, 0.3, 1.0)` (`boss_3d.gd:283`). `wow_director.gd:19` uses `Color.WHITE` on the explosion beat (alpha is 0, so it may not draw; the token is still the banned white). | GAP-DEV |
| V03 | Bebas Neue Bold + Roboto Condensed — основные | 283 | `project.godot:137` theme is `assets/ui/theme_tls.tres`, which loads `BebasNeue-Regular.ttf`, `RobotoCondensed-Regular.ttf`, `ShareTechMono-Regular.ttf`. Bold file is not the one wired. `Rajdhani-Regular.ttf` is on disk and not in the theme, which matches the `[вижн]` stored-not-used line. | GAP-DEV |
| V04 | Tonemap ACES … Depth fog `#1a2133` (density 0.012–0.015). SSAO/SSIL/Volumetric — ВЫКЛ на mobile. | 315-316 | `world_env_setup.gd:60-65` SSAO/SSIL/volumetric off, fog density 0.012, fog color `#1a2133`. Tonemap defaults to `TONE_MAPPER_ACES` (`:174`). Renderer is `gl_compatibility` (`project.godot:304-305`). | MET |
| V05 | Moon shadow 2048² (вкл). | 317 | Moon shadow is enabled (`world_env_setup.gd:80`). Atlas size is 1024 (`project.godot:306`). | GAP-DEV |
| V06 | Луч фонарика: SpotLight3D + аддитивный конус-меш (blend_add, unshaded). | 317 | `scenes/player/player_3d.tscn:61` cone shader `blend_add, unshaded, shadows_disabled`. SpotLight exists on the same scene. | MET |
| V07 | bg-deep `#0c1016` … brass `#c9a24a` … ember `#b4452f` | 11.2 table | Not scored token-by-token. `scripts/ui/theme_provider.gd:19` has ember `#b4452f`. A full token audit was not completed; absence of a row is not a MET. | EXTRA |
| V08 | Chakra/Saira/Rajdhani — `[вижн]` (stored, не подключается к Theme) | 11.3 | Rajdhani is on disk and not in `theme_tls.tres`. | BY-DESIGN |

`docs/GAMEFEEL_SPEC.md` hit-stop / shake caps and `docs/VISUAL_PASS.md` W2–W10 wiring are not TZ sentences. EXTRA. `docs/STYLE_GUIDE.md:4` says when the guide and the art disagree, the art wins — that is a local authoring rule, not a TZ amendment. The TZ still wins (`GDD.md:3-6`).

---

## i18n

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| I01 | 13 языков через I18n: RU (основной), EN, TR, ZH, ZH_TW, DE, FR, ES, pt_BR, IT, ar, JA, KO. | 22 | `data/i18n/` has those 13 files. `en`/`ru`/`ja` are 1291 keys each, 0 missing vs `en`. | MET |
| I02 | 198 ключей на локаль, ~2574 всего | 22 | 1291 keys × 13 locales. The figure is a stale census inside the requirement table, not a cap. Do not delete keys to match it. Owner should amend the number. | GAP-OWNER |

### Keeper-voice / i18n spot-audit (ru + en + ja)

Not a TZ verdict. Voice contract used as the quality bar, because the TZ is silent: store captions ask for the Keeper's terse second person (`store/screens_spec/shotlist.json` contract), and `docs/CONTENT_WORLD_BIBLE.md` says lore must not contradict GDD §12.3. Lead dev / i18n owner fixes these. Terminal `��` in one `ru` grep was a display artifact: Python found 0 U+FFFD in `ru.json`.

| Locale | Key | Defect |
|---|---|---|
| ja | `WORLD_CHAR_KEEPER_TITLE` | `管理人` (building manager). |
| ja | `FINAL_NIGHT_DESC` | `守護者` (guardian). Same person, second name. |
| ja | `NGP_KEEPERS_PACT_NAME` | `管理人の盟約`. Third register against en `Keeper's Pact`. |
| ja | `DAILY_PLAY_20_FLAVOR` | Addresses the player as `管理人`, matching en/ru "Keeper" — but that word is not the title used in `FINAL_NIGHT_DESC`. |
| ja | `WORLD_FACTION_KEEPERS_TEXT` / `LORE_PARK_01_TEXT` | Motto uses `ランタン`. Diary and `WORLD_CHAR_KEEPER_TEXT` use `街灯`. EN source mixes `lantern` and `streetlight` in `LORE_PARK_01_TEXT`; RU keeps `фонарь` in both the motto and the manifesto. RU is the consistent one. |
| ja | `WORLD_DIARY_K2_TEXT` | `飲んでいた` reads as people drinking. EN "they were drinking" is the feeders drawing power. Meaning break. |
| ja | `WORLD_DIARY_K1_TEXT` | `命令1` for a work order. RU `Наряд 1` is the right job word. |
| ja | `LORE_RESIDENTIAL_03_TEXT` | English word `why` left in the sentence. Mixed script. |
| ja | `LORE_POWER_STATION_08_TEXT` | `管理人のメモ` collapses EN `groundskeeper` into the Keeper. RU `Записка смотрителя` keeps a different role. |
| ja | `LORE_PARK_07_TEXT` | `封印` for a wax seal. Reads as a magical seal. |
| ru | `WORLD_CHAR_RADIOVOICE_TEXT` | Formal `Идите` / `вас`. |
| ru | `WORLD_RADIO_01_TEXT` | Informal `ты` / `Иди` for the same call. Address break inside one voice. |
| ru | `NGP_KEEPERS_PACT_NAME` | `Завет` is a covenant. EN is `Pact`. Heavier than the source. |
| en | `LORE_PARK_03_TEXT` | `If you're replaying this` is a game verb on a diegetic tape. RU `Если ты это слушаешь` stays in fiction. |
| ru | `ACH_05_DESC`, `ACH_06_DESC`, `ACH_18_DESC`, `NGP_SETUP_ACTION` | Latin left in player-facing copy: `Shadow`, `District`, `Hardcore`, `New Game`. Not Keeper voice; still mixed-script. |
| ja | `NGP_SETUP_ACTION` | `New Game+` left in Latin. |

No exclamation marks in the 32 Keeper-ish keys. That part is clean.

---

## Accessibility

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| C01 | colorblind (3 типа) | 378 | Dropdown is off + deuteranopia + protanopia + tritanopia (`settings_screen.gd:246-248`). | MET |
| C02 | размер текста, высокий контраст | 378 | Text-size dropdown (`settings_screen.gd:251-253`). High contrast calls `_apply_high_contrast()` (`settings_manager.gd:396`). | MET |
| C03 | auto-aim | 378 | Setting is stored and emitted (`settings_manager.gd:407-409`). No other script reads `auto_aim`. | GAP-DEV |
| C04 | арахнофоб-режим (Crawler → «слепые собаки») | 379 | `_apply_arachnophobia()` (`settings_manager.gd:416-427`) hides `BodyMesh` and shows `AltMesh` on group `crawlers`. It does not rename the creature. | GAP-DEV |
| C05 | подсказки вкл/выкл | 379 | `hints` is a stored setting (`settings_manager.gd:70`) and `quest_tracker_hud.gd:87` listens for the key. | MET |
| C06 | Графика: Low/Medium/High/Ultra (fog, particles 50–150%, тени, разрешение). | 377 | Four index presets exist (`settings_manager.gd:262-267`) and set shadow/texture/effects/fps/resolution indices. The dict has no fog-density or particle-percent fields, so the 50–150% clause is not implemented. | GAP-DEV |

`docs/GAMEFEEL_SPEC.md` `reduce_flash` / `reduce_time_fx` are not in the TZ. The settings exist (`settings_screen.gd:266-267`). EXTRA.

---

## Store

The TZ has no Play listing, screenshot, or privacy section. `docs/STORE_KIT.md` is EXTRA.

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| T01 | Android APK: arm64, keystore, debug OFF, собрать и проверить на устройстве | 669 | Still an open checkbox in the TZ. No signed AAB in this tree. Keystore and a device are owner-only. | GAP-OWNER |
| T02 | «Смотреть рекламу» (+100) или «Пропустить» (−100). Кулдаун: 1 реклама в час. На PC: имитация | 614-616 | Same gap as E03. PC simulation was not found as a separate provider path in the lines read. | GAP-DEV |

---

## Security

The TZ has no threat-model section. Save signing, Play Integrity, and `attack_sim.gd` are EXTRA. Do not score them as TZ gaps or as TZ compliance.

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| Z01 | Путь: `user://save.tres`. НИКОГДА не писать в `res://` в рантайме. | 251 | Writes go to `user://tls_savegame.save` and `user://tls_savegame_slot%d.save` (`save_system.gd:3`, `:415`). No `res://` write in that file. The path name is not `user://save.tres` (G22). The ban itself holds. Settings path `user://settings.cfg` matches TZ:252 (`settings_manager.gd:8`). | MET |

---

## Perf / size

| ID | Quote | TZ | Evidence | Verdict |
|---|---|---|---|---|
| P01 | Draw calls <200 (D1) / <350 (D11); полигоны <50K на район; динамических источников <8 | 385-386 | No budget gate in `scripts/systems/quality_manager.gd` or `light_limiter.gd` was found that fails a build on those numbers. Numbers were not measured (no engine this pass). | GAP-DEV |
| P02 | Частицы <500 одновременно; RAM <800 МБ; VRAM <400 МБ. Цель: 30–60 FPS | 388-389 | No simultaneous-particle cap and no RAM/VRAM assert found. `scenes/main_3d.tscn` ash emitter `amount = 80` is one emitter, not a cap. FPS fallback exists as a graphics-tier fps index, not as a "<30 then drop shadows" controller verified this pass. | GAP-DEV |
| P03 | Текстуры ≤2048² hero / 512² props; формат Basis Universal (ETC2/ASTC). | 387 | `docs/STYLE_GUIDE.md` repeats the size classes and `export_presets.cfg` is GL Compatibility. A full texture-dimension sweep was not run. Not scored MET. | EXTRA |
Size cap is A04 only. Music 38M is inside `<100 МБ музыка`; non-music exported audio is over `<50 МБ SFX`. One quote, one verdict.

---

## What was not scored

- Appendix V `[M1]`–`[M4]` rows that the TZ itself still lists open at `GDD.md:680-685` (9 settings tabs, equipment slots, group AI, Sniper/Brute/Burner/Rotter/Hound/Tvar as a finished wave). Roster *data* for several of those ids exists (G18) and does not match the stat table. That is not a MET of the wave.
- `docs/CARD_ART_BRIEF.md` keeper-card pipeline. Not a TZ sentence.
- `docs/IDEAL_GAP_REPORT.md` v7.5 rendering-corruption and softlock items. Not TZ sentences. Not re-tested.
- Gate green (`GDD.md` §16.4 / §25.2). Not run. Not upgraded to MET. `docs/FUNCTION_MATRIX.md` X19 still records the 3D-scene gate as an open bug; this pass did not re-run it.

## Riskiest assumption per section (checked)

- Gameplay: the named `player_fps.tscn` might still be the play camera. It is not. FPS behavior is `fps_mode` on the main-scene camera.
- Stealth: `CROUCH_NOISE_MULT` might be applied. It is only declared.
- NG+: the TZ might specify modifiers. It does not. Only a checkbox.
- Districts: `district_grading.gd` 0.03 might be the live night. The export path is unset. Live writer is `world_env_setup.gd`.
- Economy: hunger items might be a live loop. The panel scene is not instanced.
- Audio: crossfade might be 2.0 s because the comment cites the GDD. Constant is 2.2.
- Visual: `DayNight` might be painting daytime. It never binds an environment.
- i18n: a `ru` grep `��` might be mojibake. Byte scan found no U+FFFD.
- Accessibility: `auto_aim` might be wired because the toggle exists. No consumer.
- Store: Play listing copy might be a TZ requirement. It is not.
- Security: a security section might exist. The only sentence is the `res://` ban.
- Perf: `assets/audio` at 253M might blow the package cap. 162M of that is export-excluded `_pre_norm`.
 be wired because the toggle exists. No consumer.
- Store: Play listing copy might be a TZ requirement. It is not.
- Security: a security section might exist. The only sentence is the `res://` ban.
- Perf: `assets/audio` at 253M might blow the package cap. 162M of that is export-excluded `_pre_norm`.
