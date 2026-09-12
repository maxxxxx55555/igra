# Known owner-only items (RELEASE CANDIDATE FINAL, 2026-09-12)

Everything an agent session can do from this repo is done. What's left
needs a GUI, an account, a signing key, a build toolchain, or a human
looking at/playing the game — structurally outside what any headless
session can perform. Full click-by-click steps: `RELEASE_CHECKLIST.md`.

## 1. Android keystore + signed AAB (`RELEASE_CHECKLIST.md` §1, §4)

`keytool -genkey` for a release keystore, install `4.7-stable` export
templates in the Godot editor, **Project → Export → Android** → signed
`.aab`. Cannot be done headlessly — needs the editor GUI and a real
signing identity only the owner should hold.

## 2. Play Console — app creation, IARC, upload (`RELEASE_CHECKLIST.md` §5)

Create the app, answer the IARC content-rating questionnaire (exact
answers already drafted in §5.2d), paste the 13-locale listing from
`store/listing.md`, upload screenshots per
`store/screenshot-plan-detailed.md`, upload the signed `.aab`, start
Open Testing rollout. Needs a live Google account and their console UI.

## 3. Privacy policy URL + support contact (`RELEASE_CHECKLIST.md` §3)

`store/privacy-policy-template.md` has `[contact email / support URL]`
placeholders (EN+RU) by design — filling in a real, monitored contact and
publishing the text at a stable HTTPS URL is an owner identity decision,
not something a session can invent on their behalf.

## 4. One real device playtest / windowed visual check — the highest-leverage item

`docs/HONEST_ASSESSMENT.md` names this plainly: every visual/feel claim in
this repo — banding, touch-target overlap, whether the joystick actually
feels good, the final boss's real difficulty on a first attempt — is
inferred from code and static/headless gates, never observed, because
NO-GODOT (headless-only) policy means no agent session has ever seen this
game render. Concretely, this single playtest also resolves or informs:

- **Autoplay bot's unresolved softlock** (`docs/KNOWN_ISSUES.md`
  "Autoplay bot"): the mechanics engine is proven end-to-end by other
  means (district power-up via real collision+interact, per-district loot
  spawning, balance sim), but a full scripted win was never achieved
  headlessly. A human playing normally sidesteps the bot's own
  boot-harness lifecycle bug entirely and is the authoritative
  winnability check.
- **Texture compression banding risk** (`docs/artifacts/
  apk_size_report.md` §4): whether ETC2/ASTC VRAM compression introduces
  visible banding on this game's flat-gradient, palette-locked art is a
  "look at it" question with no headless substitute. A scoped pilot
  (`tiles`+`surfaces`, 65% of the texture budget, lowest risk) is
  specified and ready to try.
- **Draw-call budget's real number** (`tools/qa_sim/
  perf_check_scene.tscn` self-skips under `--headless`, dummy renderer
  always reports 0 draw calls) — needs one `--windowed` run for a true
  D1/D11 measurement.

## 5. Real AppLovin MAX SDK key — optional, monetization only

`AdService` is wired against the stub; ships fine with no ads if the
owner doesn't want them. Getting a real key needs an AppLovin account
(`RELEASE_CHECKLIST.md` §2) — not blocking a release.

## 6. Version bump at actual upload time (`RELEASE_CHECKLIST.md` §7)

`export_presets.cfg` is still `version/code=1` / `version/name="1.0"` on
purpose — bump it when the build is really about to ship, not before.

---

Everything NOT on this list — code, content, store copy, QA gates,
security hardening, docs — is agent-completed and verified at tip
(see `docs/RELEASE_ARTIFACTS.md` for the full index,
`docs/artifacts/final_gate_report.md` for the gate-by-gate proof).
