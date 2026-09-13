# Known owner-only items (FINAL CONSOLIDATION pass, 2026-09-13)

Everything an agent session can do from this repo is done. What's left
needs a GUI, an account, a signing key, a build toolchain, or a human
looking at/playing the game — structurally outside what any headless
session can perform. One copy-paste-ready document with everything below:
`docs/OWNER_RELEASE_PACKET.md` (full click-by-click detail still in
`RELEASE_CHECKLIST.md`). **Still 4 items, all owner-only, zero technical**
— this pass automated as much of each as honestly could be, see the
"attempted this pass" note on each.

## 1. Android keystore + signed AAB (`docs/OWNER_RELEASE_PACKET.md` §a)

**Attempted this pass**: JDK 17 is present (`keytool` works), but a
release keystore is a permanent secret with no non-interactive-safe way
to set its password — deliberately not auto-generated (see the packet's
§a reasoning). The Android SDK isn't installed on this machine at all
(`ANDROID_HOME` unset, no `sdkmanager`/`adb`), so a headless AAB export
was not possible either — exact install commands for both pieces are in
the packet, including the one-line headless export command to run once
they're both in place. Needs the owner to hold a signing identity only
they should hold.

## 2. Play Console — app creation, IARC, upload (`docs/OWNER_RELEASE_PACKET.md` §b)

Create the app, answer the IARC content-rating questionnaire (exact
answers already drafted), paste the 13-locale listing from
`store/listing.md` (13/13 parity certified, `docs/CERT_STORESYNC.md`),
upload screenshots per the packet's §e (8 gallery + 3 touch, 5 of 8
gallery shots still need in-game capture), upload the signed `.aab`,
start Open Testing rollout. Needs a live Google account and their
console UI — not attempted.

## 3. Privacy policy URL + support contact (`docs/OWNER_RELEASE_PACKET.md` §c)

**Attempted this pass**: generated a gh-pages-ready page (EN+RU, language
toggle) from `store/privacy-policy-template.md` and pushed it to a new
`gh-pages` branch on `origin`. What's left is 2 clicks (repo Settings →
Pages → enable) + replacing the contact-email placeholder with a real
one — an owner identity decision the page itself flags in-place, not
something a session can invent. `gh` CLI is installed but not
authenticated, so enabling Pages via `gh api` wasn't attempted (logging
in as the owner is an account action).

## 4. One real device playtest / windowed visual check — the highest-leverage item

A concrete 12-line script with the expected visual per line is now written out in
`docs/OWNER_RELEASE_PACKET.md` §g — covering every item below plus this pass's new
per-district post-fx look, the new achievement badges (legibility at their small display
size), and the new district collection cards (including the known 4-of-22 shared-photo gap,
`docs/KNOWN_ISSUES.md`).

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
