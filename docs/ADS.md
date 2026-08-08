# ADS — AdProvider system

## Архитектура (T8)

```text
AdManager (autoload, scripts/monetization/ad_manager.gd)
  └─ provider: AdProvider (interface)
       ├─ SimulatedAdProvider (по умолч. — PC / Android без SDK)
       └─ AdmobProvider (заглушка — требует Godot AdMob plugin + сборки)
```

- Результат награды приходит сигналом `ad_finished → _on_emit_reward`.
- `ads_removed`, cooldown 1/час, `get_session_impressions()` — остаются в AdManager.
- Провайдер выбирается полем `provider_mode` (export: "simulated"/"admob").

## UI

- `scenes/ui/ad_reward_ui.tscn` + `scripts/ui/ad_reward_ui.gd` — модалка «Смотреть рекламу (+100 монет) / Пропустить (−100 монет) / Отмена».
- Ключи: `ad_reward_title`, `ad_watch`, `ad_skip`, `ui_close` (добавлены во все 13 локалей).

## Интеграция реального AdMob (позже, вручную)

1. Собрать проект с официальным **Godot AdMob SDK** плагином (GDExtension/модуль).
2. В `AdmobProvider` подключить реальные вызовы: rewarded/ interstitial интерститиал.
3. Указать App ID/unit ids в export presets (metadata).
4. Снять тестовые unit ids в Google AdMob консоли.
5. Проверить политику: каждая rewarded-реклама даёт честную награду, кнопка «Пропустить» всегда доступна.

## Статус

- Реальная реклама: НЕ подключена (нет SDK — по стаканым правилам без новых зависимостей).
- Симуляция: работает, награды начисляются корректно (coin/battery/health).