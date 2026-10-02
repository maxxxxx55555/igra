# Resume note (2026-10-02, rc15 sign-off)

State: `main` is the rc15 sign-off (the tag `v8.0.0-rc15` goes on the commit that records the last verifier round). Nothing is in flight; no worktree agent is running.
Numbers and proofs: `docs/ORDER_PASS_REPORT.md` (rc15 final section), `docs/PROOFS.md`, `docs/ACCEPTANCE_CHECKLIST.md` (200 rows),
`docs/ARENA_CLOSURE.md`, `docs/CORRECTION_LOG.md` (100 rows).

## What rc15 did
The missions the rc14 swarm never delivered (weapons and HUD slots, auto-aim, the crouch capsule, the visibility model, blueprints and
the workbench, photos, hiding spots, the inventory screen) were built in rc15 batches 1 and 2 and are closed in `docs/TZ_COMPLIANCE.md`
(CORRECTION_LOG 96). Batches 3 to 15 were a player-proof pass: the real game played through injected input events with a frame read at every
step (`tools/qa_sim/playthrough`, modes A V B S), every finding fixed at its root with a `closeout_check` assertion or a play-through step that fails on the old code;
batch 15 added the first independent verifier round, which found that the quick bar had never been on screen (CORRECTION_LOG 97).

## Next (priority C, then B, then A)
1. Release (owner): install `build/tls.aab` on a phone (T01; it is signed, 183.3 MB), then the Play Console steps of `docs/RELEASE_RUNBOOK.md`.
   `version/code` stays 1 until the first upload. The frame rate on a phone is untested: 31 fps at D1 on the dev iGPU is a 4% margin (PF3).
2. C (assets): the owner buys or creates per `docs/ASSET_SHOPPING_LIST.md` (boss and monster art, Bebas Neue Bold file, weapon box, trees);
   music per `docs/OWNER_HANDOFF.md`.
3. B (beauty): the placeholders above change the look the most; primitives are 39.7K to 50.2K a frame (PF4), so real low-poly art is a
   swap, not a rebuild.
4. A (game, owner decisions): E1 second half, E11, E13 (`DEFERRED-P3`), the damage cap, the save-slot picker (G22), the GDD text lines
   (G28/D04, N01, I02). The cosmetic P2/P3 of the S sweep: Encyclopedia grid, journal paper, workbench type.

## Rules that still hold
- Never run two Godot processes at once (the first sign-off battery overlapped three probe launches of mine and was not evidence); QA
  launches are muted; never delete `<profile>.qa_snapshot`.
- The profile's onboarding flag changes what a run measures: a fresh profile opens the onboarding cards on `game_started`, which pause the
  tree and dim the frame. Every tool runner that starts a game calls `SaveSystem.mark_onboard_done()` first (CORRECTION_LOG 90, 93).
- Tools that start the game go through the user-data guard (`tools/qa_sim/guarded_windowed`, `tools/qa_sim/playthrough`, `tools/check.sh`).
- After a `class_name` change run `godot --editor --quit --path .` once, then revert `default_bus_layout.tres` and
  `docs/artifacts/content-depth/i18n_only_texts.md` (never the `.import` files).
- Static-green is not parse-green: the engine compile gate (`COMPILE_GATE bad=0`) is the parse proof.
- A gate that passes on a paused or empty scene proves nothing: assert the mechanism (the tree runs, the hit landed), not only the outcome.
- The bot is nondeterministic run to run: judge stalls over several seeds, and record them.
