# Release checklist: Last Streetlight 1.0 (`v8.0.0`)

## v8.0.0 owner steps (2026-10-11), in order

Everything here needs a person, an account, a phone or a purchase. The build is done: `build/tls.aab`, 183,290,597 bytes, signed and verified (`docs/RELEASE_ARTIFACTS.md`, rc17 section). Do the steps top to bottom.

1. **Play Console, internal testing.** Follow `docs/RELEASE_RUNBOOK.md` §3 with `build/tls.aab`. Store listing: the title is `Last Streetlight`; the descriptions of the 13 locales are in `store/listing.md` (`python tools/gen_store_listing_locales.py --check` reads GREEN at rc17); "What's new" is `store/changelog.md`; the player-facing notes are `docs/RELEASE_NOTES.md`.
2. **Screenshots.** The six release frames in `docs/stills/release/` are what the build shows (menu, a district with its lamps on and off, combat, the boss, the shop). They are 960 x 540: inside the 320 to 3840 px range of Play, but under the 1080 px short side that featuring asks for. Either upload them, or capture the same states at full resolution on the phone of step 4.
3. **Icon and feature graphic.** `store/icon-512.png` is 512 x 512 RGB without alpha, and `store/feature-graphic.png` is 1024 x 500 with alpha. Play's form asks for a 32-bit PNG icon and a feature graphic without alpha (JPEG or 24-bit PNG); if the Console refuses either, re-save it in that format **(check at upload)**.
4. **One real-device smoke test** (U1, U5, U6 of `docs/UNVERIFIABLE_HERE.md`): install from the internal-test link on a mid-range phone and run `docs/RELEASE_RUNBOOK.md` §4. Ads: case A applies (no ad offers anywhere): the bundle carries no ad SDK code (0 `Lcom/applovin/` references in its dex, `docs/RELEASE_ARTIFACTS.md`) and `monetization/applovin_sdk_key` is empty. Write down the frame time at the D1 spawn and in the power station, the heat after 20 minutes, the feel of pinch and drag, and how the rc16 effects look.
5. **Privacy policy.** Host `store/privacy-policy-template.md` at a stable URL after replacing its `[contact email / support URL]` placeholders, with Variant A of `docs/RELEASE_RUNBOOK.md` §6 (no ads); paste the URL into the listing.
6. **Content rating and data safety.** Answer the IARC questionnaire with `docs/RELEASE_RUNBOOK.md` §7 (expected PEGI 16; trust IARC) and the data safety form with its §8, Variant A.
7. **Decisions only you can make** before production: Arabic ships with eight Screens cards off the card (`docs/KNOWN_ISSUES.md`, OPEN, rc17 R0) or waits for their fix; E11 second half, D1 `apply_stun`, beauty X4 to X7 (`docs/RESUME_NOTE.md`).
8. **Music and assets (after 1.0 or before, your call).** Music: the 19 tracks and their prompts in `docs/OWNER_HANDOFF.md` §1, made as `docs/MUSIC_RECIPE.md` says, dropped at the paths listed there. Assets: `docs/ASSET_SHOPPING_LIST.md` ("Suggested purchase order"). Then run `bash tools/check.sh --static` and rebuild the AAB with `docs/RELEASE_RUNBOOK.md` §2, bumping `version/code` (`export_presets.cfg:16`).
9. **Production.** Promote the tested build with a staged rollout (`docs/RELEASE_RUNBOOK.md` §3 and §5).
10. **Desktop only, not the phone build:** the title change moved the desktop `user://` folder from `%APPDATA%\Godot\app_userdata\The Last Streetlight` to `...\Last Streetlight` (`docs/KNOWN_ISSUES.md`); the new folder holds files written by the QA runs of this pass. Before a desktop play test, rename it, or copy your old folder over it.

## History: the checklist of 2026-09-20 (superseded by the steps above)


See also: `docs/store/play_store.md` (descriptions/tags/rating notes),
`docs/store/steam.md` (secondary platform), `docs/store/HUMAN_CHECKLIST.md`
(GUI/account/toolchain steps this session can't do — AppLovin ads setup,
Android Build Template install, Play Console access). This file stays the
short top-level punch list; those cover the details.

## Build Format
- [ ] AAB format required for Google Play Store
- [ ] APK for sideloading/testing only

## Target API Level
- [ ] Target SDK: 34 (Android 14)
- [ ] Compile SDK: 34
- [ ] Min SDK: 21 (Android 5.0)
- TARGET_SDK_VERIFY: Update targetSdkVersion in AndroidManifest.xml / gradle build config

## Privacy Policy
- [ ] Placeholder privacy policy text ready
- [ ] URL for in-app privacy policy link configured
- [ ] Update in Google Play Console

## Data Safety
- [ ] Fill Data Safety form in Google Play Console
- [ ] No personal data collected (offline game)
- [ ] No analytics SDKs included

## IARC Rating
- [ ] Complete IARC rating questionnaire
- [ ] Expected: **PEGI 16** (updated from 12+ — see `docs/store/play_store.md`
      "Rating note" and `docs/store/HUMAN_CHECKLIST.md`: sustained horror
      tension, visible blood/bleed status effects, deliberate-mass-casualty
      narrative thread. This is a judgment call flagged for a second human
      look before the actual IARC submission, not a settled fact.)
- [ ] Submit via Google Play Console

## ASO (App Store Optimization)
- [x] Icon: 512x512px PNG — `assets/store/play_icon_512.png`, wired into
      `export_presets.cfg` `launcher_icons/main_192x192`
- [x] Feature Graphic: 1024x500px — `assets/store/feature_graphic_1024x500.png`
- [x] Screenshots: 5, `assets/store/screenshot_0{1-5}.png`
- [x] Description: RU + EN versions — `docs/store/play_store.md`
- [x] Short description: RU + EN — `docs/store/play_store.md`

## Version Naming
- [ ] versionName: "1.0.0"
- [ ] versionCode: 1 (increment per build)

## Testing Tracks
- [ ] Internal testing (up to 100 testers)
- [ ] Closed testing (up to 2000 testers)
- [ ] Production release

## Keystore
```bash
keytool -genkey -v -keystore tls_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias tls_key
```
- [ ] Keystore generated and backed up
- [ ] Keystore password stored securely
- [ ] Key alias and password stored securely
