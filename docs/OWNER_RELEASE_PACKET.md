# OWNER_RELEASE_PACKET.md — one copy-paste-ready document

Everything below is either a command to run, a link to click, or text to paste. It's a
condensed, action-ordered view of `RELEASE_CHECKLIST.md` (the full human-readable version,
still the source of truth for anything not literally copy-pasteable) plus what changed in the
2026-09-13 FINAL CONSOLIDATION pass. Refreshed after merging `arena/store-sync` +
`arena/art-final` and attempting the automatable pieces of this list from the repo.

**Distance to release, after this pass's automation attempts: 4 items** — Play Console
login/2FA/upload, one real device playtest, the privacy-policy contact placeholder + Pages
toggle (mostly automated this pass — 2 clicks + 1 text edit left, an identity decision, not a
technical gap), and keystore+AAB export (attempted; deliberately not auto-run — see §(a) —
exact commands given for both the missing piece the owner must run and the missing Android
SDK this machine doesn't have). See §7 for the full attempted/blocked/skipped breakdown.

---

## (a) Android keystore + signed AAB

**Attempted this pass, deliberately not run for you:** JDK 17 is present on this machine
(`keytool` works), so the command below *could* run headlessly — but a release keystore is a
permanent identity: whoever holds the password can sign updates to this listing forever, and
`keytool` has no way to prompt for a password in a non-interactive shell without putting it in
plaintext on the command line (shell history, process list). That's a real secret; it should
only ever exist somewhere you typed it yourself. Run this in your own terminal:

```bash
keytool -genkey -v -keystore release.keystore -alias tlsrelease -keyalg RSA -keysize 2048 -validity 10000
```

(Or run `tools/make_keystore.ps1` in this repo — same command, interactive, on Windows.)
**Keep `release.keystore` outside this git repo**, backed up somewhere durable — losing it
means you can never update this app under the same Play listing again.

Then fill `export_presets.cfg`:
```
keystore/release=<path to release.keystore>
keystore/release_user=tlsrelease
keystore/release_password=<the password you set above>
```

**AAB export — blocked, not attempted:** this machine has no Android SDK (`ANDROID_HOME`
unset, no `sdkmanager`/`adb` on PATH), and `export_presets.cfg` has
`gradle_build/use_gradle_build=true` + `target_sdk=34`, so a signed `.aab` needs the SDK's
build-tools and a Gradle run, not just the Godot editor. Exact install commands (PowerShell):

```powershell
# 1. Download "Command line tools only" from https://developer.android.com/studio#command-tools
#    Unzip so the path ends in ...\cmdline-tools\latest\ (sdkmanager requires that exact folder name)
$env:ANDROID_HOME = "C:\Android"
$env:Path += ";$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools"
sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

Then, one-time in the Godot editor (needs the GUI — this session is headless-only by standing
policy and cannot open it): **Editor → Editor Settings → Export → Android** → set "Android
SDK Path" to `C:\Android`. **Editor → Manage Export Templates** → install the `4.7-stable`
templates. **Project → Install Android Build Template**. After that, either **Project →
Export → Android → Export Project** in the GUI, or headlessly once the keystore + SDK path
are both filled in:

```bash
godot --headless --export-release "Android" build/TLS.aab
```

## (b) Google Play Console — click path + IARC answers

1. https://play.google.com/console → **Create app** → name `THE LAST STREETLIGHT`, default
   language English (US), type Game, Free.
2. **App content** cards, in order:
   - Privacy policy → paste the URL from §(c) below.
   - Ads → **Yes** (AppLovin MAX interstitial + rewarded).
   - App access → **All functionality available without special access**.
   - **Content ratings (IARC)** — answer: category **Game**; violence → yes, mild
     (cartoon/fantasy, non-realistic, creatures not humans); fear/horror → yes (dark
     atmosphere stealth, no jump-scares); **no** to sexual content, gambling, drugs,
     profanity, user-to-user communication, controlled substances. Expect PEGI 12 / ESRB
     Teen-ish back.
   - Target audience → age groups 13-15, 16-17, 18+; **no** to "appeals to children".
   - News app → No. COVID-19 contact tracing → No.
   - Data safety → collects/shares data **No** (switch to **Yes** + declare *Device or other
     IDs* + *App activity*, "for advertising", not shared, only once a real AppLovin key is
     live — ships with none).
   - Government apps → No.
3. **Main store listing** — paste from `store/listing.md` (13/13 locale-parity certified,
   `docs/CERT_STORESYNC.md`), see §(d) for the per-locale paste order.
4. **Release → Testing → Open testing → Create new release** → upload the signed `.aab` from
   §(a) → release notes from `store/changelog.md`'s v1.0 block (EN inside `<en-US>`, RU inside
   `<ru-RU>`) → review → **Start rollout to Open testing**.

**Package name `com.maxsimkasky.laststreetlight` becomes permanent the moment the app is
created** — cannot be changed afterward for this listing.

## (c) Privacy policy — gh-pages page already built and pushed this pass

A ready-to-publish page was generated from `store/privacy-policy-template.md` (EN + RU, with
a language toggle) and pushed to a new `gh-pages` branch on `origin` this pass — **2 owner
clicks + 1 text edit** remain, since publishing your real contact and flipping a repo setting
are both identity/account actions this session can't make for you:

1. Edit `index.html` on the `gh-pages` branch (GitHub's web editor is fine for this) and
   replace both `[REPLACE BEFORE PUBLISHING: contact email / support URL]` /
   `[ЗАПОЛНИТЬ ПЕРЕД ПУБЛИКАЦИЕЙ: ...]` spans with a real, monitored contact.
2. Repo → **Settings → Pages** → Source: **Deploy from a branch** → branch **gh-pages** /
   **(root)** → **Save**.
3. Wait ~1 minute, then the page is live at `https://<your-github-username>.github.io/igra/`
   — paste that URL into the Play Console Data Safety form (§b) and `store/listing.md`'s
   privacy-policy field.

`gh api`/`gh` CLI is installed on this machine but not authenticated (`gh auth status` →
not logged in), so enabling Pages via the API wasn't attempted — logging in as you is an
account action, not something to do on your behalf.

## (d) Per-locale listing — paste order

`store/listing.md` has all 13 locale sections, certified byte-consistent with
`data/i18n/*.json` (`docs/CERT_STORESYNC.md`, `docs/artifacts/store-sync/verify_listing.py`).
Not duplicated here — copying 700+ lines into a second document would just create a second
place for it to go stale. Paste order in Play Console **Store listing → Manage translations**:
en (default listing) first, then the other 12 in whatever order is convenient — each section
in `store/listing.md` is self-contained (title/short/full description) and locale-labeled.

## (e) Screenshot upload order

Per `store/screenshot-plan-detailed.md` §0.5 (current status): **8-slot EN phone gallery**,
in slot order —
1. `store/screenshots/shot01_light_vs_dark_1920x1080_en.png` ✅ delivered
2. `store/screenshots/shot02_district_boundary_1920x1080_en.png` ✅ delivered
3. `shot03_stealth_horror_1920x1080_en.png` ⛔ **needs in-game capture** (recipe §3 Shot 3 — no trailer substitute exists)
4. `shot04_keeper_lore_1920x1080_en.png` ⛔ **needs in-game capture** (recipe §3 Shot 4)
5. `store/screenshots/shot05_restored_forecourt_1920x1080_en.png` ✅ delivered
6. `shot06_mystery_inside_1920x1080_en.png` ⛔ **needs in-game capture** (recipe §3 Shot 6 — `hero_reactor_room` is power_station, not a valid substitute)
7. `store/screenshots/shot07_last_streetlight_1920x1080_en.png` ✅ delivered
8. `store/screenshots/shot08_city_map_1920x1080_en.png` ✅ delivered (RU variant optional, capture needed if wanted)

**3 touch-HUD phone shots** (all delivered): `shot_p1_touch_first_light`,
`shot_p2_touch_crouch`, `shot_p3_touch_interact` (all `_1920x1080_en.png`).

**Cinematic/press stills** (not gallery slots, for feature graphic / press kit / socials):
`store/trailer/hero_{first_restore,grid_cascade,reactor_room}_1920x1080.png`,
`store/trailer/hero_shorts_cut_1080x1920.png` (vertical, for Shorts/TikTok/Reels).

Shots 3, 4, 6 (and the RU shot 8, if wanted) are the only capture gap left — each needs ~5
minutes in-game per `screenshot-plan-detailed.md`'s per-shot recipe (exact district/camera/
power-stage), which is exactly why "one real playtest" (§(g)) and "capture the 3 missing
shots" are naturally the same sitting.

## (f) AppLovin MAX — optional, not blocking

Ships with **no SDK key set** — shows no real ads, collects nothing, safe to ship as-is.
Get a real key at https://dash.applovin.com whenever you want ad revenue; full integration-
review email template in `RELEASE_CHECKLIST.md` §2 if their dashboard asks for one.

## (g) The one playtest — script (12 lines, expected visual per line)

Everything below is inferred from code and proven in headless simulation
(`docs/artifacts/final_gate_report.md`), never actually seen rendered — this playtest is
what turns "should work" into "confirmed." Play on the actual target device/screen size if
possible, not just a desktop window.

1. **New Game → wait 15 seconds standing still.** *Expect:* you stay in the world the whole
   time — this used to kick you back to the main menu at ~8s (root-caused and fixed this
   session's FINAL HARDENING PASS; this line exists specifically to confirm it in real play).
2. **Walk into any district's dark zone.** *Expect:* a district-tinted grade (this pass's new
   per-district bloom/vignette/chroma/grain post-fx, `assets/textures/postfx/presets.json`) —
   subtle, should read as "a bit more cinematic," not distracting or muddy.
3. **Look at a nearby tiled floor/wall closely** (suburbs or warehouses tiles are the best
   test — `docs/artifacts/texture_compression_audit.md`'s VRAM-compressed set). *Expect:* no
   visible color banding/stepping in gradients.
4. **Take a hit, then use a medkit from inventory.** *Expect:* your health bar actually rises
   (this was a real, silent no-op bug this session found and fixed).
5. **Drain your flashlight battery, then use a battery item.** *Expect:* it actually recharges
   (same class of bug as #4, same fix).
6. **Walk/fall off a high ledge on purpose.** *Expect:* after ~3 seconds airborne you're
   placed back on the last solid ground you stood on, not falling forever.
7. **Open Settings → Controls → Touch Tuning** (touch device only). *Expect:* Comfort/
   Default/Responsive presets visibly change joystick feel when swapped.
8. **First touch-device session only: the Touch Calibration overlay.** *Expect:* it appears
   once, walks you through drag/tap/haptic, and never reappears after.
9. **Open the Achievements screen.** *Expect:* each entry shows a small badge icon (this
   pass's new art, `assets/textures/badges/`) — confirm they're legible at their small
   display size, not a blurry smear.
10. **Open the Collection/Codex screen.** *Expect:* each district card shows a moody night
    photo behind its name/progress bar (this pass's new art,
    `assets/textures/cards/`) — note: `docs/KNOWN_ISSUES.md` already flags that 4 of 22
    cards (school/hospital/gas_station/police) share a base photo and won't visually match
    their own district; this is a known, non-blocking art gap, not a bug to report twice.
11. **Reach the final boss and fight normally.** *Expect:* this is the single most important
    line — the autoplay bot clears all 11 districts but has never won the boss's second phase
    even after this session added aim-tracking/battery-management to it
    (`docs/KNOWN_ISSUES.md` "Autoplay bot"). A human needs to confirm the fight is actually
    fair/beatable/fun; the bot's failure may say nothing about a real player's experience.
12. **Save, fully close the app, relaunch, load.** *Expect:* you resume exactly where you
    left off, correct district/power-stage/inventory.

---

## 7. What this pass automated vs. attempted-and-blocked vs. deliberately skipped

| Item | Status |
|---|---|
| Merge `arena/store-sync` + `arena/art-final` | **Done** — scope-checked by subagent, merged, pushed |
| Badge icon / district card art wiring | **Done** — `scripts/ui/achievement_screen.gd`, `scripts/ui/collection_ui.gd` |
| i18n / vaporware / asset legibility re-verification | **Done** — 3 subagents, PASS/PASS/1 non-blocking finding logged |
| Release keystore | **Attempted, deliberately not run** — see §(a); a permanent secret shouldn't be generated non-interactively on your behalf |
| Signed AAB export | **Attempted, blocked** — no Android SDK on this machine; exact install commands given in §(a) |
| Privacy policy hosting | **Done** — gh-pages branch built and pushed; 2 clicks + 1 text edit remain (identity decision) |
| GitHub Pages enable via `gh api` | **Blocked** — `gh` CLI present but not authenticated; logging in as you wasn't attempted (account action) |
| Play Console app creation/upload | **Not attempted** — needs your login + 2FA, always owner-only |
| The one playtest | **Not attempted** — needs eyes and a thumb, always owner-only |
