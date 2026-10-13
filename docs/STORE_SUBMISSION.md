# Store submission pack: Last Streetlight 1.0 (Google Play)

Drafted 2026-10-11 (Session 20, the final window pass) from the tree at `6f6d643`; the bundle facts were refreshed in Session 22 from the bundle `build/tls.aab`, which was built
from `5749aa8`. **Nothing here has been submitted**: the Play Console, a phone and a contact address are the owner's. Items marked
**(check in Console)** are Google's current rules as remembered at drafting time; read them on the form before you answer.

Order of use: §1 what you upload, §2 the images, §3 the privacy policy, §4 the content rating, §5 the data safety form, §6 the other
declarations, §7 the steps. It consolidates and, where they had drifted, corrects `docs/RELEASE_RUNBOOK.md`,
`store/privacy-policy-template.md`, `docs/store/play_store.md` and `docs/release_checklist.md` (the corrections are listed in §8).

## 1. The bundle: facts read from the AAB itself

| Fact | Value | Where it was read |
|---|---|---|
| File | `build/tls.aab` (gitignored, on the build machine only), **136,508,347 bytes** | `docs/RELEASE_ARTIFACTS.md`, v8.0.0-shipping section |
| sha256 | `5c063a527b2802ae59ef69425a6f9ac900e1927ac1edc12278bb92a573243a68` | same; check it with `sha256sum build/tls.aab` before the upload |
| Built from | `5749aa8` (its runtime is that of `bafc6a3`), no uncommitted path; the seven fixes of Sessions 20 and 21, the B5 fix, the HUD pass and the two fixes of the verifier's round (Session 22) are in it (§9) | ledger row 92 |
| Package name | `com.maxsimkasky.laststreetlight`: **permanent once uploaded** (the `com.tls.game` of `docs/store/play_store.md` is stale) | manifest of the bundle of `e241597`, `docs/artifacts/rc16/proofs/s20_aab_manifest.out`; not re-read from this bundle, but `export_presets.cfg`, `android/` and `project.godot` are unchanged since `e241597` (`git diff --name-only e241597 HEAD -- export_presets.cfg android project.godot` prints nothing) |
| Version | code 1, name "1.0" | manifest |
| App label | "Last Streetlight" in `base/resources.pb`, the resource table that holds the app name (CRC-identical to the entry of the bundle whose label Session 19 verified: 42 entries of the label resource) | `s22c_aab_check_5749aa8.out` (no `base/` entry differs from the bundle of `abbf91d` or from the first bundle of Session 22, `s22_aab_diff_1b1a3f6.out`) |
| SDK levels | min 24, **target 36**; the preset's `min_sdk=29` and `target_sdk=34` (`export_presets.cfg:29-30`) are not read by this export | manifest (Play's minimum target API: **check in Console**) |
| ABI | arm64-v8a only (`architectures/armeabi-v7a=false`): 32-bit-only phones are not offered the game | `export_presets.cfg:14-15` |
| Permissions | `INTERNET` and `VIBRATE` only; no `AD_ID`, no storage, no location, no camera, no microphone | manifest |
| Application flags | `allowBackup=false` (no Android cloud backup of the saves), `isGame=true`, OpenGL ES 3.0 required | manifest |
| Ads | no ad SDK code: 0 dex references to `Lcom/applovin/` (the GDScript provider file is in the pack and, with no key, resolves to no provider) | `docs/artifacts/rc16/proofs/s22c_aab_check_5749aa8.out` |
| Signature | `jar verified.`; the signer's SHA-256 equals the upload key; keep Play App Signing | `s22c_aab_check_5749aa8.out`, `docs/RELEASE_RUNBOOK.md` §1 |
| Size | base module 26,974,685 bytes compressed; install-time asset pack 108,579,735 bytes compressed (Play caps the base module at 200 MB: **check in the App bundle explorer**) | `docs/RELEASE_ARTIFACTS.md` |
| Contents scan | 0 packed files that are not the game, in the scan's classes | `s22c_aab_scan_5749aa8.out` |

Upload no other bundle: the bundle of `63fda65` packs an API key and the one of `16abbb0` packs 77 store images
(`docs/RELEASE_ARTIFACTS.md`). Both are kept under `..\_BACKUPS\`; the file at `build/tls.aab` is the right one.

## 2. Store images: exact specs, the file to use, what to do to it

All sizes below were measured on the files (`docs/artifacts/rc16/proofs/s20_store_assets.out`); every RGBA file listed has an alpha
channel that is fully opaque (minimum 255, `s20_alpha_extrema.out`), so dropping the channel loses nothing.

| Asset | Play's rule **(check in Console)** | File to use | Measured | What to do |
|---|---|---|---|---|
| App icon | 512 x 512 px, PNG (32-bit, alpha allowed), at most 1 MB | `store/icon-512.png` | 512 x 512, RGB 8-bit, 300,965 bytes | upload as it is; if the form refuses it, re-save it as RGBA |
| Feature graphic | 1024 x 500 px, JPEG or 24-bit PNG, **no alpha** | `store/feature-graphic.png` (title and tagline, the lamp street) | 1024 x 500, RGBA 8-bit, 684,630 bytes | drop the alpha (command below). **Do not use** `assets/store/feature_graphic_1024x500.png`: it is blurred art with no title (what `docs/RELEASE_RUNBOOK.md` §3.3 named) |
| Phone screenshots | 2 to 8; JPEG or 24-bit PNG, **no alpha**; each side 320 to 3840 px, the long side at most twice the short side; 1080 px or more on the short side to be eligible for featuring | the six frames of `docs/stills/shipping/` | 960 x 527 (all six), RGBA 8-bit with every alpha 255, 397 KiB to 823 KiB each (406,724 to 842,526 bytes) | drop the alpha. 960 px is inside the accepted range and under the featuring size (re-shoot at 1920 x 1080 with `tools/qa_sim/` if wanted) |
| Adaptive icon | in the bundle, not uploaded: two 1080 x 1080 layers | `store/icon-adaptive/foreground_1080x1080.png`, `background_1080x1080.png` | RGBA 8-bit | nothing |
| Launcher icon source (legacy phones) | 192 px from a 512 px source | `assets/store/play_icon_512.png` | 512 x 512, RGB 8-bit, scene art (not the lamp) | nothing; only phones below Android 8 (API 24 and 25) show it, a design call, not a blocker |
| Tablet screenshots, promo video | optional | none prepared | | skip |

The six screenshot frames (each carries its code hash `ccf61ee`, the tree of the HUD pass, and its capture time in its name, AF3; the frames of the shipping pass are kept in `docs/stills/shipping/s21/`):

1. `docs/stills/shipping/01_main_menu_after_ccf61ee_20261012T060401Z.png`: the main menu.
2. `docs/stills/shipping/02_district_day_full_after_ccf61ee_20261012T060415Z.png`: a restored district with its lamps on (the game has no day).
3. `docs/stills/shipping/03_district_night_dark_after_ccf61ee_20261012T060410Z.png`: the same district dark, its lamps off.
4. `docs/stills/shipping/04_combat_after_ccf61ee_20261012T060420Z.png`: combat.
5. `docs/stills/shipping/05_boss_after_ccf61ee_20261012T060422Z.png`: the boss.
6. `docs/stills/shipping/08_shop_after_ccf61ee_20261012T060417Z.png`: the shop.

The frames of the HUD pass (hurt, interact prompt, and the touch layout at 1600 x 740 with touch emulated) are in `docs/stills/shipping/hud/after2/`; the touch frame is not a store screenshot (its long side is more than twice the short side), and none of them was read on a phone (`docs/UNVERIFIABLE_HERE.md` U13).

Not used, on purpose: `assets/store/screenshot_0*.png` (1280 x 720, RGBA, made before rc16, no code hash, not checked against the build) and
`store/screenshots/*_1920x1080_en.png` (RGB, older waves, no code hash). Use them only after you compare each with the running game.

One command from the repository root writes the upload set to `build/store_upload/` (Pillow is installed on this machine):

```bash
python -c "import pathlib; from PIL import Image; o=pathlib.Path('build/store_upload'); o.mkdir(parents=True, exist_ok=True); [Image.open(p).convert('RGB').save(o/pathlib.Path(p).name) for p in ['store/feature-graphic.png', *map(str, sorted(pathlib.Path('docs/stills/shipping').glob('*.png')))]]"
```

The listing text: `store/listing.md` (English and Russian, the source of truth), `docs/STORE_KIT.md` (the other 11 locales; flagged there for a native
spot-check); limits: title 30, short description 80, full description 4,000 characters **(check in Console)**.

## 3. Privacy policy: the text to host

Host it at a stable HTTPS URL (any static page), fill the two placeholders (contact and date), and paste the URL into the Console's
privacy-policy field and the store listing. It states only what this build does; each sentence was checked against the code or the manifest
(§8). Variant A of `docs/RELEASE_RUNBOOK.md` §6 (no ads) is built in, so use this text and not the template's advertising section.

### 3.1 English

> # Privacy Policy: Last Streetlight
>
> Effective date: **[date of publication]**. Last updated: **[date of publication]**.
>
> ## 1. Who we are
> "Last Streetlight" (the "App") is a single-player survival-horror game for Android. This policy explains what data the App handles.
> The developer can be reached at **[contact email / support URL]**.
>
> ## 2. Summary
> The App does not collect, transmit, sell or share personal data. It has no account system, no analytics, no crash-reporting service,
> no advertising and no in-app purchases. Everything the App stores stays on your device.
>
> ## 3. What the App stores on your device
> - Your game progress (a save file), your settings (language, volume, controls, graphics), the state of the daily challenge and your
>   tutorial progress. They live in the App's private storage and are removed when you uninstall the App or clear its data.
>   Android's automatic cloud backup is switched off for the App.
> - "Export Save" (Settings) copies your save file to your device's Downloads folder and "Import Save" reads it back, only when you press
>   those buttons. The App sends the file nowhere.
> - "Share" on the victory screen copies a short text summary of your run to the clipboard. You decide where, if anywhere, to paste it.
>   The App sends nothing.
>
> ## 4. Permissions and network
> The Android build declares two permissions: VIBRATE, for haptic feedback, and INTERNET, which comes with the game engine's Android
> template. The App has no feature that uses the network: none of its screens opens a connection, loads content from the internet or
> sends data anywhere, and this version has no online or multiplayer mode.
>
> ## 5. Advertising and third parties
> No advertising network, analytics provider or other third-party service is built into the App. The App is made with the open-source
> Godot Engine (godotengine.org, MIT licence); the engine itself includes no analytics or tracking.
>
> ## 6. Children
> The App is not designed for children. It collects no personal information from anyone, children included.
>
> ## 7. Your choices
> No data about you is held by us, so there is nothing for us to access, correct or delete. To remove what the App stores on your
> device, use "Reset progress" in its settings, clear its storage in Android's app settings, or uninstall it.
>
> ## 8. Changes
> If a later version adds advertising, online features or any data collection, this policy will be updated before that version is
> released, and the "Last updated" date will change.
>
> ## 9. Contact
> **[contact email / support URL]**

### 3.2 Русский

> # Политика конфиденциальности: «Последний фонарь»
>
> Дата вступления в силу: **[дата публикации]**. Дата последнего обновления: **[дата публикации]**.
>
> ## 1. Кто мы
> «Последний фонарь» (далее «Приложение») — одиночная игра в жанре survival-horror для Android. Эта политика объясняет, какие данные
> обрабатывает Приложение. Связаться с разработчиком можно так: **[контактный email / страница поддержки]**.
>
> ## 2. Коротко
> Приложение не собирает, не передаёт, не продаёт и не раскрывает персональные данные. В нём нет системы аккаунтов, аналитики, сервиса
> отчётов о сбоях, рекламы и внутриигровых покупок. Всё, что Приложение хранит, остаётся на вашем устройстве.
>
> ## 3. Что Приложение хранит на вашем устройстве
> - Ваш игровой прогресс (файл сохранения), настройки (язык, громкость, управление, графика), состояние ежедневного задания и
>   прогресс обучения. Всё это лежит в закрытом хранилище Приложения и удаляется вместе с ним или при очистке его данных.
>   Автоматическое облачное резервное копирование Android для Приложения выключено.
> - «Экспорт сохранения» (Настройки) копирует файл сохранения в папку «Загрузки» устройства, «Импорт сохранения» читает его обратно —
>   только по нажатию этих кнопок. Приложение никуда этот файл не отправляет.
> - Кнопка «Поделиться» на экране победы копирует в буфер обмена короткую текстовую сводку вашего прохождения. Куда её вставить и
>   вставлять ли вообще, решаете вы. Приложение ничего не отправляет.
>
> ## 4. Разрешения и сеть
> Сборка для Android объявляет два разрешения: VIBRATE (тактильный отклик) и INTERNET, которое входит в Android-шаблон игрового движка.
> Ни одна функция Приложения сеть не использует: ни один экран не открывает соединение, не загружает контент из интернета и ничего не
> отправляет; сетевого и многопользовательского режима в этой версии нет.
>
> ## 5. Реклама и третьи стороны
> В Приложение не встроены ни рекламная сеть, ни сервис аналитики, ни другие сторонние сервисы. Приложение сделано на открытом движке
> Godot Engine (godotengine.org, лицензия MIT); в самом движке нет ни аналитики, ни слежения.
>
> ## 6. Дети
> Приложение не рассчитано на детей. Оно не собирает персональные данные ни у кого, включая детей.
>
> ## 7. Ваш выбор
> У нас нет данных о вас, поэтому нам нечего показывать, исправлять или удалять. Чтобы удалить то, что Приложение хранит на устройстве,
> нажмите «Сбросить прогресс» в его настройках, очистите его хранилище в настройках Android или удалите Приложение.
>
> ## 8. Изменения
> Если в будущей версии появятся реклама, сетевые функции или сбор данных, мы обновим эту политику до выхода такой версии, и дата
> «последнего обновления» изменится.
>
> ## 9. Контакты
> **[контактный email / страница поддержки]**

`store/privacy-policy-template.md` carries a pointer to this section; its older text said the same in fewer words and is no longer the one
to host.

## 4. Content rating: the IARC answers (category: Game)

Answer the form with these; **trust the rating IARC computes**. The expected result is PEGI 16 (`docs/PRODUCTION_BIBLE.md` §6).

| Question area | Answer | Basis |
|---|---|---|
| Violence | **Yes.** Stylized violence against former-human creatures, with blood (a blood effect on a monster's death, a bleed status). No dismemberment, and no violence against realistic humans or animals | GDD §6.4 to §6.5; `scripts/enemies/base_monster.gd:737` to `scenes/vfx/vfx_blood.tscn` |
| Fear / horror | **Yes.** Sustained horror tension, monsters in the dark, a deliberately caused disaster in the story | `docs/PRODUCTION_BIBLE.md` §1 |
| Sexuality / nudity | No | none in the content |
| Language | No profanity | a scan of the English strings found 0 hits (`docs/RELEASE_RUNBOOK.md` §7) |
| Controlled substances | **Yes, a reference only.** The English strings name an item "Alcohol" (`ITEM_ALCOHOL`), an ingredient of the medkit and of the thrown fire bottle, and say nothing of anyone drinking it; the lore uses "drink" of a power grid. No tobacco, no drugs, no depiction of use. Answer Yes to a question about references to alcohol and No to one about depiction or use | `store/IARC_ANSWERS.md` (the pattern `\balcohol\b` over `data/i18n/en.json`), `scripts/crafting/workbench_logic.gd` |
| Gambling | No real or simulated gambling, no loot boxes; daily rewards are deterministic | `scripts/systems/daily_challenge_manager.gd` |
| Crude humour | No | |
| Users interact / user-generated content | **No.** No chat, no user content, no sharing of location. The "Share" button only copies text to the clipboard | `scripts/ui/win_screen.gd:103` |
| Digital purchases | **No.** There are no in-app purchases; the shop spends coins earned in play | `scripts/economy/shop_service.gd:3` |
| Unrestricted internet access | No: the App has no web view, no browser call and no network feature (§3.4 of the policy) | `docs/artifacts/rc16/proofs/s20_net_reach.out` |

## 5. Data safety form: the answers

Because the App collects and shares nothing, the form is one decision.

| Section of the form | Answer | Why |
|---|---|---|
| Does your app collect or share any of the required user data types? | **No** | no account, no analytics, no ad SDK, no network call from a screen; saves stay in private storage |
| Data types collected / shared | none selected | |
| Is all of the user data encrypted in transit? | not asked when nothing is collected; if asked: **not applicable**, nothing is transmitted | |
| Can users request that their data be deleted? | not applicable: nothing is held by the developer; the user removes local data with "Reset progress", clearing storage or uninstalling | |
| Privacy policy URL | the URL of §3 | required even for an app that collects nothing |
| Independent security review, "Families" and similar badges | leave off | |

Note for the owner: Google treats data that stays on the device as "not collected". The one transfer the App performs at all is
the user's own "Export Save" to the Downloads folder. If the Console's wording makes you doubt, the conservative reading is still
"No" (the file never leaves the device unless the user moves it). **(check in Console)**

## 6. The other declarations of the Console

| Declaration | Answer |
|---|---|
| App access | all functionality is available without special access (no login) |
| Ads | **No** (the bundle holds no ad SDK code) |
| Content rating | §4 |
| Target audience | 16 to 17 and 18 and over; not designed for children, skip the Families program |
| News app / Government app / Financial features / Health | No / No / none / none |
| Advertising ID | **No** (the manifest has no `AD_ID` permission) |
| App category and tags | Game, Action; tags per `docs/store/play_store.md` |
| Price | Free |
| Contact | an email address is required; the same one as in the policy |

## 7. The steps, in order

Each step names where the detail lives; it does not repeat it.

1. **Rotate the key first** (`docs/release_checklist.md` step 0, with the exact places): it takes minutes and nothing else depends on it, but a key that sat in a public repository is worth rotating before a policy page and a store account point at that repository.
2. **Check the file.** `sha256sum build/tls.aab` must print the value of §1; `jarsigner -verify build/tls.aab` must print `jar verified.`.
3. **Phone smoke test** (U1, U5, U6, U12 and U13 of `docs/UNVERIFIABLE_HERE.md`, and U10 for Export Save): install the bundle through an internal-test link and run `docs/RELEASE_RUNBOOK.md` §4. The bundle holds the seven fixes of Sessions 20 and 21 (§9).
4. **Make the images** with the command of §2, and read each of the seven files once.
5. **Host the policy** of §3 and note its URL.
6. **Play Console:** create the app and fill the dashboard with §6, the rating with §4 and the data safety form with §5 (`docs/RELEASE_RUNBOOK.md` §3 is the click path); main listing from §2 and `store/listing.md`; translations from `docs/STORE_KIT.md`.
7. **Internal testing:** upload `build/tls.aab` as "1.0 (1)", add testers, start the rollout (`docs/RELEASE_RUNBOOK.md` §3.6).
8. **Closed testing** if the dashboard demands it for a new personal account (12 testers for 14 days at the time of writing; **check in Console**), then production with a staged rollout (§3.7 and §3.8 of the runbook).
9. **Every upload after the first** needs `version/code` raised (`export_presets.cfg:16`).

## 8. What was corrected while drafting (stale lines in the older documents)

| Document | Stale line | What is true |
|---|---|---|
| `docs/store/play_store.md` | `min_sdk=29`, `target_sdk=34`, package `com.tls.game` | the bundle reads min 24, target 36, package `com.maxsimkasky.laststreetlight` |
| `docs/store/play_store.md` | Data safety "LAN co-op ... talks to devices on the LAN" | the code is in the build, no screen reaches it (§9 of this file, `s20_net_reach`) |
| `docs/RELEASE_RUNBOOK.md` §3.3 | feature graphic `assets/store/feature_graphic_1024x500.png`, screenshots `assets/store/screenshot_0*.png` | §2 of this file: `store/feature-graphic.png` and the six release frames |
| `docs/release_checklist.md` (history section) | target 34, compile 34, min 21 | superseded by the numbers of §1 |
| `store/privacy-policy-template.md` | "the shipped build has no networking at all" | still true of what a player can reach; the policy of §3 says it by what the screens do, which is what was checked |

## 9. What this pass could not do

- **The fixes are in the bundle now.** Session 22 exported twice from `main`; the second bundle (`5749aa8`) holds the four fixes of `6f6d643` (CORRECTION_LOG 168, 178, 179, 180), the three of Session 21 (169, 172, 174), the B5 fix (205), the HUD pass (206) and the two fixes of the verifier's round (208) (`docs/RELEASE_ARTIFACTS.md`, v8.0.0-shipping section). The manifest was not re-read from this bundle.
- **LAN co-op code is in the build and unreachable.** `scenes/main_3d.tscn` holds a `LANMenu` node (hidden) that nothing opens, and the
  lobby screen is archived; three autoloads of the multiplayer code exist and open no socket until a screen asks
  (`docs/artifacts/rc16/proofs/s20_net_reach.out`). CORRECTION_LOG 173 is latent for that reason (174 is fixed).
- **Nothing on a phone was run.** The frame rate, the heat, the feel of the touch controls and Export Save through Downloads
  (U1, U5, U6, U10, and for the HUD of Session 22 U12 and U13) are the smoke test's questions.
- **No legal review.** The policy is a plain-language draft of what the build does, not legal advice; several jurisdictions ask for a
  named controller and an address, which are yours to add.
