# Release artifacts (C9 owner-prep)

Status at 2026-09-24. Nothing here is a signed build yet; this file says exactly what exists and
what blocks the rest.

## Done
- **Release keystore generated** with `keytool` (PKCS12, RSA 4096, alias `tls_release`, 10000-day
  validity) at `.signing/tls-release.keystore`. SHA-256 fingerprint:
  `4F:6B:E6:41:5C:26:0B:34:1F:A0:CF:88:46:60:3B:82:64:0F:8B:6B:0D:5F:97:FD:FD:3A:FF:93:DD:89:59:09`.
- Its random password is in `.signing/release.env` (three `GODOT_ANDROID_KEYSTORE_RELEASE_*`
  variables). `.signing/`, `*.keystore` and `*.jks` are gitignored (`git check-ignore` verified).
- `export_presets.cfg` deliberately keeps the release keystore fields EMPTY: the file is committed, so
  putting a password in it would publish it (`tools/qa_sim/release_export_check.py` enforces this).
  Godot reads the env vars above instead.

**Back up `.signing/` outside this machine.** A lost upload key means no updates to the same listing
unless Play App Signing is enabled (recommended: upload this as the *upload* key only).

## Blocked (not attempted)
- **Signed AAB/APK export.** `%APPDATA%\Godot\export_templates\4.7.stable` is empty, so
  `--export-release` cannot run. Installing the official 4.7 templates is a large download from
  godotengine.org; not done without your OK. Gradle build is also enabled in the preset
  (`gradle_build/use_gradle_build=true`) and `android/build/` (the Android build template) is not
  installed; Godot editor: Project > Install Android Build Template.
- **Signature verification and size vs budget:** cannot be reported until an AAB exists. No number is
  claimed here.

## Exact steps once templates exist
1. Editor: Editor > Manage Export Templates > install 4.7.stable; Project > Install Android Build Template.
2. `set -a; . .signing/release.env; set +a`
3. `godot --headless --path . --export-release "Android" build/tls.aab`
4. Verify: `jarsigner -verify -verbose -certs build/tls.aab` and note the size.

## Owner-only (Play Console)
Create the app listing, complete content rating/data-safety, upload the AAB to Internal testing, add
testers, roll out. Needs your Google account; not automatable here. `gh` auth is optional (git push
already works without it). Music generation is excluded by owner decision.
