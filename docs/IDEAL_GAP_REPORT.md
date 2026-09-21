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
