# PLAN.md — точка передачи контекста

Этот файл — единая точка входа для любого человека или ИИ-агента,
который продолжает проект. Составлен на основе `docs/GDD.md` (ТЗ,
844 строки, канон механик/чисел), `docs/PRODUCTION_BIBLE.md` (визуал/
аудио/бюджеты, читается первым в начале каждой волны — см. `CLAUDE.md`),
`docs/KNOWN_ISSUES.md` и `docs/HANDOFF.md` (история находок), плюс живая
проверка текущего кода (не только чтение старых отчётов).

**Правило работы по этому плану**: один пункт за раз, гейты после
каждого пункта, коммит + пуш, отметить `[x]` в этом файле. Если пункт
неоднозначен — остановиться и спросить, не выдумывать.

**Ownership (autonomous mode, 2026-09-08):** `locales/**`, `data/i18n/**`
and all i18n tooling (`tools/i18n_*.py`) are the local agent's from now
on — the Qwen agent that previously worked this area is not running.
ARENA (cloud agent) owns `levels/**`, `content/**`, `docs/**` except
`docs/GDD.md`/`docs/PRODUCTION_BIBLE.md` (frozen) — never edit those
paths, never touch its branch/PR except to merge a completed,
in-scope-only PR per `ARENA_NEXT_PROMPT.md`'s protocol. `arena/01a080ba-
igra` (suburbs district content, PR #1) was merged and deleted
2026-09-08 — see decisions log below.

## Autonomous decisions log

Format: what / why / alternatives considered. Appended to, never
rewritten.

---

**2026-09-08 (RELEASE CANDIDATE PASS, autonomous, owner override):**
Owner explicitly authorized merging Arena's open PR directly from this
session (GitHub UI/`gh` unusable on their machine) — a prior wave's hard
stop against touching Arena's branch/PR was lifted for this one action
only. Verified before merging: Arena's own 4 commits (merge-base to
branch tip) touched only `content/**` + `docs/CONTENT_DISTRICT_SUBURBS.md`
— 5 new files, 0 deletions, 0 conflicts with `main`. Merged
`arena/01a080ba-igra` (`--no-ff`), pushed, deleted the remote branch.

Two OTHER `arena/*` branches existed on origin (`019ffbd0-igra`,
`01a07b1c-igra`) — inspected but **not merged**: their own commits touch
`scripts/`, `tools/`, `weapons/`, an entire autopilot test framework —
far outside the `content/**`/`levels/**`/`docs/**` scope this project's
own PR-integration protocol requires for a self-merge, and old enough
(merge-base 13+ commits behind current `main`) that a blind merge risked
large silent conflicts with work already shipped since. Left alone,
flagged for the owner to review manually — see final chat report.

Wired the merged suburbs content: `document_pickup.gd`/`journal_ui.gd`
now resolve optional `title_key`/`content_key` catalog fields through
`LocalizationManager` (legacy raw-text catalog entries unchanged), so
content-authored lore translates without a new content pipeline; 8 notes
spawn via a new extensible `LORE_DOCS` dict in `district_loot.gd`
(reuses the existing one-shot procedural scatter, same as `DOCUMENTS`).
16 `LORE_SUBURBS_*` keys translated x13 locales directly (Qwen is not
running). Skipped the corner-shop key-lock and per-zone prop placement
from Arena's wiring checklist — real scene editing, higher risk/effort
for narrative polish that isn't required for the core loop; not
attempted blind, documented as backlog instead (ponytail: don't guess at
scene changes without visual verification).

Found and fixed two live i18n regressions while auditing "instant
language switch": `hud_3d.gd`'s HP/Stamina/Battery/Noise/Visibility/
Ammo/Radar/Sprint/Stealth captions and `journal_ui.gd`'s note list were
built once and never listened for `LocalizationManager.language_changed`
— stale text survived a live Settings → Language change until the scene
reloaded. Both now reconnect on that signal. `quest_journal.gd`/
`skill_tree_ui.gd` have the same shape of gap but weren't fixed this
pass (lower priority — see `docs/KNOWN_ISSUES.md`).

Audio: `SettingsManager`'s volume sliders covered Master/Music/SFX/Voice
but not `Ambient` — the bus `audio_system.gd`/`district_atmosphere.gd`
actually route district ambience through, with zero player-facing
control. Added the slider (same pattern as its siblings). Left the `UI`
bus without a slider — nothing in the project currently routes any sound
to it, so a control for it would be speculative, not a fix.

---

## А. Что уже работает (проверено, не предположение)

Ядро игры полностью играбельно — подтверждено `boot_check_scene.tscn`
(меню → новая игра → 60с реального геймплея → сохранение → выход →
загрузка, без падений) и `tools/check.sh --static` (10/10 зелёных гейтов).

| Система | Файлы | Статус |
|---|---|---|
| Игровой цикл, состояния | `scripts/core/game_manager.gd`, `scripts/core/routes.gd` | Работает, гейт `boot_check_scene.tscn` зелёный |
| Электросеть, 11 районов, 4 стадии питания | `scripts/systems/power_grid.gd`, `scripts/world/district_atmosphere.gd` | Работает; уличные фонари реально реагируют на стадию района (исправлено в TRUTH WAVE — раньше не реагировали вообще, см. `docs/KNOWN_ISSUES.md`) |
| Стелс: шум + видимость (не полоса детекции) | `scripts/systems/footstep_system.gd`, монстры (`vision_range`/`vision_angle`) | Работает по формуле GDD §7 |
| Бой: комбо, dodge, хитбоксы, смерть/респавн | player/enemy скрипты, `scripts/enemies/base_monster.gd` | Работает |
| 12 типов врагов + босс | `scripts/enemies/*_3d.gd` (12 файлов) | Все звучат в бою (`_set_cues` на всех), баланс подтянут к GDD §6.2 (WAVE 6 P1) |
| Оружие: pistol/rifle/shotgun | `scripts/weapons/weapon_*.gd` | Работает, у каждого своё имя/звук/иконка |
| Фонарик + дерево улучшений батареи/яркости/etc | `scripts/systems/flashlight_upgrade_manager.gd` | Работает, стоимость улучшений сверена с GDD §3.3 |
| Крафт (верстак) | `scripts/ui/workbench.gd`, `data/items/*.tres` | Все 8/8 рецептов craftable (WAVE 6 P2) |
| Скилл-дерево | `scripts/systems/skill_tree_manager.gd` | Работает, но **3 ветки вместо 4 из GDD §8** — см. раздел Б |
| Сохранения | `scripts/core/save_system.gd` | Работает; `reset_all()` реально сбрасывает XP/скиллы при New Game (это было сломано, исправлено — см. `CLAUDE.md` «TRUTH WAVE») |
| 5 концовок | `scripts/systems/endings_manager.gd` | Работает: у каждой концовки своя музыка (стинг для 3, полный трек для 2) |
| Достижения | `scripts/systems/achievements_manager.gd` | 20 достижений, реальные пороги (не «срабатывает на первом же событии», это было багом — исправлено) |
| Квесты | `scripts/systems/quest_manager.gd` | Все квесты, которые GDD подразумевает достижимыми, реально достижимы (3 «мёртвых» квеста оживлены через зоны/пазл) |
| 5-слойная адаптивная музыка + погода + звуки района | `scripts/systems/music_manager.gd`, `scripts/systems/district_atmosphere.gd`, `scripts/systems/weather_system.gd` | Работает, включая только что подключённые дождь/ветер и 40 звуковых деталей района |
| i18n-инфраструктура (13 языков) | `scripts/core/localization_manager.gd`, `data/i18n/*.json`, гейт `i18n_check_scene.tscn` | Инфраструктура полная и без ошибок; **контент переведён не на 100%** — см. раздел Б |
| Онбординг для новых игроков | `scripts/ui/onboarding_overlay.gd` | Показывается один раз на новом профиле сохранения |
| Энциклопедия монстров с детальным просмотром | `scripts/ui/encyclopedia_ui.gd` | Работает |
| Реклама (AppLovin MAX) | `scripts/monetization/ad_service.gd` | Код реальный и подключён к геймплею (interstitial + rewarded revive/battery), но без настоящего SDK-ключа — см. раздел Б |

---

## Б. Что отсутствует или сломано (по приоритету)

1. **Draw calls превышают бюджет D1 (<200) для стартового района.**
   Последнее измеренное значение — 234 (после батчинга скамеек/деревьев/
   конусов/фонарей в MultiMesh), бюджет D11 (<350) выполнен, D1 — нет.
   **Перепроверено 2026-09-08**: сначала ошибочно заподозрил уже
   исправленную (в "FINAL PERFECTION P3") причину — Pole/Lamp фонарей;
   `git blame`/чтение `streetlight_3d.gd` подтвердило, что это давно
   батчится. Актуальный источник остатка (анализ из прошлой волны,
   подтверждён) — меши монстров (6, намеренно не батчатся, они
   динамические) и подбираемые предметы (12, индивидуальные). Точную
   разбивку по draw call'ам без редакторского Visual Profiler (не
   запускается в headless/CLI-сессии) получить нельзя — дальше без
   дизайнерского решения (меньше предметов одновременно) или глубокого
   батчинга анимированных/подбираемых мешей не продвинуться. См.
   `docs/PRODUCTION_BIBLE.md` п.7 и `docs/KNOWN_ISSUES.md`.

2. ~~`emissive_windows.gd` никогда не рендерил ни одного окна~~ —
   **ОКАЗАЛОСЬ УЖЕ ИСПРАВЛЕНО** до начала этой волны (коммит `c917ab1`,
   до моего вмешательства): старый `scripts/world/emissive_windows.gd`
   (искавший несуществующую геометрию стен) удалён, реальные окна во
   всех 11 районах рисует `scripts/visual/emissive_windows.gd` —
   самодостаточный `MultiMeshInstance3D`, вручную размещённый в каждой
   `.tscn` района, без зависимости от поиска стен вообще (в проекте
   нигде не спавнится геометрия стен — фильтровать было физически
   нечего). Проверено: `EmissiveWindows` есть во всех 11
   `scenes/districts/*.tscn`. Никакого дизайнерского решения не
   потребовалось — задача снята с плана. Файлы: `scripts/world/emissive_windows.gd`,
   `scripts/world/world_bootstrap.gd`.

3. **Скилл-дерево: 3 ветки вместо 4, заявленных в GDD §8.** Намеренно
   не выдумана 4-я ветка вместо реального контента — нужно решение, что
   в неё должно входить (это игровой дизайн, не код). Файл:
   `scripts/systems/skill_tree_manager.gd`'s `SKILL_TREES`.

4. **i18n-контент: ЗАВЕРШЕНО 2026-09-08 (автономная волна).** Было 3424
   строки-заглушки на английском (817 ключей × 11 языков) на начало
   волны. Переведено батчами, гейты зелёные после каждого коммита:
   `SCR_*` (122, `d329308`), `Q_*` (40, `98da3e1`), `SKILL_*` (28,
   `88bd6a0`), `ACH_*` (22, `4ce4f69`), `QUEST_*` (11, `455e2a1`),
   `END_*`/`ENDING_*` (25, `d2e9b02`), `MAP_*`/`UPG_*`/`WEAKSPOT_*` (22,
   `e904d98`), остальной хвост — `INV_*`/`ITEM_*`/`JOURNAL_*`/`PROMPT_*`/
   `SHOP_*`/`STATS_*`/`TIP_*`/`ONBOARD_*`/`ENC_*`/`hud_*`/`menu_*`/
   `msg_*`/`cb_*` и разное (90, `e4dac8d`).

   **Финальный пересчёт**: 165 строк всё ещё формально "= английскому",
   но это **не пробел** — вручную сверено, каждая: легитимный когнат/
   заимствование (Auto, Park, Normal, AUDIO, Journal, Radio, SS-N-коды,
   " kg" как единица СИ и т.п. — реально одинаково пишутся в этих
   языках) либо мой сознательный выбор при переводе (например
   "Speedrunner"/"Endurance" как игровой термин-заимствование в
   de/fr/it/pt_BR). Ни разу не оставлено непереведённым по недосмотру.
   Инфраструктура: гейт зелёный, 0 «сырых» `tr()`-багов, **0
   romanized-placeholder текста** (детектор запускался дважды за волну).
   i18n-контент можно считать закрытым; если появятся НОВЫЕ ключи в
   будущих волнах — переводить сразу, не копить новый backlog.

5. **Релиз ещё не готов физически** (код готов, ручных шагов не
   хватает — полный список в `docs/SESSION_REPORT_SHIP.md`'s
   `FINAL HUMAN_CHECKLIST`):
   - релизный keystore не создан (`tools/make_keystore.ps1` для этого
     есть);
   - реальный AppLovin SDK-ключ не установлен;
   - приватная политика не опубликована по стабильному URL
     (`docs/PRIVACY_POLICY.md` готов как черновик);
   - Web/Windows export templates физически не установлены в Godot —
     новые пресеты в `export_presets.cfg` ещё не проверялись реальным
     экспортом.

6. **Draw-call бюджет — только измеряется, не гейтуется автоматически.**
   `docs/PRODUCTION_BIBLE.md`'s п.7 checklist явно просит сделать это
   автоматической проверкой (`perf_check_scene.tscn` существует и
   печатает число, но не проваливает гейт при превышении). Инфраструктурная
   задача, независимая от пункта 1.

7. **Два известных «мёртвых» экрана-дубля не удалены** (сознательно,
   по правилу «не удалять непроверенное мёртвым И не запланированное»):
   `scripts/ui/lobby_menu.gd` (LAN-лобби, никуда не подключён) и
   `scripts/ui/save_slot_entry.gd`/`save_slots_ui.gd` (мультислотовый
   выбор сохранения, тоже не подключён — реальный слот один, через
   кнопку Continue). Нужно решение: либо подключить (это реальные
   фичи), либо официально списать в архив.

8. **Один тестовый гейт (`game_test_3d_scene.tscn`) имеет известную
   особенность окружения** — процесс не завершается сам после печати
   результатов (не баг игры, баг жизненного цикла процесса в этой
   песочнице), из-за чего им неудобно пользоваться без `tasklist`/
   принудительного завершения. Не блокирует разработку, но стоит
   один раз разобраться, если будет время.

---

## В. План работ по порядку

### Этап 1 — decisions needed (дизайнерские решения, не код)
Эти три пункта блокируют реальную работу, а не могут быть решены
программистом в одиночку — нужен ответ от вас, прежде чем делать любой
из пунктов Б.2/Б.3/Б.7:

- [x] Что должна делать 4-я ветка скилл-дерева? (Б.3) → **DECIDED: Stealth branch** (noise/visibility stats)
- [x] Какие меши считать «стеной» для окон? Или отложить фичу вообще?
      (Б.2) → **DECIDED: only building-facade meshes**, exclude street props
- [x] Судьба lobby/save-slots экранов: подключить или архивировать? (Б.7) → **DECIDED: archive** (document as intentionally dead)

### Этап 2 — измеримые технические задачи (можно делать без дизайн-решений)
- [x] Пересчитать реальный i18n-backlog заново — done, see Б.4 table (~3424 strings, no code change).
- [x] Превратить `perf_check_scene.tscn` в настоящий гейт. Done: commit `7c76569` (гейтит D11<350; headless честно SKIP, реальная проверка требует --windowed).
- [x] Задокументировано: D1<200 остаток = монстры (6) + подбираемые
      предметы (12), обе причины требуют дизайн-решения или глубокого
      батчинга, не быстрой правки. См. п.1 выше и `docs/KNOWN_ISSUES.md`.

### Этап 3 — контентная работа (после Этапа 1, зависит от решений)
- [x] Реализовать 4-ю ветку скилл-дерева. Done: commit `b861b14`.
- [x] Эмиссивные окна — уже исправлены до этой волны (commit `c917ab1`), проверено.
- [x] Перевести i18n-backlog — ЗАВЕРШЕНО. 8 коммитов, 3424 → 165 строк
      (все оставшиеся — проверенные легитимные когнаты, не пробелы).
      Детали и коммиты см. Б.4 выше.

### Этап 4 — релиз (только человеческие шаги, не могу выполнить сам)
Полный пошаговый чек-лист теперь в **`RELEASE_CHECKLIST.md`** (корень
репозитория) — что кликать, в каком порядке, с исправленными местами
(package name, готовые Web/Windows пресеты).
- [ ] Сгенерировать релизный keystore, заполнить `export_presets.cfg`.
- [ ] Получить и вписать реальный AppLovin SDK-ключ.
- [ ] Опубликовать `docs/PRIVACY_POLICY.md` по стабильному URL.
- [ ] Проверить реальный Web-экспорт (шаблоны теперь нужно только
      установить в редакторе — пресет уже есть в `export_presets.cfg`).
- [ ] Проверить реальный Windows-экспорт (аналогично — пресет готов).
- [ ] Первая загрузка в Play Console (открытое тестирование).

### Финальная проверка — ЗАВЕРШЕНО 2026-09-08 (автономная волна)
- [x] Полный прогон всех гейтов: `tools/check.sh --static` 10/10,
      compile/signal-arity/autoload-api/i18n/asset/save-integrity/
      footstep/audio-hum все `fails=0`/`bad=0`, `boot_check_scene.tscn`
      (`--windowed`) `fails=0` чистый прогон меню→новая игра→60с
      геймплея→сейв→выход→загрузка, `perf_check_scene.tscn`
      `draw_calls=234` (D11<350 OK). `default_bus_layout.tres` не
      тронут за всю волну.
- [x] Обновлён `docs/HANDOFF.md` реальным состоянием (новая секция
      "Latest phase" вверху, история ниже не тронута).
- [x] Итоговый отчёт — см. коммит-сообщение финального коммита этой
      волны и `RELEASE_CHECKLIST.md`.
