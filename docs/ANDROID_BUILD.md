# ANDROID BUILD — THE LAST STREETLIGHT

## Требования
- Godot 4.7 (Windows), экспорт-темплейты Android установлены (Editor → Manage Export Templates).
- JDK 17+ (keytool для keystore) и Android SDK (adb) — по желанию, только для установки на устройство.

## Шаг 1. Keystore (однократно)

Debug-keystore уже есть в `res://tls_debug.keystore` (сгенерирован `tools/make_keystore.ps1`):

```
powershell -ExecutionPolicy Bypass -File tools/make_keystore.ps1
```

- alias: `tlsdebug`, пароль: `tlsdebug` (только для DEBUG-сборок).
- Для публикации в Google Play сгенерируй отдельный **release-keystore** и храни в секрете:
  `keytool -genkey -v -keystore release.keystore -alias tlsrelease -keyalg RSA -keysize 2048 -validity 10000`.
- В `export_presets.cfg` прописан debug-keystore. Release-пути — `keystore/release` — заполняются вручную перед финальной подписью.

## Шаг 2. Экспорт APK

1. Editor → Project → Export → Выбрать пресет **Android**.
2. Проверка: `arm64-v8a=true`, `armv7=false`, Debug/Release.
3. Export Project (или cmdline):

```
godot --headless --export-debug "Android" build/TLS_debug.apk
godot --headless --export-release "Android" build/TLS_release.apk
```

## Шаг 3. Установка на устройство

```
adb install -r build/TLS_debug.apk
```

Или перекинуть `.apk` на телефон и открыть файловым менеджером (нужно разрешение на установку из неизвестных источников).

## Шаг 4. Проверка ре-лиза (checklist)

- [ ] APK без `.import`-мусора, текстурные форматы ETC2/ASTC включены в настройках проекта.
- [ ] Custom Build = OFF (нет нативных плагинов — AdMob подключается через AdProvider-интерфейс позднее).
- [ ] Приложение работает офлайн (ни одной сетевой зависимости в рантайме кроме LAN-мультиплеера).
- [ ] Debug-подпись не используется в релиз-кандидате.
- [ ] `--quit-after` прогон без ошибок на машине перед экспортом.

## Известные ограничения

- AdMob: **не подключён** до сборки со смарт-плагином Godot AdMob (см. `docs/ADS.md`). Сейчас работает симуляция (`SimulatedAdProvider`).
- LAN-мультиплеер живёт поверх UDP — на некоторых роутерах нужен UPnP/ручной проброс портов (см. `docs/A10_multiplayer_decision.md`).