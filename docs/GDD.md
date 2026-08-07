# GDD — THE LAST STREETLIGHT (КАНОН v4, полный)

> **Единый канон.** Этот документ — единственный источник истины: по нему можно
> собрать игру целиком и без ошибок. Приложения: `ART_UI_STYLE.md` (стиль),
> `ART_AUDIO_PROMPT.md` (арт/звук), `UI_SPEC.md` (раскладки экранов),
> `GDD_SUPPLEMENT_v3.md` (детальные таблицы S1–S20). При конфликте главенствует
> этот документ.

---

## 1. ОБЗОР

| Поле | Значение |
|------|----------|
| Название | THE LAST STREETLIGHT («Последний фонарь») |
| Жанр | Survival horror, экшен, стелс, головоломки |
| Камера | **От первого лица (FPS)** — `player_fps.tscn`, камера в глазах персонажа |
| Движок | Godot 4.7, GDScript 2.0 (строгая типизация) |
| Платформа | Android (основная), Desktop (опционально). Офлайн |
| Мир | Единая карта из 11 районов. НЕ процедурный, НЕ бесконечный |
| Хронометраж | 8–12 ч (одна концовка), 15+ ч (все концовки/секреты) |
| Языки | 13 языков через I18n: RU (основной), EN, TR, ZH, ZH_TW, DE, FR, ES, PT, IT, PL, JA, KO. 198 ключей на локаль, ~2574 всего |

### 1.1. Логлайн
Город погружён в **вечную ночь** после эксперимента «Проект Архитектор».
Игрок — выживший с единственным фонариком. Восстанавливая электросеть района
за районом, он возвращает улицам свет — и узнаёт правду о катастрофе.

### 1.2. Ядро геймплейного цикла
```
Войти в тёмный район → собрать материалы (кабели, предохранители, батарейки)
→ решить пазл/починить генератор → зажечь улицы (стадия STREETS)
→ район становится светлее и безопаснее → пройти к следующему району
```
Свет — одновременно: ресурс (батарея), оружие (Shadow гибнет в конусе),
навигация (зажжённые улицы = безопасный путь) и награда (визуальная).

---

## 2. КАМЕРА И УПРАВЛЕНИЕ (FPS)

### 2.1. Камера
- `CharacterBody3D` + дочерняя `Camera3D` на уровне глаз (высота ~1.7 м).
- Поворот: мышь/палец по экрану. Pitch ограничен ±90°.
- Хедбоб: лёгкое покачивание при беге (0.1, не выше — укачивание).
- FOV 80° (base), кратковременно +5° при спринте.
- Фонарик — `SpotLight3D` на камере (см. §11), светит туда, куда смотрит игрок.
- RayCast3D от камеры (длина 3 м) — взаимодействие с объектами.

### 2.2. Android-управление (касания)
| Зона | Действие |
|------|----------|
| Левая половина экрана | Drag = поворот камеры |
| Левая половина, двойной тап | Dodge |
| Правая половина (низ) | Кнопка «Действие» (атака/взаимодействие) |
| Правая половина (верх) | Кнопка «Фонарик» (вкл/выкл, долгий тап = строб) |
| Кнопка «Прыжок» | Тап |
| Свайп вниз | Присесть (crouch) |
| Пиныч (двумя пальцами) | Зум камеры (опц.) |

### 2.3. ПК-управление (опционально)
- WASD — движение; мышь — камера (captured); Space — прыжок; Shift — бег;
- F — фонарик; E — взаимодействие; Ctrl — присесть; C — строб; Esc — пауза.

### 2.4. Кинематика (Godot-канон)
- `CharacterBody3D` + `move_and_slide()`; гравитация через `get_gravity()` (не хардкод).
- Coyote time 0.1 s, jump buffer 0.1 s.
- Спринт: скорость ×1.6, шум выше (см. §7).
- Crouch: скорость ×0.4, шум ×0.3, видимость ×0.5, высота капсулы 1.2 м.

---

## 3. ФОНАРИК И БАТАРЕИ

### 3.1. Фонарик
- Всегда в руках. Параметры базы: конус 45°, дальность 8 м, цвет `#c9a24a`,
  energy 2.0, shadow 1024² (опц. на mobile — без теней).
- Тепловая шкала батареи: сегменты (5–10) на HUD, гаснут по мере разряда.
- Мерцание при заряде <20% (убирается апгрейдом «Стабильность» L5).
- Стробоскоп (чертёж): двойной тап по кнопке фонарика — STUN врагов в конусе 1.5 s, кд 10 s.

### 3.2. Батарея
- Полный заряд: 100%. Расход: 1%/2 с (конус включён), 0 в выключенном.
- Батарейка (предмет): +25% заряда. Накопитель батарей в инвентаре.
- При 0% — фонарик гаснет, мир почти чёрный (см. §11.1).

### 3.3. Дерево улучшений фонарика (S4.2)
| Ур. | Яркость | Дальность | Стабильность | Угол | Ёмкость | Цена |
|-----|---------|-----------|--------------|------|---------|------|
| L1 | +20% | +1 м | −10% drain | +10° | +20% | 100 |
| L2 | +40% | +2 м | −20% | +20° | +40% | 250 |
| L3 | +60% | +3 м | −30% | +30° | +60% | 500 |
| L4 | +80% | +4 м | −40% | +40° | +80% | 1000 |
| L5 | +100% | +5 м | −50% | +50° | +100% | 2000 |
- Максимум: 19 250 монет на все ветки L5.

---

## 4. ЭЛЕКТРОСЕТЬ, СТАДИИ, ПОБЕДА

### 4.1. Районы (11, фиксированный порядок восстановления)
`suburbs → residential → park → school → hospital → gas_station → police →
warehouses → industrial → substation → power_station`

### 4.2. Стадии района (`DistrictData.Stage`)
| Стадия | Значение | Эффект |
|--------|----------|--------|
| DARK | 0 | Фонари выключены, ambient 0.03, луна 0.12 — только силуэты |
| PARTIAL | 1 | Частичное питание, часть фонарей |
| STREETS | 2 | Улицы горят, ambient 0.11, луна 0.25, обучение закрывает фазу |
| FULL | 3 | Район спасён: ambient 0.16, луна 0.40, безопаснее, visual reward |

### 4.3. Правила
- Район открыт, если все его пререквизиты (`powered_by`) в FULL — иначе `FIRST_RESTORE`-подсказка.
- Продвижение: `PowerGrid.advance_district(id, stage)` из пазлов/генераторов.
- Переключатели `PowerSwitch` и пазлы: `toggle_district` = STREETS ↔ DARK.
- События: `district_stage_changed`, `streetlight_activated`, `district_restored`,
  `power_grid_updated`, `district_powered`.
- Все 11 районов FULL → `GameManager.trigger_win()` → концовка (§12.4).
- Сохранение стадий: `PowerGrid.to_dict()/from_dict()` (save_system).

---

## 5. БОЕВАЯ СИСТЕМА (S1)

### 5.1. Комбо (ближний бой)
| Удар | Windup | Active | Урон | Стамина | Бонус |
|------|--------|--------|------|---------|-------|
| 1 Jab | 0.25 s | 0.15 s | 8 | 5 | — |
| 2 Cross | 0.30 s | 0.15 s | 12 | 5 | если 1-й попал или <0.8 s |
| 3 Slam | 0.45 s | 0.20 s | 20 | 8 | knockback 1.5 м |
- Окно комбо 1.2 s. Урон во время windup = сброс + 0.3 s stun.
- Стамина < 5 — кнопка атаки серая.
- Итоговый урон: `base × (1 + flashlight_bonus) × crit`; конус фонарика = +25%,
  удар в спину = ×1.5.

### 5.2. Dodge
- Двойной тап/свайп в сторону. 15 стамины. I-frames 0.35 s, кд 0.8 s.

### 5.3. Хитбоксы
- Игрок: Capsule (r 0.3, h 1.6). Атака: Box 0.6×0.4×1.2 м перед камерой, активен
  только в active frames.
- Friendly fire: нет. Knockback по направлению от источника.

### 5.4. Смерть и респавн
- HP=0: 2 s падение → экран смерти (причина, время, % районов, документы).
- Респавн: на последний активный фонарь/вход района, HP 50%, батарея не восстанавливается.
- Hardcore (настройка): 1 жизнь, смерть = удаление сейва.

---

## 6. ВРАГИ И БОСС (S3, S19)

### 6.1. Универсальный FSM
`IDLE → PATROL → INVESTIGATE → CHASE → ATTACK → FLEE → STUN → DEAD`
- Реализация: `BehaviorTree` (LimboAI-паттерн) или `match`-стейт-машина;
  NavigationAgent3D для CHASE; чёрный список/distraction.

### 6.2. Типы
| Тип | HP | Урон | Скорость | Зрение | Слух | Свет | Слабость |
|-----|----|------|----------|--------|------|------|----------|
| Shadow | 30 | 15 | 1.2× | 0 м (слух 15 м) | 15 м | 10 dmg/s, <30% HP — распад | свет |
| Crawler | 50 | 20 | 1.5× | 6 м (cone 120°) | 10 м | отвлекает на 1 s | удар в спину |
| Watcher | 80 | 12 | 1.0× | 12 м (cone 90°) | 8 м | STUN 2 s → ярость | свет |
| Hunter | 120 | 35 | 0.9× | 10 м (cone 60°) | 12 м | slow ×0.5 → rage ×1.3 | свет |
| Destroyer | 200 | 25 | 0.7× | 5 м (cone 180°) | 15 м | не реагирует | комбо-3 |
| Архитектор | 800 | 40 | 1.1× | 20 м | 20 м | замедление атак | стробоскоп |

- Приоритет детекта: урон → свет+видимость → шум → близость.
- Loot: 30% шанс с трупа.

### 6.3. Босс The Architect (S7.3)
- Фаза 1 (100–70%): телепорты + снаряды (dodge). Свет замедляет атаки.
- Фаза 2 (70–30%): невидим в темноте (виден только в конусе), призыв Shadow ×3.
- Фаза 3 (30–0%): обвал арены (балки 40 dmg), ближний бой, финишер combo-3 + строб.

---

## 7. СТЕЛС И ШУМ (S2)

- Источники шума: бег 8 м/0.8, удар 5 м/1.0, dodge 3 м/0.4, перегруз (>35 кг) +30%.
- Распространение: сфера по слою "noise" → монстры INVESTIGATE → CHASE.
- Видимость: в конусе фонарика +100%, в тьме 3 м, за стеной 0%, бег +20%.
- Индикатор: пульсация ember-виньетки по краю (не число).
- Hiding spots: шкафы, кусты, багажники, тёмные углы. Внутри видимость 0;
  монстр ищет 10 s в радиусе 5 м после потери цели.

---

## 8. ЭКОНОМИКА, ПРОГРЕССИЯ, КВЕСТЫ (S4, S5)

- Валюта: монеты (тайники 50–200, продажа лута 10–50%, достижения, реклама +100).
- Траты: улучшения фонарика, чертежи, предметы торговца, скины (этап 7).
- НЕТ голода, НЕТ pay-to-win. Донат = только пополнение монет.
- Оружие и патроны — ЕСТЬ (FPS-шуттинг-слой поверх ближнего боя, см. §19).
- Квесты: MQ (восстановление районов, автомат), SQ (NPC/документы), BQ (зачистка),
  EQ (исследование). Журнал с чекбоксами, до 3 активных объективов на HUD.
- Кривая: 0–200 монет D1 → 8000+ к D11; полный проход 8–12 ч.

---

## 9. СБОРКА (ВЕРСТАК) (S8)

| Чертёж | Материалы | Эффект | Где |
|--------|-----------|--------|-----|
| Усиленная батарея | 2 батарейки + 1 кабель | Ёмкость +20% | D2 подвал |
| Ультрафиолет | 3 кабеля + 1 предохранитель + 2 батарейки | 5 dmg/s в конусе | D4 физика |
| Стробоскоп | 2 предохранителя + 1 трансформатор | STUN 1.5 s, кд 10 s | D7 допросная |
| Переносной верстак | 5 досок + 2 металла + 1 инструмент | крафт в поле | D8 магазин |
| Батарея L2 | 1 усиленная + 2 кабеля + 1 трансформатор | Ёмкость +40% | D9 цех |

---

## 10. СОХРАНЕНИЕ (S15)

- Слоты: 3 ручных + 1 автосейв. Формат: `.tres` (`SaveData extends Resource`) или JSON.
- Что сейвится: позиция, HP, стамина, батарея, инвентарь, вес, улучшения, чертежи,
  стадии районов, фонари, квесты, бестиарий, статистика, настройки.
- Автосейв: вход/выход из района, активация фонаря, решение пазла, покупка, секрет, смерть, каждые 60 s.
- Путь: `user://save.tres`. НИКОГДА не писать в `res://` в рантайме.
- Настройки: `user://settings.cfg` (ConfigFile).

---

## 11. СТИЛЬ (ВИЗУАЛ, ШРИФТЫ, СПРАЙТЫ)

> Полная арт-библия: `ART_UI_STYLE.md`. Это её краткая выжимка — обязательный минимум.

### 11.1. Свет и тьма (permanent night)
- Дня нет. Холодная тьма окружения × тёплый свет источников — главный
  атмосферный и навигационный контраст.
- DARK: почти pitch-black (ambient 0.03, луна 0.12) — только силуэты вне конуса.
- LIT/FULL: фонари горят, ambient 0.11/0.16, луна 0.25/0.40.
- «Тьма → зажглись фонари» — главная визуальная награда.

### 11.2. Палитра (токены)
| Токен | HEX | Назначение |
|-------|-----|------------|
| bg-deep | `#0c1016` | Фон экранов |
| panel | `#141b24` | Панели UI |
| panel-edge | `#2a3340` | Рамки |
| brass | `#c9a24a` | Акценты, фонарик |
| brass-dim | `#8a7338` | Неактивные акценты |
| ember | `#b4452f` | Опасность, HP |
| steel-text | `#aeb6bf` | Основной текст |
| bone-text | `#d8d2c4` | Заголовки |
| stamina | `#5f8a4e` | Выносливость |
| teal | `#4a9ab5` | Информация |
- Запрет: чистые `#000`/`#fff`, неон, кислотные цвета, высокая насыщенность.

### 11.3. Шрифты (все в `assets/fonts/`, OFL)
| Назначение | Шрифт |
|------------|-------|
| Заголовки экранов | Chakra Petch Bold |
| Заголовки панелей | Saira Condensed Bold |
| Основной текст | Rajdhani Regular/SemiBold |
| Второстепенный | Saira Condensed Regular |
| Цифры/статы | Share Tech Mono |
| Моно-хакер/радио | Bebas Neue / Roboto Condensed (доп.) |
- Запрет: Inter, Roboto, Arial, системные шрифты, рукописные.

### 11.4. Панели и окна
- Фон `panel`, рамка 1 px `panel-edge`, **срезанные углы (chamfer, radius 0)**.
- Зерно 8–12% + виньетка по краям + лёгкая dropshadow.
- Запрет: glasmorphism, скругления.

### 11.5. Иконки и спрайты
- Иконки: линейные outline 1.5–2 px, `brass`/`brass-dim`, без заливки/градиентов.
- Предметы: 128×128 PNG с альфой (батарейка, аптечка, ключ, кабель, предохранитель,
  трансформатор, чертёж, монета, документ, фото) — цвета по `ART_AUDIO_PROMPT.md`.
- Монстры: 512×512 силуэты-плейсхолдеры (Shadow тёмно-синий, Crawler бурый,
  Watcher серо-голубой, Hunter тёмно-тактический, Destroyer ржавый, Босс 1024²).
- Тайлы районов: 256² бесшовные (пол/стена/потолок), палитры районов в
  `ART_AUDIO_PROMPT.md` §ENVIRONMENT.
- 3D: HUD/экраны процедурные (Theme/ColorRect/шейдеры) — PNG-арт опционален,
  но стилистика идентична.

### 11.6. 3D-грейд (Mobile renderer)
- Tonemap AgX, glow только для костров, depth fog `#1a2133` (density 0.012–0.015).
- SSAO/SSIL/Volumetric fog — ВЫКЛ на mobile. Moon shadow 2048² (вкл).
- Луч фонарика: SpotLight3D + аддитивный конус-меш (ShaderMaterial blend_add, unshaded).
- ЛУТ: тёплый отлив светов, холодный — теней.

---

## 12. ЭКРАНЫ И СЮЖЕТ

### 12.1. Поток экранов
```
BOOT → SPLASH → MAIN_MENU → LOADING → PLAYING ↔ PAUSE ↔ SETTINGS
DEAD ← DIALOG → VICTORY → CREDITS → MAIN_MENU
Overlay: INVENTORY, CITY_MAP, JOURNAL, BESTIARY, SHOP, WORKBENCH, PHOTO_MODE
```

### 12.2. Полный список экранов (детали раскладки — `UI_SPEC.md`)
MAIN_MENU, LOADING, HUD_BATTLE, PAUSE, SETTINGS, CITY_MAP, JOURNAL, BESTIARY,
INVENTORY, CHARACTER, FLASHLIGHT_UPGRADE, SHOP, ACHIEVEMENTS, STATS,
PHOTO_MODE, CONTROLS_TOUCH, WEATHER, WORKBENCH, DEATH, PUZZLE_CABLES, RADIO,
STORY_SCENE, FINAL_NIGHT, POWER_GRID, EVENTS (итого 25).

### 12.3. Сюжет — три акта (S7.1)
- Акт I (D1–3): выживание, дом, первый фонарь, радио-голос «Идите на электростанцию».
- Акт II (D4–8): документы раскрывают «Проект Архитектор»; монстры — бывшие люди.
- Акт III (D9–11): подстанция, электростанция, босс, финальный выбор.
- Точка невозврата: вход в D10.

### 12.4. Концовки (S7.4)
| Концовка | Условия |
|----------|---------|
| Свет (хорошая) | 11 районов FULL + все документы |
| Надежда | 11 районов FULL, <50% документов |
| Выживший | только D11 |
| Тьма (плохая) | смерть/не починена сеть |
| Истина (секрет) | все документы + аудио-логи + фото + бункер D11 |

---

## 13. АУДИО (S9)

> Полная таблица: `ART_AUDIO_PROMPT.md` §AUDIO. Краткая выжимка:

- Шины: `Master → Music | SFX (Footsteps, Combat, UI, Environment) | Voice`.
- Музыка — **адаптивные слои** (crossfade 2 s):
  `Ambient_Dark (120 s, холодный дрон) → Ambient_Lit (тёплый) →
  Threat_Low (INVESTIGATE) → Threat_High (CHASE, heartbeat 60 bpm) →
  Action_Sting (бой)`.
- Стиль музыки: минималистичный dark ambient / industrial / эмбиент-хоррор —
  без мелодичных тем, только слои, дроны, ударные биения и шумовые текстуры.
  Районный эмбиент меняется (dron per district); LIT-районы звучат теплее.
- Футстепы: 6 поверхностей × 3 скорости (афальт/бетон/дерево/металл/лужа/стекло),
  RayCast3D вниз определяет поверхность.
- Звуки монстров (телепорт-щелчок Shadow, царапание Crawler, дыхание Watcher,
  шаги Hunter, гул Destroyer) — все с указанием радиуса слышимости (§9.2/GDD).
- UI-звуки: тёплые латунные клики (hover/click/error/save/achievement).
- Форматы: OGG музыка, WAV→OGG короткие SFX. Объём: <50 МБ SFX, <100 МБ музыка.

---

## 14. НАСТРОЙКИ И ДОСТУПНОСТЬ (S12)

- Графика: Low/Medium/High/Ultra (fog, particles 50–150%, тени, разрешение).
- Accessibility: colorblind (3 типа), размер текста, высокий контраст, auto-aim,
  арахнофоб-режим (Crawler → «слепые собаки»), подсказки вкл/выкл.

---

## 15. ПРОИЗВОДИТЕЛЬНОСТЬ (S13) — Mobile

- Draw calls <200 (D1) / <350 (D11); полигоны <50K на район; динамических
  источников <8 (остальное — baked lightmap).
- Текстуры ≤2048² hero / 512² props; формат Basis Universal (ETC2/ASTC).
- Частицы <500 одновременно; RAM <800 МБ; VRAM <400 МБ.
- Цель: 30–60 FPS; при <30 — снижать тени/частицы/LOD.

---

## 16. ТЕХНИЧЕСКИЙ СТЕК (Godot 4.7)

### 16.1. Структура проекта
```
res://scenes/      — .tscn (player/, ui/, world/, enemies/, environment/, tools/)
res://scripts/     — .gd, имя = сцене
res://assets/      — ТОЛЬКО импортированные файлы (models/, textures/, audio/, fonts/)
res://resources/   — .tres (district_*.tres, item_*.tres, theme)
res://autoload/    — синглтоны (или прямо в scripts/ + project.godot)
res://components/  — HealthComponent, AttackComponent и т.п.
res://shaders/     — .gdshader
```

### 16.2. Автолоады (46)
`ThemeSetup, MapController, LANNetwork, PowerGrid, SaveLoad, EventBus, Bootstrap,
ShotTool, WorldBootstrap, UISFX, LightGrid, Shop, DayNight, DistrictThemes,
DistrictAtmosphere, GameManager, SaveSystem, InputService, ItemDatabase,
InventoryManager, Encyclopedia, CoinWallet, ShopService, UpgradeSystem,
UIManager, WeatherSystem, SettingsManager, ProgressTracker, AudioManager,
AchievementManager, MusicManager, LocalizationManager, QuestManager,
DistrictManager, PuzzleSystem, LANDiscovery, NetworkManager, SkillTreeManager,
XpManager, NewGamePlus, NoisePropagation, FlashlightUpgradeManager,
WorkbenchManager, EndingsManager, TutorialSystem`

### 16.3. Правила кода
- Строгая типизация, `@export`, `@onready`, сигналы вместо прямых вызовов
  (`EventBus` — глобальная шина, ~95 сигналов).
- `enum State` + `match` для стейт-машин; `BehaviorTree` для врагов.
- `preload()` в _ready, `load()` только динамически. `await`, никогда `yield`.
- Твины `create_tween()` (kill старых); пулы объектов для пуль/лута (не queue_free в хот-пате).
- Индентация: ТАБЫ (вся кодовая база); UTF-8 без BOM; гейты перед коммитом (см. 16.4).

### 16.4. Гейты качества (перед каждым коммитом)
1. `compile_scene.tscn` — 345+ скриптов парсятся, 0 ошибок.
2. `autoload_api_check_scene.tscn` — все обращения `Autoload.member` существуют.
3. `signal_arity_check_scene.tscn` — сигналы/коннекты по арности.
4. `asset_check_scene.tscn` — иконки, аудио, экспорт-настройки.
5. `i18n_check_scene.tscn` — все ключи переведены (tr/zh/zh_TW).
6. `craft_check_scene.tscn` — крафт/экономика/концовки.
7. Runtime: `--quit-after` прогон без ошибок.
8. `doctor.ps1` — сводная проверка (компиляция, автолоады, индентация).

---

## 17. РЕАЛЬНАЯ БАЗА ПРЕДМЕТОВ (из item_database.gd + data/items/)

Источник — `scripts/inventory/item_database.gd` + `data/items/*.tres` + `assets/textures/items/*.png`.

| ID (файл) | Тип | Вес | Примечание |
|-----------|-----|-----|------------|
| battery | CONSUMABLE | 0.3 | +25% заряда фонарика |
| medkit | CONSUMABLE | 0.8 | +40 HP |
| key | KEY | 0.1 | ключ |
| scrap | MATERIAL | 0.5 | металлолом |
| cable | MATERIAL | 2.5 | для трансформаторов |
| fuse | MATERIAL | 0.4 | предохранитель |
| gear | MATERIAL | 1.0 | шестерня |
| wiring | MATERIAL | 0.4 | проводка |
| circuit | MATERIAL | 0.3 | микросхема |
| transistor | MATERIAL | 0.1 | транзистор |
| motor | MATERIAL | 2.0 | двигатель |
| radio_part | MATERIAL | 0.8 | деталь радио |
| scope_lens | MATERIAL | 0.2 | линза прицела |
| serum | CONSUMABLE | 0.3 | сыворотка |
| gas_canister | MATERIAL | 1.5 | баллон газа |
| ancient_key | KEY | 0.2 | древний ключ |
| transformer | MATERIAL | 2.0 | трансформатор |
| tool / wrench | TOOL | 1.8 | инструмент |
| coin | CURRENCY | 0.0 | монета |
| backpack_l1 | UPGRADE | 0.0 | +10 кг |
| backpack_l2 | UPGRADE | 0.0 | +20 кг |
| document | LORE | 0.0 | документ |
| audio_log | LORE | 0.1 | аудио-лог |
| photo | LORE | 0.0 | фото |
| ammo | AMMO | 0.05 | патроны (универсальные) |
| прочие из `assets/textures/items/` | — | — | can_food, water, bandage, repair_kit, explosive, molotov, taser, lockpick, pistol/rifle/shotgun, backpack |

> Реальный список (по картинкам `assets/textures/items/`): ammo, ancient_key,
> backpack, bandage, battery, blueprint_backpack_capacity/slots,
> blueprint_flashlight_battery/brightness, cable, can_food, circuit, coin,
> explosive, flashlight, fuse, gas_canister, gear, icon_ammo/health/stamina,
> key, lockpick, medkit, molotov, motor, pistol, radio_part, repair_kit,
> scope_lens, scrap, serum, taser, transistor, water, wrench, wiring.
> Чертежи: blueprint_uv_flashlight, blueprint_strobe_flashlight,
> blueprint_portable_workbench, blueprint_enhanced_battery (см. §9).

---

## 18. ОРУЖИЕ (FPS-слой; weapon_base.gd класс WeaponBase)

| Параметр | Base |
|----------|------|
| `damage` | 25 (переопределяемый) |
| `fire_rate` | 0.15 s |
| `range` | 50 м |
| `max_ammo` | 30 |
| `reload_time` | 2.0 s |
| `spread` | 0.02 |
| `recoil` | 0.5 |
| cигнал | `fired`, `ammo_changed(current, max)` |

- Подклассы: `weapon_pistol.gd`, `weapon_rifle.gd`, `weapon_shotgun.gd` (свои damage/fire_rate/max_ammo).
- Управление боеприпасами, перезарядка по таймеру, учёт текущего боезапаса.
- Пикапы: `weapon_pickup.gd` (unlock в WeaponManager), `ammo_pickup.gd`.
- `weapon_mod_manager.gd` — моды оружия.
- Патроны — универсальные (ammo.png), выпадают из лута/магазина.

---

## 19. СКИЛЛ-ДЕРЕВО (из skill_tree_manager.gd)

4 ветки, прокачка за очки опыта (XP → уровень → очки):

**Combat** (атака)
- damage_boost_1 → damage_boost_2
- crit_chance, fire_rate, reload_speed

**Defense** (защита)
- max_health → health_regen
- stamina_boost
- damage_resist → knockback_resist

**Exploration** (исследование)
- battery_capacity → light_radius
- move_speed → sprint_efficiency
- inventory_space

**Utility** (утилиты)
- stealth → noise_reduction
- xp_boost → loot_luck
- lockpick_speed → craft_speed

- `XpManager`: очки XP за убийства, пазлы, восстановление районов, секреты;
  `level_up`, `skill_point_earned`, `xp_gained`.

---

## 20. ВЕРСТАК / КРАФТ (workbench_manager.gd)

Рецепты (реальные, материалы — из §17):
- `blueprint_uv_flashlight` — 3 cable + 1 fuse + 2 battery;
- `blueprint_strobe_flashlight` — 2 fuse + 5 scrap (уточнить в коде);
- `blueprint_portable_workbench` — по ингредиентам из кода;
- `blueprint_enhanced_battery` — усиленная батарея.

---

## 21. ДОСТИЖЕНИЯ (achievements_manager.gd — ach_01…ach_15+)

ID: ach_01 … ach_15 (+ секретные). См. §S17 в GDD_SUPPLEMENT:
первый свет, электрик, светоч, библиотекарь, охотник на теней,
тихий как мышь, мастер комбо, перегруз, фотограф, искатель, эконом,
без царапин, архитектор, истина, тьма, спидраннер, коллекционер,
железный человек, сон в летнюю ночь, кто там?

---

## 22. РЕАЛЬНЫЙ АУДИО-НОМЕНКЛАТ (файлы assets/audio/)

### Музыка (assets/audio/music/)
- default, downtown, harbor, industrial, park, residential (районные треки)
- music_ambient, music_ambient_dark, music_battle, music_boss, music_boss_dark,
  music_combat, music_menu_dark, music_tension, music_victory

### SFX (assets/audio/sfx/)
- amb_lamp_hum, amb_wind — эмбиент
- mon_crawler_scratch, mon_destroyer_hum, mon_hunter_roar, mon_shadow_teleport,
  mon_watcher_breath, mon_watcher_scream — монстры
- sfx_click, sfx_flashlight_on/off, sfx_hit, sfx_hurt, sfx_jump, sfx_reload,
  sfx_shoot, sfx_step — игрок/UI
- step_asphalt_dry/wet, step_clank, step_concrete, step_dirt, step_glass,
  step_gravel, step_metal, step_puddle, step_wood — футстепы (RayCast-поверхности)

**Канон стиля музыки** (см. §13): dark ambient / industrial / эмбиент-хоррор,
адаптивные слои, crossfade 2 s, холодный дрон + тёплый LIT-дрон в спасённых районах.

---

## 23. ЭКРАНЫ — ФАКТИЧЕСКИЕ СЦЕНЫ (scenes/ui/*.tscn)

main_menu, settings, difficulty, pause_menu, save_slots, game_over, death_screen,
victory_screen, credits, epilogue, confirm_quit, loading_screen, pre_loading,
boot_loading, splash, screens (агрегатор), hud_3d, hud_enhanced, coin_hud,
district_banner, quest_tracker_hud, skill_tree_ui, skill_button, inventory_panel,
level_select, lobby, new_game_plus, tutorial, touch_controls, transition_manager,
post_process.

*(итого ~30 UI-сцен — покрывают 25 экранов §12.2)*

---

## 24. БЫСТРЫЕ СЛОТЫ, ФОТОАЛЬБОМ, СОБЫТИЯ, РЕКЛАМА, УВЕДОМЛЕНИЯ, СТАТИСТИКА

### 24.1. Быстрые слоты (Quick Slots)
- 6 слотов на HUD (パーズ в паузе, 2×3 сетка).
- Предметы перетаскиваются из инвентаря. Тап по слоту = использовать.
- Слоты: оружие×2, батарея, аптечка, граната, особый предмет.
- Клавиши ПК: 1–6 для использования.

### 24.2. Фотоальбом
- Коллекция: 200 фото (85/200 на скрине).
- Источники: находка документа/аудио-лога, секретная зона, квест, враг (после убийства).
- Три категории: Photos (сюжетные), Creatures (монстры), Artifacts (артефакты).
- Просмотр: превью 128×128, детальный просмотр на весь экран.
- Достижение «Фотограф» за 50 фото, «Искатель» за 100, «Коллекционер» за 200.

### 24.3. Ежедневные события (Daily Events)
- Таймер обратного отсчёта до следующего события.
- Бонус-множитель: ×1.5 / ×2 / ×3 за 3/5/7 дней подряд.
- Событие: специальный район (временный), уникальный лут, ограниченный магазин.
- UI: карточка события с таймером, кнопка «Начать», награды.

### 24.4. Рекламные награды (Ad Rewards)
- Два варианта: «Смотреть рекламу» (+100 монет) или «Пропустить» (−100 монет).
- UI: модальное окно с вариантами, превью награды.
- Кулдаун: 1 реклама в час. На PC: имитация (без реальной рекламы).

### 24.5. Уведомления (Toast)
- Временные всплывающие сообщения (верхний правый угол).
- Типы: достижение, квест, находка, предупреждение.
- Формат: иконка + текст + длительность 3 с.
- Звук: тёплый латунный дин (achievement) или металлический клик (finding).

### 24.6. Статистика игрока
- Экран «Статистика»: время игры, убийства по типам, расстояние, пазлы, фото.
- Разбивка: Overall, Combat, Exploration, Collection.
- Таблица: 20+ строк (враги убиты, выстрелы, прыжки, смерти, сейвы,货币).

### 24.7. Подтверждение выхода
- Модальное окно «Выйти из игры?» с вариантами: Сохранить и выйти / Выйти без сохранения / Отмена.
- Появляется при ESC на ПК или кнопке «Назад» на Android.

---

## 25. ЧЕК-ЛИСТ — РЕАЛИЗОВАНО / НУЖНО ДОДЕЛАТЬ

### 25.1. Уже реализовано
- [x] FPS-камера, движение (coyote/jump-buffer), хедбоб, Android-тач
- [x] Фонарик + батареи + апгрейды + строб + ультрафиолет
- [x] PowerGrid: 11 районов, стадии, пререквизиты, победа
- [x] Пазлы: генераторы, предохранители, лифт, кран, щит, трансформаторы
- [x] Бой: комбо-3, dodge, стамина, криты, knockback, I-frames
- [x] 5+ типов врагов (shadow/crawler/watcher/hunter/destroyer), босс 3 фазы
- [x] Стелс: шум, видимость, hiding spots, ember-виньетка
- [x] Экономика: монеты, магазин, CoinWallet
- [x] Инвентарь, верстак, крафт (5 чертежей)
- [x] Квесты (MQ/SQ/BQ/EQ), журнал, бестиарий, энциклопедия
- [x] XP, скилл-дерево (4 ветки), апгрейд фонарика
- [x] Сохранение 3+1, автосейв, настройки cfg
- [x] 30 UI-сцен, локализация (ru/en/tr/zh)
- [x] Музыка и 24+ sfx, футстепы, звуки монстров
- [x] LAN discovery/multiplayer, New Game+, tutorial
- [x] Оптимизация: ETC2, LOD, LightGrid, 60 FPS
- [x] Достижения (20+), скины, оружие (пистолет/автомат/дробовик)

### 25.2. Нужно доделать
- [ ] 13 локализаций (сейчас 5) — RU/EN/TR/ZH/ZH_TW/DE/FR/ES/PT/IT/PL/JA/KO
- [ ] Быстрые слоты (6 штук на HUD)
- [ ] Фотоальбом (200 фото, 3 категории)
- [ ] Ежедневные события (таймер, бонус-множитель)
- [ ] Рекламные награды (мотреть/пропустить)
- [ ] Toast-уведомления
- [ ] Экран статистики игрока
- [ ] Подтверждение выхода
- [ ] Адаптивная музыка (5 слоёв с crossfade)
- [ ] Футстепы по 6 поверхностям (RayCast)
- [ ] Android APK: arm64, keystore, debug OFF
- [ ] Все 8 гейтов (16.4) зелёные; doctor.ps1 COMPILE OK

Вся механика ниже УЖЕ существует в репозитории (проверено сборкой 4.7,
без ошибок парсинга):
- [x] FPS-игрок (player_fps.tscn), движение, фонарик, джойстик/тач-управление
- [x] PowerGrid (11 районов, стадии, победа), пререквизиты районов
- [x] Пазлы, генераторы, fuse_box, transformer, рубильники (PowerSwitch)
- [x] Бой, враги FSM/BehaviorTree, 5+ типов (shadow/crawler/watcher/hunter/destroyer), босс 3 фазы
- [x] Стелс: шум (NoisePropagation), hiding spots, видимость, radar/minimap
- [x] Инвентарь, крафт, верстак, экономика, магазин, CoinWallet
- [x] Квесты, журнал, бестиарий, энциклопедия, достижения (20+)
- [x] XP, скилл-дерево, апгрейд фонарика (яркость/ёмкость/дальность)
- [x] Сохранение 3+1, автосейв таймером и триггерами, настройки cfg
- [x] 30 UI-сцен, локализация (ru/en/tr/zh), темы (ThemeProvider/VisualStyle)
- [x] Музыка и 24+ sfx, футстепы, звуковые события монстров
- [x] LAN discovery/multiplayer, New Game+, hardcore, tutorial/onboarding
- [x] Оптимизация: ETC2/ASTC, LOD, приглушённые тени, LightGrid, object_pool, 60 FPS
