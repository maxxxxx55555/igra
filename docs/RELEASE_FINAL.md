# RELEASE_FINAL — cross-platform release runbook

Consolidates `docs/store/HUMAN_CHECKLIST.md`, `docs/release_checklist.md`,
`docs/store/play_store.md`, `docs/store/steam.md` into one ordered,
actionable path to first release, plus the platforms that had no runbook
yet (Yandex Games, itch.io) and an AppLovin approval email template. This
file is the entry point; the docs above still hold the full detail for
their own platform.

Everything below needs a GUI, an account, real credentials, a signing key,
or a build toolchain this session doesn't have — none of it can be done by
Claude directly. It's written as steps a human runs in order.

## 0. Before any upload: local build gates

```bash
bash tools/check.sh
```
Must be clean (all mandatory gates + boot-flow). Bump `version/code` and
`version/name` in `export_presets.cfg` (currently `1` / `"1.0"`) per your
own versioning scheme before each new build you upload anywhere.

## 1. Keystore (release, not the committed debug one)

The repo ships a debug keystore (`tls_debug.keystore`) for local iteration
only — never upload a build signed with it. Generate a **separate** release
keystore, store it and its password outside the repo:

```bash
keytool -genkey -v -keystore release.keystore -alias tlsrelease -keyalg RSA -keysize 2048 -validity 10000
```

Paste the resulting path into `export_presets.cfg`'s `keystore/release` /
`keystore/release_user` / `keystore/release_password` before the first
signed build. (`docs/release_checklist.md` has an older keystore command
with a different alias/filename — that one predates this consolidated
doc; use the command above for the actual release signing key.)

## 2. Android — Google Play Console (primary platform)

1. Install the Android Build Template in the Godot editor (Project →
   Install Android Build Template) — required before `gradle_build/
   use_gradle_build=true` (already set) actually works.
2. Complete the AppLovin MAX steps below first if ads are going live in
   this build; otherwise the debug ad stub ships (safe, just shows no
   real ads).
3. Export → **AAB**, not APK (`docs/store/play_store.md` "Build steps").
4. Create the app in Play Console if not already created. Upload to
   **Internal testing** first, then **Closed/Open testing** before
   Production:
   - Play Console → your app → Testing → Open testing → Create new release
   - Upload the signed `.aab`
   - Fill release notes
   - Add testers (an email list or a Google Group) if not already open to
     everyone
   - Review → Start rollout to Open testing
5. Complete the **Data Safety** form and **IARC** rating questionnaire —
   see §6/§7 below for the exact answers this project's own audit expects.
6. Publish icon/screenshots/description from `docs/store/play_store.md`
   ("ASO" section in `docs/release_checklist.md` — already checked off,
   the files exist and are wired in `export_presets.cfg`).

## 3. AppLovin MAX — approval / integration review email template

AppLovin's dashboard onboarding sometimes needs a manual note to their
integration team (e.g. requesting mediation review, or following up on an
app-ads.txt / SDK integration check). Template:

```
Subject: Integration review request — THE LAST STREETLIGHT (Android)

Hi AppLovin team,

Requesting an integration review for our Android title before we move
ad serving from test mode to live.

App name: THE LAST STREETLIGHT
Package name: com.tls.game
Platform: Android (Godot 4.7, AppLovin MAX Godot plugin)
Ad formats integrated: Rewarded (revive / extra battery), Interstitial
  (district-travel, 180s cooldown, never mid-combat)
SDK integration status: Plugin enabled in export_presets.cfg
  (gradle_build/plugins_enabled=AppLovinMAX), dependency added in
  android/build/build.gradle, launchMode set to singleTask per your
  Godot integration guide.
Current state: SDK key not yet set — ads run through a local debug stub
  until a real key is issued.
Store listing: [paste Play Console listing URL once created]
Contact: [your email]

Please let us know if anything else is needed before mediation review /
live traffic approval.

Thanks,
[your name]
```
Fill the bracketed fields before sending. Only send this after the SDK key
and ad unit IDs from `docs/store/HUMAN_CHECKLIST.md` §"AppLovin MAX ads"
are actually in place — reviewing a stub integration wastes their time and
yours.

## 4. Yandex Games

No prior runbook existed for this platform; assets are delivered
(`assets/store/v2/yandex/{yandex_icon_512,yandex_cover_1080x1080,
yandex_banner_1920x600}.png`) but nothing was published yet.

1. Yandex Games requires an **HTML5 export**, not Android/AAB — Godot 4.7
   supports Web export via export templates (not currently configured in
   `export_presets.cfg`; add a `Web` preset via the Godot editor Export
   dialog first). GL Compatibility renderer (already the project's
   renderer) is the right choice for broadest browser support.
2. Create a developer account at https://games.yandex.ru (or the
   international Yandex Games console) and register a new game.
3. Upload the exported HTML5 build as a ZIP per Yandex's packaging spec
   (check their current docs for the exact manifest/entry-point
   requirements — this changes between their SDK versions).
4. Yandex Games has its own SDK for ads/leaderboards/achievements
   (`YandexGamesSDK`) — **not integrated in this project**. Shipping
   without it is fine (plain HTML5 build works), but their platform ads
   and save-to-cloud features won't be available unless someone adds that
   SDK integration as its own task.
5. Fill the store listing using `yandex_icon_512.png` (icon),
   `yandex_cover_1080x1080.png` (cover art), `yandex_banner_1920x600.png`
   (banner) — already generated, just needs uploading in their console.
6. Localize the listing text — Yandex Games' primary audience is
   Russian-speaking; `data/i18n/ru.json` already has complete, real
   (non-fallback) translations for all UI strings, so the RU store copy
   can be a real translation of `docs/store/play_store.md`'s description,
   not a fallback.

## 5. itch.io

No prior runbook existed for this platform either; assets delivered
(`assets/store/v2/itch/{itch_cover_630x500,itch_thumbnail_315x250,
itch_screenshot_wide_{1,2,3}_1280x720}.png`).

1. itch.io accepts almost any build format as a downloadable zip —
   Android APK/AAB, or a desktop (Windows/Linux) export once a desktop
   preset exists in `export_presets.cfg` (none does yet — same gap noted
   in `docs/store/steam.md` §"Build steps"; add one Export preset and it
   covers both itch and Steam).
2. Create a project at https://itch.io/game/new.
3. Upload the build zip(s) — itch supports multiple platform uploads per
   project (e.g. an Android APK alongside a Windows zip) if you want both.
4. Set pricing (this project has no IAP/paywall per the GDD — "no
   paywalled content split" is already the marketing line in
   `docs/store/play_store.md`); "Name your own price" or free are the two
   models that fit that positioning without contradicting the store copy.
5. Upload `itch_cover_630x500.png` as the cover image,
   `itch_thumbnail_315x250.png` as the thumbnail, and the three
   `itch_screenshot_wide_*_1280x720.png` files as screenshots.
6. itch.io has no formal content-rating questionnaire like IARC/Data
   Safety — just a self-reported content-warning field; use the same
   PEGI-16-equivalent reasoning as `docs/store/play_store.md`'s Rating
   note (horror tension, stylized blood/bleed, mass-casualty narrative
   thread).

## 6. Steam

Full detail already in `docs/store/steam.md` — summary:
1. Add a Windows/Linux export preset (none exists yet).
2. Steamworks SDK + app ID + store page setup are entirely account/GUI-
   gated — no Steamworks credentials configured in this repo.
3. `docs/store/steam.md` already has the full description, tags, system
   requirements, and privacy section ready to paste once an app ID exists.

## 7. Privacy policy — placeholder

No hosted policy exists yet; the accurate policy for the CURRENT build is
short because there's genuinely little to disclose:

```
THE LAST STREETLIGHT — Privacy Policy (draft)

This game does not collect personal data. It has no account system and
no analytics SDK. Local-network multiplayer only connects to devices on
the same LAN the player explicitly joins - no data leaves the device
through it.

If AppLovin MAX advertising is enabled in a future build, this policy
will be updated to disclose AppLovin's own data collection (advertising
ID, device information) per their SDK's requirements before that build
ships to any store.

Contact: [your email/support address]
```
Publish this (or a lawyer-reviewed version of it) at a stable URL before
Play Console submission — Play Console requires a live URL, not inline
text. Paste the URL into `docs/store/play_store.md`'s Data Safety section
once it exists (currently marked TODO there).

## 8. Data Safety — exact fields for Play Console's form

Matches the reasoning already in `docs/store/play_store.md`:

| Question | Answer |
|---|---|
| Does your app collect or share user data? | **No** (current build — no accounts, no analytics SDK) |
| Is data encrypted in transit? | N/A — nothing is transmitted off-device except explicit LAN co-op traffic to devices the player connects to directly |
| Can users request data deletion? | N/A — nothing is collected to delete |
| Does your app have an ads SDK? | **Yes** — AppLovin MAX, currently shipping with no SDK key set (falls back to a local debug stub, collects nothing). Once a real key is set, re-answer this section per AppLovin's own disclosure (advertising ID, device info) — **do not submit with "No ads SDK" once the key is live.** |
| Target audience / age | Not designed for children; PEGI 16 equivalent content (see Rating note in `docs/store/play_store.md`) |

## Sized backlog (not release-blocking, worth tracking)

- Web export preset doesn't exist — needed for Yandex Games, blocks §4
  step 1 until added.
- Desktop (Windows/Linux) export preset doesn't exist — needed for Steam
  and optionally itch.io, blocks §5/§6 build steps.
- YandexGamesSDK (ads/leaderboards/cloud saves on that platform) not
  integrated — the HTML5 build works without it, just without those
  platform features.
- GodotSteam (or equivalent) not integrated — in-game achievements work
  standalone regardless; Steam-side achievement sync needs it.
