# ROLES — порядок автозагрузок (18)
1 EventBus 2 GameManager 3 SaveSystem 4 InputService 5 ItemDatabase 6 InventoryManager
7 PowerGrid 8 Encyclopedia 9 CoinWallet 10 ShopService 11 UpgradeSystem 12 RewardsManager
13 UIManager 14 WeatherSystem 15 SettingsManager 16 RandomEvents 17 ProgressTracker 18 AudioManager.
Состояние читать через GameManager.is_playing()/is_menu()/... НЕ через enum извне.
Визуал: ThemeProvider (токены/стили референса) + VisualStyle (силуэты/тайлы/виньетка) +
AssetRegistry (опциональный PNG). Звук: AudioManager (процедурный).