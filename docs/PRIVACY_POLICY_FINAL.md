# Privacy policy: the final text to host (Last Streetlight)

This file replaces `store/privacy-policy-template.md` and the draft `docs/PRIVACY_POLICY.md` as the text to publish. It describes the build that ships (the signed bundle of
`docs/RELEASE_ARTIFACTS.md`). Every statement of the policy is held by a line of code or of the export settings in the table at the end, and
`python tools/qa_sim/privacy_audit.py --check` (a static gate of `tools/check.sh`) fails when a network, analytics or ad hit appears that `docs/PRIVACY_AUDIT.md` does not classify.

## What the owner does

1. Replace the two kinds of placeholder in the English and the Russian text: `[date of publication]` (and its Russian twin) and `[contact email / support URL]` (and its Russian twin).
   They are the only text in square brackets. Do not publish while one remains.
2. Host the text at a stable public HTTPS address that is a web page, not a PDF. Recipe on GitHub Pages: the repository `maxxxxx55555/igra` has a branch `gh-pages` whose only file is `index.html`
   (the page of 2026-09-13, written from the older template). Replace its text with the two policy texts below, commit, and in the repository's Settings, Pages, choose the branch
   `gh-pages` and the folder `/ (root)`. The address is then `https://maxxxxx55555.github.io/igra/`. UNVERIFIABLE-HERE: whether Pages is switched on and what the page shows today; open the address in a private window.
3. Paste the address into the Play Console (Policy, App content, Privacy policy) and into the store listing (`store/listing.md`, Data-safety notes). The answers of the Data safety form are in `store/IARC_ANSWERS.md`.
4. If a later build switches on the advertising provider, publish an updated policy before that build, as section 5 of the text promises (the checklist is `docs/store/HUMAN_CHECKLIST.md`).

## English text

> # Privacy Policy: Last Streetlight
>
> Effective date: **[date of publication]**. Last updated: **[date of publication]**.
>
> ## 1. Who we are
> "Last Streetlight" (the "App") is a single-player survival-horror game for Android. This policy explains what data the App handles. The developer can be reached at **[contact email / support URL]**.
>
> ## 2. Summary
> The App does not collect, transmit, sell or share personal data. It has no account system, no analytics, no crash-reporting service, no advertising in this version and no in-app purchases.
> Everything the App stores stays on your device.
>
> ## 3. What the App stores on your device
> - Your game progress (a save file with three backups), your settings (language, volume, controls, graphics), your best runs (a local list), the state of the daily challenge and your tutorial progress.
>   The save file is signed with a key inside the game so that a changed file is noticed; the signature protects nothing from you and sends nothing anywhere. All of it lives in the App's private storage
>   and is removed when you uninstall the App or clear its data. Android's automatic cloud backup is switched off for the App.
> - A small log of integrity checks (for example, that a game file was changed) is kept in the same private storage, encrypted. It is never sent.
> - "Export Save" (Settings) copies your save file to your device's Downloads folder and "Import Save" reads it back, only when you press those buttons. The App sends the file nowhere.
> - "Share" on the victory screen copies a short text summary of your run to the clipboard. You decide where, if anywhere, to paste it. The App sends nothing.
>
> ## 4. Permissions and network
> The Android build declares two permissions: VIBRATE, for haptic feedback, and INTERNET, which comes with the game engine's Android template and is kept for the advertising provider that a later version may switch on (section 5).
> No screen of the App opens a connection, loads content from the internet or sends data anywhere, and this version has no online or multiplayer mode.
>
> ## 5. Advertising and third parties
> No advertising network, analytics provider or other third-party service runs in this version. The code of a rewarded-advertising provider exists in the project, but it is not part of the Android build and it
> stays inactive until the developer sets an advertising key; without a key every offer of an ad hides itself. If a later version switches advertising on, this policy will be updated before that version is released
> and will say what the provider collects (for example the advertising identifier and device information). The App is made with the open-source Godot Engine (godotengine.org, MIT licence); the engine itself includes no analytics or tracking.
>
> ## 6. Children
> The App is not directed to children under 13 and its content (horror themes, creatures, mild blood) is rated by the store's content-rating questionnaire for older players. The App collects no personal information from anyone,
> children included, so no parental consent is needed or asked for.
>
> ## 7. Your choices
> No data about you is held by us, so there is nothing for us to access, correct or delete. To remove what the App stores on your device, use "Reset progress" in its settings, clear its storage in Android's app settings, or uninstall it.
>
> ## 8. Changes
> If a later version adds advertising, online features or any data collection, this policy will be updated before that version is released, and the "Last updated" date will change.
>
> ## 9. Contact
> **[contact email / support URL]**

## Русский текст

> # Политика конфиденциальности: «Last Streetlight»
>
> Дата вступления в силу: **[дата публикации]**. Дата последнего обновления: **[дата публикации]**.
>
> ## 1. Кто мы
> «Last Streetlight» (далее «Приложение») — одиночная игра в жанре survival-horror для Android. Эта политика объясняет, какие данные обрабатывает Приложение. Связаться с разработчиком можно так: **[контактный email / страница поддержки]**.
>
> ## 2. Коротко
> Приложение не собирает, не передаёт, не продаёт и не раскрывает персональные данные. В нём нет системы аккаунтов, аналитики, сервиса отчётов о сбоях, рекламы в этой версии и внутриигровых покупок.
> Всё, что Приложение хранит, остаётся на вашем устройстве.
>
> ## 3. Что Приложение хранит на вашем устройстве
> - Ваш игровой прогресс (файл сохранения и три резервные копии), настройки (язык, громкость, управление, графика), ваши лучшие прохождения (локальный список), состояние ежедневного задания и прогресс обучения.
>   Файл сохранения подписан ключом внутри игры, чтобы изменённый файл был замечен; подпись ничего не скрывает от вас и никуда ничего не отправляет. Всё это лежит в закрытом хранилище Приложения и удаляется
>   вместе с ним или при очистке его данных. Автоматическое облачное резервное копирование Android для Приложения выключено.
> - Небольшой журнал проверок целостности (например, что игровой файл был изменён) лежит в том же закрытом хранилище в зашифрованном виде. Он никуда не отправляется.
> - «Экспорт сохранения» (Настройки) копирует файл сохранения в папку «Загрузки» устройства, «Импорт сохранения» читает его обратно — только по нажатию этих кнопок. Приложение никуда этот файл не отправляет.
> - Кнопка «Поделиться» на экране победы копирует в буфер обмена короткую текстовую сводку вашего прохождения. Куда её вставить и вставлять ли вообще, решаете вы. Приложение ничего не отправляет.
>
> ## 4. Разрешения и сеть
> Сборка для Android объявляет два разрешения: VIBRATE (тактильный отклик) и INTERNET, которое входит в Android-шаблон игрового движка и сохранено для рекламного модуля, который может включить будущая версия (раздел 5).
> Ни один экран Приложения не открывает соединение, не загружает контент из интернета и ничего никуда не отправляет; сетевого и многопользовательского режима в этой версии нет.
>
> ## 5. Реклама и третьи стороны
> В этой версии не работают ни рекламная сеть, ни сервис аналитики, ни другие сторонние сервисы. Код модуля рекламы за вознаграждение есть в проекте, но в сборку для Android он не входит и остаётся выключенным,
> пока разработчик не задаст рекламный ключ; без ключа любое предложение рекламы прячется. Если будущая версия включит рекламу, эта политика будет обновлена до выхода такой версии и расскажет, что собирает провайдер
> (например, рекламный идентификатор и сведения об устройстве). Приложение сделано на открытом движке Godot Engine (godotengine.org, лицензия MIT); в самом движке нет ни аналитики, ни слежения.
>
> ## 6. Дети
> Приложение не предназначено для детей младше 13 лет, а его содержание (хоррор-темы, существа, умеренная кровь) оценено вопросником возрастного рейтинга магазина для более старших игроков. Приложение не собирает
> персональные данные ни у кого, включая детей, поэтому согласие родителей не требуется и не запрашивается.
>
> ## 7. Ваш выбор
> У нас нет данных о вас, поэтому нам нечего показывать, исправлять или удалять. Чтобы удалить то, что Приложение хранит на устройстве, нажмите «Сбросить прогресс» в его настройках, очистите его хранилище в настройках Android или удалите Приложение.
>
> ## 8. Изменения
> Если будущая версия добавит рекламу, онлайн-функции или сбор каких-либо данных, эта политика будет обновлена до выхода такой версии, а дата «последнего обновления» изменится.
>
> ## 9. Контакты
> **[контактный email / страница поддержки]**

## Where the code holds each statement

| Statement | Held by |
|---|---|
| Only VIBRATE and INTERNET are asked for | `export_presets.cfg:35` `permissions/internet=true` and `export_presets.cfg:36` `permissions/vibrate=true`; no other `permissions/` line is true |
| The advertising plugin is not in the build | `export_presets.cfg:39` `gradle_build/plugins_enabled` is empty |
| Without a key no ad is offered | `scripts/monetization/ad_service.gd:60` `_default_provider` returns no provider in a release build without `monetization/applovin_sdk_key` |
| No network client, no analytics SDK, no URL in the game | `docs/PRIVACY_AUDIT.md` (generated; the static gate keeps it true) |
| No multiplayer mode is reachable | `docs/PRIVACY_AUDIT.md` (the lobby is named by no file but its own two) and `docs/A10_multiplayer_decision.md` |
| Android cloud backup is off | `android/build/src/main/AndroidManifest.xml:20` `allowBackup` is `false` |
| The save is signed, not sent, and kept with three backups | `scripts/core/save_system.gd:23` `_sign` makes an HMAC-SHA256 of the save body; `scripts/core/save_system.gd:216` `BACKUP_DEPTH` is 3 |
| The integrity log is encrypted and local | `scripts/security/security_log.gd:14` `open_encrypted_with_pass` writes it in the private storage |
| Export Save writes to Downloads on a button | `scripts/core/save_system.gd:68` `get_system_dir` |
| Share copies to the clipboard only | `scripts/ui/win_screen.gd:142` `clipboard_set` |
| Reset progress exists | `scripts/core/save_system.gd:413` `reset_all` |

## Children

COPPA: the App is not directed to children under 13 and collects no personal information, so the Rule has nothing to apply to; the Play Console's "Target audience" question is answered 13 and over (or 16 and over), never "includes children".
The estimate of the age rating is in `store/IARC_ANSWERS.md`.
