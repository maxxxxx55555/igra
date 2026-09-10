# RELEASE_CHECKLIST.md — human-only steps to ship

## 0. TL;DR — the irreducible human minimum

Everything code / content / store-side is **done by agents** (GOLD MASTER,
`origin/main`). What's left needs a GUI, an account, a signing key, or a
build toolchain and cannot be done from an agent session:

1. **Keystore + build.** `keytool -genkey … -alias tlsrelease` (§1), put
   the path/passwords in `export_presets.cfg`, install `4.7-stable`
   export templates + the Android build template in the Godot editor
   (§4), then **Project → Export → Android** → signed `.aab`.
2. **Privacy policy URL.** Put a real support email in
   `store/privacy-policy-template.md` (or `docs/PRIVACY_POLICY.md`),
   publish the text at any stable URL (§3).
3. **Play Console.** Create the app, answer the IARC content-rating
   questionnaire (exact answers in §5.2d), paste the listing from
   `store/listing.md` (13 locales — the 11 non-EN/RU ones are transcreated
   from in-game strings; a native read before publish is recommended, not
   required), the adaptive icon is in `store/icon-adaptive/`, art from
   `store/`, screenshots per `store/screenshots-plan.md`; upload the
   `.aab`, start rollout to Open Testing (§5). `store/review-responses.md`
   has paste-ready replies for the first reviews.

Optional / not blocking: real AppLovin SDK key (§2 — ships fine on the
no-ad debug stub without it), extra platforms (§6), eyes-on playtest
(`docs/HANDOFF.md` "HUMAN PLAYTEST SCRIPT v2"), version bump at upload
time (§7), one `perf_check_scene.tscn --windowed` run for the real
draw-call number. Full gap list: `docs/GAP_TO_IDEAL.md`.

### Already done by agents (do NOT redo)

| Area | State | Ref |
|---|---|---|
| Code / gameplay / autoloads | GOLD MASTER v2; headless suite green ×2 | `<gm2-hash>`, `2101311`, `f3bd1e3` |
| `tools/qa_sim/headless_suite` verification gate | 12 autoloads · 11 districts + loot · 5 endings · save/load+lang · combat · 1061 keys ×13 at runtime · soak | `f3bd1e3` |
| District-load / pickup engine errors | fixed — rebuild deferred out of the physics signal (0 "Function blocked" errors) | `2101311` |
| i18n — 13 locales, every user-facing string | 1061 keys × 13, 0 MISSING at runtime | `a712dd1`, prior |
| Content — 11/11 districts, 88 lore notes | packed, wired, translated | prior waves |
| Store listing — **13 locales** | title/tagline from shipped i18n; short≤80/full/bullets/tags transcreated; EN+RU master untouched | `3babbff` |
| Android adaptive icon | `store/icon-adaptive/` fg+bg 1080, safe-zone + extrema verified, wired in `export_presets.cfg` | `3babbff` |
| Review-response playbook | `store/review-responses.md` — 5 classes × EN+RU | `3babbff` |
| Trailer / press kit — 5 key-art masters, edit plan, reviewer email | `store/trailer/`, `store/press-kit.md` | `6fea56e` |
| Merged `arena/*` branches cleaned up | `01a08729`, `01a08b05` deleted; 2 held per owner | prior pass |

`docs/RELEASE_FINAL.md` still has platform-specific detail (Yandex Games,
itch.io, Steam) not repeated here.

Run this before anything else, every time:
```bash
bash tools/check.sh --static && GODOT=/path/to/godot tools/qa_sim/headless_suite
```
Both must be green. If not, stop and fix that first — don't sign or
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

Do these in order. Play Console won't let you roll out until every
**Dashboard → "Set up your app"** task has a green check.

1. https://play.google.com/console → **Create app**. Name
   `THE LAST STREETLIGHT`, default language **English (United States)**,
   type **Game**, **Free**, accept the declarations.
2. **App content** (left nav → Policy → App content). Complete each card:
   a. **Privacy policy** → paste the URL from step 3.
   b. **Ads** → **Yes, my app contains ads** (AppLovin MAX interstitial +
      rewarded).
   c. **App access** → **All functionality is available without special
      access** (no login, no gated areas).
   d. **Content ratings** → start the IARC questionnaire. Answers for this
      game: category **Game**; **violence** — *cartoon/fantasy, non-
      realistic, creatures not humans* → yes, mild; **fear/horror** — yes
      (dark atmosphere, jump-scare-free stealth); **no** to sexual
      content, gambling, drugs, profanity, user-to-user communication
      (LAN co-op is direct-IP, not a social feature), controlled
      substances. Submit → it returns PEGI 12 / ESRB Teen-ish. Save.
   e. **Target audience and content** → age groups **13–15, 16–17, 18+**
      (not designed for children); **no** to "appeals to children".
   f. **News app** → No. **COVID-19 contact tracing** → No.
      **Data safety** → fill per §8 of `docs/RELEASE_FINAL.md`:
      collects/shares user data **No** (if the AppLovin key from step 2 is
      live, switch to **Yes** and declare *Device or other IDs* +
      *App activity*, "for advertising", not shared, per AppLovin's
      published Data Safety guidance); encrypted in transit **N/A**;
      deletion request **N/A**.
   g. **Government apps** → No.
3. **Store presence → Main store listing** — paste from `store/`:
   - **App name** / **Short description** / **Full description** from
     `store/listing.md` (EN now; add the RU localization under
     *Store listing → Manage translations* using the RU block).
   - **App icon** → `store/icon-512.png` (512×512 PNG, ≤1 MB).
   - **Feature graphic** → `store/feature-graphic.png` (1024×500 PNG).
   - **Phone screenshots** → at least 2, 16:9 or 9:16, each 1080–3840 px
     on the long edge. Capture the 8 shots in `store/screenshots-plan.md`
     (it names the exact district + camera + power stage for each). A
     couple can come straight from **Trailer Mode** (Settings → Game →
     Trailer Mode hides the HUD).
   - **Tablet screenshots** — optional; reuse the phone set if short on
     time.
   - **Promo / key art** (not required by Play, used everywhere else) →
     `store/trailer/` has 5 ship-ready masters (3 wow-moment stills
     1920×1080, 1 vertical Shorts frame 1080×1920, 1 press-kit header
     1600×900). `store/trailer.md` is the trailer edit plan (60–90 s cut
     + 0:30 vertical), `store/trailer/README.md` is per-file use-cases,
     `store/press-kit.md` is the reviewer fact sheet + outreach email.
4. **Release → Testing → Open testing → Create new release**:
   - **App bundles** → upload the signed `.aab` from step 4 (the export
     step, above).
   - **Release name** — e.g. `1.0 (1)`.
   - **Release notes** → paste `store/changelog.md`'s v1.0 EN block
     inside `<en-US>…</en-US>` (and RU inside `<ru-RU>…</ru-RU>`).
   - **Countries / regions** → add all, or your target set.
   - **Review release** → resolve any warnings → **Start rollout to
     Open testing**.

**Important**: the Android package name (`com.maxsimkasky.laststreetlight`)
becomes permanent the moment the app is created — Play Console does not
allow changing it afterward for the same listing.

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
