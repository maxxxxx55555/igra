# RELEASE_CHECKLIST.md — human-only steps to ship

Everything code/content-side that could be automated is done (see
`PLAN.md` for the full status table and `docs/HANDOFF.md` for the
narrative summary). Every item below needs a GUI, an account, a signing
key, or a build toolchain — none of it can be done from this session.
This file supersedes older overlapping docs on a few points that changed
since they were written (noted inline); `docs/RELEASE_FINAL.md` still has
useful platform-specific detail (Yandex Games, itch.io, Steam) not
repeated here.

Run this before anything else, every time:
```bash
bash tools/check.sh
```
Must be fully green. If it isn't, stop and fix that first — don't sign or
upload a build off a red gate.

---

## 1. Android keystore (release signing)

The repo only ships a **debug** keystore (`tls_debug.keystore`) — safe for
local testing, never for a real upload. Generate the real one and keep it
**outside this git repo**, backed up somewhere durable (losing it means
you can never update the app on Play Store again under the same listing):

```bash
keytool -genkey -v -keystore release.keystore -alias tlsrelease -keyalg RSA -keysize 2048 -validity 10000
```

Then open `export_presets.cfg` and fill in:
```
keystore/release=<path to release.keystore>
keystore/release_user=tlsrelease
keystore/release_password=<the password you set above>
```
(`tools/make_keystore.ps1` in this repo can run the same `keytool`
command for you on Windows if you'd rather not type it by hand.)

## 2. AppLovin MAX — get a real SDK key

Currently shipping with **no SDK key set** — the app runs a local debug
stub that shows no real ads and collects nothing. This is safe to ship
as-is, but no ad revenue happens until you do this:

1. Sign in / create an account at https://dash.applovin.com.
2. Create the app (Android, package name **`com.maxsimkasky.laststreetlight`**
   — note: `docs/RELEASE_FINAL.md`'s email template still shows the old
   placeholder `com.tls.game`; that was changed in `export_presets.cfg`
   after that doc was written — use the real one above, not what's in
   that template).
3. Once AppLovin issues a key, set it wherever `AdService` reads its SDK
   key from (see `docs/store/HUMAN_CHECKLIST.md` "AppLovin MAX ads" for
   the exact file/field — it was already located and documented there).
4. If their dashboard needs a manual integration review, send this,
   filling the brackets:

```
Subject: Integration review request — THE LAST STREETLIGHT (Android)

App name: THE LAST STREETLIGHT
Package name: com.maxsimkasky.laststreetlight
Platform: Android (Godot 4.7, AppLovin MAX Godot plugin)
Ad formats integrated: Rewarded (revive / extra battery), Interstitial
  (district-travel, 180s cooldown, never mid-combat)
SDK integration status: Plugin enabled (gradle_build/plugins_enabled=
  AppLovinMAX), dependency added in android/build/build.gradle.
Current state: SDK key not yet set - ads run through a local debug stub
  until a real key is issued.
Store listing: [paste Play Console listing URL once created]
Contact: [your email]
```

## 3. Publish the privacy policy

`docs/PRIVACY_POLICY.md` has the full drafted text, ready to publish —
it just isn't hosted anywhere yet. (`store/privacy-policy-template.md`,
added with the store kit in PR #8, is a shorter fill-in-the-brackets
version of the same policy — use whichever you prefer; the Data Safety
answers in step 5 match both.)

1. Fill in the `[your email/support address]` placeholder in that file
   with a real, monitored address.
2. Publish the text at any stable URL you control (a GitHub Pages page,
   a personal site, even a public Gist — Play Console just needs a
   working link, not a specific host).
3. Paste that URL into the Data Safety form in step 5 below, and into
   `docs/store/play_store.md`'s Data Safety section (currently marked
   TODO there).

## 4. Install export templates (one-time, in the Godot editor)

`export_presets.cfg` now has **Android, Web, and Windows Desktop**
presets configured (Web/Windows were added this session — they didn't
exist before). None of them can actually produce a build until the
matching export templates are installed:

- Godot editor menu → **Editor → Manage Export Templates** → Download
  and Install (must match the exact engine version this project uses,
  `4.7-stable`).
- For Android specifically, also: **Project → Install Android Build
  Template** (needed for `gradle_build/use_gradle_build=true`, already
  set).

After that, test each export once locally before trusting it for a real
upload:
- **Project → Export... → Android** → Export Project → produces a
  signed `.aab` once step 1's keystore is filled in.
- **Project → Export... → Web** → Export Project → produces
  `build/web/index.html` + supporting files; open `index.html` through a
  local web server (not `file://`) to sanity-check it runs.
- **Project → Export... → Windows Desktop** → Export Project → produces
  `build/windows/TheLastStreetlight.exe`; run it directly to confirm it
  launches.

## 5. Google Play Console — first upload (primary platform)

1. https://play.google.com/console → **Create app**.
2. Fill the app details form (name, default language, app/game, free).
3. **Data Safety** section — answer exactly (per this project's own
   privacy audit, see `docs/RELEASE_FINAL.md` §8 for the reasoning):
   - Does your app collect or share user data? **No**
   - Is data encrypted in transit? **N/A** (nothing transmitted off-device
     except explicit LAN co-op traffic to devices the player connects to
     directly)
   - Can users request data deletion? **N/A**
   - Does your app have an ads SDK? **Yes** — AppLovin MAX. If you've
     completed step 2 above and a real key is live, answer this
     section per AppLovin's own disclosure (advertising ID, device
     info) instead of "No ads SDK."
   - Target audience: not designed for children; PEGI 16-equivalent
     content.
4. **App content** → **Privacy policy** → paste the URL from step 3.
5. **Testing → Open testing → Create new release**:
   - Upload the signed `.aab` from step 4.
   - Write release notes.
   - Add testers (an email list, or make it public) if the testing
     track isn't already open.
   - Review page → **Start rollout to Open testing**.
6. Store listing (icon, screenshots, description) — the finished kit is
   in `store/` (added in PR #8): `listing.md` (title / short / full
   description, EN + RU), `changelog.md` (v1.0 release notes, EN + RU),
   `feature-graphic.png` (1024×500, ready to upload), `icon-512.png`
   (512×512), `screenshots-plan.md` (the 8 shots to capture, with the
   in-game location for each — you still need to take them). Older copy
   notes in `docs/store/play_store.md` are superseded by `store/` where
   they differ.

**Important**: the Android package name (`com.maxsimkasky.laststreetlight`)
becomes permanent the moment you complete this step — Play Console does
not allow changing it afterward for the same app listing.

## 6. Optional additional platforms

Full step-by-step for these is in `docs/RELEASE_FINAL.md` §4-6 (Yandex
Games, itch.io, Steam) — the one correction to that doc: it says Web and
Windows export presets "don't exist yet" — they now do, in
`export_presets.cfg` (added this session), so you can skip straight to
the export/upload steps in those sections once step 4 above is done.

## 7. Version bump

`export_presets.cfg` is still at the placeholder `version/code=1` /
`version/name="1.0"`. Bump both per whatever versioning scheme you want
to use, at the time of your actual first upload — not before, so the
version number reflects when it was really shipped.
