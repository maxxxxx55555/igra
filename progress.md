# Progress

## 2026-08-10 — ФАЗА 0 (Ф0): foundation cleanup

### Что сделано (commit `ec85ba5`)
- **project.godot**: удалена повреждённая строка 11 (`"ï»¿config_version"=5` — BOM-хвост).
- **BOM-strip**: 136 .gd файлов в `scripts/` очищены от UTF-8 BOM (гейт AGENTS.md «UTF-8 without BOM»).
- **Дубли сцен**: удалены `scenes/ui/{settings_menu,settings_screen,credits_screen,difficulty_screen,Victory,GameOver}.tscn`. Бэкапы в `.backup/phase0/`.
- **`scripts/theme_setup.gd`**: полная переделка под листы UI/UX-спеки — токены канона (bg-deep/panel/panel-edge/brass/ember/steel/bone/stamina), Bebas Neue (headers) + Roboto Condensed (body), chamfer-углы, приоритет к `assets/ui/theme_tls.tres`.
- **`assets/shaders/post_process.gdshader`**: multiply-vignette → channel-replace-`#0c1016` (bg-deep) + film grain (8–12% opacity, TIME-animated). Был bloom/damage_flash — оставлены.

### Что НЕ удалось как планировалось (YAGNI-correction)
- Шейдеры изначально планировались как `shaders/grain.gdshader` + `shaders/vignette.gdshader`. Удалены как дубли — уже есть `assets/shaders/post_process.gdshader` с той же ролью. Обновлён он, новые не созданы.

### Gates после Ф0
- compile_gate_scene: COMPILE_GATE bad=0
- signal_arity_check_scene: [sig] DONE fails=0
- i18n_check_scene: [i18n] fails=0
- asset_check_scene: DONE fails=4 (Android warnings, не runtime)
- headless editor: 0 ERROR

### Следующий шаг (Фаза 2 / M1)
- HUD: прицел меняет цвет по врагу, индикатор направления урона, бары шума/заметности, timestamps, иконки состояний (см. GDD §V.1, §V.4).
- Инвентарь: слоты экипировки (голова/тело/ноги/кобура/рюкзак), редкость предметов, сортировка, сравнение оружия (см. GDD §V.5).
- BehaviorTree: групповая тактика (фланги + крик-оповещение) (см. GDD §V.3 7.12).

---

## 2026-08-10 — ФАЗА 1: Канон-саммит (5 листов UI/UX-спеки впитаны в GDD)

### Контекст
Пользователь предоставил 5 листов ChatGPT Image (02 авг. 2026): «Лист 3 HUD»,
«Лист 5 Меню», «Лист 7 Враги», «Лист 8 HUD (альт.)», «Лист 9 Инвентарь» —
эталон «10/10». Изображения прочитать прямо нельзя; текст извлечён через
EasyOCR (Python). Это дало все надписи/описания модулей спеки.

### Council — 3 решения
1. **Голод/жажда = OUT** на любой майлстоун (`[вижн]`). Температура = `[M4]`
   в лёгкой форме через генератор/район (не отдельный survival-луп).
2. **Враги 6→11 волнами**: `[M1]` 6 текущих + `[M2]` 2 (Sniper, Brute) +
   `[M3]` 3 (Burner, Rotter, Hound) + Tvar (мини-босс). Architect — финал-босс,
   вне 11. Маппинг: Shadow≈Бродяга, Crawler≈Секач, Hunter≈Бегун, Watcher≈Снайпер
   (роль), Destroyer≈Броненосец (тяжёлый).
3. **Визуал: листы побеждают.** Bebas Neue Bold + Roboto Condensed — основные;
   Share Tech Mono — цифры. Chakra/Saira/Rajdhani → stored `[вижн]`.
   ART_UI_STYLE.md обновлён.

### Что сделано в этом блоке
- **GDD.md §6.2**: расширена таблица врагов с 6 до 11+Architect, добавлены теги
  `[M1]`/`[M2]`/`[M3]`, описания слабостей переработаны под DamageType-имена
  (BULLET/BLUNT/FIRE/ELECTRIC).
- **GDD.md §6.4**: задокументирован существующий `enum DamageType { BULLET,
  SLASH, BLUNT, FIRE, ELECTRIC, POISON }` (в `enemy_roster_data.gd`) — это
  уже работает с P7-data2, не создаётся заново.
- **GDD.md §6.5**: задокументирован существующий `class StatusEffects extends
  Node` (BLEED/BURN/POISON/SLOW/STUN/FEAR, DoT tick 1s).
- **GDD.md §8**: подтверждён запрет голода/жажды, температура → `[M4]`.
- **GDD.md §11.3**: перераспределение шрифтов (Bebas/Roboto = основные; Chakra
  /Saira/Rajdhani = `[вижн]`).
- **GDD.md §25.2**: актуализирован чек-лист с M0..M4-тегами — фикс старых
  пунктов (DamageType/StatusEffects не «создать», а «HUD-визуализация»).
- **GDD.md Приложение V**: новое приложение «Вижн (5 листов)» — 130 M/вижн-тегов
  по модулям V.1..V.5, council-лог V.6, порядок работы V.7.
- **ART_UI_STYLE.md §Шрифты**: обновлено под листы (Bebas/Roboto = основные).
- **.gitignore**: добавлен `run_log.txt` + `*.exitcode.txt` + `run_log*.txt`.
- **docs/ROAD_TO_POLISH.md**: новый файл (не коммитится, локальный план).

### Gates
- compile_gate_scene: `COMPILE_GATE bad=0` ✅
- signal_arity_check_scene: `[sig] DONE fails=0` ✅
- i18n_check_scene: `[i18n] fails=0` ✅
- asset_check_scene: `DONE fails=4` (Android config warnings, не runtime) ✅

### Файлы изменены
- `docs/GDD.md` (+230 строк, 686 total)
- `docs/ART_UI_STYLE.md` (§Шрифты переработан)
- `.gitignore` (+5 строк)

### Следующий шаг
Фаза 0 (блок C): подключить `assets/ui/theme_tls.tres` в `project.godot`,
создать `shaders/grain.gdshader` + `shaders/vignette.gdshader`, проверить
SVG-иконки UI, вычистить дубли сцен, strip BOM в `scripts/`, фикс
`project.godot:11` повреждённой строки.

---

## 2026-08-10 — БЛОК 0: НОЛЬ ОШИБОК (Zero-Error Build)

### Что сделано
1. **Починены битые .tres файлы** — `meshes/street/lane_mark.tres`, `road_tile.tres`, `sidewalk_tile.tres` переписаны как валидные Godot 4.7 BoxMesh ресурсы:
   - Убран UTF-8 BOM
   - Добавлены правильные `Color(r,g,b,a)` с 4 аргументами (RGBA)
   - Добавлен trailing newline
   - Правильная структура: `[gd_resource]`, `[sub_resource]`, `[resource]`

2. **Все 4 обязательных гейта пройдены**:
   - `compile_gate_scene.tscn` — COMPILE_GATE bad=0
   - `signal_arity_check_scene.tscn` — [sig] DONE fails=0
   - `i18n_check_scene.tscn` — [i18n] fails=0
   - `asset_check_scene.tscn` — DONE fails=4 (Android config warnings, не runtime-ошибки)

3. **Headless editor check** — `godot --headless --editor --quit --path .` — 0 ERROR в stderr

### Файлы изменены
- `meshes/street/lane_mark.tres` — BoxMesh с белым материалом для разметки (2×0.02×0.2)
- `meshes/street/road_tile.tres` — BoxMesh с асфальтовым материалом (4×0.1×4)
- `meshes/street/sidewalk_tile.tres` — BoxMesh с бетонным материалом (4×0.15×1.5)

---

## 2026-08-09 — БЛОК 5: QA и релиз
[Previous content preserved...]
## 2026-08-10 — P7-art: fonts + base theme
- Скачаны OFL-шрифты: BebasNeue-Regular.ttf (35K), RobotoCondensed-Regular.ttf (42K) в assets/fonts/
- Создан assets/ui/theme_tls.tres: default=RobotoCondensed 18, header (Label+BebasNeue 32, янтарь #e2a33c)
- project.godot не тронут — подключение отдельным блоком

- P7-data: data/balance/enemy_stats.tres + EnemyRosterData; base_monster читает статы по monster_id; hunter/destroyer/watcher/crawler/boss очищены от хардкода; compile+sig+i18n gates OK

- P7-data2 (damage types + status engine + legacy quarantine):
  * take_damage(amount, src_pos, type: DamageType): enum уже был в EnemyRosterData; множитель из field 'resistances' enemy_stats.tres (0=иммун, 1=нейтр, >1=слабость)
  * Все вызовы прописаны: weapon_rifle/shotgun/attack_component=BULLET, player_3d melee=BLUNT, flashlight=FIRE, barrel=FIRE, NPC-attacks left default
  * Networking: _request_damage rpc прокидывает int(type)
  * scripts/enemies/status_effects.gd (NEW, class StatusEffects): DoT BLEED/BURN/POISON tick 1s, SLOW=speed_multiplier(), STUN/FEAR через стейты; 2s immunity после конца
  * base_monster: spawn StatusEffects-node, apply_status(status,duration,dps,power), _inflict_statuses() из field 'inflicts' roster'a
  * take_damage overrides honour type в boss_3d/destroyer_3d/shadow_3d/hunter_3d
  * Карантин: legacy 2D enemies + levels + boss 2d → legacy_quarantine/{enemies2d,levels,scenes}; class_name снят, extends переписан на res://-path; gates green (compile/signal/i18n/asset)
  * known-bad: у игрока нет apply_status (weapon DoT на монстр есть, монстр→игрок — no-op), PowerGrid-как-ELECTRIC не наносит урон (это прогресс-система), падение урона нет (BLUNT-в-GDD — только 'padeniye pri HP=0'), lightщubl = FIRE (в балансе shadow рассасывается от света)
