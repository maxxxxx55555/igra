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

Follow-up (same day): fixed the same live-language-switch gap in
`quest_journal.gd` (rebuild-on-language_changed, matching
`settings_screen.gd`'s pattern) and `skill_tree_ui.gd`/`skill_button.gd`
(tab titles + skill name/desc/cost retranslate via the existing
`refresh()` chain). `docs/KNOWN_ISSUES.md`'s live-switch list is now
fully closed.

**2026-09-08 ("merge arena" command, PR #2):** owner sent the exact
command to merge Arena's second PR (`arena/01a08149-igra`: residential +
park district content, the world bible, lit-tile assets). Scope-checked
first (own commits vs merge-base: `content/**`, `docs/**` except frozen,
`assets/textures/**` only — in bounds), all 8 new JSON files
syntax-validated, merged `--no-ff`, 0 conflicts, full 5-gate + windowed
boot/perf suite green, branch deleted.

Wired everything the same way suburbs was: `residential`/`park` note ids
added to `district_loot.gd`'s `LORE_DOCS`, their catalog entries added to
`documents_catalog.json` with `title_key`/`content_key`. Added a new
`scripts/world/world_bible.gd` — minimal static id→dict lookups over
`content/world/*.json`/`content/lore/*.json` (characters, factions,
revealed radio transcripts), stage-gated through `DistrictManager`, no
new systems (same style as `district_loot.gd`'s own static utility
methods). Used it in two places: `journal_ui.gd` shows an already-
revealed "Related: X, Y" line under a note's text when it carries
`world_refs` (park notes only, so far); `radio.gd` appends revealed
`content/world/radio_transcripts.json` broadcasts as extra channels next
to its 5 fixed demo ones (same `tr()`-via-`TranslationServer` path the
screen already used — `LocalizationManager` registers every JSON key
with Godot's real `TranslationServer`, confirmed by reading
`localization_manager.gd`, so this isn't the same class of bug as the
raw-`tr()`-never-resolves issue from earlier waves).

Deliberately NOT built: a UI to browse the whole world bible (characters/
factions list, timeline) — the brief said "minimal APIs only, no new
systems," and nothing in the merged content requires more than the two
cross-link points above to be functional. `history.json` (`hist_*`)
entries have no `i18n_keys` field by the world bible's own contract (not
directly shown to the player) — not translated, correctly.

85 new keys × 13 locales translated directly (not Qwen, not a
placeholder pass): `LORE_RESIDENTIAL_*`(16), `LORE_PARK_*`(16),
`WORLD_CHAR_*`(18), `WORLD_FACTION_*`(10), `WORLD_RADIO_*`(6),
`WORLD_DIARY_*`(8), `WORLD_NEWS_*`(10), `JOURNAL_RELATED`(1).
`content/world/history.json` intentionally excluded (see above).

Caught and reverted before commit: registering `WorldBible`'s new
`class_name` required one `godot --headless --editor --quit` run (a
plain `--path . --quit` doesn't rebuild `global_script_class_cache.cfg`)
— that editor pass silently corrupted `default_bus_layout.tres` on its
own resave (dropped the whole Master bus block, dropped `room_size` from
the reverb, mangled the resource `uid`). Caught by manually diffing the
file before staging, reverted with `git checkout --`, documented in
`docs/KNOWN_ISSUES.md` as a standing gotcha for next time.

---

**2026-09-09 (merge arena PR #4, autonomous, NO-GODOT static mode):**
Merged `arena/01a08281-igra` (police district pack + Arena's
`docs/CONTENT_PIPELINE_AUDIT.md` re-run across districts 1–7, 0 new
defects) — scope-checked (content/districts/police, assets/textures,
docs/** only, all within Arena's zones), both JSON files valid, all 20
item ids and all 16 distinct `world_refs` ids cross-checked against
`data/items/*.tres` and `content/world/*`/`content/lore/*` by hand
before merging (not just trusted from the audit doc). `--no-ff`, 0
conflicts, pushed, branch deleted, static gates green.

Wired identically to prior districts: `district_loot.gd`'s `LORE_DOCS`
gained the `police` entry (`BY_DISTRICT`/`BLUEPRINTS`/`STORY_DOC` already
had `police` rows pre-existing in code, ahead of content — only the
lore-note id list was new); 8 `documents_catalog.json` entries generated
the same way as prior batches (89 entries total, 0 duplicates). 16
`LORE_POLICE_*` keys translated ×13 locales (983 keys/locale,
`i18n_audit.py` confirms `MISSING: 0`).

Re-verified (not just trusted) both open CODE-facing facts from PR #3
still hold for the new pack: police is not a leaf of `powered_by`
(`industrial` still lists it as a co-parent — #21 stays correct as
written), and `district_themes.gd`'s `police` row has no `"music"` key
(colour-only, per the #22 fix already applied) — logged as
`STATIC_AUDIT.md` #25, status VERIFIED, no code change needed either
time.

Caught and fixed before commit: `git add -A` swept in an untracked
`.claude/worktrees/` directory (unrelated local worktree scaffolding,
flagged at session start as `?? .claude/worktrees/` in git status, not
authored by this session) that would otherwise have been committed to
`main`. Unstaged, added `.claude/worktrees/` to `.gitignore`, re-staged
only the intended files. Lesson: `git add -A` is unsafe when untracked
non-project directories exist; prefer explicit paths after checking
`git status` for surprises, especially right after a fresh session
resume.

`ARENA_NEXT_PROMPT.md` rewritten to queue district 8 (`warehouses` per
GDD §4.1) with its computed `powered_by` closure spelled out
(`hospital → residential → suburbs`, so Act II Architect material
*is* legal there for the first time, unlike every district since
hospital) and a heads-up about `industrial`'s two-parent convergence
for the district after that.

---

**2026-09-09 (merge arena PR #5, autonomous, NO-GODOT static mode):**
Merged `arena/01a0859c-igra` (warehouses district pack + Arena's
`docs/CONTENT_PIPELINE_AUDIT.md` re-run across districts 1–8, 0 new
defects; plus a surgical repair of a 3px edge-frame defect on the
shipped dark `warehouses_floor.png`, re-deriving the lit twin from the
repaired dark). Scope-checked, both JSON files valid, all 20 item ids
and all 12 distinct `world_refs` ids cross-checked by hand against
`data/items/*.tres` and `content/world/*`/`content/lore/*` before
merging. `--no-ff`, 0 conflicts, pushed, branch deleted, static gates
green.

Wired identically to prior districts: `district_loot.gd`'s `LORE_DOCS`
gained `warehouses` (its `BY_DISTRICT`/`BLUEPRINTS`/`DOCUMENTS` rows
already existed in code ahead of content); 8 `documents_catalog.json`
entries appended (97 total, 2 correctly carry no `world_refs` key since
their source notes had an empty array); 16 `LORE_WAREHOUSES_*` keys
translated ×13 locales (999 keys/locale, `i18n_audit.py`: `MISSING: 0`).

Re-verified both open CODE-facing facts from PR #3/#4 (`STATIC_AUDIT.md`
#21/#22) against the new pack: warehouses confirmed not a leaf
(`industrial.powered_by = [warehouses, police]`), its `district_themes.gd`
row has no `"music"` key — logged as `STATIC_AUDIT.md` #26, VERIFIED,
no code change needed. Also load-tested the Arena-side texture repair
(dark floor + both new lit twins) as valid PNGs within the prop-texture
budget (`docs/PRODUCTION_BIBLE.md` §4) — clean.

Notable first: warehouses' closure (hospital→residential→suburbs)
legitimately unlocks the Act II Project Architect world-bible set for
the first time (every district since hospital was on a branch that
didn't require it); verified all three Architect ids plus the fourth
(`char_architect`) are used at `min_stage >= 2` in the pack, matching
their own `hospital/STREETS` reveal gate exactly — no premature-unlock
leak of the kind #24 (park/`char_babka_manya`) originally found.

`ARENA_NEXT_PROMPT.md` rewritten to queue district 9 (`industrial` per
GDD §4.1) — the first **two-parent convergence**
(`powered_by = [warehouses, police]`), so its guaranteed closure is
the *union* of both branches (suburbs, residential, park, hospital,
warehouses, police — six districts), not a single chain. Flagged this
explicitly in the prompt since it's the first closure computation of
this shape and the easiest one to get wrong.

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

**2026-09-08 (FULL AUTONOMY, NO-GODOT static-audit pass):** owner
mandated a defect hunt verified entirely by code tracing — no Godot
binary run at all this pass (a prior pass's `--editor --quit` had
silently corrupted `default_bus_layout.tres`; this mode removes that
risk class entirely). Used 3 parallel Explore subagents (power grid/
emissive windows; save+load/endings; settings+i18n screen sweep) plus
my own tracing (boot order, loot flow, skill tree all 4 branches,
journal/world-bible, radio). Full register with file:line evidence:
`docs/STATIC_AUDIT.md`. Player-facing summary + a 5-minute manual check
list: `docs/PLAYER_VISIBLE_CHANGES.md`.

Headline finding: **8 of 18 skill-tree skills across all 4 branches
were purchasable (real skill-point cost) but did literally nothing** —
`damage_boost_1/2`, `crit_chance`, `fire_rate`, `reload_speed` (combat),
`health_regen`, `light_radius` (survival), `loot_luck` (utility). Three
more (`max_health`, `stamina_boost`, `battery_capacity`) called player
methods (`set_max_health` etc.) that don't exist anywhere in the
codebase. And the root cause behind all "push once" skills losing their
effect on every Continue: `SkillTreeManager.load_data()` runs during
`SaveSystem`'s data-parse phase, before the player node exists, so its
effect-replay loop always no-op'd. All wired/fixed this pass — see
`STATIC_AUDIT.md` #2-#5 for the exact fix per skill.

Also severe: `ending_screen.gd` was a completely dead, never-shown node
whose `_unhandled_input` was nonetheless always live (its only guard
depended on a `Tween` that's never created) — every Escape press during
ordinary gameplay called `Endings.mark_ended()` and force-quit to the
main menu, racing the real pause menu on the same keypress. Fixed with
a one-line guard.

Decisions on what NOT to fix (would need a design call or a new system,
not a wire-up — documented in `STATIC_AUDIT.md`, not guessed at):
- Only 3 of 5 GDD endings (`light`/`hope`/`truth`) are reachable;
  `survivor`/`dark` are dead branches because `all_restored()` is
  always true by the time the ending evaluator ever runs, and death
  never triggers an evaluation at all. Needs a real design decision
  (when should "Survivor" fire? should death show a real "Dark" ending
  instead of the current static death screen?).
- `scripts/visual/emissive_windows.gd` (the live implementation) never
  reacts to district power stage at all — pure one-time randomness,
  contradicting its own design brief. A real fix needs per-instance
  MultiMesh color updates keyed by stage, not a one-line wire-up.
- GDD's PARTIAL stage ("some streetlights lit") isn't implemented in
  `streetlight_3d.gd` — PARTIAL looks identical to DARK. Same reasoning
  as the windows above.
- `content/districts/*/item_spawns.json`'s stage-gated tables/fixed-
  spawns are never read by any script; `district_loot.gd`'s own
  `REPAIR_PARTS` already guarantees the same solvability goal via an
  older, simpler, already-working flat mechanism. Wiring the JSON would
  mean building a new stage-aware spawn system to replace a working
  one — out of scope for a defect-fix pass.

Also fixed (major/minor, not skill-tree): a global lighting handler
reacting to every district's stage change instead of just the player's
current one; a renamed/removed inventory item id restoring as a
permanent ghost slot; `TOTAL_DOCUMENTS` (endings threshold) was a
hand-typed const that had already drifted stale after the suburbs/
residential/park lore-note additions, made "collect all documents"
trivial — now computed from the live spawn tables; save-slot UI always
showed "Level: 1" and the 1970 epoch date; two confirmed 100%-dead-code
no-ops deleted (a duplicate signal emit, an always-false sync
condition); 9 more UI files (found via a full sweep, not just the ones
flagged in earlier passes) fixed for live-language-switch retranslation
— `docs/KNOWN_ISSUES.md`'s list should now be genuinely complete.

Process note: caught and fixed one self-introduced bug this pass by
re-reading every edited function before committing (a mid-file edit had
left an orphaned tail — the flashlight battery-bonus code — sitting
outside its function, referencing an undefined variable). With no
compile gate available in no-Godot mode, this manual re-read step is
now the only defense against exactly that class of mistake — treat it
as mandatory, not optional, for the rest of this mode.

---

**2026-09-08 ("merge arena" command, PR #3):** merged
`arena/01a08213-igra` — three districts at once (`school`, `hospital`,
`gas_station`) plus `docs/CONTENT_PIPELINE_AUDIT.md`, a static audit of
all 6 packs shipped so far. Scope-checked (content/**, docs/**, assets/
textures/** only, including two in-scope edits to already-merged
`suburbs`/`park` content files — verified those didn't rename any note
id my earlier wiring depends on), 8 JSON files validated, merged
`--no-ff`, 0 conflicts, static gates green, branch deleted.

Wired the same way as suburbs/residential/park: 24 new note ids added to
`district_loot.gd`'s `LORE_DOCS`, matching catalog entries generated via
a small one-off python script (not hand-typed — 24 entries with nested
`world_refs` arrays is exactly the kind of transcription work a script
should do). 48 keys × 13 locales translated directly, `i18n_audit.py`
confirms 0 missing.

Resolved both data facts Arena's own audit flagged as CODE's call
(full reasoning + evidence: `docs/STATIC_AUDIT.md` #21-#22):
- **school/gas_station power topology vs GDD §4.1**: verified NOT a bug.
  `data/districts/*.tres` already forms a branching, reconverging DAG
  (`industrial` needs BOTH `warehouses` AND `police`) that predates this
  session entirely; GDD §4.1's single arrow-chain is a narrative/display
  ordering, not a literal unlock-dependency spec. Left the `.tres` files
  untouched — rewriting them to force a strict chain would invalidate
  Arena's own already-shipped `world_refs` reveal-gate closures (computed
  against the real branching topology in `CONTENT_PIPELINE_AUDIT.md`
  §3.4), a much larger and riskier change than the "fix" would be worth.
- **`district_themes.gd` vs `music_manager.gd` music-row disagreement**:
  traced both to their actual call sites. `district_themes.gd`'s
  per-district `"music"` key is read by nothing anywhere in the
  codebase (confirmed dead — its own values were suspicious copy-paste,
  5 districts sharing one file). `music_manager.gd`'s `AMBIENT_BY_
  DISTRICT` is itself a documented-unreachable fallback, since
  `AMBIENCE_DARK_BY_DISTRICT`/`AMBIENCE_LIT_BY_DISTRICT` already cover
  all 11 districts and are what actually plays. Reconciled by deleting
  the dead field rather than picking a "winning" value nothing would
  ever read — the one true source of per-district audio stays the
  `AMBIENCE_*_BY_DISTRICT` pair.

Also surfaced (not fixed, logged as `STATIC_AUDIT.md` #24): Arena's own
`park_note_05` fix exposed a real imprecision in `WorldBible.is_revealed()`
— it checks `stage >= min_stage`, and every district defaults to `DARK`
(0) whether visited or not, so a `min_stage: 0` reveal is trivially true
for a district the player hasn't reached. Not a live bug today (content
authoring discipline — §3.4's reachability rule — is the actual guardrail,
and it's followed correctly in all 6 shipped packs), but a real gap in
the primitive itself if a future pack or a UI feature ever trusts it
without also checking district visitation. Deferred rather than risk an
uncompiled change to a lookup two live features depend on.

`ARENA_NEXT_PROMPT.md` updated to queue `police` (district 7, GDD §4.1),
with its own reachability closure spelled out explicitly (`suburbs +
park` only) so the next Arena pass doesn't have to rediscover the same
rule the audit caught park breaking once already.

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
