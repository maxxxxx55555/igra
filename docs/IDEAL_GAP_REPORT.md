# Ideal gap report — 2026-09-21 (v7.3.2, softlock CLOSED + audio loudness + arena debug audit merged)

Updates v7.3.1 below (same date, kept as history). Unlike v7.3.1 (audit-only, nothing closed),
this pass closed two real items.

## What changed this pass (v7.3.2)

- **Residential spine-softlock (TOP-10 #2, was) — CLOSED**, `b7213ac`. A fresh arena branch
  (`arena/01a0c324-igra`, merged `68d6ce4`) carried `docs/SPINE_SOFTLOCK_AUDIT.md` with a
  ranked candidate list. Its #1 candidate (C1, high-speed tunneling at 170 m/s) was checked
  against real telemetry (temporary diagnostic prints, reverted after, never shipped) and
  **rejected**: player velocity was 0.0 while stuck, not 170 — no tunneling. The audit's #2
  candidate (C4, the stuck-nudge launching the player out of bounds) was confirmed, but its
  proposed fix was wrong for this codebase: `player_3d.gd:544` normalizes movement direction
  before applying speed, so shrinking the nudge vector's length (the audit's suggestion)
  cannot change velocity. The real lever was nudge **duration** (1.2s at full speed = up to
  204m, matching the previously-logged 150-250m position jumps) — cut to 0.25s. **3-seed bot:
  3/3 WINS, zero FAIL/SOFTLOCK lines in any log** (up from the 2/3 boss-fix baseline — a net
  improvement, not just a recovery). QA-bot-only change, no gameplay/balance file touched.
  Full trace in `docs/KNOWN_ISSUES.md`.
- **Audio loudness (part of the standing DEV-REMAINING item) — the shipped-track half CLOSED**,
  `86ef452`. Measured all 21 music/ambient tracks against the house law (-18 LUFS, TP<=-1.5
  dBFS) with `ffmpeg loudnorm`. Found and fixed: `abandoned_hallways.mp3` (MENU theme, was
  -15.13 LUFS / **+0.10 dBTP — actually clipping**) and `abandoned_hallways_alt.mp3`
  (school/hospital theme, -14.44/**+0.04 dBTP, also clipping**), plus `layer_lit.ogg` (-14.07,
  4 LU hotter than its `layer_dark.ogg` crossfade sibling). All three now measure -18.0 to
  -17.9 LUFS with safe true peak. `music_combat.ogg`'s -21.93 spread was left alone — already
  documented in `docs/MUSIC_RECIPE.md` as a deliberate variant pool, not a defect. Remaining
  audio work (new-track generation + mixing those once they exist) is 100% owner-blocked now,
  not a dev task — folded into the music item in `docs/OWNER_HANDOFF.md` rather than staying a
  separate DEV-REMAINING line.
- **Arena backlog — 1 more ref landed**, `68d6ce4`: `arena/01a0c324-igra`
  (`docs/SPINE_SOFTLOCK_AUDIT.md`, docs-only, clean merge, directly enabled the softlock fix
  above). The other 5 refs from v7.3.1's audit are unchanged (still 0 mergeable, not
  re-checked this pass — nothing new landed on any of them).
- **`docs/OWNER_HANDOFF.md` (new)** consolidates all owner-blocked work into one document:
  19 music prompts inline (was previously only in `docs/MUSIC_RECIPE.md`), the exact windowed
  screenshot command, release-ops steps (and flags a real keystore-command inconsistency
  between `docs/RELEASE_CHECKLIST.md` and `docs/store/HUMAN_CHECKLIST.md` rather than silently
  picking one), and the 3 economy options as neutral decision cards. Also corrects a stale
  gap-report line: "8 before/after, 8 store shots" conflated two different deliverables — the
  5 `assets/store/screenshot_0X.png` files are already shipped (confirmed on disk), only
  `docs/stills/`'s 8 shots (0 files) are genuinely owner-blocked.

## TOP-10, restated (genuinely open only)

1. **Full W2-W10 visual pass wiring.** Unchanged — **DEV, large, needs eyes-on-render**.
2. **Economy: repeat-profile coin shortfall.** Unchanged, 3 scored options ready
   (`docs/ECONOMY_OPTIONS.md`, decision card in `docs/OWNER_HANDOFF.md`) — **DEV or design
   call, medium; awaiting an owner decision, not blocked on more analysis**.
3. **Music generation.** Unchanged — **OWNER, ~2-4h**, all 19 prompts now also inline in
   `docs/OWNER_HANDOFF.md`.
4. **Windowed stills** (`docs/stills/`, 8 shots — NOT the store listing screenshots, which are
   already shipped). **OWNER-ONLY, ~2 min**, exact command in `docs/OWNER_HANDOFF.md`.
5. **Android keystore + signed AAB, Play Console setup.** Unchanged — **OWNER-ONLY, ~1-2h**.
6. **`gh auth login`.** Unchanged, still not done — **OWNER-ONLY, ~2 min**.

(Residential softlock and the shipped-track audio-loudness half are both closed as of this
pass — removed from the list rather than carried forward stale.)

---

# Ideal gap report — 2026-09-21 (v7.3.1, backlog audit + softlock re-investigation)

Updates v7.3 below (same date, kept as history). No TOP-10 item **closed** this pass — this
pass's work was audit/investigation/analysis depth, not new fixes, and is reported honestly
as such rather than padded.

## What changed this pass (v7.3.1)

- **Arena merge backlog (Phase M0) — re-audited, still 0 mergeable.** All 5 still-unmerged
  `origin/arena/*` refs re-checked against current `main` (2 commits past the v7.3 tag):
  `019ffbd0-igra` and `01a07b1c-igra` both still produce real 3-way conflicts under `git
  merge-tree --write-tree` (confirmed with the modern conflict-listing form of the command,
  not just a diff-stat guess); `01a09af1-igra` conflicts even on `tools/qa_sim/autoplay_bot`
  itself and remains the same stale 552-file mega-merge v7.2's integrator pass first flagged;
  `01a0ab24-igra`'s docs (`GAMEFEEL_SPEC.md`/`QA_MATRIX.md`) are confirmed superseded — main's
  `QA_MATRIX.md` is a strictly newer, extended version (40+30 cases vs. the branch's original
  16); `card-unique-rescue` stays rejected per its already-documented fabricated-cert finding,
  not re-opened. Full per-ref evidence in `docs/RUN_STATE.md`. `origin/gh-pages` is not an
  arena ref (privacy-policy deploy target) and was excluded, not silently skipped.
- **Residential spine-softlock (TOP-10 #2, was) — one more hypothesis ruled out, one more
  rejected, still open.** The "locked boiler room blocks the pickup" theory (item_spawns.json
  places the district's first-needed `cable` in the same `zone` as the key-gated
  `transistor`) was investigated and disproven before any code was touched:
  `district_loot.gd` confirms 3D districts have no real zone markers at all — `zone` is
  authoring metadata only, every fixed-spawn lands via the same seeded scatter, no door/lock
  code exists anywhere. Separately, gave the bot's movement a `NavigationAgent3D` (mirroring
  `base_monster.gd`, since the bot previously steered in a straight line with only a 2s stuck-
  nudge for obstacles) and verified with a real 3-seed run: **0/3, worse than the 2/3
  baseline**, with a new softlock in `suburbs` (previously always-solid) alongside
  `park`/`hospital`. Reverted per the IRON RULE, documented in `docs/KNOWN_ISSUES.md`. The
  softlock's real mechanism is still unknown; next session needs finer-grained telemetry
  inside the 45s stall window, not a third guess.
- **Economy gap (TOP-10 #3) — 3 funding-path options written up, no decision made.**
  `docs/ECONOMY_OPTIONS.md` (new): wire the existing (currently cosmetic) kill-coin number
  into `CoinWallet`, cut the two target catalog prices, or add a bounded quest/puzzle faucet —
  each scored on code impact / player risk / effort / reversibility, all marked
  NEEDS-OWNER-DECISION per this phase's analysis-only scope. Also corrects the standing "0
  repeatable income" framing: daily challenges already pay real wallet coins (avg 216.5,
  calendar-gated), which the single-playthrough bot trace correctly never sees but a real
  returning player already has.
- **Verification battery re-run**, reusing results only where nothing that could affect them
  changed (stated per-row below, per this repo's own economy-of-context rule): static 12/12
  (re-run), i18n 13/13 MISSING:0 (re-run), quarantine audit PASS (re-run), `balance_sim.py`
  PASS (re-run, independently reproduces the same 1,300-coin gap `ECONOMY_OPTIONS.md` cites).
  Engine gates (26/27) and the boss-resolved 2/3 `autoplay_bot` baseline were **not** re-run —
  reused from the v7.3 tag commit, since this pass's only gameplay-code edit (the
  `NavigationAgent3D` bot experiment) was fully reverted via `git checkout --`, never
  committed, leaving zero net code delta since that measurement.

## TOP-10, restated (genuinely open only — v7.3's numbering carried forward where unchanged)

1. **Full W2-W10 visual pass wiring.** Unchanged from v7.3 — **DEV, large, needs eyes-on-render**.
2. **Spine-phase softlock in `residential`.** Unchanged from v7.3, deeper investigation this
   pass (2 hypotheses now rejected with evidence, 1 lead ruled out before coding) — **DEV,
   unscoped, more telemetry needed before a third attempt**.
3. **Economy: repeat-profile coin shortfall.** Unchanged from v7.3, now has 3 scored options
   ready to pick from (`docs/ECONOMY_OPTIONS.md`) — **DEV or design call, medium; awaiting an
   owner decision on which option (or "accept the gap"), not blocked on more analysis**.
4. **Music generation.** Unchanged — **OWNER, ~2-4h**, prompts ready in `docs/MUSIC_RECIPE.md`.
5. **Windowed stills + store screenshots.** Unchanged — **OWNER-ONLY, ~10 min**.
6. **Android keystore + signed AAB, Play Console setup.** Unchanged — **OWNER-ONLY, ~1-2h**.
7. **`gh auth login`.** Unchanged, still not done — **OWNER-ONLY, ~2 min**.

(The arena merge backlog was never one of v7.3's numbered TOP-10 items — it's tracked
separately in `docs/RUN_STATE.md`, re-confirmed this pass as still 0 mergeable. Not listed as
a numbered gap here because there's nothing actionable left in those 5 refs without new
human-authored conflict resolution, which isn't a gap this repo's own automation can close.)

---

# Ideal gap report — 2026-09-21 (v7.3, real-engine pass)

Updates v7.2's report (2026-09-20, below) after a pass with something no prior session had:
a real Godot 4.7 binary on this machine, not a headless-only sandbox. That changed two
things — real `autoplay_bot` runs against real gameplay, and TOP-10 #4 (the "re-verify gate
failures on a real machine" item) actually got done, which flipped several "environmental,
unconfirmed" gate failures into "confirmed environmental, now fixed" or "confirmed real."

## What changed this pass

- **Boss-phase softlock (was TOP-10 #2) — CLOSED**, `acddc80`. Root cause confirmed with
  real telemetry (not simulated): the Architect's P2/P3 chase periodically sinks below the
  arena floor (measured Y −1 → −33 across ~90s in one real run), and the existing rescue
  teleport only checked full 3D distance with a 1.5s grace period, so a vertically-fallen
  boss read as "close" and the rescue never fired fast enough. Fixed by checking vertical
  separation independently, no grace period. **3-seed bot: 2/3 wins, boss fight reached and
  resolved both times** (up from a 1/3 pre-fix baseline on the same revision, where the other
  2 seeds hit this exact signature). One unrelated new finding surfaced by this same bot run:
  seed2 hit a spine-phase softlock in `residential` (not boss-related) — logged below as a
  new open item, not silently dropped.
- **Arena P2 stealth skills (was TOP-10 #3) — CLOSED**, `c2dbeb4`. `low_profile` and
  `quiet_pace` added per `docs/DESIGN_AUDIT_ARENA.md`, localized to all 13 locales,
  rank-0-safe by construction (bot baseline unaffected).
- **Shop.gd dead code (was TOP-10 #5) — CLOSED via deletion**, `aa6548b`. Traced the live
  "Shop" UI screen and confirmed it's fully wired to `ShopService`/`CoinWallet` — a separate,
  working system. `shop.gd`'s battery/stamina/medkit catalog was never connected to it or
  anything else and predates it; deleted, not a planned feature. **The underlying economy
  gap this item was about (1,300-coin repeat-profile shortfall) is NOT closed by this** —
  deletion removes dead code, it doesn't add income. Still open, see Economy row below.
- **`_QUARANTINE` fold-in (was TOP-10 #9) — CLOSED**, `d704461`. Export-filter exclusion
  (not physical deletion, per this repo's hard rule) across all 3 presets. Measured via a
  real `--export-pack` run: 213,686,040 → 213,110,424 bytes (−0.27%, real number not an
  estimate).
- **Audio mix-audit auto-fixes — CLOSED (the auto-fixable subset)**, `39b2254`. VICTORY mood
  exempted from force-loop (was replaying a 14.5s figure forever under the win screen's 120s
  arc); 8 confirmed-0-consumer duplicate/orphan audio files deleted. Loudness normalization,
  new track generation, and the MENU track swap still need audio generation + ears — itemized
  in `docs/MUSIC_RECIPE.md` (new this pass) and `docs/AUDIO_MIX_AUDIT.md`.
- **Visual pass (TOP-10 #1) — barely moved, on purpose.** Only W10's streetlight
  per-district `energy_mult` wiring landed (`e865149`) — pure numeric, no shader/material,
  no rendering judgment needed. Everything else in W2-W10 has its asset already authored
  (shaders/materials/vfx scenes/env presets all exist on disk, confirmed) but genuinely needs
  a rendered frame to judge quality, which this pass deliberately didn't attempt blind, even
  though this sandbox can technically render now — see `docs/VISUAL_REMAINING.md` (new this
  pass) for the itemized remainder, including one real doc/code conflict found (District-
  Themes' proposed ambient constants don't match `world_env_setup.gd`'s actual live values).
- **TOP-10 #4 (real-machine gate re-verify) — DONE, and the diagnosis changed.** v7.2's
  report said all 6 sandbox gate failures were "environmental," proven via git-stash A/B
  testing but never actually fixed (no real machine to fix them on). This pass had a real
  machine: ran `godot --headless --path . --import` (the exact fix `docs/RELEASE_READINESS_REPORT.md`
  v6 already documented but no session since had hardware to apply), and 5 of the 6
  failures (compile-gate, asset-check, boot-flow, theme-unify, save-integrity) went
  **green**. Final tally: **26/27 engine+static gates**, up from v7.2's 21/27 — the only
  remaining fail is the 3D-scene 90s-timeout stall, the same one named as pre-existing in
  v7, v7.1 and v7.2. See `docs/RELEASE_READINESS_REPORT.md` v7.3 for the full breakdown.

## Per-category score

| Category | Score | Evidence |
|---|---|---|
| Core game loop | 7/10 | unchanged this pass |
| Save / NG+ | 8/10 | unchanged this pass |
| Districts | 7/10 | unchanged, but see new open item: seed2's spine-phase softlock in `residential` (below) |
| Economy | 6/10 | `shop.gd` dead code resolved (hygiene win), but the real gap — repeat-profile players ~1,300 coins short of 2 catalog items with 0 repeatable income — is unchanged; deleting dead code doesn't fund anything |
| Stealth / AI | 8/10 | P2 skills (`low_profile`/`quiet_pace`) landed this pass, `c2dbeb4`; P1's prior fixes still hold (unchanged) |
| Boss fight | 8/10 | root cause found and fixed with real telemetry this pass, `acddc80`; 2/3 bot wins with the boss resolved both times, up from 1/3 |
| Balance data | 8/10 | unchanged this pass; `balance_sim.py` PASS, stealth branch now 4 skills/13 SP (was 2/7), matching the design audit's arithmetic exactly |
| i18n | 8/10 | 2 new keys (`SKILL_LOW_PROFILE_*`/`SKILL_QUIET_PACE_*`) × 13 locales this pass, parity green, `MISSING: 0` |
| Accessibility | 7/10 | unchanged this pass |
| Audio | 7.5/10 | mix-audit auto-fixes landed (`39b2254`); loudness/new-track work still needs generation + ears, recipe now exists (`docs/MUSIC_RECIPE.md`) |
| Visual / UI polish | 4/10 | one more W-item wired (streetlight `energy_mult`) out of the ~10 remaining; still the lowest-scoring category, unchanged in substance — see `docs/VISUAL_REMAINING.md` |
| Zero-shipped-debris | 9/10 | unchanged |
| Release/QA process | 9/10 | real engine-gate re-verification actually happened this pass: 26/27 on real hardware (up from 21/27), only the long-documented 3D-scene stall remains; IRON RULE maintained (boss fix has a recorded 3-seed run in its commit) |

## New open item found this pass

- **Spine-phase softlock, `residential` district.** Found by this pass's own post-fix
  verification bot run (seed2): `SOFTLOCK: no progress for 45s — phase=spine
  district=residential spine_i=1`, at `.qa_logs/autoplay_seed2.log` (this run's artifacts).
  Not the boss-phase bug (different phase, different district, unrelated cause) — genuinely
  new, not previously documented in `docs/KNOWN_ISSUES.md`. **DEV, unscoped** — this pass's
  time went to the boss-phase fix (explicitly prioritized) and didn't leave room to
  diagnose a second softlock; needs its own root-cause pass the same way the boss one got.

## TOP-10 gap-to-ideal items (re-ordered; closed items removed)

1. **Full W2-W10 visual pass wiring.** Still **DEV, large (multi-session), needs eyes-on-render**
   — unchanged in substance from v7.2, see `docs/VISUAL_REMAINING.md` for the current itemized
   list (assets all exist, wiring + quality judgment is the gap) plus one real doc/code
   conflict this pass found and flagged rather than guessed at.
2. **New spine-phase softlock in `residential`.** **DEV, unscoped** — see above. Same class
   of bug as the boss-phase one (a bot-detected softlock with real telemetry available in
   `.qa_logs/`), needs the same diagnostic treatment.
3. **Economy: repeat-profile coin shortfall.** **DEV or design call, medium** — `shop.gd`'s
   removal closed the dead-code question but not the underlying gap
   (`docs/DESIGN_AUDIT_ARENA.md` P6 has the full ledger: 1,300-coin gap, 0 repeatable-grind
   income by design). Needs an actual design decision (new faucet, reduced prices, or accept
   the gap as intentional friction), not a code fix.
4. ~~Store listing full long-form translation to 11 non-English locales~~ — **REMOVED,
   was already done.** Checked this pass: `python tools/gen_store_listing_locales.py --check`
   → GREEN, and `store/listing.md` genuinely contains complete, non-placeholder title/
   tagline/short+full description/8 bullets/ASO tags for all 13 locales, landed `82a7e87`
   (2026-09-10-13). This item was wrongly carried forward as open across v7, v7.1, v7.2, and
   this report's own first draft — v7.2's Verification table even said "13/13 GREEN" a
   section above its own gap list, and nobody (including this pass, initially) cross-checked
   the two. Corrected in `docs/RELEASE_READINESS_REPORT.md` v7.3 rather than repeated again.
5. **Music generation** — `docs/MUSIC_RECIPE.md` (new this pass) has all 19 Suno prompts
   ready to paste, ordered, with target files and post-production steps. **OWNER, ~2-4h**
   (generation + trim/loudnorm/export per track — the prompts are ready, the audio isn't).
6. **Windowed stills + store screenshots** (8 before/after, 8 store shots). Unchanged.
   **OWNER-ONLY, ~10 min** — this pass confirmed the sandbox now has a real Godot binary,
   but headless capture is still architecturally impossible (no compositor); the windowed
   command is unchanged from prior sessions' notes.
7. **Android keystore + signed AAB, Play Console setup.** Unchanged. **OWNER-ONLY, ~1-2h.**
8. **`gh auth login`.** Unchanged, still not done (`gh auth status` checked this pass — not
   logged in). **OWNER-ONLY, ~2 min.**

## Shortest path to 9/10 overall

Same as v7.2: the visual pass (#1) is still the highest-leverage single item and the only
category below 6/10. The new spine-phase softlock (#2) is now the second priority — it's a
correctness bug with a nonzero chance of blocking a real playthrough, exactly like the boss
one was, and this pass already proved the diagnostic method (real bot run + heartbeat
telemetry + targeted fix) works.
