# ROAD_TO_POLISH — план «до идеала» (полный аудит 2026-08-10)

> Источники требований: `docs/GDD.md` v4 (канон), `docs/ART_UI_STYLE.md`, `docs/UI_SPEC.md`, `docs/GDD_CONFORMANCE.md`.
> Каждый пункт = одна ветка = один PR (AGENTS.md §PR rules).
> Приоритет: **P0** = блокирует релиз/сборку; **P1** = видимое игроку; **P2** = полировка.

---

## A. Технический долг (блокирует «красиво»)

### A0. **P0 — project.godot повреждён**
- `project.godot:11` — мусорная строка `"ï»¿config_version"=5` (BOM-хвост). Must fix.
- `config/icon="res://assets/ui/icon.png"` — но `assets/ui/` пустой, файла нет.
- `AGENTS.md` упоминает 48 автолоадов; фактически 50 (есть `I18n`, `AdManager`, нет `ScreenFlowManager`). Reconcile с `docs/GDD.md:371-379`.
- **Файл:** `project.godot`, `assets/ui/icon.png`, `docs/GDD.md` §16.2 (обновить канон или код).

### A1. **P0 — BOM в ~140 .gd файлах**
- AGENTS.md: «UTF-8 without BOM». Фактически ~140 файлов (вся кодовая база кроме старых переименованных) имеют BOM.
- Симптом: в `scripts/systems/music_manager.gd` комментарии читаются как `"??????????"` — código russo ilegível.
- **Действие:** массовый strip BOM (Latin1 → UTF-8 no BOM), один коммит,doctor.ps1 должен это ловить.
- **Исключить:** `legacy_quarantine/`, `.tls_bak/` (мёртвый код — не чинить, см. A3).

### A2. **P1 — 156 `.gd.uid` файлов в репо**
- `*.gd.uid` — Godot internal, обычно не коммитятся. Удалить из git, добавить в `.gitignore`.
- Один коммит: `git rm --cached *.gd.uid` + `.gitignore`.

### A3. **P0 — мёртвый код `legacy_quarantine/` и `.tls_bak/`**
- AGENTS.md §Never commit: `.tls_bak/` уже под запретом.
- `legacy_quarantine/` — 17 файлов со старым 2D-движком, никто их не грузит.
- **Действие:** `git rm -r legacy_quarantine/ .tls_bak/`, добавить в `.gitignore`. Проверка: `compile_gate` должен остаться `bad=0`.

### A4. **P0 — дубли сцен в `scenes/ui/`**
| Группа | Файлы | Действие |
|--------|-------|---------|
| settings | `settings.tscn`, `settings_menu.tscn`, `settings_screen.tscn` | оставить 1, удалить 2 |
| credits | `credits.tscn`, `credits_screen.tscn` | оставить 1 |
| difficulty | `difficulty.tscn`, `difficulty_screen.tscn` | оставить 1 |
| victory | `Victory.tscn`, `victory_screen.tscn` | оставить 1 |
| gameover | `GameOver.tscn`, `game_over.tscn` | проверить, оставить 1 |

- Для каждой группы: grep по `load()/preload()/change_scene_to_file()` — какой реально используется.
- Удалить неиспользуемые, обновить ссылки. Гейт `asset_check` это словит.

### A5. **P1 — `stress_test.gd` отладочный скрипт в основной кодовой базе**
- `scripts/stress_test.gd` помечен в AGENTS.md как не-коммит (debug scaffolding). Check references, remove if unused.

---

## B. Визуальная красота (это и есть «как щас → идеально»)

### B1. **P0 — нет единой Theme.tres**
- `assets/ui/theme_tls.tres` упомянут в progress.md, но `assets/ui/` **пустой**.
- `ThemeSetup` автолоад объявлен, но ресурса темы нет — все экраны рендерятся дефолтными Godot-стилями (чёрные кнопки, системный шрифт).
- **Действие:** создать `assets/ui/theme_tls.tres` со:
  - StyleBoxTexture/Flat с chamfer-углами для Panel (использовать NinePatch или StyleBoxFlat с `border_blend`, нулевой corner radius, chamfer через `expand_margin`).
  - Цвета Canon Tokens: `bg-deep #0c1016`, `panel #141b24`, `panel-edge #2a3340`, `brass #c9a24a`, `brass-dim #8a7338`, `ember #b4452f`, `steel-text #aeb6bf`, `bone-text #d8d2c4`, `stamina #5f8a4e`.
  - Шрифты: ChakraPetch-Bold (headers), SairaCondensed-Bold (panel titles), Rajdhani-Regular/SemiBold (body), SairaCondensed-Regular (secondary), ShareTechMono-Regular (numbers).
  - Запретные цвета (`#000000`, `#ffffff`) — ни в одном StyleBox.
- **Подключить в `project.godot`**: `[gui] theme/custom="res://assets/ui/theme_tls.tres"` либо через `ThemeSetup`.
- **Чек:** каждый из 25 экранов UI_SPEC зачистить от инлайн StyleBoxFlat — пусть наследуют от Theme.

### B2. **P1 — нет шейдеров grain + vignette**
- `shaders/` существует, но пуст. ART_UI_STYLE §«Зерно и виньетки»: ColorRect на CanvasLayer с ShaderMaterial.
- **Действие:** создать `shaders/grain.gdshader` (animated noise, 8-12% opacity), `shaders/vignette.gdshader` (radial прозрачное → `#0c1016`).
- Поднять как `post_process.tscn` (уже есть, доработать) → CanvasLayer high z-order.
- Подключить во все экраны кроме HUD (на HUD поверх玩耍).

### B3. **P1 — `panel_card.gd` есть, но не используется всеми экранами**
- `scripts/ui/panel_card.gd` определён, но экраны рисуют свои панели вручную. UI_SPEC §«Все экраны через PanelCard».
- **Действие:** один PR прогоняет 8 ключевых экранов (MAIN_MENU, SETTINGS, SHOP, INVENTORY, JOURNAL, BESTIARY, WORKBENCH, FLASHLIGHT_UPGRADE) через PanelCard → единый вид.

### B4. **P1 — иконки 128×128 для предметов: есть файлы, нет в Theme**
- `assets/textures/items/` — 32 PNG. Но UI-код использует ColorRect-placeholder, а не текстуры.
- UI_SPEC §9 INVENTORY: «иконка-плейсхолдер + бейдж кол-ва». Plações намёк — надо заменить на `TextureRect` с реальными PNG.
- **Действие:** один PR — проводка `item_data.gd` → `item.icon: Texture2D` preload по имени, лиоя inventory_panel + quick slots + shop. Везде один ракурс.

### B5. **P1 — 3D-грейд: AgX vs ACES**
- GDD §11.6: «Tonemap ACES (AgX недоступен в Compatibility)».
- ART_UI_STYLE.md § «Tonemap **AgX** (основной) — единственный, не менять».
- **Конфликт канонов.** Решить через GDD (выигрывает GDD.md): ACES. Привести ART_UI_STYLE к GDD либо обновить GDD (через совет).
- **Технически:** `world_env_setup.gd` → Environment.tone_mapper. Проверить, что в GL Compatibility действительно нет AgX (его добавили в 4.3, может быть доступен). Если доступен — AgX даёт лучше для тёплого/холодного контраста; обновить канон.

### B6. **P1 — depth fog цвет и density не по канону**
- Канон: `#1a2133`, density 0.012–0.015.
- Проверить `world_env_setup.gd`, `fog_setup.gd` на соответствие цифрам.
- На DARK-стадии — может быть плотнее (атмосфера тьмы), на FULL — слабее (награда «район спасён, видно»). Сейчас линейно?

### B7. **P1 — HUD раскладка не соответствует ART_UI_STYLE §HUD**
- Канон: лево-верх HP/Stamina/Battery (сегментированный для батареи), право-верх круглый radar, низ-центр хотбар 6, лево-низ джойстик-кольцо, право-низ кластер круглых кнопок brass.
- Проверить `scenes/ui/hud_3d.tscn` и `hud.tscn` —哪一个 canonical?
- Сегментированная батарея (5–10 сегментов, brass→brass-dim→empty) — обязательный элемент, مرئي в тьме, главный feedback разряда.

### B8. **P2 — силуэты монстров 512×512 ещё не на месте**
- GDD §11.5: «Монстры: 512×512 силуэты-плейсхолдеры».
- Проверить `assets/` — есть ли placeholder PNG на Shadow/Crawler/Watcher/Hunter/Destroyer/Boss.
- Либо PNG, либо процедурные Cohetes de humo силуэты — но должно быть едино.

### B9. **P2 — районные тайлы 256² бесшовные**
- GDD §11.5: «Тайлы районов: 256² для полов/стен/потолков, палитры в ART_AUDIO_PROMPT §ENVIRONMENT».
- Проверить `assets/textures/` на tile-ness (seamless).

### B10. **P2 — иконки outline 1.5–2px brass**
- UI-иконки (не items): linear outline, толщина 1.5–2px, без заливки. Проверить `assets/ui/` — он пуст. Все SVG/PNG UI-иконок должны быть созданы или заменены на themed Button + FontIcon.

---

## C. Звук — adaptive music

### C1. **P1 — music_manager не канон**
- Текущий (`scripts/systems/music_manager.gd`):
  - 6 Mood (MENU/AMBIENT/TENSION/BATTLE/BOSS/VICTORY), crossfade 2.2s, `.wav` файлы.
- Канон (GDD §13): **5 adaptive layers** — `Ambient_Dark, Ambient_Lit, Threat_Low, Threat_High, Action_Sting`, crossfade **2.0 с**.
- **Действие:** переписать enum Mood → 5 слоёв + State для district ambience (Ambient_Dark/Lit by stage). Fixed DAY/NIGHT/LIT/FULL уже есть в PowerGrid. Layer`s blend by signal `district_stage_changed`.
- Porno crossfaderтех 2.0s exactly. District ambience — 6 треков (`downtown/harbor/industrial/park/residential/default`).
- GATE: добавить «music_layer_check» в `craft_check_scene.tscn` или отдельный скрипт, проверять соответствие 5+6.

### C2. **P1 — футстепи 6×3 поверхностей: проверить**
- GDD §13: 6 поверхностей (асфальт/бетон/дерево/металл/лужа/стекло) × 3 скорости.
- GDD §22: SFX-файлы названы `step_asphalt_dry/wet, step_clank, step_concrete, step_dirt, step_glass, step_gravel, step_metal, step_puddle, step_wood` — **9 файлов**, не 6×3=18.
- **Решить:** расширить номенклатуру до 6×3 (asphalt dry/wet есть, добрать бетон/дерево/металл/лужа/стекло × {walk/run/sneak}). Или принять 9+как достаточно и обновить GDD §13/§22.

### C3. **P2 — audio paths и формат**
- GDD: «OGG music, WAV→OGG SFX». Фактически music `.wav`. Конвертировать music → `.ogg` (godot import-настройка loop + compressed).

---

## D. Локализация

### D1. **P1 — screens.gd хардкод RU**
- GDD §25.2: «Полная локализация `screens.gd` (~1900 строк) через `tr()`».
- 233 `tr()` по всей базе — частично. Найти хардкод-строки RU в `scripts/ui/screens.gd` (если она агрегатор) и каждом экране.
- **Gate:** `i18n_check_scene.tscn` уже проходит `fails=0` — значит gate слабоват, проверить расширение.
- Создать недостающие ключи в 13 локалях `data/i18n/*.csv`.

---

## E. Гейты и CI

### E1. **P0 — все 8 гейтов должны быть зелёные**
- GDD §16.4 перечисляет 8 гейтов. Фактически AGENTS.md гоняет 4.
- **Добавить 4 гейта:** `autoload_api_check_scene.tscn`, `craft_check_scene.tscn`, `--quit-after` runtime, `doctor.ps1`.
- Каждый должен exit 0.
- **PR description** обязан содержать результаты 4+4 гейтов.

### E2. **P1 — doctor.ps1 должен словить BOM и дубли**
- Дописать в `scripts/tools/validate_all.gd` / `doctor.ps1`: check BOM, check duplicate scenes по BaseName, check. действующий список автолоадов = канон §16.2.

---

## F. Android и релиз

### F1. **P0 — Android APK не собран**
- GDD §25.2: «arm64, keystore, debug OFF, собрать и проверить на устройстве».
- `docs/ANDROID_BUILD.md` есть. Действие: сделать `export_presets.cfg` через Godot UI (Android, arm64, keystore), собрать debug APK, проверить запуск на эмуляторе/устройстве.
- AGENTS.md §art-pipeline: код не блокируется на релиз-арте, но `export_presets.cfg` кодовый файл — должен быть в репо.

### F2. **P1 — AdMob plugin пустой**
- `scripts/monetization/admob_provider.gd:8` `TODO: подключить GodotAdMobPlugin`.
- Без плагина AdProvider — фасад (AGENTS.md это допускает). Документировать в `progress.md` как намеренный geçir.

### F3. **P2 — release_checklist**
- `docs/release_checklist.md` проверить по финальной упаковке.

---

## G. Геймплейные конформационные дыры (консервативные)

Из `GDD_CONFORMANCE.md` majority = PARTIAL. Ключевые нерешённые статические сомнения:

### G1. **P1 — сюжет (§12.3) MISSING**
- 3 акта, D10 точка невозврата. В коде не проверено. Найти `scripts/levels/`/`level_01..03.gd` — есть ли act-gating?
- Реализовать gate: `GameManager.advance_act(n)` тригерится по district count.

### G2. **P1 — 5 концовок (§12.4) — проверить EndingsManager**
- Условия: Свет/Надежда/Выживший/Тьма/Истина. Найти в `scripts/systems/endings_manager.gd` matrix, добавить craft_gate matrix test.

### G3. **P2 — Workbench recipe strobe discrepancy**
- GDD §9: strobe = `2 предохранителя + 1 трансформатор`. GDD §20: strobe = `2 fuse + 5 scrap`. Один источник vrai. Решить через совет.

### G4. **P2 — autoloader count 48 vs 50**
- GDD §16.2 = 48. Проект = 50 (с `I18n`, `AdManager`). Согласовать: либо обновить канон, либо слить лишнее.

---

## H. Порядок работы (зависимости)

```
A0 project.godot fix → A1 BOM strip → A3 rm legacy → A4 dedup scenes → A2 rm .uid
                                  ↓
B1 theme_tls.tres → B2 grain/vignette shaders → B3 PanelCard → B4 item icons wire
              ↓                ↓
B5 ACES/AgX решение → B6 fog tune → B7 HUD layout
                                  ↓
C1 music_manager rewrite → C2 footstep nomenclature → C3 OGG
                                  ↓
D1 screens.gd tr() → E1 все 8 гейтов зелёные → E2 doctor.ps1 BOM/dedup
                                  ↓
F1 Android APK → F2 AdProvider doc → G1..G4 conformance
                                  ↓
RELEASE
```

## I. Чек-лист «идеально»

- [ ] Все 8 гейтов exit 0 (compile, autoload_api, signal_arity, asset, i18n, craft, runtime, doctor).
- [ ] 0 BOM в `scripts/`, 0 `.uid` в git, 0 дублей сцен.
- [ ] `assets/ui/theme_tls.tres` подключён в `project.godot`, каждый экран использует её, 0 хардкод-StyleBox.
- [ ] `shaders/grain.gdshader` + `vignette.gdshader` на CanvasLayerповерх всех экранов.
- [ ] 音: 5 adaptive layers, crossfade 2.0s, district ambience по стадии.
- [ ] Локализация: 13 локалей × 198 ключей, 0 хардкод-строк.
- [ ] HUD: сегментированная батарея, круглый radar brass, хотбар 6, кластер круглых кнопок brass-dim.
- [ ] Все 32 иконки предметов в TextureRect (не ColorRect-placeholder).
- [ ] Android APK собран и запущен.
- [ ] 5 концовок + 3 акта + точка невозврата D10 — есть gate-тест.
- [ ] `progress.md` обновлён после каждого блока, `docs/GDD_CONFORMANCE.md` перепроверен → DONE по каждому пункту.
