# Known owner-only items (RELEASE CANDIDATE FINAL v2, 2026-09-13)

Everything an agent session can do from this repo is done. What's left
needs a GUI, an account, a signing key, a build toolchain, or a human
looking at/playing the game — structurally outside what any headless
session can perform. Full click-by-click steps: `RELEASE_CHECKLIST.md`.
**Exactly 4 items, all owner-only, zero technical** (the FINAL HARDENING
PASS closed the technical blockers this list carried before — see
`PLAN.md`'s RC FINAL v2 section for what changed).

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
game render. What this single playtest now resolves, updated after the
FINAL HARDENING PASS:

- **Autoplay bot: the boot-lifecycle bug is fixed** (root cause found and
  fixed, not just worked around — `docs/KNOWN_ISSUES.md` "Autoplay bot").
  The district spine now clears headlessly (11/11) in the clear majority
  of runs, a first for this project. What remains unwon is the final
  boss's P2 phase specifically — the bot's simple approach-and-attack
  loop can't out-position a boss that may kite, which is a question of
  *bot* sophistication, not *game* winnability. A human playing normally
  is unaffected by any of this and is still the authoritative check on
  whether the boss fight itself is fun/fair/beatable.
- **Texture compression banding**: 74 specific files (`tiles`, `surfaces`,
  3 `environment`) were actually converted to VRAM Compressed and
  individually PSNR-verified ≥40dB this pass (`docs/artifacts/
  texture_compression_audit.md`) — PSNR is an objective proxy for pixel
  difference, not a substitute for eyes on the actual render. Look at a
  few district floors/walls (especially `tiles`) for banding before
  trusting this specific change in production.
- **Draw-call budget's real number** (`tools/qa_sim/
  perf_check_scene.tscn` self-skips under `--headless`, dummy renderer
  always reports 0 draw calls) — needs one `--windowed` run for a true
  D1/D11 measurement.
- **Touch feel**: `touch_probe_scene.tscn` proves the joystick/haptic/
  interact-pulse code paths have no accidental latency and hit their
  timing budgets in simulation (`docs/KNOWN_ISSUES.md` "Touch feel") —
  it cannot prove a real thumb on real glass feels good.

---

Optional, genuinely not blocking a release (not counted in the 4 above):

- **Real AppLovin MAX SDK key** — `AdService` is wired against the stub;
  ships fine with no ads if the owner doesn't want them
  (`RELEASE_CHECKLIST.md` §2).
- **Version bump at actual upload time** (`RELEASE_CHECKLIST.md` §7) —
  `export_presets.cfg` is still `version/code=1` on purpose, bump it when
  the build is really about to ship.

---

Everything NOT on this list — code, content, store copy, QA gates,
security hardening, docs — is agent-completed and verified at tip
(see `docs/RELEASE_ARTIFACTS.md` for the full index,
`docs/artifacts/final_gate_report.md` for the gate-by-gate proof).
