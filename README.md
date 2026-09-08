# THE LAST STREETLIGHT

3D FPS survival-horror стелс-игра. Godot 4.7, рендерер GL Compatibility.
Платформы: Android (основная), Windows/Web (пресеты добавлены, экспорт
ещё не проверен вживую — см. `PLAN.md`).

**Лор одной строкой**: город обесточен, город полон монстров. Ты чинишь
электросеть район за районом — включённый уличный фонарь и есть твоя
награда и твоё убежище одновременно.

## Как запустить

1. Открой `project.godot` в **Godot 4.7 Stable** (движок лежит в
   `..\godot_extracted\Godot_v4.7-stable_win64_console.exe`, если у тебя
   его ещё нет под рукой).
2. Нажми **F5** (или кнопку Run) — либо из терминала:
   ```bash
   Godot_v4.7-stable_win64_console.exe --path .
   ```
3. Рендерер: **GL Compatibility**, уже настроен в `project.godot`, ничего
   менять не нужно.

**Точка входа**: `project.godot`'s `run/main_scene` →
`scenes/ui/boot_loading.tscn` → далее по цепочке
`Routes` (`scripts/core/routes.gd`): boot → сплэш → главное меню →
(New Game/Continue) → `scenes/main_3d.tscn` (весь игровой мир собирается
в одной сцене из районов).

## Структура проекта

```
scenes/          — сцены (.tscn): ui/, districts/ (11 районов), props/, weapons/, vfx/, tools/ (гейты)
scripts/         — GDScript (.gd)
  core/          — GameManager, SaveSystem, Routes
  events/        — EventBus (единая шина сигналов)
  ui/            — HUD, меню, экраны (большинство строится процедурно из кода, не из .tscn)
  systems/       — MusicManager, WeatherSystem, PowerGrid, SkillTreeManager, AudioManager и др.
  world/         — районы, фонари, атмосфера, генератор
  enemies/       — 12 типов монстров + босс (base_monster.gd — общий FSM)
  weapons/       — pistol/rifle/shotgun (weapon_base.gd — общий класс)
  monetization/  — AdService (AppLovin MAX, за фича-флагом)
  tools/         — гейты качества и разовые пробники (_asset_check.gd и т.п.)
assets/          — текстуры, звук, шрифты, UI-графика
data/            — i18n (13 языков), предметы, балансировочные .tres
docs/            — GDD, Production Bible, история волн разработки, отчёты сессий
tools/           — гейты (check.sh, flow_check.py, scene_node_check.py), скрипты сборки
```

Автозагрузки (`/root/<Name>`) настроены в `project.godot`'s `[autoload]`
секции — свежий подсчёт: **53 автозагрузки** (`GameManager`, `EventBus`,
`SaveSystem`, `MusicManager`, `WeatherSystem`, `AdService` и т.д.).

## Сборка APK (Android)

### Требования
- Godot 4.7 с Android Export Template
- Android SDK (min SDK 29, target SDK 34)
- JDK 17+
- Keystore (debug: `tls_debug.keystore` — уже в репозитории; **релизный
  keystore ещё не создан**, см. `PLAN.md` и `docs/RELEASE_FINAL.md`)

### Команды
```bash
godot --headless --export-debug "Android" build/TLS.apk
# или через редактор: Project → Export → Android → Export Project
```

Пакет: `com.maxsimkasky.laststreetlight` — **зафиксирован**, менять
после первой публикации в Play Console будет уже нельзя.

Пресеты Web и Windows Desktop добавлены в `export_presets.cfg`, но
Godot export templates для них ещё не устанавливались в этом окружении —
экспорт не проверялся вживую.

## Обязательные проверки перед коммитом

```bash
bash tools/check.sh --static
python tools/flow_check.py
python tools/scene_node_check.py
```

Полная версия (с движковыми гейтами, включая цикл загрузки) —
`bash tools/check.sh` без `--static`. Отдельные движковые гейты (если
общий скрипт зависает — известная особенность окружения, не баг):

```bash
Godot_v4.7-stable_win64_console.exe --headless --path . scenes/tools/compile_gate_scene.tscn
Godot_v4.7-stable_win64_console.exe --headless --path . scenes/tools/signal_arity_check_scene.tscn
Godot_v4.7-stable_win64_console.exe --headless --path . scenes/tools/autoload_api_check_scene.tscn
Godot_v4.7-stable_win64_console.exe --headless --path . scenes/tools/i18n_check_scene.tscn
Godot_v4.7-stable_win64_console.exe --headless --path . scenes/tools/asset_check_scene.tscn
Godot_v4.7-stable_win64_console.exe --headless --path . scenes/tools/save_integrity_check_scene.tscn
Godot_v4.7-stable_win64_console.exe --windowed --path . scenes/tools/boot_check_scene.tscn
```

Все должны завершиться с кодом `0` (`fails=0`/`bad=0` в выводе).
`boot_check_scene.tscn` в `--headless` режиме в этом окружении зависает —
известная особенность песочницы, всегда запускай его с `--windowed`.

## Текущее состояние проекта

Проект прошёл множество волн разработки (полная история — в
`docs/HANDOFF.md` и `docs/SESSION_REPORT_*.md`). Ядро игры полностью
играбельно: меню → новая игра → 11 районов, электросеть, стелс, бой,
крафт, скилл-дерево, 5 концовок, сохранения, 13 языков интерфейса.

**Для актуального разбора «что готово / что нет» и плана дальнейших
работ — читай `PLAN.md` в корне репозитория.** Он написан специально,
чтобы любой человек или ИИ-агент мог продолжить проект без дополнительных
объяснений.

## Важно знать перед началом работы

- **Параллельная сессия** отдельного ИИ-агента (условно «OpenCode»)
  периодически коммитит напрямую в `main`, в основном ассеты
  (`assets/audio/`, `assets/textures/`) и отчёты (`docs/REPORT_*.md`).
  Перед началом работы всегда смотри `git status` — незакоммиченные
  изменения в `assets/` почти наверняка принадлежат ей, не трогай их без
  необходимости.
- Никогда не запускай `godot --headless --editor --quit` (полный
  реимпорт проекта) — это надёжно ломает `default_bus_layout.tres`
  (роняет шину Master). Если файл повреждён — `git checkout --
  default_bus_layout.tres`.
- Не удаляй файлы, пока не доказано, что они мертвы **и** не запланированы
  как фича (урок из `hiding_spot.gd` — см. `CLAUDE.md`).
- Полная поддержка 13 языков обязательна для любой новой строки текста —
  через `LocalizationManager.t()`, никогда через нативный `tr()` Godot на
  «сырое» предложение (это реальный баг, который уже несколько раз чинили).
