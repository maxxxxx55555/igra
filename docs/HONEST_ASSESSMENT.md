# HONEST_ASSESSMENT.md — where THE LAST STREETLIGHT actually stands

Written 2026-09-11 (PLAYABLE IDEAL pass, STEP 3). This is a candid read, not a marketing
pass — it exists to tell the owner what a stranger playing this for the first time on a
mid-range Android phone would actually experience, good and bad. Every claim below is
either sourced to a static/headless-verified fact (docs cited) or explicitly flagged as
opinion/estimate. Nothing here is a playtest — **no session has played this game**; that
gap is itself the loudest finding.

## Scores (out of 10, this reviewer's honest read)

| Axis | Score | Why |
|---|---|---|
| Gameplay depth | 6/10 | Real mechanics (noise/visibility stealth, 4-branch skill tree, crafting, a repair-based progression loop, 5 branching endings) — but only one core verb loop (find parts → power switch → repeat) across all 11 districts; the substation cable puzzle is the *only* mechanical variety break. |
| Content volume | 7/10 | 11 districts, 88 hand-written lore notes ×13 languages, 12 enemy types, a boss with 3 phases — genuinely substantial for a solo/small-team project. Runtime is short relative to that volume (see below). |
| Polish | 6/10 | i18n, accessibility, save-integrity, and crash-safety are unusually deep for this project's size (real native-QA pass, real headless regression suite). But **zero minutes of this has ever been seen on a screen** — every visual claim (banding, layout, touch-target overlap, actual frame pacing) is inferred from code, never observed. |
| Replay value | 4/10 | 5 endings is a real hook, but nothing *outside* the ending branches changes on a second run (no seed variation, no modifier, no daily/weekly content until this pass). NG+ exists as a system but has no mechanical twist beyond "again." |
| Viral potential | 5/10 | The core visual hook (dark → lit contrast) is genuinely trailer-ready and the store kit (13-locale listing, trailer stills, press kit) is unusually complete for this stage. But there is no live audience yet — zero reviews, zero screenshots taken from a real device, zero social proof. Viral potential is a property of a *released* game; this one hasn't shipped. |
| Mobile playability | 5/10 | Touch infrastructure is real and this session hardened it (dead-zone, response curve, haptics, sensitivity, a Help screen) — but it has **never been touched by a human finger on a real device**. A stealth-horror FPS with a virtual joystick + 4-6 action buttons is a genre that lives or dies on feel, and feel cannot be verified from a terminal. |

**Overall: 5.5/10 as a shippable product today** — not because the design or code is weak
(both are unusually careful for the team size), but because an unplayed, unseen build
cannot honestly score higher no matter how much static verification backs it. The
verification work in this repo (`docs/PLAN.md`, `docs/GAP_TO_IDEAL.md`) is real and closes
every gap a headless session *can* close. It cannot close the one gap that matters most:
nobody has played it.

## What HOOKS

- **The one clean visual idea.** "Every streetlight you fix stays lit" gives the whole game
  a legible, screenshot-and-trailer-ready throughline that most solo stealth games lack —
  confirmed by how easily the store kit built around exactly one sentence
  (`store/listing.md` tagline, `store/trailer.md`).
- **The flashlight as a weapon/eyes/liability triple-bind.** Genuinely elegant: light lets
  you see, hurts some enemies, and gives you away, all from one button
  (`scripts/player/player_3d.gd` `flashlight_enabled`, `HINT_FLASHLIGHT`).
  This is the strongest single mechanical hook in the game.
- **13 fully-localized languages with a real native-speaker QA pass**, not machine
  translation left unchecked — `docs/NATIVE_QA_FINDINGS.md` (10 CRITICAL + 458 HIGH fixes
  applied). Rare for a project this size and a real edge in non-English markets.
- **5 branching endings from real, checkable state** (districts restored, documents found,
  bunker access, death conditions) rather than a single binary win/lose —
  `scripts/systems/endings_manager.gd`.

## What HURTS (brutally)

- **No server, no multiplayer beyond LAN direct-IP, no cloud saves.** A player who loses
  their phone loses their save. There is no account system to recover it, and no
  cross-device play. In 2026, that's a real friction point for retention.
- **APK size vs. content is untested and likely unfavorable.** Every texture in the project
  ships Lossless/uncompressed (`docs/KNOWN_ISSUES.md` "Mobile texture compression" — 1230
  files checked, 0 VRAM-compressed). Combined with ~14 audio beds × 36s and dozens of SFX,
  this is very likely a large APK for its content volume until that migration happens.
- **Onboarding is now content-complete but still text-first.** 7 onboarding panels
  (`scripts/ui/onboarding_overlay.gd`) explain mechanics with captions over static art; there
  is no interactive tutorial beat that *makes* the player crouch, use the flashlight, or
  fight before the real game starts. A player who skips onboarding (the Skip button exists
  and is one tap) gets zero mechanical scaffolding.
- **Touch UX is unverified in the one way that matters.** This pass added dead-zone tuning,
  a response curve, haptics, and a Help screen — all real, all headless-tested for wiring —
  but the actual *feel* of a virtual joystick + a 4-6-button cluster on a 6" screen during a
  stealth encounter has never been felt by a human. This genre is notoriously hard to get
  right on touch; the risk here is not hypothetical.
- **No daily hook until this pass, and even now it's new and unplayed.** A single-session,
  no-live-service game has nothing pulling a player back tomorrow beyond "I want to see the
  next district" — which runs out after ~3-7 hours (`tools/qa_sim/balance_sim.py` estimate).
- **No social proof.** Zero App Store/Play Store reviews, zero screenshots from a real
  device, zero press coverage — because it hasn't shipped. This is not fixable by more
  engineering; it is fixable only by releasing and by the owner's own outreach
  (`store/press-kit.md`, `store/review-responses.md` are ready for when that starts).
- **The final boss is a real difficulty cliff for a first-time player.** 800 HP / 40 damage
  (`scripts/enemies/enemy_roster_data.gd` `&"boss"` entry) against a 100 HP player with no
  guaranteed damage-boost skills bought is a genuine skill gate, not a formality — this
  session's own headless autoplay bot could complete the entire 11-district spine with real
  inputs but could not reliably beat the boss without a scripted combat AI (`docs/GAP_TO_IDEAL.md`
  / `docs/KNOWN_ISSUES.md` autoplay-bot entry, honestly reported, not swept under the rug).
  A first-time mobile player reaching the finale with underleveled combat skills may bounce
  off the very last encounter.

## What's MISSING vs. the genre's best (Monument Valley / Limbo / Inside / Alto's Odyssey)

- **Monument Valley / Alto's Odyssey-level visual signature.** Those titles are recognizable
  from a single frame. This game's palette-locked "cold dark / warm light" rule is a real
  idea in the same spirit, but it has never been rendered and screenshotted from a real
  device — the comparison can't be honestly made yet.
- **Limbo / Inside-level minimalism of controls.** Those games run on 2-3 inputs. This game
  asks a touch player to manage a joystick plus 6+ discrete buttons (attack, sprint, stealth,
  interact, flashlight, strobe, quick-wheel) — closer to a full console control scheme
  shrunk onto glass than to the one-thumb elegance of the genre's mobile standard-bearers.
  `docs/GAP_TO_IDEAL.md`'s P2 list already flags aim-assist as unbuilt; a control-count
  *reduction* pass (context-sensitive single action button instead of 4+ discrete ones)
  is not on any list yet and would likely matter more than any single new feature.
- **Alto's Odyssey-level "endless, ambient, always-approachable" loop.** This game is a
  finite, story-gated campaign — a legitimate different genre choice, not a flaw, but it
  means there is no low-commitment 2-minute session mode for the "waiting for the bus" use
  case those games own.
- **A demonstrated live audience.** All three comparison titles had reviews, press, and
  player word-of-mouth before anyone could call them "viral." This project has none yet —
  the honest comparison is "pre-launch vs. launched," not "worse design."

## Score: 5.5/10 (pre-launch, unplayed build)

The ceiling is real — the design, the localization depth, and the verification discipline
in this repo are well above what a project this size usually has. The floor is also real:
until a human plays this on the device it will actually ship on, every number above is an
estimate, not a fact. `RELEASE_CHECKLIST.md`'s "optional eyes-on playtest" line is not
optional in the sense this document means it — it is the single highest-leverage remaining
action, above any further code work.
