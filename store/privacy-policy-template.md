# Privacy Policy — template (to host at a stable URL)

Owner: CONTENT/store agent. This is a **plain fill-in template** for the human owner to host on
a stable page and link from the store listing (Play/Steam require a live URL, not inline text).
Facts below match the current build; keep them honest. Everything in `[square brackets]` must be
replaced before publishing. Read it top to bottom and only remove a paragraph if it is genuinely
false for the shipping build.

A full plain-language **RU version** (all 9 sections, mirroring the EN policy) is at the
bottom so the RU listing can point to a Russian policy too. The only things the owner must
fill in are the `[square bracket]` placeholders: the contact email / support URL (the app
name and dates are already filled in, EN and RU alike).

> **⚠ PLACEHOLDERS STILL OPEN (final sync, 2026-09-13 — RC FINAL v2):** exactly 4 fill-in
> slots remain — `**[contact email / support URL]**` ×2 in the EN text (§1, §9) and its RU
> mirror `**[контактный email / страница поддержки]**` ×2 (§1, §9). Everything else in both
> policy texts is final and matches the shipped build. Do not publish while any `[square
> bracket]` remains.
>
> **Claim audit note:** the previous draft's §4 described a LAN multiplayer feature. That
> feature is NOT reachable in the launch build (the LAN prototype is archived with no UI
> entry — `docs/A10_multiplayer_decision.md`), so §4 has been rewritten to the shipped
> reality: no networking at all, and the INTERNET permission exists solely for the optional,
> key-less, inert ad plugin. RU §4 mirrors this.

---

# Privacy Policy — The Last Streetlight

_Effective date: 2026-09-13_
_Last updated: 2026-09-13_

## 1. Who we are
This policy explains what data, if any, the game **The Last Streetlight** ("the App", "we", "us")
collects. The developer can be reached at: **[contact email / support URL]**.

## 2. Summary
The App is **offline-first single-player**. As shipped, it **does not collect, store, or
transmit personal data**. There is no account system, no analytics SDK, no multiplayer or other
online feature, and no advertising SDK enabled in the default build.

## 3. Data we collect
None. The App does not collect your name, email address, device identifiers, location, or any
other personal information. Game progress is stored **locally on your device** in your own save
file and is never uploaded. (Settings → Game lets you *export* that file to your own device
storage or *import* one you already own; either action touches only your own files — nothing
is sent anywhere.)

## 4. Permissions & connections
The shipped build has no networking at all: it never talks to other devices and there is no
multiplayer mode in the launch app (the earlier LAN prototype is not reachable from any UI).
The Android build declares exactly two permissions: `VIBRATE` (touch haptics) and `INTERNET`
— the latter is reserved for the optional advertising plugin described in §5 and goes unused
by the game itself; while no ad key is configured nothing is loaded from or sent to the
network. In the default build the App does not access the internet for analytics or accounts.

## 5. Advertising (if enabled)
The current build integrates an optional advertising framework (AppLovin MAX) that is **disabled**
and collects nothing until a developer key is configured; with no key set, the in-game ad slots
show only an offline placeholder window that loads nothing from the network. **If** advertising is
enabled in a future update, this policy will be updated to disclose what the advertising provider
collects (including advertising identifiers and device information) before any build with ads
ships.

## 6. Children's privacy
The App does not knowingly collect any personal information from children. Because we collect no
personal information at all, there is nothing to delete; removing the App and its local save files
removes all data it holds.

## 7. Your choices & control
Because no personal data is collected, there is nothing to access, correct, or delete on our side.
To remove all App data, delete the App or clear its app data in your device settings (this erases
your local save files).

## 8. Changes to this policy
If we ever change what the App collects (for example, if advertising or online features are
added), we will update this page before the change ships. The "Last updated" date above reflects
the most recent revision.

## 9. Contact
Questions about this policy or the App's data practices: **[contact email / support URL]**.

---

## РУ / RU version (Политика конфиденциальности)

_Дата вступления в силу: 2026-09-13_
_Дата последнего обновления: 2026-09-13_

### 1. Кто мы
Эта политика объясняет, какие данные (если вообще какие-либо) собирает игра **«Последний
фонарь»** (далее — «Приложение», «мы»). Связаться с разработчиком можно так:
**[контактный email / страница поддержки]**.

### 2. Коротко
Приложение работает **офлайн** и является одиночным. В текущей версии оно **не собирает, не
хранит и не передаёт персональные данные**. В нём нет системы аккаунтов, нет SDK аналитики,
нет мультиплеера и прочих онлайн-функций и нет включённой рекламы.

### 3. Какие данные мы собираем
Никаких. Приложение не собирает ни имя, ни email, ни идентификаторы устройства, ни
геолокацию, ни любую другую личную информацию. Прогресс игры хранится **локально на вашем
устройстве** в вашем файле сохранения и никуда не отправляется. (В настройках есть экспорт
этого файла в хранилище устройства и импорт уже имеющегося у вас файла — обе операции
касаются только ваших файлов и никуда их не отправляют.)

### 4. Разрешения и подключения
В текущей сборке сеть не используется вовсе: приложение ни с кем не связывается,
мультиплеера в релизной версии нет (LAN-прототип недоступен ни из какого экрана). Android-сборка
запрашивает ровно два разрешения: `VIBRATE` (тактильный отклик) и `INTERNET` — второе
зарезервировано под опциональный рекламный модуль из §5 и самой игрой не используется; пока
ключ рекламы не задан, из сети ничего не загружается и в сеть ничего не отправляется.
В текущей сборке приложение не обращается к интернету для аналитики или аккаунтов.

### 5. Реклама (если будет включена)
В текущую сборку интегрирован необязательный рекламный каркас (AppLovin MAX), который
**выключен** и ничего не собирает, пока не задан ключ разработчика; без ключа игровые
рекламные слоты показывают лишь офлайн-заглушку, ничего не загружая из сети. **Если**
реклама будет включена в будущем обновлении, эта политика будет обновлена **до выхода**
такой сборки — с раскрытием того, что собирает рекламный провайдер (включая рекламные
идентификаторы и информацию об устройстве).

### 6. Дети
Приложение сознательно не собирает никаких персональных данных детей. Поскольку мы вообще не
собираем персональные данные, удалять на нашей стороне нечего: удаление приложения и его
локальных файлов сохранения удаляет все данные, которые оно хранит.

### 7. Ваш контроль
Так как персональные данные не собираются, на нашей стороне нечего просматривать, исправлять
или удалять. Чтобы удалить все данные Приложения, удалите само приложение или очистите его
данные в настройках устройства (это сотрёт ваши локальные сохранения).

### 8. Изменения этой политики
Если мы когда-либо изменим то, что собирает приложение (например, добавим рекламу или
онлайн-функции), мы обновим эту страницу до выхода такого изменения. Дата «последнего
обновления» выше отражает последнюю редакцию.

### 9. Контакты
Вопросы об этой политике и о данных Приложения: **[контактный email / страница поддержки]**.

---

## Before publishing (owner checklist)
1. Replace every remaining `[square bracket]` placeholder — exactly 4, all the
   contact email / support URL (×2 EN, ×2 RU). Dates and the app name are already
   filled in (EN and RU alike) with the RC FINAL v2 sync date.
2. Publish at a stable HTTPS URL and paste it into the store listing's privacy-policy field
   (the Play listing currently marks it TODO — see `store/listing.md` Data-safety notes).
3. If any future build enables AppLovin advertising, update §5 (and the RU version) to disclose
   the SDK's data collection before that build ships — see `docs/store/HUMAN_CHECKLIST.md`.
4. Keep the policy in the same language(s) as your store listings (EN + RU here).
