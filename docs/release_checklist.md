# Release checklist: Last Streetlight 1.0 (`v9.0.0-ultimate`, tagged in Session 23 on the sign-off commit `chore: aaa-ultimate sign-off`)

## v9.0.0-ultimate owner steps (2026-10-14, Session 23; written in Session 19, re-read in 20 to 23), in order

Everything here needs a person, an account, a phone or a purchase. The build is done: `build/tls.aab` is the second signed bundle of Session 23, built from the final runtime and verified (`docs/RELEASE_ARTIFACTS.md`, the v9.0.0-ultimate sections give its bytes, its sha256 and the checks it passed); `version/code` is 2, because Play refuses a code it has seen and the v8 bundle carries 1. Do the steps top to bottom, and upload no earlier bundle: **the first bundle of Session 23 (`1414899`, 136,607,113 bytes) is superseded and must not be uploaded** (its export filter left out the two scripts the integrity guard preloads and the 15 skill icons, CORRECTION_LOG 242 and 243); the bundle of `v8.0.0-shipping` (`5749aa8`, 136,508,347 bytes, code 1) has the same icon gap, no ending or streak sting (245) and none of the pass: if it sits in your internal-testing track, replace that release with this one; the older ones (the one of `63fda65` packs `opencode.json` with an API key, the one of `16abbb0` 77 store images, and the earlier bundles of Sessions 21 and 22 named in their sections of `docs/RELEASE_ARTIFACTS.md`) are superseded too. The consolidated store pack (the bundle's facts, the exact image specs, the privacy policy in English and Russian, the content-rating and data-safety answers, the Console declarations) is `docs/STORE_SUBMISSION.md`; steps 1 to 6 below point into it. The fixes of Session 23 (`docs/CORRECTION_LOG.md`, rows 210 to 250, and `docs/RUN_STATE.md`, Session 23) are in this bundle.

0. **First: rotate the secrets that sit in the history of the public repository** (`docs/CLEANUP_LEDGER.md` section 8 is the list: CORRECTION_LOG 167, 197 and 247). **(a) The API key in `opencode.json`** (found in Session 19, CORRECTION_LOG 167; swept in Session 20, CORRECTION_LOG 197). What it is: `opencode.json:9`, `provider.omniroute.options.apiKey`, which held until `6ac7ac7` an `sk-` key of 35 characters for OmniRoute, the local AI router at `http://localhost:20128/v1`. Where it is exposed: the file is tracked in the public repository, and the key was added by the one commit `5553c2e` (so it is in the history of every clone, `docs/artifacts/rc16/proofs/s19_repo_public.out`), and the bundle of `63fda65`, which you must not upload, packed it; it is the only secret in the repository and its history (`docs/artifacts/rc16/proofs/s20_secret_scan.out`). Rotate it: (a) in OmniRoute's own dashboard create a new API key and delete the old one; if that router was ever reachable beyond this machine (a tunnel, a LAN bind, a port forward), rotate the upstream provider keys it holds as well; (b) keep the new key out of git: set `OMNIROUTE_API_KEY` in your user environment: line 9 of `opencode.json` has read `"apiKey": "{env:OMNIROUTE_API_KEY}"` since `6ac7ac7` (opencode substitutes `{env:NAME}` in its config: **check opencode's config docs**), so the file needs no change; (c) the old key stays in git history for good, which is why the rotation and not a rewrite of history is the fix. The release keystore's password lives only in the ignored `.signing/release.env` and occurs in no log or bundle that was scanned (`docs/artifacts/rc16/proofs/s19_secretscan_e241597.out`, `docs/artifacts/rc16/proofs/s20_secretscan_files.out`). **(b) The debug keystore password** that `tools/make_keystore.ps1` held until `6ac7ac7` (8 characters, alias `tlsdebug`, in the history since `7066810`): if a debug keystore made with it is on a machine, run the script again (it draws a fresh password now and prints it) and set the new one in the Godot export dialog; no release is signed with it. **(c) The AppLovin MAX key** is not set: when you set it, it goes in your environment, never in a tracked file (`tools/qa_sim/secret_scan.py` fails the commit that does). **(d) The release keystore** and its passwords stay in `.signing/` (gitignored): keep a copy off this machine, a lost keystore cannot be recovered from the repository (with Play App Signing it is only the upload key, `docs/RELEASE_RUNBOOK.md` section 1). A rotation, not a rewrite of the history, is the fix for (a) and (b) (the old values stay in git for good); the rewrite is owner row K-1 (step 7).
1. **Play Console, internal testing.** Follow `docs/STORE_SUBMISSION.md` §7 (it points into `docs/RELEASE_RUNBOOK.md` §3) with `build/tls.aab`; check its sha256 against `docs/RELEASE_ARTIFACTS.md` first. Its `version/code` is 2, so it uploads over the v8 bundle of code 1 (replace that release in the track, do not add a second one). Store listing: the title is `Last Streetlight`; the descriptions of the 13 locales are in `store/listing.md` (`python tools/gen_store_listing_locales.py --check` is GREEN in `v800_gates_8663aec.out`, CORRECTION_LOG 152); "What's new" is `store/changelog.md`; the player-facing notes are `docs/RELEASE_NOTES.md`.
2. **Screenshots.** The six release frames in `docs/stills/shipping/` are what the build shows (menu, a district with its lamps on and off, combat, the boss, the shop). They are PNG with an alpha channel (960 x 527 each, 397 to 823 KiB; every alpha is 255): inside the 320 to 3840 px range of Play, but under the 1080 px short side that featuring asks for, and Play takes screenshots as JPEG or 24-bit PNG without alpha **(check at upload)**, so re-save them without alpha. Either upload them so, or capture the same states at full resolution on the phone of step 4.
3. **Icon and feature graphic.** `store/icon-512.png` is 512 x 512 RGB without alpha, and `store/feature-graphic.png` is 1024 x 500 with alpha. Play's form asks for a 32-bit PNG icon and a feature graphic without alpha (JPEG or 24-bit PNG); if the Console refuses either, re-save it in that format **(check at upload)**.
4. **One real-device smoke test: the one checklist is `docs/RELEASE_RUNBOOK.md` section 4** (install, boot, new game, save and continue, ads, the 13 languages, suspend and resume, then the numbers and the feel questions): install from the internal-test link on a mid-range phone and run it, and write what you see in U1, U3, U5, U6, U8, U10, U12, U13, U15, U18, U19, U21 and U23 of `docs/UNVERIFIABLE_HERE.md` (U13 is the HUD). Ads: case A applies (no ad offers anywhere): the bundle carries no ad SDK code (0 `Lcom/applovin/` references in its dex, `docs/RELEASE_ARTIFACTS.md`) and `monetization/applovin_sdk_key` is empty.
5. **Privacy policy.** Host `store/privacy-policy-template.md` at a stable URL after replacing its `[contact email / support URL]` placeholders, with Variant A of `docs/RELEASE_RUNBOOK.md` §6 (no ads); paste the URL into the listing.
6. **Content rating and data safety.** Answer the IARC questionnaire with `docs/RELEASE_RUNBOOK.md` §7 (expected PEGI 16; trust IARC) and the data safety form with its §8, Variant A.
7. **Decisions only you can make** before production: **O-1, the frame cost of High**: the windowed perf gate reads RED at the final head (a p95 of 35.00 and 38.63 ms against 33, on the dev iGPU at full HD, the High tier, 2x MSAA; `docs/PERF_PASS.md` section 0b), and nothing was changed to turn it green; ship High as it is and let the quality manager and dynamic resolution step a phone down, or lighten High (the 4x MSAA read 5.5 to 8.9 ms of the frame in the ablations, the 2x was not measured), after the numbers of step 4 (U1, U21). **K-1, the history rewrite**: the repository's history is 874 MB, `docs/CLEANUP_LEDGER.md` section 9 has the commands, they need your approval logged in `docs/CORRECTION_LOG.md` and every clone and fork re-cloned. **L-1, the Russian comments**: 1,656 lines of the scripts (`docs/TZ_DECISIONS.md`, LANG-23), say so if the sweep is wanted. **ST-1, the 0.14 s freeze at a district change** (`docs/STREAMING_TEST.md`). **The 5 endings images the bundle keeps** (`assets/store/endings/`, CORRECTION_LOG 182): keep them or drop them from the export filter before the next export. **B-1, F-1 and S-1**: the AAA reference frames, a person's first five minutes and the moods of the district pairs (U14, U16, U20). Arabic ships with eight Screens cards off the card (`docs/KNOWN_ISSUES.md`, OPEN, rc17 R0) or waits for their fix; D1 `apply_stun`, beauty X4 to X7 (`docs/RESUME_NOTE.md`); the findings still open (`docs/KNOWN_ISSUES.md`, OPEN: CORRECTION_LOG 170 and 171 accepted, 173 and 177 the owner's, 177 before an ad SDK key is set). Closed since Session 19: 168, 169, 172, 174, 178 to 180, B5 (205) and the E11 second half (it is row 169).
8. **Music and assets (after 1.0 or before, your call).** Music: the 19 tracks and their prompts in `docs/OWNER_HANDOFF.md` §1, made as `docs/MUSIC_RECIPE.md` says, dropped at the paths listed there. Assets: `docs/ASSET_SHOPPING_LIST.md` ("Suggested purchase order"). Then run `bash tools/check.sh --static` and rebuild the AAB with `docs/RELEASE_RUNBOOK.md` §2, bumping `version/code` (`export_presets.cfg:16`, it is 2 in the bundle of Session 23).
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
