# Release artifacts (C9 owner-prep)

Status at 2026-10-10 (rc16 sign-off): the signed release AAB was rebuilt from `5bacfbe` and is verified below; the rc15 record after it is history.

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
