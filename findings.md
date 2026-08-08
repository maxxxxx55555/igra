# findings.md — runtime-verified 08.08.2026

## Закрыто (исправлено в коде, сверено построчно)
- MP-1..4 (LAN), I18N-1/2 (шрифт/дубли) — FIXED
- T1 SFX, T2 photos, T3 boss minion, T4 HUD weight, T5 procedural anim — FIXED
- T6: 13 локалей реальные (195+ ключей, 0 пустых, 13/13 валидны). PL нет — вместо него ar (см. ниже).
- T7: export_presets Android + keystore, tools/make_keystore.ps1 (keystore сгенерирован), docs/ANDROID_BUILD.md
- T8: AdProvider interface + SimulatedAdProvider + AdmobProvider (stub) + docs/ADS.md + ad-ключи во всех локалях
- Сигналы: item_picked_up унифицирован (1 арг, StringName); settings_changed был без параметров — стало (key, value)
- nil-deref: skill_tree stamina-boost — player.stats под null-guard
- Хардкод-локализация входных экранов: main_menu.gd/pause_menu.gd → LocalizationManager.t()

## REAL RUNTIME STATE (verified by instantiating main_3d.tscn, 08.08.2026)

Autoloads: **48/48 present** — every GDD singleton (PowerGrid, GameManager, QuestManager, RewardsManager, RandomEvents, AdManager, etc.) is live.

`main_3d.tscn` live tree contains:
- WorldEnvironment, DirectionalLight "Moon", a **bare Camera3D** (no CharacterBody3D child, no flashlight SpotLight3D, no weapon)
- HUD canvas: HP/Stamina/Battery bars, radar, BtnAttack/Sprint/Stealth/Interact, joystick ring, WeightBar, enemy HP bar
- StreetBuilder: road/sidewalk/marking MultiMeshInstance3D (procedural streets, NO district scenes, NO enemies)
- GPUParticles3D "Ash", ambient+SFX audio players
- Splash
- `screens.tscn`: ALL UI as flat procedural ColorRects (MainMenu, Pause, Settings, Inventory, CityMap, Journal, QuestJournal, Achievements, Stats, Shop, Death, Victory, Saves) — screens.gd drives them

### Honest gap: what is NOT in the running game vs GDD
- **No player controller** in the tree — no CharacterBody3D, no FPS movement, no flashlight SpotLight3D. HUD expects a player that isn't instantiated here.
- **No districts, no enemies, no boss, no combat** visible at runtime — managers exist as data, but no district scenes/enemy nodes are spawned in main_3d.
- **No real 3D content** — only procedural road Multimeshes + a particle system. GDD's 11 districts, 6 enemy types, boss arena = not present in the running scene.
- **UI is placeholder** — screens.tscn is flat ColorRects with default-styled cards, not the styled panels in GDD §11.
- GDD gameplay (§2–9, §13 adaptive music, §18 weapons) is either data-only or not instantiated in main_3d.

## Open (actionable)
1. Player controller + flashlight + FPS movement wired into main_3d (the single biggest gap).
2. At least one playable district scene (suburbs, DARK stage) with streetlights to restore.
3. One enemy type (Shadow) + light-kill behavior, so the core loop runs.
4. UI panels restyled to GDD §11 (not flat ColorRects).
5. `screens.gd` (~1900 RU hardcode) → full `tr()` (large pass).
6. PL locale missing (ar present instead) — reconcile with GDD list.
7. Dead event_bus duplicates: scripts/event_bus.gd, scripts/core/event_bus.gd.
8. Adaptive music 5-layer crossfade (currently 2-player variant).
9. APK not built (SDK/templates needed); keystore ready.
10. AdMob real ads not wired (stub, by design — no new deps).
11. Adaptive music 5-layer crossfade (currently 2-player variant).

## Ниже: старье закрыто
- SEC-0 (утечка токена — отзыв токена за пределами кода, обязателен владельцу)
- AUTO-1/2, CLEAN-1/2 (автозагрузки, EV.DISTRESS, StressTest, quarantine) — FIXED