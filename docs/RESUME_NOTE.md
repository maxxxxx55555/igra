# Resume note (2026-09-30, rc14 sign-off)

State: `main` is the rc14 sign-off (tag `v8.0.0-rc14`). Nothing is in flight; no worktree agent is running.
Numbers and proofs: `docs/ORDER_PASS_REPORT.md` (rc14 final section), `docs/ARENA_CLOSURE.md`, `docs/CORRECTION_LOG.md`.

## What the swarm delivered
Four worktree agents (audio, player, menus, world) were started before a usage limit stopped them. Only the audio
agent's A01 bus graph reached `main` (`5114d23`, patches `18b01e59`). The player, menus and world agents left no
commits and their worktrees were removed, so there was nothing to merge. Their missions are **unbuilt**:

| Mission | Rows (source) | Where it is tracked |
|---|---|---|
| player: first-person weapons and HUD slots, auto-aim, crouch capsule, visibility model | G25, C03 (dormant until G25), G07 capsule, S02 | `docs/TZ_COMPLIANCE.md` DEFERRED-STRUCTURAL, `docs/TZ_DECISIONS.md` |
| menus: settings tabs, delete-save confirm, inventory (V.5), quick wheel, menu backgrounds (V.2) | G22 picker (GAP-OWNER), GDD V.2 / V.5 | `docs/TZ_COMPLIANCE.md`, `docs/GDD.md` |
| world: blueprints, photos, weapon pickup placement, hiding-spot placement | G21, G26, S04-hide | `docs/TZ_COMPLIANCE.md` DEFERRED-STRUCTURAL |
| audio: SFX wiring of `assets/audio/sfx/interact/*`, intermittent DETAIL_BEDS | delivered-but-unwired table | `docs/ASSET_SHOPPING_LIST.md` |

Brief for an audio continuation: an EventBus-driven table in `audio_manager.gd` that maps interact events to the
delivered files; never a constant bed (PRODUCTION_BIBLE 3, the owner asked for no hum).

## Next (priority B, then A, then C)
1. B (beauty): the placeholders in `docs/ASSET_SHOPPING_LIST.md` rows 1-4, 7-9 change the look the most; the dark-box
   skyline and capsule monsters are stand-ins, not art. Primitives are 1.34 M per frame against the 50K budget
   (PERF_PASS 18): real low-poly geometry is the fix, not more effects.
2. A (game): the DEFERRED-STRUCTURAL rows above, in the order weapons (G25), menus, blueprints and photos (G21, G26).
3. C (assets): the owner buys or creates per the shopping list; music per `docs/OWNER_HANDOFF.md`.
4. Release: Play Console upload and device smoke test per `docs/RELEASE_RUNBOOK.md` (owner steps).

## Rules that still hold
- Never run two Godot processes at once; QA launches are muted; never delete `<profile>.qa_snapshot`.
- After a `class_name` change run `godot --editor --quit --path .` once, then revert `default_bus_layout.tres` and
  `docs/artifacts/content-depth/i18n_only_texts.md` (never the `.import` files).
- Static-green is not parse-green: the engine compile gate (`COMPILE_GATE bad=0`) is the parse proof.
- The bot is nondeterministic run to run: judge stalls over 13 seeds, and record them.
