# REPORT — FINAL POLISH WAVE

## Волна 3: OWNER-DECISIONS + SAFE-CLEANUP + INTEGRITY (2026-09-01)

Решения: 0 применено владельцем-агентом / 3 pending (все три влияют на контент/доступность —
по правилу волны НЕ применялись самовольно). Полная таблица фактов/вариантов:
**docs/DECISIONS_PENDING.md** (D1 шрифты-кириллица, D2 theme_tls.tres, D3 OpenDyslexic).

Карантин (_QUARANTINE/, перенос, НЕ удаление) — после повторной проверки «ноль ссылок»:
- 6 шрифтов: bebas_neue_bold, roboto_condensed, ChakraPetch-Bold, SairaCondensed-{Bold,Regular},
  Rajdhani-SemiBold (+ их .import-сайдкары) ← assets/fonts/
- 4 сцены-дубли: scenes/effects/{blood_particles,footstep_dust,hit_spark,muzzle_flash}.tscn
  (заменены scenes/vfx/*, потребители: base_monster.gd:589-590, weapon_*.tscn)
- В assets/fonts остались только 4 рабочих шрифта + сайдкары (Bebas, Rajdhani-Regular,
  RobotoCondensed-Regular, ShareTechMono).

Удалено (с предварительным бэкапом _BACKUPS/2026-09-01_unused_nodes_pre_removal/):
4 узла-сайд-эффекта + их осиротевшие ресурсы, ПОСЛЕ headless-верификации:
| сцена | удалённый узел | осиротевшие ресурсы (вычищены) | headless после правки |
|---|---|---|---|
| main_3d.tscn | AudioAmbient, AudioSFX (пустые AudioStreamPlayer3D) | — | PASS (137/137) |
| player_3d.tscn | Footsteps (заменён кодовой FootstepSystem) | ext 4_step (step_concrete.wav), sub flashlight_cyl_mesh (был осиротевшим ДО волны), load_steps 29→28 | PASS |
| document_pickup.tscn | AnimationPlayer (нет play-вызовов) | sub AnimLib_1, load_steps 7→6 | PASS |

Integrity (измерено, headless Godot 4.7):
- Сцены: **137/137 загружено, 0 parse errors, 0 missing resources**
  (141 в дереве минус 4 дубля в карантине; tools/_probe-сцены в расчёте не участвуют).
- Полный boot проекта: 0 ERROR; автолоады LocalizationManager/EventBus/GameManager/ThemeSetup
  живы; известный шум «N ObjectDB instances leaked» — cleanup-предупреждение, не блокер.
- Локализация: LocalizationManager.t() живой (ACHIEVEMENTS_TITLE→"Achievements", ui_close→"Close");
  истина игры = data/i18n/*.json (815 ключей ru=en). strings.csv — legacy (30 ключей, 27 мёртвых,
  3 дублируют JSON): TranslationServer его НЕ регистрирует (.translation артефакты не генерятся
  без editor-import) — **в игре не используется, краша нет, текстовые узлы наполняются из JSON**.
- play_final гейты: **6/6 ALL_PASS** (verify_wave2.py), байты идентичны бэкапу 6/6.

Заблокировано: 0. Откатов не потребовалось.

---

(история волн ниже)


**Готово. Восстановлено: 1 (strings.csv из бэкапа) | Проверено: 96 без текста/на каноне (0 глифов, 0 исправлений палитры) + 141 сцена (0 битых ext_resource из 212) + 10 шрифтов | Исправлено: 0 | Помечено как лишнее: 4 узла-сайд-эффекта + 4 сцены-дубли + 2 дубли-шрифта** (+8 побочных эффектов безопасно закомментировано `; UNUSED_SIDE_EFFECT`, структура узлов сохранена). Аномалия: 7 карантинных .tscn исчезли из-за внешнего воздействия (до применения; ноль ссылок, никакого влияния — залогировано).

## Расшифровка QA-прохода (этап 2)
- **ext_resource:** 212 ссылок в 141 .tscn/.tres → 0 битых. Сцены целы.
- **Текст:** 5 «пустых» Label/Button (hud_3d.tscn, boot_loading.tscn) — все заполняются кодом (hud_3d.gd:22,33; screens.gd:604). 0 дефектов. LORE.md отсутствует — канон = docs/ART_UI_STYLE.md.
- **Шрифты:** тема (theme_provider.gd) грузит латинскую тройку Bebas/RobotoCondensed/ShareTechMono без кириллицы — на ru-строках срабатывает ThemeDB fallback (не tofu, но канон-деградация: заголовки теряют Bebas). Дубли bebas_neue_bold.ttf (Impact) и roboto_condensed.ttf (Arial Narrow) с кириллицей — ноль ссылок. ChakraPetch/SairaCondensed/Rajdhani-SemiBold — ноль ссылок (Rajdhani-Regular используется dyslexia-настройкой; OpenDyslexic-Regular.ttf отсутствует — путь в _apply_dyslexia_font молча загрузит null при включении опции).
- **UI палитра:** theme_tls.tres — 2 цвета, оба в допуске (d=17/29 к bone/brass); project.godot всё ещё указывает на theme_tls.tres, но theme_setup.gd перезаписывает тему ThemeProvider'ом на _ready. Не трогал (project.godot вне прав).
- **Сайд-эффекты (помечены `; UNUSED_SIDE_EFFECT`, НЕ удалены):**
  - main_3d.tscn: AudioAmbient, AudioSFX (пустые AudioStreamPlayer3D, код не обращается)
  - player_3d.tscn: Footsteps (заменён кодовой FootstepSystem из footstep_system.gd)
  - document_pickup.tscn: AnimationPlayer (нет play-вызовов)
  - scenes/effects/{blood_particles,footstep_dust,hit_spark,muzzle_flash}.tscn — дубли scenes/vfx/* (реальные потребители: base_monster.gd:589-590, weapon_*.tscn)
- **Карантин:** legacy_quarantine = 25 .uid + пустые папки (0 входящих ссылок); assets/_orphaned = 145 файлов + 140 sidecars (0 входящих). Аномалия исчезновения 7 .tscn — см. ERROR_LOG_FINAL.md.
- **Восстановление:** localization/strings.csv восстановлен из _BACKUPS (оба бэкапа MD5-идентичны; .import-сайдкар снова валиден).

## File actions (этап 1, T6 redo)
| file / group | action | consumer hint / reason |
|---|---|---|
| 94 files previously in assets/_orphaned/ | restored | via _restore_orphans.py; incl. 11 crest_*_96.png, 20 fonts |
| assets/textures/environment/* (4) | orphaned | zero refs; superseded by tiles/<district>_floor|wall.png |
| assets/textures/icons/*_64.png (27) | orphaned | v1 icon set; UI uses ui_v2 + icons_v2 |
| icons_v2: ctrl_*/district_*/event_*/upgrade_*/craft/*/cycle/*, *_128 (46) | orphaned | zero refs (см. таблицу выше) |
| thumbs_v2/*_thumb_256x144.png (6) | orphaned | zero refs; only ui_v2/weather template in code |
| fog_depth.gdshader, ui/*.tres x4, sfx/jingles/one_shots (~62) | orphaned | zero refs |

## T7 — textless scan
76 images: 0 glyphs (все флаги детектора = зерно/окна/маркеры). 0 regens.

## T8 — canon palette pass
20 sampled assets: 100% canon (crest_hospital flag — артефакт ресемплинга).

## Verification
- 8 random .import sidecars → 0 broken. 145/145 orphaned exact-match. All marked .tscn structurally intact (node counts unchanged).

