# THE LAST STREETLIGHT — финальная доводка игрового процесса

## Goal
Довести игровой процесс до проверяемого соответствия канону `docs/GDD.md` v4 без параллельных систем, с обязательными зелёными gate-сценами и коммитом каждого завершённого этапа.

## Phases
- [in_progress] Phase 1 — инвентаризация репозитория, состояния Git, инструментов и фактических расхождений
- [pending] Phase 2 — базовый игровой цикл: boot → районы → материалы → пазлы/генератор → STREETS → свет → сохранение/победа
- [pending] Phase 3 — игрок, фонарь, управление PC/Android, HUD и accessibility
- [pending] Phase 4 — combat: оружие, комбо, dodge, stamina, враги, Architect, death/respawn
- [pending] Phase 5 — progression: economy, inventory, workbench, quests, journal, skills, achievements, album/events
- [pending] Phase 6 — story, endings, screens/UI и полная локализация
- [pending] Phase 7 — audio: пять адаптивных слоёв, ambience, footsteps, budgets
- [pending] Phase 8 — save integrity, security/release/mobile budgets
- [pending] Phase 9 — gates, doctor, runtime smoke test, Android build if SDK exists, final audit

## Next Step
Проверить доступные команды Windows и состояние проекта через PowerShell, затем составить точную карту файлов и расхождений.

## Errors Encountered
| Error | Attempt | Resolution |
|---|---:|---|
| bash launcher points to missing WindowsApps\bash.exe | 1 | Использовать `powershell.exe` через доступный инструмент; если launcher блокирует и его — сообщить об ограничении среды |

## Decisions
- Канон: `docs/GDD.md` v4; `docs/GDD_CONFORMANCE.md` используется как стартовый аудит, но не как доказательство реализации.
- Правки только surgical; новые дублирующие менеджеры запрещены.
- После каждого изменения `.gd/.tscn/.tres/project.godot` запускать 4 обязательных gate-сцены.
- Push не выполнять без отдельной команды пользователя.
