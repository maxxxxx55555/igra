# Release runbook: signed AAB → Google Play

Ordered owner steps, copy-paste where possible. It reuses the texts that already exist instead of
repeating them:
- `docs/RELEASE_ARTIFACTS.md`: keystore, export commands
- `store/listing.md`: EN/RU listing masters
- `docs/STORE_KIT.md`: the other 11 locales
- `store/privacy-policy-template.md`: EN + RU policy
- `docs/store/HUMAN_CHECKLIST.md`: on-device verification

Anything Google may have changed since 2026-09-26 is marked **(check in Play Console)**.

## 0. Blockers to clear before the first export

| # | Blocker | Why | Do this |
|---|---|---|---|
| B1 | ETC2/ASTC texture import | **Done rc14:** `import_etc2_astc=true` in `project.godot`; the textures import BPTC and ASTC | — |
| B2 | Export format | **Done rc14:** `gradle_build/export_format=1` (AAB), `export_path="build/tls.aab"` | — |
| B3 | Optional bonus | The game contains no ads. The Android bonus uses the local Wi-Fi transport. | Check the final manifest and exercise the bonus on a phone (§4). |
| B4 | Templates and build tools | **Done rc14 on this machine:** 4.7.stable export templates, the Android build template in `android/build/` (gitignored), Gradle 8.11.1, SDK Platform 36 and Build-Tools 36.1.0 (`docs/RELEASE_ARTIFACTS.md`) | On another machine: Editor → Manage Export Templates → 4.7.stable; Project → Install Android Build Template; point Editor Settings → Export → Android at JDK 17 and the SDK |
| B5 | Target SDK | Play enforces a minimum target API **(check in Play Console)**. The preset's `min_sdk=29` and `target_sdk=34` (`export_presets.cfg:29-30`) are not read by this export, so Godot's default applies: the v8.0.0 bundle's manifest reads min 24 and target 36 (current Godot master: `editor/export/android_sdk_manager.h`) | Leave empty unless the Console asks for more. `docs/store/play_store.md` "min_sdk=29 / target_sdk=34 / com.tls.game" is stale: the preset's package is `com.maxsimkasky.laststreetlight` |
| B6 | Size | Play caps the base module's compressed download at 200 MB **(check in Play Console)** | rc14 AAB: 183.1 MB file, base module about 27 MB, game data in an install-time asset pack (155.1 MB compressed). Read the final numbers in the App bundle explorer |
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

1. **Create app:** name *Last Streetlight*, default language English (United States), **Game**,
   **Free**. Accept the declarations.
2. **Dashboard → Set up your app:**
   - **Privacy policy:** the URL from §6.
   - **App access:** "All functionality is available without special access".
   - **Contains ads:** No.
   - **Content rating:** §7.
   - **Target audience:** 16–17 and 18+. Not designed for children; skip the Families program.
   - **News app:** No. **Data safety:** §8.
   - **Government app:** No. **Financial features:** none. **Health:** none.
   - **Advertising ID:** No.
3. **Main store listing:**
   - Title, short description (≤ 80) and full description (≤ 4000) from §9.
   - App icon: `store/icon-512.png` (512²).
   - Feature graphic: `store/feature-graphic.png`, alpha dropped (`docs/STORE_SUBMISSION.md` §2).
   - Phone screenshots: the six frames of `docs/stills/ultimate/` that `docs/STORE_SUBMISSION.md` §2 lists, alpha dropped (`docs/STORE_SUBMISSION.md` §2).
   - Category: **Game → Action**. Tags per `docs/store/play_store.md`. A contact email is required.
4. **Store listing → Manage translations:** add ru, es, de, fr, it, pt-BR, tr, ja, ko, zh-CN, zh-TW
   and ar with the §9 texts.
5. **Test and release → Setup → App signing:** keep Google-generated app signing (§1).
6. **Internal testing:**
   - Create a new release, upload `build/tls.aab`, name it "1.0 (3)" (the bundle of Session 26 carries `version/code` 3).
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

## 4. First launch on a phone: the one checklist (single source)

Every other document points here (`docs/release_checklist.md` step 4, `docs/RESUME_NOTE.md`, `docs/STORE_SUBMISSION.md`, `docs/UNVERIFIABLE_HERE.md` U1). Run it on a mid-range phone with the bundle of the pass
(`build/tls.aab`, `version/code` 3, bytes and sha256 in `docs/RELEASE_ARTIFACTS.md`) installed from the internal-test link, before every promotion. Write what you see in the U-row named at the step: a number or a
sentence is an answer, "fine" is not. A step that fails goes to `docs/KNOWN_ISSUES.md` with the phone's model and Android version.

**A. Does it run**

1. First boot: no crash, the loading screen reads "Last Streetlight", and the language picker works.
2. New Game → tutorial → first generator runs; the district lights up.
3. Save, force-close, relaunch, **Continue**: same district, same inventory.
4. Open a bonus on cellular. Join Wi-Fi without internet, observe the button update, then disconnect and verify the reason beside the disabled button. Repeat on the paused death screen.
5. Switch language through all 13 locales; titles and HUD fit, and the Sprint and Stealth buttons hold their longest label (pt_BR "FURTIVIDADE": U13).
6. Suspend and resume mid-district; the daily challenge card still shows.

**B. The numbers**

7. The frame time at the D1 spawn and in the power station (any frame-time overlay) and the tier the first start picked (Settings): does it hold 30 FPS or more? (U1) Does the quality manager step the tier down and
   back up in the 20 minutes of step 8? (U23)
8. 20 minutes of play: FPS stays ≥ 30 and the device doesn't overheat (feeds `docs/PERF_PASS.md` §2); the battery drop and the heat over 30 minutes, and the frame rate of the last minutes against the first (U19).

**C. The feel and the look** (one sentence each)

9. Touch: the two-finger pinch zoom (0.8 to 1.35) and the drag to a quick slot (U5); the touch cluster, the Button Size slider at 1.5 and the first-run calibration dialog under a thumb (U13).
10. Look: the eight states of U6 (the warm lamps, the grain, the ember vignette on a hit, the Ultra sprint blur); the near-black facades on an OLED at the lowest and the highest brightness (U18); the menu art in a dark
    room and in a bright one (U12); the edges at Medium (2x MSAA) and at Ultra (4x) (U21); the 16 px body text of the HUD, the inventory and the settings (U15).
11. Export Save and Import Save through the phone's Downloads folder: start a Hardcore run, Export Save, die, Import Save from the menu (U10).
12. Sound, with headphones: the reverb of a street, an alley and an interior (U3), and a fight (U8: does the music distort?).

## 5. After release

Tag the release commit. Keep the `.signing/` backups. Bump `version/code` for every upload. Answer
reviews using `store/review-responses.md`.

## 6. Privacy policy (host at a stable URL, then paste the URL in §3.2)

Publish the [English and Russian release policy](../store/privacy-policy-template.md) at https://maxxxxx55555.github.io/igra/ before submission.

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

Data collected or shared: **No**. Contains ads: **No**. The local connection check sends zero requests. Local deletion instructions for each platform are in the published policy.

## 9. Store listing per locale (polish applied)

**Titles (≤ 30).** Use the game's own localized title (`menu_title`), or the English brand
everywhere if you prefer one global name:
- en: Last Streetlight
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
