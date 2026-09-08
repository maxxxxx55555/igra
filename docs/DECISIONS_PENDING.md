# DECISIONS_PENDING — owner-решения (2026-09-01)

Статус: **жду решения владельца по 3 вопросам.** Факты измерены и приведены ниже.
Контент/доступность НЕ менялись. Каждая строка — измерение, не оценка.

## D1 — Шрифты темы без кириллицы (ru = язык по умолчанию)

Факты (fontTools, измерено):
- ThemeProvider подключает: `BebasNeue-Regular.ttf` (269 глифов, латиница+цифры),
  `RobotoCondensed-Regular.ttf` (363 глифа, латиница), `ShareTechMono-Regular.ttf`
  (268 глифов, латиница) — **у всех трёх нет кириллицы**.
- В `assets/fonts/` лежат дубли с кириллицей: `bebas_neue_bold.ttf` (family «Impact»,
  1019 глифов), `roboto_condensed.ttf` (family «Arial Narrow», 663 глифа) — но это
  **другие шрифты** (клоны Impact/Arial Narrow), НЕ «те же Bebas/Roboto с кириллицей».
- LocalizationManager: `UI_FONT_PATH = Rajdhani-Regular.ttf` (1043 глифа, кириллица ЕСТЬ)
  + SystemFont fallback (Noto Sans CJK/Arabic в цепочке).
- 13 локалей: ru, en, es, de, fr, it, pt_BR, tr, ja, ko, zh, zh_TW, ar.
  Кириллица нужна только ru (tr/ja/ko/zh/ar и так идут через системный fallback).

Что происходит сейчас (измерено): русские строки рендерятся SystemFont-fallback'ом
(на Windows — Segoe UI/Segoe UI Historic). Tofu НЕТ, но заголовки теряют канон-шрифт
Bebas Neue → визуальный разрыв стиля на ru-скринах.

| вариант | суть | риски | рекомендация |
|---|---|---|---|
| **A** | Оставить как есть + задокументировать | 0 рисков, но ru-заголовки системным шрифтом — канон-стиль на ru не соблюдён | — |
| **B** | Подключить в ThemeProvider.font fallback-цепочку: Bebas → Rajdhani (кириллица) как sub-fallback через `font.fallbacks` (заголовки: латиница Bebas, кириллица Rajdhani) | правка только theme_provider.gd (+3 строки), шрифты уже в assets/fonts; визуально смешанная гарнитура в одном заголовке | **рекомендую B**: сохраняет канон на латинице, чинит кириллицу без новых ассетов |

## D2 — Мёртвый theme_tls.tres

Факты (grep, измерено):
- `project.godot` → `theme/custom="res://assets/ui/theme_tls.tres"` (единственная ссылка).
- `theme_setup.gd` (autoload ThemeSetup) на `_ready()` перезаписывает: `root.theme =
  ThemeProvider.build_theme()` — theme_tls.tres никогда не рендерится.
- Содержимое: 2 цвета (rgb(207,201,184) d=17 к bone; rgb(226,163,60) d=29 к brass — в допуске),
  2 шрифта (BebasNeue + RobotoCondensed латиница) — та же проблема D1.
- HANDS-OFF-статуса НЕ имеет (вне списка канонических замен).

| вариант | суть | риски | рекомендация |
|---|---|---|---|
| **A** | Убрать `theme/custom` из project.godot, theme_tls.tres → _QUARANTINE | project.godot правится (владелец-файл); при выкинутом ThemeSetup-автолоаде UI потеряет тему совсем | — |
| **B** | Ничего не менять, theme_tls.tres остаётся мёртвым грузом с 0 эффектом | 0 рисков; мусорный артефакт в assets/ui | **рекомендую B сейчас**, A — только вместе с решением D1 (единая точка истины — ThemeProvider) |

## D3 — Отсутствующий OpenDyslexic-Regular.ttf

Факты (grep + ls, измерено):
- `settings_manager.gd:316`: при включённой опции dyslexia_font грузит
  `load("res://assets/fonts/OpenDyslexic-Regular.ttf")` — файл **не существует**
  в assets/fonts/ (проверено: 10 ttf, OpenDyslexic нет).
- `load()` несуществующего вернёт null → `add_theme_font_override("font", null)` —
  молчаливый сброс оверрайда, UI остаётся на ThemeProvider-теме. Краша нет (измерено:
  путь обёрнут в цикл по группе "ui_text"; null-override игнорируется Godot 4.7).
- Опция видна в настройках? — да: settings UI отдаёт `dyslexia_font` toggle.
- Опция фактически сломана с момента, когда шрифта нет в репо.

| вариант | суть | риски | рекомендация |
|---|---|---|---|
| **A** | Скрыть/убрать toggle dyslexia из настроек (фича откладывается до появления шрифта) | правка кода настроек; UX-регрессия для тех, кто хотел опцию | — |
| **B** | Найти и добавить OpenDyslegic-Regular.ttf (OFL-лицензия, ~100 KB) в assets/fonts/ | новый ассет; нужно owner-подтверждение лицензии и источника | **рекомендую B**: фича заявлена в UI, сейчас это тихий обман пользователя; шрифт бесплатный (SIL OFL) |

---
Все три решения влияют на контент/доступность → по правилу волны НЕ применял сам.
Zero-risk решений среди трёх нет (D2-A трогает project.godot — не нулевой риск).
