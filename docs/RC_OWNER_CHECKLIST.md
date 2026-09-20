# Release Checklist: THE LAST STREETLIGHT — RC owner-only ship steps

**Purpose**: ordered, evidence-cited owner steps to take the RC from green gates to a
live Open Testing rollout on Google Play, each with a 30-second smoke test and a
failure block. Docs-only publication artifact; it executes nothing.
**Created**: 2026-09-20 (QA lead, RC verification pack; game at `d736c37`)
**Feature**: `docs/GAME_AUDIT.md` (2026-09-20 fix pass being released),
`docs/QA_MATRIX.md` (verification matrix this checklist gates into)

**Marker semantics**: `[x]` = the owner performed the step AND its smoke test passed.
Never mark a step done from this document's text alone.

**Evidence rules (read once)**:
- Every command, URL, button label, and file path below is copied from an existing
  repo doc — the citing doc is named in each step's **Evidence** line. Nothing is
  invented from memory; anything not present in repo docs is explicitly marked
  **NEEDS-OWNER-CONFIRMATION** instead of guessed.
- Commit hashes quoted *inside* older repo docs (`54f1b31`, etc.) were recorded against
  the pre-squash history and do not resolve in this clone; the live tree is `d736c37`
  (only commit present). File/line and command claims were re-verified against
  `d736c37` 2026-09-20.
- Sibling files: root `RELEASE_CHECKLIST.md` remains the full human-readable source of
  truth (this file condenses only the four owner steps + gates + playtest);
  `docs/release_checklist.md` is an older short punch list (kept untouched).
- Related matrices: `docs/QA_MATRIX.md` §H (export) and §I–N (RC extension).

Work the steps **in order**. After EACH step, run its 30-second smoke test before
continuing. If a smoke test fails, go to that step's "WHAT TO DO IF THIS FAILS" block —
do not proceed to the next step on a red step.

---

## STEP 0 — Pre-flight gates (green or stop)

- [ ] CHK001 Repo is on the exact commit being released (`d736c37` or a descendant
      that was re-gated).
- [ ] CHK002 Pre-flight command passes:

```bash
bash tools/check.sh --static && GODOT=/path/to/godot tools/qa_sim/headless_suite
```

**Evidence**: root `RELEASE_CHECKLIST.md` "Run this before anything else, every time"
(verbatim command + "Both must be green. If not, stop and fix that first — don't sign
or upload a build off a red gate."); `docs/HOW_TO_TEST.md` §1–2 (static gate output is
"все строки `OK` и `Всё зелёное`", exit code 0); gate scene list `tools/check.sh:208-225`.

**30-second smoke test**: re-run `bash tools/check.sh --static`; the tail shows
`Всё зелёное` and the shell exit code is 0 (per `docs/HOW_TO_TEST.md` §1's stated
expected result).

**WHAT TO DO IF THIS FAILS**: any red gate prints its last 15 log lines per
`docs/HOW_TO_TEST.md` §2 — read those, fix the named cause first, and do NOT sign or
upload anything off a red gate (root `RELEASE_CHECKLIST.md` pre-flight note, verbatim).
If the engine portion hangs, run each `res://scenes/tools/*_check_scene.tscn`
individually with the Godot binary instead (workaround recorded in
`.claude/NEXT_SESSION_PROMPT.md`).

---

## STEP 1 — Release keystore (identity — do once, protect forever)

- [ ] CHK010 Generate the release keystore **in your own terminal, outside this git
      repo**:

```bash
keytool -genkey -v -keystore release.keystore -alias tlsrelease -keyalg RSA -keysize 2048 -validity 10000
```

(On Windows this repo's `tools/make_keystore.ps1` runs the same `keytool` command
interactively.)

- [ ] CHK011 Back up `release.keystore` somewhere durable outside the repo (losing it =
      can never update the app under the same Play listing again).
- [ ] CHK012 Fill the three release fields in `export_presets.cfg` (currently all
      empty, verified `d736c37`):

```
keystore/release=<path to release.keystore>
keystore/release_user=tlsrelease
keystore/release_password=<the password you set above>
```

- [ ] CHK013 Confirm the debug keystore is NOT what ships in the RC
      (`keystore/debug=res://tls_debug.keystore`, user/password `tlsdebug`; the repo
      rule: "Debug-подпись не используется в релиз-кандидате").

**Evidence**: root `RELEASE_CHECKLIST.md` §1 (command, alias `tlsrelease`, the three
`keystore/release*` fields, keep-outside-repo + backup warning, `make_keystore.ps1`
alternative); `docs/ANDROID_BUILD.md` Шаг 1 (same `keytool` command + alias; debug
keystore facts); `docs/OWNER_RELEASE_PACKET.md` §(a) (why no agent runs this for you:
a release keystore is a permanent identity and must never be generated
non-interactively); `docs/ANDROID_BUILD.md` Шаг 4 checklist (debug-signature rule);
`export_presets.cfg:22-27` (current debug/release field state).

**30-second smoke test**: `ls -la release.keystore` at your chosen outside-repo path
shows a non-empty file created just now, and
`grep -n "keystore/release" export_presets.cfg` shows all three fields non-empty and
pointing at that path.

**WHAT TO DO IF THIS FAILS**: `keytool` not found → install JDK 17+ (requirement
named in `docs/ANDROID_BUILD.md` Требования). Wrong password while filling the preset
→ retype it where you generated the key — the keystore password is a real secret and
is the owner's to know, per `docs/OWNER_RELEASE_PACKET.md` §(a). Debug keystore filled
into the release fields by mistake → blank them and repeat CHK012 with the release
file; the debug signature is acceptable for sideload testing only
(`docs/release_checklist.md` Build Format section).

---

## STEP 2 — Export templates + Android SDK (one-time toolchain)

- [ ] CHK020 Godot editor menu → **Editor → Manage Export Templates** → Download and
      Install, matching exact engine version `4.7-stable`.
- [ ] CHK021 Godot editor menu → **Project → Install Android Build Template** (required
      because `gradle_build/use_gradle_build=true` is already set in
      `export_presets.cfg:36`).
- [ ] CHK022 Godot editor → **Editor → Editor Settings → Export → Android** → set
      "Android SDK Path" (owner-machine path; the doc-recorded example is
      `C:\Android`).
- [ ] CHK023 Android SDK pieces present (doc-recorded PowerShell block,
      `docs/OWNER_RELEASE_PACKET.md` §(a)):

```powershell
$env:ANDROID_HOME = "C:\Android"
$env:Path += ";$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:ANDROID_HOME\platform-tools"
sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
```

(Command-line tools download: `https://developer.android.com/studio#command-tools`,
folder must end in `...\cmdline-tools\latest\`.)

**Evidence**: root `RELEASE_CHECKLIST.md` §4 (template install items + menu labels +
`4.7-stable` match); `docs/HUMAN_CHECKLIST.md` steps 3–4 (build-template requirement;
verify the AppLovin plugin checkbox in the Export dialog if ads are ever enabled);
`docs/OWNER_RELEASE_PACKET.md` §(a) (SDK path, `sdkmanager` block, target SDK 34
context).

**30-second smoke test**: **Project → Export...** → select the **Android** preset →
the export dialog opens with an **Export Project** button available (button label per
`docs/ANDROID_BUILD.md` Шаг 2 item 3 and root `RELEASE_CHECKLIST.md` §4).

**WHAT TO DO IF THIS FAILS**: no templates → repeat CHK020 with exact `4.7-stable` (a
mismatched template version is the classic failure; version named in root
`RELEASE_CHECKLIST.md` §4). Export reports missing Android support → the build
template and/or SDK path from CHK021/CHK022 is absent — `docs/HUMAN_CHECKLIST.md`
step 3 states exports fail without the build template. **NEEDS-OWNER-CONFIRMATION**:
the owner machine's actual SDK install path (docs only record the `C:\Android`
example).

---

## STEP 3 — Signed AAB

- [ ] CHK030 Editor → **Project → Export... → Android** → **Export Project** to produce
      the signed AAB — or headlessly (keystore + SDK path already filled):

```bash
godot --headless --export-release "Android" build/TLS.aab
```

- [ ] CHK031 Version is the intended first-upload value at upload time:
      `export_presets.cfg` currently ships placeholder `version/code=1` /
      `version/name="1.0"` (verified `d736c37`, lines 15-16); the doc convention is
      versionCode 1 (increment per build) / versionName "1.0.0" — bump/not-bump per the
      doc rule "at the time of your actual first upload, not before".
- [ ] CHK032 AAB (not APK) is the artifact going to Play; APK stays for
      sideload/testing only.
- [ ] CHK033 Pre-release statics on this exact commit are green (`docs/QA_MATRIX.md`
      QA-EX-04: `bash tools/check.sh --static` + engine gates; report pasted where the
      release flow expects it).

**Evidence**: `docs/OWNER_RELEASE_PACKET.md` §(a) (verbatim headless AAB command +
"produces a signed `.aab` once step 1's keystore is filled in" from root
`RELEASE_CHECKLIST.md` §4); root `RELEASE_CHECKLIST.md` §7 (bump at upload time);
`docs/release_checklist.md` Build Format (AAB required, APK sideload-only) + Version
Naming ("1.0.0" / 1, increment per build); `docs/ANDROID_BUILD.md` Шаг 2–3 (menu
labels; APK headless variant for reference);
`export_presets.cfg:15-17,36` (version fields, gradle flag, package
`com.maxsimkasky.laststreetlight`).

**30-second smoke test**: `ls -la build/` shows a fresh non-empty `TLS.aab` (file
existence and freshness only — signature trust was established in STEP 1/2).

**WHAT TO DO IF THIS FAILS**: export errors about signing → STEP 1 fields, especially
that the release keystore (not debug) is configured (`docs/ANDROID_BUILD.md` Шаг 4
rule). Gradle/build-template errors → STEP 2 CHK021/CHK022 and
`docs/HUMAN_CHECKLIST.md` steps 3–4. Preset produces `.apk` instead of `.aab` →
re-check the Android preset's export format in **Project → Export...** per
`docs/release_checklist.md` Build Format; the doc-recorded success path is the AAB
command above.
**NEEDS-OWNER-CONFIRMATION**: owner naming beyond `build/TLS.aab` (docs record only
the `TLS.aab`/`TLS_release.apk` examples).

---

## STEP 4 — Privacy policy: contact email + hosted URL

- [ ] CHK040 Pick the policy text: full draft in `docs/PRIVACY_POLICY.md` or the
      shorter fill-in template `store/privacy-policy-template.md` (root
      `RELEASE_CHECKLIST.md` §3 says either is fine; the Data Safety answers in STEP 5
      match both).
- [ ] CHK041 Replace the contact placeholder — literally the line
      `Contact: [your email/support address]` in `docs/PRIVACY_POLICY.md`, and on the
      gh-pages page the two spans `[REPLACE BEFORE PUBLISHING: contact email / support
      URL]` / `[ЗАПОЛНИТЬ ПЕРЕД ПУБЛИКАЦИЕЙ: ...]` — with a real, monitored address
      (identity action; verified still un-filled on the remote `gh-pages` branch's
      `index.html` as of 2026-09-20).
- [ ] CHK042 Publish at any stable URL you control. The pre-built route: GitHub repo →
      **Settings → Pages** → Source: **Deploy from a branch** → branch **gh-pages** /
      **(root)** → **Save** → wait ~1 minute → the page is live at
      `https://<your-github-username>.github.io/igra/`. (Alternatives per root
      `RELEASE_CHECKLIST.md` §3: a personal site, even a public Gist — "Play Console
      just needs a working link, not a specific host.")
- [ ] CHK043 If AppLovin's SDK key has gone live before today, update the AppLovin
      paragraph to match what actually ships (`docs/PRIVACY_POLICY.md` "Before
      publishing" item 2). If no key is live, the text is accurate as-is.
- [ ] CHK044 Record the final URL where the docs expect it: Play Console Data Safety
      form (STEP 5) and `docs/store/play_store.md`'s Data Safety section (currently
      marked TODO there).

**Evidence**: `docs/PRIVACY_POLICY.md` (full text + "Before publishing" 1–3 verbatim);
`docs/OWNER_RELEASE_PACKET.md` §(c) (gh-pages page already built and pushed; "2 owner
clicks + 1 text edit"; Settings → Pages click labels verbatim; the
`https://<your-github-username>.github.io/igra/` URL pattern); root
`RELEASE_CHECKLIST.md` §3 (stable-URL rule + Gist alternative + paste-into
`play_store.md` TODO note).

**30-second smoke test**: open `https://<your-github-username>.github.io/igra/` (or
your chosen URL) — the page renders AND the contact line shows your real address, not a
bracketed placeholder.

**WHAT TO DO IF THIS FAILS**: 404 at the Pages URL → the Pages toggle wasn't saved
(repo → **Settings → Pages** is owner-only because it is an account/identity action —
`docs/OWNER_RELEASE_PACKET.md` §(c)); wait the ~1 minute propagation stated there and
reload. You cannot flip repo settings on this GitHub account → use the documented
alternative (any stable URL you control). **NEEDS-OWNER-CONFIRMATION**: the actual
contact email itself — it is an identity decision no repo doc can supply, and the
placeholders stay bracketed until you type it.

---

## STEP 5 — Play Console: create app, upload AAB, start rollout

Do these in order — "Play Console won't let you roll out until every Dashboard →
'Set up your app' task has a green check" (root `RELEASE_CHECKLIST.md` §5, verbatim).
Warning (verbatim, same section): the package name
`com.maxsimkasky.laststreetlight` becomes permanent the moment the app is created and
cannot be changed afterward for the same listing.

- [ ] CHK050 `https://play.google.com/console` → **Create app** → name
      `THE LAST STREETLIGHT`, default language **English (United States)**, type
      **Game**, **Free**, accept the declarations.
- [ ] CHK051 **App content** cards (left nav → Policy → App content), in order:
      a. **Privacy policy** → paste the STEP 4 URL.
      b. **Ads** → **Yes, my app contains ads** (AppLovin MAX interstitial + rewarded).
      c. **App access** → **All functionality is available without special access**.
      d. **Content ratings** → IARC questionnaire, exact doc answers: category
         **Game**; violence — yes, mild (cartoon/fantasy, non-realistic, creatures not
         humans); fear/horror — yes (dark atmosphere stealth, no jump-scares); **no**
         to sexual content, gambling, drugs, profanity, user-to-user communication,
         controlled substances.
      e. **Target audience and content** → age groups **13–15, 16–17, 18+**; **no** to
         "appeals to children".
      f. **News app** → No. **COVID-19 contact tracing** → No. **Government apps** →
         No.
      g. **Data safety** → collects/shares user data **No** (switch to **Yes** and
         declare *Device or other IDs* + *App activity*, "for advertising", not shared,
         only if the AppLovin key from §2 of root `RELEASE_CHECKLIST.md` is live);
         encrypted in transit **N/A**; deletion request **N/A**.
- [ ] CHK052 IARC result accepted — **NEEDS-OWNER-CONFIRMATION** on the expected
      rating: root `RELEASE_CHECKLIST.md` §5.2d and `docs/OWNER_RELEASE_PACKET.md`
      §(b) say to expect "PEGI 12 / ESRB Teen-ish", while `docs/release_checklist.md`
      records "**PEGI 16** (updated from 12+ … a judgment call flagged for a second
      human look before the actual IARC submission, not a settled fact)". The answers
      in CHK051d are identical in both; only the expected outcome differs — accept the
      rating IARC actually returns and log the decision.
- [ ] CHK053 **Store presence → Main store listing** → paste from `store/listing.md`
      (13 locale sections; EN default first, then the 12 via **Store listing →
      Manage translations** — paste order per `docs/OWNER_RELEASE_PACKET.md` §(d)).
- [ ] CHK054 Art: **App icon** `store/icon-512.png` (512×512 PNG, ≤1 MB);
      **Feature graphic** `store/feature-graphic.png` (1024×500 PNG).
- [ ] CHK055 **Phone screenshots** (at least 2, 16:9 or 9:16, 1080–3840 px long edge):
      use the 5 ✅-delivered EN shots + 3 touch-HUD shots now, and capture the 3
      still-missing in-game shots (3, 4, 6 — status table `docs/OWNER_RELEASE_PACKET.md`
      §(e)) during STEP 6 with the per-shot recipe in
      `store/screenshot-plan-detailed.md`; **Trailer Mode** (Settings → Game → Trailer
      Mode hides the HUD) is the doc-recommended capture aid.
- [ ] CHK056 **Release → Testing → Open testing → Create new release** → **App
      bundles** → upload the signed `.aab` from STEP 3 → **Release name** e.g.
      `1.0 (1)` → **Release notes** paste `store/changelog.md`'s v1.0 block (EN inside
      `<en-US>…</en-US>`, RU inside `<ru-RU>…</ru-RU>`) → **Countries / regions** →
      **Review release** → resolve warnings → **Start rollout to Open testing**.
- [ ] CHK057 Optional, non-blocking, doc-listed: real AppLovin SDK key (root
      `RELEASE_CHECKLIST.md` §2 — "ships fine on the no-ad debug stub without it";
      account at `https://dash.applovin.com`); extra platforms (§6); version bump
      timing (§7); one windowed `perf_check_scene.tscn` run.

**Evidence**: root `RELEASE_CHECKLIST.md` §5.1–5.5 (URL, every button label and card
answer above verbatim, rollout-path labels, "Set up your app" green-check rule,
package-permanence warning, release-notes paste markers, screenshot specs incl.
Trailer Mode note); `docs/OWNER_RELEASE_PACKET.md` §(b)/(d)/(e) (same click path,
paste order, screenshot delivery status); `store/changelog.md` v1.0 block (exists,
verified 2026-09-20); `docs/release_checklist.md` IARC section (PEGI-16 dissent);
`docs/HANDOFF.md` owner-TODO §3 (same path summarized).

**30-second smoke test**: after CHK051–CHK053, open **Dashboard → "Set up your app"** —
every completed card shows its green check (the doc's own readiness criterion); after
CHK056, re-open **Release → Testing → Open testing** and confirm the release lists the
uploaded bundle and release name you entered. The exact post-rollout status label Play
displays next is **NEEDS-OWNER-CONFIRMATION** (no repo doc quotes it — do not compare
against remembered wording, just record what you see).

**WHAT TO DO IF THIS FAILS**: a card refuses to save → it is usually the Data Safety /
privacy-URL pair — re-check STEP 4's URL is live (its smoke test) and matches CHK051g's
No-collect answer for the current no-ad-key build. Upload rejected → AAB (STEP 3) not
signed with the release keystore from STEP 1 (debug signature is the common cause —
`docs/ANDROID_BUILD.md` Шаг 4 rule). Listing text looks wrong in a locale → the
`docs/QA_MATRIX.md` QA-ST rows cover render/char-limit checks; the 11 transcreated
sections were native-QA'd (`docs/NATIVE_QA_FINDINGS.md`), so a rendering fault is a
Console-side paste/render issue, not a copy defect — repaste from `store/listing.md`.
Rollout button blocked → return to the Dashboard checklist; the doc rule is that every
"Set up your app" task must be green before rollout.

---

## STEP 6 — Eyes-on playtest (the single highest-leverage remaining action)

**You play; nothing else substitutes.** Both cited scripts stress that every feel/
visual claim in this repo was inferred from code, never observed — "NO-GODOT policy
means no agent session has ever seen this game run" (root `RELEASE_CHECKLIST.md` §0,
"Not actually optional" note; same statement in `docs/HANDOFF.md` GOLD MASTER v5
"Read this first").

- [ ] CHK060 Run the primary script: `docs/HANDOFF.md` **"HUMAN PLAYTEST SCRIPT v2"**
      (14 lines, ≈25–35 min, boot → districts → endings → soak; its own closing line:
      "If 1–14 pass: RC v2 confirmed").
- [ ] CHK061 Run the delta script for this year's hardening fixes:
      `docs/OWNER_RELEASE_PACKET.md` §(g) (12 lines) — especially line 11 (fight the
      final boss; the packet's verdict: bot now wins it for real, "a human still needs
      to play this fight … the most likely line to surface a real problem") and line 1
      (idle-15s no-kick regression).
- [ ] CHK062 While in there, capture the 3 missing store screenshots (shots 3, 4, 6 —
      recipes in `store/screenshot-plan-detailed.md`; OWNER_RELEASE_PACKET §(g) notes
      the playtest and the capture "are naturally the same sitting") and knock out the
      open owner-eyes rows from `docs/QA_MATRIX.md` (QA-AU-01/04/05, QA-AC-04/06,
      QA-EX-02/03, QA-JU-02, QA-GP-04, QA-IK-02, QA-ST-02/03 — the RC-extension rows
      that only a human can mark).
- [ ] CHK063 Then the **30-second smoke test** below; then fill `docs/QA_MATRIX.md`
      row outcomes and `docs/KNOWN_ISSUES.md` with anything new.

**Doc-recorded launch command** (owner-machine path — **NEEDS-OWNER-CONFIRMATION**;
any Godot 4.7 build is equivalent per `docs/HOW_TO_TEST.md` §2–3):

```
C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64_console.exe --path .
```

**30-second smoke test**: after the run, boot once more — main menu appears (line 1 of
the HANDOFF script), and **Continue** resumes the save from the end of your session
(condensed from OWNER_RELEASE_PACKET §(g) line 12: "you resume exactly where you left
off, correct district/power-stage/inventory"). Zero `SCRIPT ERROR` lines in the
console during that boot.

**WHAT TO DO IF THIS FAILS**: capture the log tail with the documented method
(`godot --path . 2>&1 | tail -40`, `docs/HOW_TO_TEST.md` §6) and grep it for the three
signals that doc names — `SCRIPT ERROR`, `Invalid call`, `Cannot open file` — then file
the finding in `docs/KNOWN_ISSUES.md` with the line that failed (HANDOFF script line
number) and do NOT widen the rollout; a playtest red keeps the release at its current
scope until a fix is gated green through STEP 0 again.

---

## NEEDS-OWNER-CONFIRMATION register (nothing here was invented — confirm or supply)

| # | Item | Why it can't come from repo docs |
|---|---|---|
| 1 | Expected IARC rating: PEGI 12/Teen-ish vs PEGI 16 | Two repo docs disagree (root `RELEASE_CHECKLIST.md` §5.2d vs `docs/release_checklist.md` IARC section); answers identical, outcome call is the owner's |
| 2 | Contact email for the privacy policy | Identity decision; placeholders verified still empty 2026-09-20 |
| 3 | Godot 4.7 binary path on the owner machine | Docs record the TLS_Build path only |
| 4 | Android SDK install path | Docs record only the `C:\Android` example |
| 5 | Post-rollout status label in Play Console | No repo doc quotes the label |
| 6 | Artifact filename beyond `build/TLS.aab` | Only example names exist in docs |

## Source index (every step's claims trace to these)

- Root `RELEASE_CHECKLIST.md` — full owner manual: §0 TL;DR/pre-flight, §1 keystore,
  §2 AppLovin, §3 privacy policy, §4 templates, §5 Play Console, §7 version bump, §8
  save export/import.
- `docs/OWNER_RELEASE_PACKET.md` — §(a) keystore+AAB incl. SDK block, §(b) Console
  click path + IARC answers, §(c) gh-pages route, §(d) paste order, §(e) screenshot
  status, §(g) 12-line playtest script.
- `docs/HANDOFF.md` — HUMAN PLAYTEST SCRIPT v2 (14 lines) + owner-TODO section.
- `docs/ANDROID_BUILD.md` — keystore Шаг 1, export labels Шаг 2–4, debug-signature
  rule.
- `docs/release_checklist.md` — punch list: Build Format, Target API, Privacy Policy,
  Data Safety, IARC (PEGI-16 note), ASO, Version Naming, Testing Tracks, keystore
  command.
- `docs/store/HUMAN_CHECKLIST.md` — build-template + plugin GUI steps; AppLovin.
- `docs/PRIVACY_POLICY.md` + `store/privacy-policy-template.md` — policy texts.
- `docs/store/play_store.md` — EN/RU listing source + Data-safety TODO.
- `store/listing.md`, `store/changelog.md`, `store/screenshot-plan-detailed.md`,
  `store/icon-adaptive/`, `store/screenshots/` — paste-ready artifacts.
- `docs/HOW_TO_TEST.md` — gate expectations and log-reading method.
- `docs/SECURITY_THREAT_MODEL.md` + `docs/QA_MATRIX.md` §J — save-integrity context.
- `.claude/NEXT_SESSION_PROMPT.md` — engine-hang workaround for STEP 0.
