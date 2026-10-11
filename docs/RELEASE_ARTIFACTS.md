# Release artifacts (C9 owner-prep)

Status at 2026-10-11 (`v8.0.0-final`): the signed release AAB was rebuilt from `e241597` in Session 19 and is verified below (the bundle of `63fda65` packs 31 files that are not the game, an API key among them, CORRECTION_LOG 167, and the first rebuild, of `16abbb0`, 77 store images, CORRECTION_LOG 182: upload neither); the v8.0.0, rc17, rc16 and rc15 records after it are history.

## Done
- **Release keystore generated** with `keytool` (PKCS12, RSA 4096, alias `tls_release`, 10000-day
  validity) at `.signing/tls-release.keystore`. SHA-256 fingerprint:
  `4F:6B:E6:41:5C:26:0B:34:1F:A0:CF:88:46:60:3B:82:64:0F:8B:6B:0D:5F:97:FD:FD:3A:FF:93:DD:89:59:09`.
- Its random password is in `.signing/release.env` (three `GODOT_ANDROID_KEYSTORE_RELEASE_*`
  variables). `.signing/`, `*.keystore` and `*.jks` are gitignored (`git check-ignore` verified).
- `tools/make_keystore.ps1` is the generator of a **debug** keystore (alias `tlsdebug`, the debug password written in `docs/ANDROID_BUILD.md`). It holds no
  release key material (it embeds the debug store password written in `docs/ANDROID_BUILD.md`), the keystore it writes (`tls_debug.keystore`) is gitignored, and it is the only tracked file whose name contains "keystore".
  `release.env` and `*.p12` are gitignored by name as well as through `.signing/` (R8 round 13, `705b2be`).
- `export_presets.cfg` deliberately keeps the release keystore fields EMPTY: the file is committed, so
  putting a password in it would publish it (`tools/qa_sim/release_export_check.py` enforces this).
  Godot reads the env vars above instead.

**Back up `.signing/` outside this machine.** A lost upload key means no updates to the same listing
unless Play App Signing is enabled (recommended: upload this as the *upload* key only).

## Signed AAB (v8.0.0-final, rebuilt 2026-10-11, Session 19)

- **Built:** `build/tls.aab`, **136,500,858 bytes (136.5 MB)**, sha256 `eadfc1d8f4e364d98def48b548252592c379267a73264d0e8aee662fb3a579fb`, built from commit `e241597` with no uncommitted path (launch ledger row 67, `s19_export2_e241597`, EXPORT run 2 of 2 of this pass), `godot --headless --path . --export-release "Android" build/tls.aab` with the `GODOT_ANDROID_KEYSTORE_RELEASE_*` variables of `.signing/release.env`, `# EXIT=0` (`docs/artifacts/rc16/proofs/s19_export2_e241597.out`). As before, the run ended only after `android\build\gradlew.bat --stop` (that command's output is in no proof file), and the export's resave of `default_bus_layout.tres` was reverted.
- **Against the v8.0.0 bundle** (`docs/artifacts/rc16/proofs/s19_aab_diff_v800_e241597.out`): 207 entries fewer, 0 added, 9 with other bytes. Removed: the 31 files of CORRECTION_LOG 167, the imports of the 77 store images of `assets/store/` of CORRECTION_LOG 182, the 98 imported textures of those images and of the 21 of `store/`, and the exported test scene. Changed: the signature files, the pack index, the sparse pack table, the uid cache, the class cache (the same 75 classes in another order) and the two compiled scripts of the P0 fixes (`scripts/ui/hud_3d.gdc`, `scripts/ui/pause_menu.gdc`); `project.binary` is the v8.0.0 one (same size and CRC).
- **App label:** "Last Streetlight" in all 42 entries of its label resource (`docs/artifacts/rc16/proofs/s19_label_e241597.out`).
- **Contents:** 2,684 entries; the base module 26,974,685 bytes compressed (78,462,232 raw, as in v8.0.0), the install-time asset pack 108,572,798 bytes compressed (165,949,235 raw; v8.0.0: 155,283,834 and 213,749,515); no entry under `docs/`, `tools/`, `scenes/tools/` or `scripts/tools/` (`docs/artifacts/rc16/proofs/s19_aab_verify_e241597.out`). `release_export_check.py --aab`: 0 packed files in its classes of what is not the game (tools, tests, docs, the text files of the project root, the store art of `store/` and of `assets/store/` but its launcher icon source and `assets/store/endings/`), PASS (`docs/artifacts/rc16/proofs/s19_aab_post_e241597.out`; the v8.0.0 bundle read 31 with the first classes, `s19_aab_pre_63fda65.out`, and the bundle of `16abbb0` 77 with these, `s19_aab_assetstore_pre_024c7b7.out`); 0 entries of the 21 images of `store/` (`docs/artifacts/rc16/proofs/s19_storeart_post_e241597.out`). The 5 images of `assets/store/endings/` stay: docs/SIZE_BUDGET.md keeps them as planned art of the ending screens, which no script loads yet (the owner decides, `docs/KNOWN_ISSUES.md`). No ad SDK code: 1 dex file, 0 references to `Lcom/applovin/` (`docs/artifacts/rc16/proofs/s19_adsdk_e241597.out`). The keystore path and password occur neither in the export log nor in the verification log of this build nor in any bundle entry outside `META-INF` (`docs/artifacts/rc16/proofs/s19_secretscan_e241597.out`, counts only; the path itself is no secret, it is named above).
- **Signature:** `jar verified.` (exit 0), the signer's SHA-256 equals the upload key (`signer_match=yes`, `docs/artifacts/rc16/proofs/s19_aab_verify_e241597.out`).
- **Earlier bundles of this day, upload neither:** the v8.0.0 bundle of `63fda65` (183,290,613 bytes, sha256 `58a0242a`) packs `opencode.json` with an API key (CORRECTION_LOG 167), kept at `..\_BACKUPS\2026-10-11_15-38\build\tls.aab`; the first rebuild, of `16abbb0` (155,586,711 bytes, sha256 `256c946f`), packs the 77 store images (CORRECTION_LOG 182), kept at `..\_BACKUPS\2026-10-11_17-15\build\tls.aab` (sizes and hashes: `docs/artifacts/rc16/proofs/s19_backups.out`). Its own records are `s19_export_16abbb0.out`, `s19_aab_verify_16abbb0.out` and `s19_aab_diff_16abbb0.out`.

## Signed AAB (v8.0.0, rebuilt 2026-10-11, superseded: packs 31 files that are not the game)

- **Built:** `build/tls.aab`, **183,290,613 bytes (183.3 MB)**, sha256 `58a0242ac1f4a496d898f1a998bfc0588675ae854c8c75e36187b4be1fd1750f`, built from commit `63fda65` with no uncommitted path (launch ledger row 58, `export_v800_63fda65`, EXPORT run 2 of 2), the same command as below, `# EXIT=0` (`docs/artifacts/rc16/proofs/export_v800_63fda65.out`). As before, the run ended after `gradlew --stop`, and the export's resave of `default_bus_layout.tres` was reverted.
- **App label:** "Last Streetlight" in all 42 entries of its label resource (`docs/artifacts/rc16/proofs/r5_label_after_63fda65.out`); the rc17 bundle read "TLS" (`docs/artifacts/rc16/proofs/r5_label_before_c76442b.out`, CORRECTION_LOG 151).
- **Contents:** 2,891 entries; the base module 26,974,685 bytes compressed (78,462,232 raw), the install-time asset pack 155,283,834 bytes compressed (213,749,515 raw); no entry under `docs/`, `tools/`, `scenes/tools/` or `scripts/tools/`; no ad SDK code (0 dex references to `Lcom/applovin/`, `docs/artifacts/rc16/proofs/r5_aab_adsdk_63fda65.out`).
- **Signature:** `jar verified.` (exit 0), the signer's SHA-256 equals the upload key (`signer_match=yes`, `docs/artifacts/rc16/proofs/aab_verify_v800.out`).
- **The rc17 bundle** (183,290,597 bytes) is kept outside the repository at `..\_BACKUPS\2026-10-11_03-05\build\tls.aab`.

## Signed AAB (rc17, rebuilt 2026-10-11)

- **Built:** `build/tls.aab`, **183,290,597 bytes (183.3 MB)**, sha256 `6608a50ac665b006070f193ccc1357775868ee4a577dfdccac48edf24214a0fe`, built from commit `c76442b` with no uncommitted path (launch ledger row 47, `export_rc17_c76442b`, EXPORT run 1 of the 2 of the owner directive of 2026-10-11): the same command and `.signing/release.env` as below, `# EXIT=0` (`docs/artifacts/rc16/proofs/export_rc17_c76442b.out`). As in rc16, the run ended after `gradlew --stop` stopped the Gradle daemon, and the export resaved `default_bus_layout.tres`, which was reverted with `git checkout`. 303 bytes larger than the rc16 bundle. No entry under `docs/`, `tools/`, `scenes/tools/` or `scripts/tools/` (`docs/artifacts/rc16/proofs/aab_verify_rc17.out`).
- **Contents:** 2,891 entries; the base module 26,974,670 bytes compressed (78,461,686 raw), the install-time asset pack 155,283,834 bytes compressed (213,749,515 raw). The base module is far under the 200 MB cap of Play (`docs/RELEASE_RUNBOOK.md`, B6), so no compression pass is needed.
- **No ad SDK code:** the six entries named `applovin` are the GDScript wrapper and the provider script; the one dex file has 0 references to `Lcom/applovin/` (`docs/artifacts/rc16/proofs/r3_aab_adsdk_c76442b.out`), and `monetization/applovin_sdk_key` is empty (`project.godot:266`), so the build shows no ads (case A of `docs/RELEASE_RUNBOOK.md` §4).
- **Signature:** `jar verified.` (exit 0) with the same warnings as rc16; the signer's SHA-256 equals the upload key of the rc15 section (`signer_match=yes`, `docs/artifacts/rc16/proofs/aab_verify_rc17.out`).
- **The rc16 bundle** (183,290,294 bytes) is kept outside the repository at `..\_BACKUPS\2026-10-11_01-17\build\tls.aab` (`backup-first`, RUN_STATE skill log).

## Signed AAB (rc16 sign-off, rebuilt 2026-10-10)

- **Built:** `build/tls.aab`, **183,290,294 bytes (183.3 MB)**, sha256 `428dd6df511b45ec625206a9aa6a1185d458016e9e55c16dcc124482707d263b`, built from commit `5bacfbe` with no uncommitted path (launch ledger row 36, `export_rc16_5bacfbe`, the EXPORT run that the owner's LOOP-BREAK directive added, CORRECTION_LOG 145): `godot --headless --path . --export-release "Android" build/tls.aab` with the three `GODOT_ANDROID_KEYSTORE_RELEASE_*` variables loaded from `.signing/release.env`, `# EXIT=0` (`docs/artifacts/rc16/proofs/export_rc16_5bacfbe.out`). The bundle was written at 19:05:26Z; the run ended only after `gradlew --stop` in `android/build` stopped the Gradle daemon, which held the output pipe of the export open. It is 33,197 bytes larger than the rc15 bundle. It holds no entry under `docs/`, `tools/`, `scenes/tools/` or `scripts/tools/` (`docs/artifacts/rc16/proofs/aab_verify_rc16.out`), so a later commit that touches only documents and proof logs carries the same game (`git diff --name-only 5bacfbe v8.0.0-rc16`).
- **The bus layout:** the export resaved `default_bus_layout.tres` in the working tree at 19:03:11Z, the rewrite of `docs/KNOWN_ISSUES.md:1071` (the default values dropped, among them `room_size`, whose default is 0.8, and the uid text changed); `git checkout -- default_bus_layout.tres` reverted it after the run. The bundle holds the binary conversion `export-19246414aa9fb561ced4b8dce477acec-default_bus_layout.res` (3,047 bytes), which names `room_size` and `Master` (`docs/artifacts/rc16/proofs/aab_verify_rc16.out`).
- **Contents:** 2,891 entries; the base module 26,974,670 bytes compressed (78,461,686 raw), the install-time asset pack `assetPackInstallTime` 155,283,546 bytes compressed (213,748,996 raw) (`docs/artifacts/rc16/proofs/aab_verify_rc16.out`). Play caps the base module's compressed download at 200 MB and sizes asset packs separately **(check the App bundle explorer at upload)**.
- **Signature:** `jarsigner -verify build/tls.aab` prints `jar verified.` (exit 0), with the warnings of a self-signed upload key (no validated certificate chain, self-signed, no timestamp), a note on POSIX file attributes and 2,889 lines of the JarInputStream manifest-order note; `keytool -printcert -jarfile build/tls.aab`: owner `CN=Maxsim Kasky, O=Maxsim Kasky, C=RU`, SHA-256 equal to the upload key of the rc15 section below (`signer_match=yes`, `docs/artifacts/rc16/proofs/aab_verify_rc16.out`).
- **The rc15 bundle** (183,257,097 bytes) is kept outside the repository at `..\_BACKUPS\2026-10-10_22-02\build\tls.aab` (`backup-first`, RUN_STATE skill log).

## Signed AAB (rc15 sign-off, rebuilt 2026-10-02; first built 2026-09-27)

- **Built:** `build/tls.aab`, **183,257,097 bytes (183.3 MB)**, built from commit `8ad0b93` (183,257,435 before the verifier round's code changes on the same day, 183,140,397 at the rc14 sign-off on 2026-10-01, 183,064,789 on 2026-09-27); the export holds no `docs/`, `tools/` or tool-scene files, so a later commit that touches only those leaves it valid (`git diff --name-only 8ad0b93 <tag>`), `godot --headless --path . --export-release
  "Android" build/tls.aab` with the three `GODOT_ANDROID_KEYSTORE_RELEASE_*` variables loaded from
  `.signing/release.env`. Gradle build, arm64-v8a only. `build/` and `*.aab` are gitignored.
- **Contents:** base module 27.0 MB compressed (78.5 MB raw; native libs 24.5 MB, dex 1.8 MB, res 0.7 MB at the first
  build); the game data ships in the install-time asset pack `assetPackInstallTime` (155.3 MB compressed, 213.7 MB
  raw), 2882 entries in all. Play caps the base module's compressed download at 200 MB and sizes asset packs separately
  **(check the App bundle explorer at upload)**.
- **Signature:** `jarsigner -verify build/tls.aab` prints `jar verified.`, with the usual upload-key
  warnings (self-signed, no timestamp) and a JarInputStream manifest-order note that AGP-built
  bundles commonly carry. `keytool -printcert -jarfile build/tls.aab`: owner `CN=Maxsim Kasky,
  O=Maxsim Kasky, C=RU`, SHA-256 `4F:6B:E6:41:5C:26:0B:34:1F:A0:CF:88:46:60:3B:82:64:0F:8B:6B:0D:5F:97:FD:FD:3A:FF:93:DD:89:59:09`,
  identical to `keytool -list -v` on `.signing/tls-release.keystore` (alias `tls_release`).
- **Toolchain installed for it (owner-approved downloads):** Godot 4.7.stable export templates in
  `%APPDATA%\Godot\export_templates\4.7.stable`; the Android build template extracted into
  `android/build/` (gitignored, `android/.build_version` = `4.7.stable`); Gradle 8.11.1 plus the Android
  Gradle Plugin 8.6.1 dependencies; Android SDK Platform 36 and Build-Tools 36.1.0 (sdkmanager, under the
  SDK license already accepted on this machine). `android/build/gradle.properties` sets
  `android.builder.sdkDownload=false`, so Gradle cannot fetch the NDK on its own; none was installed.
- **Ads:** the preset ships with the AppLovin plugin off (RELEASE_RUNBOOK B3 option A: no key, no ads;
  release builds hide every reward offer). `docs/store/HUMAN_CHECKLIST.md` step 4 turns it back on.
- **Not verified here:** install and run on a device (RELEASE_RUNBOOK §4). `bundletool` is not on this
  machine, so the per-device download size is read in Play Console.

## Rebuild
1. `set -a; . .signing/release.env; set +a`
2. `godot --headless --path . --export-release "Android" build/tls.aab`
3. Verify: `jarsigner -verify build/tls.aab` and `keytool -printcert -jarfile build/tls.aab` (SHA-256 as above).
4. Bump `version/code` in `export_presets.cfg` before every upload after the first.

## Owner-only (Play Console)
Create the app listing, complete content rating/data-safety, upload the AAB to Internal testing, add
testers, roll out. Needs your Google account; not automatable here. `gh` auth is optional (git push
already works without it). Music generation is excluded by owner decision.
