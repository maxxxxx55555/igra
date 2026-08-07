# findings.md — актуализировано 07.08.2026

## Закрыто (исправлено в коде, сверено построчно)
- MP-1, MP-2, MP-3, MP-4 (LAN/NetworkManager/UPnP/spawn) — FIXED
- I18N-1 (системный шрифт CJK/Arabic через ThemeDB.fallback_font) — FIXED
- I18N-2 (верхнерегистровые дубли SETTINGS/Language/Difficulty) — FIXED этим скриптом

## Закрыто этим проходом (finish_game_v2.ps1)
- SEC-0: удалён а.txt с утёкшим ANTHROPIC_AUTH_TOKEN. !!! Отозвать токен + git filter-repo.
- AUTO-1: включены автозагрузки RewardsManager и RandomEvents.
- AUTO-2: реализован Ev.DISTRESS (emit radar_marker_added).
- CLEAN-1: удалён узел StressTest из main_3d.tscn.
- CLEAN-2: мёртвые/дубль-скрипты перенесены в legacy_quarantine/ (по скану ссылок).

## Открыто (P3 — см. P3_AUDIT.md, проверять через compile_gate)
- Рассогласование сигналов: enemy_died vs enemy_killed (wave_manager), settings_changed (xp/skill_tree).
- nil-deref: base_monster player_ref, skill_tree player.stats, puzzle_base ItemDatabase.get_item().
- Хардкод-локализация: screens.gd / pause_menu.gd / main_menu.gd (заменить на tr()).
- Архитектура: 3 системы экранов (UIManager / Screens / ScreenFlowManager) — оставить одну.
- GDD.md/ROADMAP.md/progress.md привести к 3D-реальности.