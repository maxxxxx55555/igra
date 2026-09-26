# Release runbook: signed AAB → Google Play

Ordered owner steps, copy-paste where possible. It reuses the texts that already exist instead of
repeating them:
- `docs/RELEASE_ARTIFACTS.md`: keystore, export commands
- `store/listing.md`: EN/RU listing masters
- `docs/STORE_KIT.md`: the other 11 locales
- `store/privacy-policy-template.md`: EN + RU policy
- `docs/store/HUMAN_CHECKLIST.md`: AppLovin

Anything Google may have changed since 2026-09-26 is marked **(check in Play Console)**.

## 0. Blockers to clear before the first export

| # | Blocker | Why | Do this |
|---|---|---|---|
| B1 | **ETC2/ASTC texture import is off** | Godot's Android exporter refuses without it: "ETC2/ASTC texture compression is required for Android export" (`platform/android/export/export_plugin.cpp`). `project.godot` has no `import_etc2_astc`, and all 520 VRAM textures are imported as BPTC only (`docs/PERF_PASS.md` #9) | Editor → Project Settings → Advanced → Rendering → Textures → VRAM Compression → **Import ETC2 ASTC = On**. Let the editor reimport, then commit `project.godot` and the updated `.import` files |
| B2 | **Export format is APK** | The Android preset has no `gradle_build/export_format`, so it defaults to "Export APK", and Play needs an AAB | Project → Export → Android → Gradle Build → **Export Format = Export AAB**; export path `build/tls.aab`. Commit `export_presets.cfg` (no credentials in it) |
| B3 | **Ads decision** | With no AppLovin key, every release build falls back to the debug ad stub, which grants revive and battery with no ad (`docs/SECURITY_SWEEP_V2.md` #2) | **A, no ads at launch:** apply SECURITY_SWEEP_V2 #2 (release hides ad offers). **B, ads at launch:** follow `docs/store/HUMAN_CHECKLIST.md` "AppLovin MAX ads" (SDK key, plugin enabled, consent flow for EEA/UK users), then use the B texts in §6–§8 |
| B4 | Templates and build tools | `docs/RELEASE_ARTIFACTS.md`: no 4.7 export templates, no Android build template | Editor → Manage Export Templates → install **4.7.stable**; Project → Install Android Build Template. Point Editor Settings → Export → Android at your JDK 17 and Android SDK |
| B5 | Target SDK | Play enforces a minimum target API **(check in Play Console)**. The preset sets no `target_sdk`, so Godot's default applies (current Godot master: min 24, target 36, `editor/export/android_sdk_manager.h`) | Leave empty unless the Console asks for more. `docs/store/play_store.md` "min_sdk=29 / target_sdk=34 / com.tls.game" is stale: the preset's package is `com.maxsimkasky.laststreetlight` |
| B6 | Size | Play caps the base module's compressed download at 200 MB **(check in Play Console)**. The last desktop PCK measured 205.5 MB (`docs/PERF_PASS.md` #10) | After §2, read the size in Play Console (App bundle explorer). If over the cap, do `docs/SIZE_BUDGET.md`'s unfinished E7 audio re-encode first |
| B7 | Merge re-verification | `docs/MERGE_PLAN.md` §4 | Bot, windowed frames, `check.sh` full, on the merged tree |

## 1. Keystore (location only; never paste secrets anywhere)

- **Upload keystore:** `.signing/tls-release.keystore` (PKCS12, alias `tls_release`). The SHA-256
  fingerprint to expect is recorded in `docs/RELEASE_ARTIFACTS.md`.
- **Password:** in `.signing/release.env` as the three `GODOT_ANDROID_KEYSTORE_RELEASE_*`
  variables (path, user, password).
- `.signing/`, `*.keystore` and `*.jks` are gitignored. `export_presets.cfg` keeps the keystore
  fields empty on purpose, and `tools/qa_sim/release_export_check.py` fails the build if one is
  ever committed.
- Back up `.signing/` in **two** places off this machine before the first upload. In Play, keep
  Google-managed **Play App Signing** (the default for new apps), so this keystore is only the
  *upload* key and a lost copy can be reset through Play support.

## 2. Build and verify

```bash
set -a; . .signing/release.env; set +a        # Git Bash; PowerShell: set the same three variables
godot --headless --path . --export-release "Android" build/tls.aab
jarsigner -verify -verbose -certs build/tls.aab            # expect "jar verified"
keytool -list -v -keystore .signing/tls-release.keystore   # SHA-256 must match RELEASE_ARTIFACTS.md
```

Bump `version/code` (`export_presets.cfg:16`) for every upload after the first. Keep `version/name`
human-readable ("1.0", then "1.0.1", …).

## 3. Play Console, in order

1. **Create app:** name *The Last Streetlight*, default language English (United States), **Game**,
   **Free**. Accept the declarations.
2. **Dashboard → Set up your app:**
   - **Privacy policy:** the URL from §6.
   - **App access:** "All functionality is available without special access".
   - **Ads:** A = "No", B = "Yes, my app contains ads".
   - **Content rating:** §7.
   - **Target audience:** 16–17 and 18+. Not designed for children; skip the Families program.
   - **News app:** No. **Data safety:** §8.
   - **Government app:** No. **Financial features:** none. **Health:** none.
   - **Advertising ID:** A = "No" (Godot's default manifest has no AD_ID permission). B = "Yes,
     Advertising or marketing" (the AppLovin plugin adds AD_ID).
3. **Main store listing:**
   - Title, short description (≤ 80) and full description (≤ 4000) from §9.
   - App icon: `assets/store/play_icon_512.png` (512²).
   - Feature graphic: `assets/store/feature_graphic_1024x500.png`.
   - Phone screenshots: `assets/store/screenshot_01.png` … `_05.png` (1280×720).
   - Category: **Game → Action**. Tags per `docs/store/play_store.md`. A contact email is required.
4. **Store listing → Manage translations:** add ru, es, de, fr, it, pt-BR, tr, ja, ko, zh-CN, zh-TW
   and ar with the §9 texts.
5. **Test and release → Setup → App signing:** keep Google-generated app signing (§1).
6. **Internal testing:**
   - Create a new release, upload `build/tls.aab`, name it "1.0 (1)".
   - Release notes: en-US *"First test build."* and ru-RU *"Первая тестовая сборка."*
   - Save → Review → **Start rollout**.
   - Testers tab: add an email list and copy the opt-in link.
7. **Closed testing, if the Dashboard asks for it:** new personal developer accounts must run a
   closed test with a minimum number of opted-in testers for a minimum number of days before they
   can apply for production **(check the current numbers on the Dashboard; they were 12 testers for
   14 days)**.
8. **Production:** Apply for production access if required, then create the production release
   (promote the tested AAB). Use a staged rollout: 10 % → 50 % → 100 %, watching Android vitals
   (crashes, ANRs) between steps.

## 4. Device smoke test before every promotion

1. Install from the internal-test link. First boot: no crash, and the language picker works.
2. New Game → tutorial → first generator runs; the district lights up.
3. Save, force-close, relaunch, **Continue**: same district, same inventory.
4. Ads. A: no ad offers anywhere (death screen, HUD battery). B: the rewarded ad plays and then
   grants its reward.
5. Switch language through all 13 locales; titles and HUD fit.
6. 20 minutes of play: FPS stays ≥ 30 and the device doesn't overheat (feeds `docs/PERF_PASS.md` §2).
7. Suspend and resume mid-district; the daily challenge card still shows.

## 5. After release

Tag the release commit. Keep the `.signing/` backups. Bump `version/code` for every upload. Answer
reviews using `store/review-responses.md`.

## 6. Privacy policy (host at a stable URL, then paste the URL in §3.2)

**Text:** `store/privacy-policy-template.md` (EN + RU). Replace its 4 `[contact email / support URL]`
placeholders.

**Variant A:** if SECURITY_SWEEP_V2 #2 is applied, replace the second sentence of §5 with:

> With no key set, the game shows no advertising and loads nothing from the network.

The same change applies to RU §5.

**Variant B, ads at launch:** replace EN §5 with the text below, and mirror it in RU §5:

> **5. Advertising.** The App shows optional rewarded and interstitial ads through AppLovin MAX.
> To serve and measure ads, AppLovin and its ad partners may collect your device's advertising ID,
> IP address (used for approximate location), device and operating-system information, and
> interactions with ads. See AppLovin's privacy policy: https://www.applovin.com/privacy/. You can
> reset or delete your advertising ID in your device settings. Where the law requires consent
> (for example in the EEA and UK), the App asks for it before any personalized ad is shown.

Also remove "no advertising SDK enabled in the default build" from §2, and update "Last updated".

## 7. Content rating (IARC questionnaire, category *Game*)

| Question area | Answer | Basis |
|---|---|---|
| Violence | **Yes**: stylized violence against former-human creatures; **blood yes** (blood effect on monster death, bleed status). No dismemberment, no violence against realistic humans or animals | GDD §6.4–§6.5; `scripts/enemies/base_monster.gd:737` → `scenes/vfx/vfx_blood.tscn` |
| Fear / horror | **Yes**: sustained horror tension, monsters in darkness | pillars in `docs/PRODUCTION_BIBLE.md` §1 |
| Sexuality / nudity | No | — |
| Language | No profanity | en string scan: 0 hits |
| Controlled substances | No depiction or use. One passing reference to drunkenness in a police lore note | `LORE_POLICE_05_TEXT` |
| Gambling | No real or simulated gambling, no loot boxes | Daily rewards are deterministic |
| Crude humour | No | — |
| User interaction | No chat, no user-generated content, no location sharing | LAN is archived and unreachable |
| Digital purchases | **No** in-app purchases (IAP packs removed; the shop spends earned coins only) | `scripts/economy/shop_service.gd:3` |
| Ads | Declared separately in §3.2 | — |

The expected result is **PEGI 16**, per `docs/PRODUCTION_BIBLE.md` §6. If IARC returns a different
rating, trust IARC.

## 8. Data safety form

**Variant A (no ads):**
- Collects or shares user data: **No**. The app's own traffic is none; the save stays on the device.
- Deletion: uninstalling removes all data.

**Variant B (AppLovin MAX):** enter exactly what AppLovin's current Google Play Data safety guidance
lists **(check AppLovin's developer docs at upload)**. Typically:

| Data type | Collected | Shared | Purposes |
|---|---|---|---|
| Device or other IDs | yes | yes | advertising, analytics, fraud prevention |
| Approximate location (from IP) | yes | yes | advertising, analytics |
| App interactions | yes | yes | advertising, analytics |
| Diagnostics | yes | no | analytics |

Also: encrypted in transit **yes**; collection is required for ad delivery; users can reset the
advertising ID.

## 9. Store listing per locale (polish applied)

**Titles (≤ 30).** Use the game's own localized title (`menu_title`), or the English brand
everywhere if you prefer one global name:
- en: The Last Streetlight
- ru: Последний фонарь
- es: La última farola
- de: Die letzte Laterne
- fr: **Le Dernier Réverbère** (accents restored, I18N_TABLE_V2 row 78)
- it: L'ultimo lampione
- pt-BR: O último poste de luz
- tr: Son Sokak Lambası
- ja: 最後の街灯
- ko: 마지막 가로등
- zh-CN: 最后一盏街灯
- zh-TW: 最後一盞街燈
- ar: آخر مصباح شارع

Optional for zh: the game's own term is 路灯 (48 uses vs 3 of 街灯), so 最后一盏路灯 / 最後一盞路燈
would match the in-game text. It's a brand call.

**Short descriptions (≤ 80):**
- **en/ru:** from `store/listing.md` "Short description", the declared source of truth. STORE_KIT's
  ru line differs; use `store/listing.md`.
- **es, de, fr, it, pt-BR, ja, ko, ar:** as in `docs/STORE_KIT.md` "Locale coverage".
- **Three replacements** (natural word order; the originals attach "every streetlight" to the
  wrong noun):

| Locale | Replace | With |
|---|---|---|
| tr | Işığı geri getir. Her sokak lambası bir can taşıyan gizlilik korkusu. | Işığı geri getir. Her sokak lambasının bir hayat olduğu gizli korku oyunu. |
| zh-CN | 重燃光明。每一盏路灯都是生命的潜行恐怖游戏。 | 重燃光明。在这款潜行恐怖游戏中，每一盏路灯都是生命。 |
| zh-TW | 重燃光明。每一盞路燈都是生命的潛行恐怖遊戲。 | 重燃光明。在這款潛行恐怖遊戲中，每一盞路燈都是生命。 |

**Full descriptions:**
- en/ru: `store/listing.md` "Full description".
- The other 11: `docs/STORE_KIT.md` "Full listings". STORE_KIT itself flags that these still need
  a native spot-check.
- The in-game text changes in `docs/I18N_TABLE_V2.md` don't affect these texts, except the fr title.
