# Run state — orchestrator pass (2026-09-20)

## Session 3 (2026-09-20, later): balance consumption from arena design audit
Consumed `docs/DESIGN_AUDIT_ARENA.md` from `arena/01a0bdfa-igra` (`docs(design):`
commit `0a15e5e`, 8 proposals P1-P8; a later `docs(qa):` commit `a365088` on the same
branch extends `docs/QA_MATRIX.md` + adds `docs/RELEASE_CHECKLIST.md`, docs-only).

**Critical regression found and fixed first** (`d6c86cc`): the PRIOR session's own
"player speed fix" (`data/balance/player_stats.tres` 170/300/90 → 1.7/3.0/0.9) was
wrong. It was based on comparing the player's raw speed number to monster speed
numbers and assuming proximity was correct, never checked against actual behavior.
`tools/qa_sim/autoplay_bot` proved it: with the "fixed" values, 0/3 seeds won, all
stuck within meters of spawn within 45s (district distances need the original
traversal speed). Reverted to 170/300/90; bot confirmed 3/3 wins. Corrected
`docs/GAME_AUDIT.md` in place (finding #2 + score rows) rather than deleting the
record of the mistake. **Lesson for next session: never ship a numeric balance
change without an `autoplay_bot` run first** — this one sat unverified in `main`
for an entire session before this pass caught it.

Applied from the arena audit (zone: balance/data files, gameplay scripts):
- P6 (coin-economy reporting) + P7 (duration-target scoping to DARK) — `8f48faf`,
  docs/simulator-reporting only, zero runtime delta, no bot test needed (verified the
  new `[7]` balance_sim.py section reproduces the audit's derived numbers exactly).
- P1 (repair the stealth skill investment) — `2a88503`: `silent_steps` was reducing
  a noise-radius signal with zero listeners instead of the noise scalar monsters
  actually read; `_state_investigate()` re-armed its own search timer to 5.0 every
  tick on arrival, so search never expired. Both fixed. Bot: 1/3 win, 2 softlocks —
  both after restoring 2-4/11 districts in nav-heavy districts (park/hospital)
  unrelated to noise/investigate logic, matching this repo's own documented
  historical baseline (`docs/KNOWN_ISSUES.md`: "6/10 wins... spine-navigation
  failures"). Meets the audit's own stated target (>=1 win, 1-2/3 expected, not 3/3).

**Not applied — out of zone:** P2 (new `low_profile`/`quiet_pace` skills) and P3
(NG+ menu-copy rework) both require new keys across all 13 `data/i18n/*.json` locale
files, which is `cl/a11y-i18n`'s zone per `docs/AGENT_ZONES.md`, not mine. Their
non-localization pieces (skill effect wiring, routing logic) are ready to implement
once locale keys exist — see `docs/DESIGN_AUDIT_ARENA.md` P2/P3 for the exact
proposed strings and target files.

**Not applied — deferred, not evidence-rejected:** P4 (pause `proc_audio.gd` with
gameplay), P5 (make purchased battery capacity real instead of clamped to 100), P8
(fix `MonsterTelegraph`'s mesh-lookup timing so the boss P1 warning is actually
visible). All three passed a read-through and looked implementable, but after the
speed-revert finding above this session deliberately stopped adding balance/gameplay
changes rather than rushing three more without individually-verified bot runs. Each
still has full file/line detail and acceptance criteria in the arena doc.

## Phase M (merge check): WAITING
Lane readiness: arena design branch — ready (`arena/01a0bdfa-igra`, consumed above).
Arena QA branch (`docs(qa):`) — ready (`a365088`, docs-only, same branch).
`docs/RUN_STATE_OC.md` (OpenCode) — **missing**. `docs/RUN_STATE_CL.md` (Cline) —
**missing**. Not all lanes ready; per protocol, stopping here rather than merging or
polling. No merge, no tag, no `RELEASE_READINESS_REPORT.md` v7.2 this session — those
are gated on OC+CL finishing or an owner "MERGE NOW", neither of which happened.

## This session (2026-09-20): full-game audit + gameplay fixes
- Phase 0: `gh auth status` not logged in (device-flow login needs a human at
  github.com, can't complete headlessly) — skipped per "never block on gh". Push path
  proven directly via git instead: `git ls-remote origin refs/heads/main` ==
  `git rev-parse main` after every push below, all matched.
- Phase 1: `docs/GAME_AUDIT.md` — full score table, 9 P1 fixes shipped, 6 findings
  documented but not fixed (zone boundary / needs playtest / needs design call), 5
  design improvements with acceptance criteria. Read it for detail; commits:
  `f1002d3` `7ec2e3a` `f7832c1` `ee273ee` `6bf1deb` `cab439b` `ac847af` `4c0be57`.
- **Gate baseline changed since the last orchestrator pass — verified, not a
  regression.** Full `bash tools/check.sh` (non-static) now shows 20/26, not the
  previously-recorded 25/26. The 6 failures are compile-gate, asset-check, 3D-scene
  (the already-documented pre-existing stall), save-integrity, boot-flow, and
  theme-unify. Root-caused all 6 before touching anything:
  - compile-gate / asset-check / theme-unify all fail on the *same* pre-existing
    cause — stale/missing `.godot/imported/*.ctex` cache for several PNGs
    (`city_iso_2048.png`, `btn_tex_disabled.png`, `quickslot_v2_72.png`, and 41/41
    item icons in asset-check) in this headless environment. Confirmed present
    *before* any Phase 2 edit (same error in a standalone `scene_smoke.gd` run at
    the very start of this session).
  - save-integrity / boot-flow: confirmed via `git stash` A/B test — both fail
    identically (byte-identical error messages) against pristine pre-session code.
    save-integrity fails *worse* on pristine (13 fails incl. basic save/load
    round-trip) — a `user://` filesystem behavior issue in this sandbox, not
    anything in `save_system.gd`.
  - Static gate (12/12), `scene_node_check.py` (clean), and
    `tools/qa_sim/balance_sim.py` (PASS) all stayed green throughout.
  - Not fixed this session: none of these 6 are in scope for a gameplay-fix pass
    (they're headless-environment/import-cache issues, not code bugs) — flagging
    here so the next session doesn't re-litigate the stash A/B test.
- Phase 3 (integrator): **not run.** Neither trigger condition met — no literal
  "MERGE NOW" from the owner this session, and `docs/RUN_STATE_OC.md`/
  `docs/RUN_STATE_CL.md` still don't exist (OpenCode/Cline haven't started).
  Unchanged from the stance below.

---


## Done, pushed
- `86228c6` Phase 0: CLAUDE.md economy rules block; no `.mcp.json` in repo (nothing to disable at
  repo scope); `rtk` not installed, not verified, skipped.
- `ff863c3` Phase 1: merged `arena/01a0b08a-igra` (verified real, clean, conflict-free before
  merging — not trusted from the task description). Gates re-verified after a clean `--import`:
  static 12/12, full 25/26 (only the pre-existing 3D-scene stall). 4 OTHER unmerged `arena/*`
  branches checked and deliberately NOT merged — see below, not silently dropped.
- `8704231` Phase 2: `AGENTS.md` (OpenCode zone), `.clinerules/zone.md` (Cline zone),
  `docs/AGENT_ZONES.md` (manifest). Local branches `oc/visual-w10`/`cl/a11y-i18n` created from
  current main, not pushed (both empty so far).
- `bf0f7c9` Phase 3: `docs/TOOLING_DECISIONS.md` — nothing installed (see file for why).

## Arena branches NOT merged — real evidence, not a guess
- `arena/019ffbd0-igra` (77 files, 2953+/1052- vs main, 110 conflict-marker lines in a merge-tree
  dry run) — deep early-history divergence (commits go back to hiding-spot/save-system fixes
  already shipped on main under different hashes). Real conflict, needs human resolution.
- `arena/01a07b1c-igra` (45 files, 1197+/216-, 71 conflict-marker lines) — FPS weapon-layer
  changes that likely conflict with the live weapon code on main.
- `arena/01a09af1-igra` (552 files, 20244+/343-, 6 conflict-marker lines) — its own history is
  just merges of two ALREADY-merged branches, yet diverges massively from current main. Almost
  certainly stale/abandoned, not safe to merge blind.
- `arena/01a0ab24-igra` (3 files, 517+, **direct semantic conflict**) — a more detailed,
  conflicting `docs/GAMEFEEL_SPEC.md`/new `docs/QA_MATRIX.md`/`docs/BALANCE_MATRIX.md` vs the
  version already wired into shipped code this session (`f372a5c`). Flagged in both zone
  contracts for whoever picks up visual/a11y work next.
- `arena/card-unique-rescue` — already explicitly rejected in this repo's own history
  (`docs/RELEASE_ARTIFACTS.md`: fabricated 22/22 cert, byte-identical blobs to main). Not
  re-attempted.

## Integrator stance
No dev work on `main` right now. Waiting on either owner command "MERGE NOW" or both
`docs/RUN_STATE_OC.md`/`docs/RUN_STATE_CL.md` showing done+pushed (neither exists yet — no
OpenCode/Cline session has started work).

## Owner actions
1. `/model opusplan` (Phase 0 ask).
2. Open OpenCode Desktop on this repo, checkout `oc/visual-w10` — it auto-reads `AGENTS.md`.
3. Open Cline Desktop on this repo, checkout `cl/a11y-i18n` — it auto-reads `.clinerules/zone.md`.
4. When both are done: say "MERGE NOW" (or just wait — this tool checks both RUN_STATE files).
