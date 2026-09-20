# Ideal gap report — 2026-09-20 (RC finish pass)

What "ideal" (9-10/10, ship-ready) looks like for each system, scored against what's
actually verified in this checkout right now — not aspirational. Every score cites the
evidence it's based on. `docs/GAME_AUDIT.md` has the original full-system audit from
earlier the same day; this report is the state *after* that audit's fixes, this session's
own regression-catch-and-revert, and the arena design audit's proposals.

## Per-category score

| Category | Score | Evidence |
|---|---|---|
| Core game loop | 7/10 | `game_manager.gd` state machine solid, no changes needed this pass (`docs/GAME_AUDIT.md` finding #1) |
| Save / NG+ | 8/10 | NG+ reachable end-to-end (last session), district pointer resets, battery/skill composition now order-independent (this pass, `24ceb68`), NG+ menu clarity shipped (`4e7560e`) |
| Districts | 7/10 | stable, unchanged this pass |
| Economy | 6/10 | `balance_sim.py` now reports the coin ledger honestly (`8f48faf`) instead of silently passing; real gap remains: `scripts/systems/shop.gd` (the "Shop" autoload) is dead code, zero callers - repeat-profile players have no verified in-run way to close the ~1,300-coin gap to 2 catalog items (see TOP-10 #6) |
| Stealth / AI | 7/10 | `silent_steps` now actually reaches the noise value monsters check, investigate-timer arrival bug fixed (`2a88503`); hidden-player damage guard already fixed prior session |
| Boss fight | 6/10 | P1 warning now visible (`24ceb68`); a boss-phase softlock is real but intermittent and its root cause is unconfirmed (battery/light-gate hypothesis tested and disproven this pass, see TOP-10 #2) |
| Balance data | 8/10 | player-speed regression caught and reverted (`d6c86cc`), battery capacity ceiling now honored everywhere (`24ceb68`) |
| i18n | 8/10 | `lan_menu.gd` fully localized, 19 new NG+/LAN keys across all 13 locales, parity + key-usage gates green (`4e7560e`); P2's two proposed new stealth skills have no keys yet (never implemented, see TOP-10 #3) |
| Accessibility | 7/10 | a probe now exists and proves all 3 toggles gate their real juice sites AND survive save->reload (`c889b41`) - previously unverified entirely |
| Audio | 7/10 | procedural layer now explicitly pauses with gameplay, guarded against two real mid-pause races (`f9bbfd7`) |
| Visual / UI polish | 4/10 | only W1 (graphics presets) and now W9 (focus/disabled theme states, `2d5e702`) of `docs/VISUAL_PASS.md`'s W1-W10 are wired; W2-W8, W10 are real delivered shaders/materials sitting unused (see TOP-10 #1) |
| Zero-shipped-debris | 9/10 | 13 BOM files + 7 debug-print/commented-code issues fixed prior session |
| Release/QA process | 7/10 | IRON RULE established this pass (no balance commit without a recorded bot run); 6 gate failures in this sandbox all root-caused as pre-existing/environmental via git-stash A/B testing, not code regressions - still need a real-machine reverification (see TOP-10 #4) |

## TOP-10 gap-to-ideal items

Ordered by impact/effort, not by category.

1. **Full W2-W10 visual pass wiring** (`docs/VISUAL_PASS.md` §8 has the exact per-wave
   spec). **DEV, large (multi-session), needs eyes-on-render** — this sandbox is
   headless-only; every prior session that touched this correctly declined to wire 9
   waves of shader/material code blind. Highest visual-quality impact in this list by far.
2. **Boss-phase softlock root cause** — confirmed real and intermittent (this pass's own
   diagnostic: 1 clean win, 2 prior softlocks, all in the boss phase after full district
   completion), battery/light-gating hypothesis disproven with real telemetry, remaining
   hypothesis (occasional navigation Y-dip below floor) unconfirmed. **DEV, medium** — the
   new `battery=`/`fl_on=` heartbeat fields (`scripts/tools/_qa_autoplay_runner.gd`) are
   already in place; needs a few more `autoplay_bot` runs that happen to reproduce it.
3. **Arena design audit P2** (two new stealth skills, `low_profile`/`quiet_pace`) — fully
   specified with exact values and localization copy in `docs/DESIGN_AUDIT_ARENA.md`, never
   implemented (P3's UI/copy rework shipped this pass, P2's skill additions did not).
   **DEV, medium** — skill_tree_manager.gd + base_monster.gd/player_3d.gd consumer wiring,
   plus 2 new keys x 13 locales.
4. **Re-verify the 6 gate failures on the owner's real machine.** All 6 (compile-gate,
   asset-check, 3D-scene, save-integrity, boot-flow, theme-unify) were root-caused this
   session as sandbox-specific (missing `.godot/imported/` cache for several textures, a
   `user://` filesystem quirk, the long-documented 3D-scene stall) via a `git stash` A/B
   test against pristine code - not regressions from any commit. **OWNER, ~10 min**: run
   `bash tools/check.sh` (non-static) on a real dev machine and confirm the count differs
   from this sandbox's 21/27.
5. **Shop.gd**: either delete the dead "Shop" autoload (`scripts/systems/shop.gd`, zero
   callers, confirmed this pass) or actually wire it to close the economy's real
   repeat-profile funding gap. **DEV, small-medium** — a real design call, not a bug fix;
   currently `ShopService` (the live, wired system) is unaffected either way.
6. **Store listing full long-form translation** to 11 non-English locales (short
   descriptions done, per v7.1). **DEV or owner-reviewable, ~1h/locale or MT+review.**
7. **Windowed stills + store screenshots** (8 before/after, 8 store shots) — headless
   capture proven impossible by a prior session; exact command in this file's history.
   **OWNER-ONLY, ~10 min.**
8. **Android keystore + signed AAB, Play Console setup** (app creation, IARC, listing
   upload). **OWNER-ONLY, ~1-2h, needs a Google account + local Android SDK.**
9. **`res://_QUARANTINE/` directory** — spotted in gate output, never folded into the
   size-budget pass. **DEV, small** — same methodology as `docs/QUARANTINE_AUDIT.md`
   already used for `_orphaned`/`_pre_norm`.
10. **`gh auth login`** — device-flow login needs a human at github.com; this session
    never blocks on it (push path proven directly via git) but PR/CI-based workflows stay
    unavailable until it's done. **OWNER-ONLY, ~2 min.**

## Shortest path to 9/10 overall

The single highest-leverage item is #1 (visual pass) — it's the only category below 6/10
(Visual/UI at 4/10) and has zero dependency on the others. Everything else on this list is
independently completable in any order. #2 (boss softlock) is the second priority: it's
the one correctness question with a nonzero chance of blocking a real playthrough, and the
diagnostic infrastructure to close it out is already in place.
