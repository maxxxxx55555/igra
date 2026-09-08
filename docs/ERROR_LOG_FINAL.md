# FINAL POLISH — ERROR LOG

## T6 incident + restore (STEP 0)
- First orphan run moved 101 files to assets/_orphaned/ (false positives on dynamic paths: crest_/ach_/<district>_floor|wall etc.).
- _restore_orphans.py (tls_gen) ran partially before session died: 94 restored, 7 left.
- Remaining 7: assets/_orphaned/_orphaned_textures_items_{backpack,can,flashlight,key,medkit,tool,water}_icon.tscn
  - Reason: .tscn has no .import sidecar; script restores via sidecar only.
  - Verified ZERO references in scripts/scenes/data/components (grep "_orphaned|<item>_icon.tscn").
  - Action: LEFT QUARANTINED in assets/_orphaned/ — genuine dead placeholder scenes superseded by items/*.png.
- Post-restore verification: 8 random .import sidecars spot-checked, source_file targets all exist -> 0 broken.
- crest_*_96.png x11 present in assets/textures/crests/. Fonts dir: 20 files intact.

## T6 redo (corrected WIRED rule)
- Classifier: basename grep + 12 dynamic %s-globs (crest_, ach_medal_v2_, monster_, stat_,
  branches headers, portraits, weather_, items/%s.png, photos/%s.png, skills %s_96, weapon renders,
  tiles %s_floor|wall) + 21 prefix whitelist + 508-name REPORT_* keep-set + mtime<10min skip.
- Dry run caught classifier bug (candidate-root vs file parent dir) BEFORE apply; fixed, re-dry-run,
  then applied: moved 145 (+140 .import sidecars) into assets/_orphaned/ preserving rel paths.
- Post-apply: 145/145 non-import files verified in _orphaned/assets/**; wired set untouched.

## ANOMALY (unresolved cause)
- The 7 quarantined .tscn placeholders (_orphaned_textures_items_*_icon.tscn) disappeared from
  assets/_orphaned/ root between the restore check and T6 apply. Not caused by _t6_redo.py
  (dry runs write nothing; apply only renames listed paths — verified 145/145 exact match).
  Pre-loss verification stood: zero refs, trivial ColorRect placeholders. No project impact.
  No copies found in _BACKUPS/.backup/.tls_bak.

## T7 / T8 results
- T7: 0 regens (all 76 scanned images textless; 11 detector flags disproven by zoom).
- T8: 0 fixes (all 20 sampled assets on-canon; crest_hospital flag = sampler resample artifact).

## QA-ПРОХОД 2 (полный аудит)
### 1. ext_resource integrity
- Скан: 141 .tscn/.tres (scenes/components/assets/addons/templates), 212 ext_resource → **0 битых**.
- Найден сломанный источник локализации: localization/strings.csv отсутствовал (остался только
  .import-сайдкар, ссылающийся на 13 несуществующих .translation). Проверка кода: LocalizationManager
  работает на data/i18n/*.json (не csv) → csv мёртвый артефакт. **Восстановлен** из
  _BACKUPS/_BACKUP_BEFORE_MEGA_PATCH_20260803_052926/localization/strings.csv (1134 б; оба бэкапа
  MD5-идентичны). Сайдкар снова валиден. РЕШЕНИЕ: восстановление, не удаление (безопасный default).

### 2. Текст и канон
- 5 «пустых» text-узлов (boot_loading.tscn Tip='...'; hud_3d.tscn BtnPause/BtnInteract/PromptLabel/
  EnemyName='') — все заполняются в рантайме (hud_3d.gd:22,33; controls.gd:4; screens.gd:604). НЕ дефекты.
- LORE.md / CANON.md отсутствуют; канон-референс = docs/ART_UI_STYLE.md (палитра bg-deep/panel/
  panel-edge/brass/brass-dim/ember/steel/bone/stamina).

### 3. Шрифты / глифы
- Аудит 10 .ttf через fontTools: подключённая в ThemeProvider тройка BebasNeue-Regular (269 глифов,
  латиница), RobotoCondensed-Regular (363, латиница), ShareTechMono (268, латиница) — **без кириллицы**.
  Игра дефолтится на ru → русские строки идут через ThemeDB fallback (SystemFont Noto/Arial). Риска
  tofu нет (fallback настроен в localization_manager.gd:57-78), но заголовки теряют канон-шрифт на ru.
  НЕ исправлял (правило: не трогать код/шрифты без.owner-решения — деградация косметическая).
- Дубли с кириллицей: bebas_neue_bold.ttf (family «Impact», 1019 глифов), roboto_condensed.ttf
  («Arial Narrow», 663) — ноль ссылок в коде/сценах. Похоже на кривые клоны, НЕ подключены.
  НЕ удалял (fonts под запретом прошлой сессии).
- ChakraPetch-Bold, SairaCondensed-{Bold,Regular}, Rajdhani-SemiBold — ноль ссылок (Rajdhani-Regular
  используется settings_manager.gd:_apply_dyslexia_font как dyslexia-режим; **OpenDyslexic-Regular.ttf
  отсутствует** — при включении опции load() вернёт null, тема откатится. Залогировано как известный баг).

### 4. UI палитра
- assets/ui/theme_tls.tres: 2 цвета — rgb(207,201,184) d=17 к bone, rgb(226,163,60) d=29 к brass —
  в допуске (≤40), НЕ off-canon. Запретные #000000/#ffffff не используются.
- project.godot theme/custom → theme_tls.tres, но theme_setup.gd (autoload) перезаписывает тему
  ThemeProvider.build_theme() на _ready — theme_tls фактически мёртв. НЕ трогал (project.godot
  вне разрешённых путей записи).

### 5. Сайд-эффекты — помечены ; UNUSED_SIDE_EFFECT, структура сохранена
| узел/файл | тип | причина |
|---|---|---|
| scenes/main_3d.tscn :: AudioAmbient | AudioStreamPlayer3D | пустой (нет stream), код не обращается |
| scenes/main_3d.tscn :: AudioSFX | AudioStreamPlayer3D | пустой (нет stream), код не обращается |
| scenes/player/player_3d.tscn :: Footsteps | AudioStreamPlayer3D | заменён кодовой FootstepSystem (player_3d.gd:235) |
| scenes/pickups/document_pickup.tscn :: AnimationPlayer | AnimationPlayer | ни одного play()-вызова в scripts/document_pickup.gd |
| scenes/effects/{blood_particles,footstep_dust,hit_spark,muzzle_flash}.tscn | PackedScene | дубли scenes/vfx/* (живые потребители: base_monster.gd:589-590 preload, weapon_{pistol,rifle,shotgun}.tscn:4). Ноль входящих ссылок |
- Формат пометки: строка `; UNUSED_SIDE_EFFECT (…)`. Первый вариант с хвостом после `[node …]` отклонён
  самопроверкой (риск парсинга) → перенесён: в main_3d/player_3d/document_pickup коммент СТРОКОЙ ВЫШЕ
  узла (валидно: comments игнорируются парсером между узлами), в effects/* — в КОНЕЦ файла (после
  [gd_scene] в первой строке коммент невалиден). Все 7 файлов перепроверены: node counts и [gd_scene]
  заголовки целы.
- Ash (GPUParticles3D, main_3d:68) — НЕ помечен: emitting=true, это живой атмосферный эффект.
- HUD (main_3d:78) — НЕ помечен: инстанс hud_3d.tscn, самоуправляемая сцена.
- AudioStreamPlayer.new() в коде (audio_system.gd, proc_audio.gd и др.) — НЕ мусор: пул/фабрики.

### 6. Карантин
- legacy_quarantine/: 25 .uid + пустые папки (enemies2d, enemy_light, levels) — .gd тел уже нет,
  0 входящих res:// ссылок из scripts/scenes/data/assets/addons/templates.
- assets/_orphaned/: 145 файлов + 140 .import, 0 входящих ссылок — на запуск игры не влияет.
- Аномалия исчезновения 7 .tscn — см. секцию ANOMALY выше: внешнее воздействие, ноль зависимостей,
  краш исключён (grep по всем consumer-директориям).

### Счётчик изменений QA-2
- восстановлено: 1 (strings.csv)
- помечено: 8 (4 узла + 4 сцены-дубли) + отчёт по 6 шрифтам и theme_tls.tres
- удалено: 0; структура узлов: 100% сохранена

## ВОЛНА 3 — OWNER-DECISIONS + SAFE-CLEANUP + INTEGRITY (2026-09-01)

### Owner-решения
- Собраны факты по 3 кандидатам (кто ссылается/локали/fallback) → docs/DECISIONS_PENDING.md.
- D1 (шрифты без кириллицы): влияет на контент → PENDING. Ключевой факт: дубли
  bebas_neue_bold/roboto_condensed — другие шрифты (Impact/Arial Narrow), НЕ «Bebas/Roboto
  с кириллицей»; подключить их = сменить гарнитуру. Рекомендация B: Bebas→Rajdhani fallback-цепочка.
- D2 (theme_tls.tres): мёртвый (единственный потребитель — project.godot, перезаписывается
  ThemeSetup-автолоадом), но вариант A требует правки project.godot → PENDING (рекомендую B: оставить).
- D3 (OpenDyslexic): фича заявлена в настройках, шрифта нет → load()=null, тихий сброс
  оверрайда (краша нет — измерено headless boot). Влияет на доступность → PENDING
  (рекомендация B: добавить OFL-шрифт).

### Карантин (переносы, не удаления)
- Повторный grep «ноль ссылок» по всем consumer-директориям: 6 шрифтов = 0 refs,
  4 сцены-дубли = 0 refs → перенесены в _QUARANTINE/ с сохранением rel-путей
  (fonts: 6 ttf + 6 .import; effects: 4 tscn).
- PS-глюк при первом переносе .import (кавычки в Join-Path) — все 6 перемещены
  со второй попытки, assets/fonts сверен: осталось ровно 4 рабочих ttf + 4 .import.

### Удаление 4 узлов (по правилу: только после headless-верификации)
- Бэкап до правки: _BACKUPS/2026-09-01_unused_nodes_pre_removal/ (3 tscn).
- Удалены: main_3d AudioAmbient+AudioSFX (20→18 узлов), player_3d Footsteps (22→21),
  document_pickup AnimationPlayer (6→5).
- Inline-python через PS падал на escaping (3 попытки, SyntaxError) → скрипты на диске.
- Первый regex-проход снял только 3/4 узла (PATTERN MISS AudioSFX: после удаления
  AudioAmbient маркер-строка AudioSFX потерялась) → точечный второй проход, 4/4.
- Вычищены осиротевшие ресурсы удалённых узлов: ext 4_step, sub flashlight_cyl_mesh
  (осиротевший ЕЩЁ ДО волны — подтверждено по бэкапу), sub AnimLib_1; load_steps
  пересчитаны (29→28, 7→6).

### Integrity (headless Godot 4.7, измерено)
- _scene_check.gd: SCENES_TOTAL=137 LOADED=137 ERRORS=0 (дублей в карантине нет в дереве).
- «Compilation failed» строки в логе — ЛОЖНЫЕ срабатывания чекера: load() в SceneTree._init()
  до регистрации автолоадов (LocalizationManager/EventBus/AudioManager). Полный boot
  (--quit-after 3): 0 ERROR, единственный шум — «3 resources still in use at exit».
- Локализация: t() живой; строки реальны. strings.csv: TranslationServer не регистрирует
  (dest .translation не сгенерированы) — csv не используется игрой (JSON = истина, 815 ключей).
- verify_wave2.py: play_final 6/6 ALL_PASS; байты 6/6 идентичны бэкапу.
- ОТКАТОВ не потребовалось; integrity не падал.

### Итог волны 3
- Решения: 0 применено / 3 pending | Карантин: 10 файлов (6 шрифтов+сайдкары, 4 сцены) |
- Удалено узлов: 4 (с бэкапом + headless-верификацией) | Integrity: 137/137, ссылки M/M, 6/6 гейтов |
- Заблокировано: 0.



