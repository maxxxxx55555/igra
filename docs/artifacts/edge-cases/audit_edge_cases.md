# Edge-case audit of the MEGA FINAL PASS wiring (2026-09-13)

Independent review agent, briefed adversarially against code written the same day. Every
claim was cited to file:line by the reviewer and re-checked before fixing.

**`EDGE AUDIT: 2 P0, 2 P1, 2 P2`** — all six actioned; four fixed in `c454e76`, one
resolved by another fix, one confirmed as intended behaviour.

## P0 1 — collected secrets respawned on district re-entry — FIXED

`scripts/world/world_runtime.gd` frees the district root and rebuilds it on every entry to
a different district, so `DistrictSceneFactory.build()` → `DistrictLoot.populate()` →
`_spawn_secrets()` re-ran and put back secrets already taken. `secret.gd`'s `_taken` flag
lives on the freed node, so it could not survive. Repro: walk A → B → A and every secret in
A is collectible again.

Consequences: unlimited reward farming through `InventoryManager.try_add`, and the
`seeker` achievement (10 secrets) closable by re-collecting one secret ten times.

Fixed by consulting the one component that does remember — `_spawn_secrets()` now skips any
row for which `ProgressTracker.is_secret_found(id)` is true.

## P0 2 — New Game did not reset ProgressTracker or NewGamePlus — FIXED

`SaveSystem.reset_all()` resets Power, Upgrades, Wallet, Shop, Inventory, Encyclopedia,
Quests, Endings, XP and Skills — but not `ProgressTracker` or `NewGamePlus`. This is
precisely the bug class `CLAUDE.md` already records as TRUTH WAVE P0.2 (where the same
omission hid XP and skill carry-over), recurring in two systems added today.

A fresh New Game therefore kept the previous run's secret/kill/puzzle counters, its
`_ach_done` set, its found-secret id list, and its NG+ level plus active modifiers. Combined
with the P0 1 fix it would have been worse still: already-found secrets would never
reappear in a genuinely new game.

Both now reset in `reset_all()`.

## P1 3 — `NewGamePlus.reset_for_new_game()` had no caller — RESOLVED BY 2

Only `scripts/tools/_game_test.gd` invoked it, as a unit test of the method itself. The
P0 2 fix gives it its first real call site.

## P1 4 — 27 of 31 achievements unlocked silently — FIXED

`AchievementManager._unlock()` emitted only its own local `achievement_unlocked` signal and
was never bridged to `EventBus.achievement_unlocked`. Everything subscribed to the bus —
the achievement stinger in `UISFX`, the `AudioManager` fanfare, and the new Keeper
captions — therefore only ever heard the four achievements `ProgressTracker` grants
directly. It is also why the two caption rows keyed to `ach_08` / `ach_09`
(`moment_overload`, `moment_photographer`) could never have fired, despite the caption
matcher correctly accepting both id forms. Forwarded to the bus.

## P2 5 — `seeker` had no per-id idempotency — RESOLVED BY 1

`achievements_manager._on_secret_found` has no per-id guard, unlike `ProgressTracker`. With
the respawn bug fixed there is no longer a way to feed it the same secret repeatedly.

## P2 6 — daily `find_secrets` ticked on documents only — ADDRESSED

Raised as "confirm intent, not a confirmed bug". It was correct historically: when that
line was written secrets were unreachable, so documents were the only findable thing. Now
that secrets work, real secret finds tick it too. Documents stay, because there are ~100 of
them against 26 secrets and daily targets run as high as 24 — dropping documents would make
those templates unachievable.

## Verified clean

Recorded so the coverage of this audit is known, not just its findings:

- **Autoload ordering.** `CaptionsManager` (project.godot:110) touches `NewGamePlus` (104),
  `EndingsManager` (107) and `EventBus` (63) in `_ready()` — all earlier, safe.
  `AchievementManager` (91) → `NewGamePlus` (104) and `NoisePropagation` (105) →
  `NewGamePlus` (104) only touch it inside runtime callbacks, never at `_ready()`, so order
  is irrelevant for both. `UISFX`'s `_wire_late_autoloads()` deferral is correct and
  sufficient.
- **Old saves load.** `ProgressTracker.from_dict`, `NewGamePlus._load_save`,
  `CaptionsManager._load_state` and `DailyChallengeManager._load_state` all use `.get()`
  with defaults, so a save predating `secret_ids` / `modifiers` loads without error.
- **Signal arity and String/StringName.** All ten newly connected signals match their
  callable signatures, mixed String/StringName included.
- **`_UI_GAIN_DB`** is looked up with the same short-name key form its call sites use.
- **`DistrictLoot`'s static cache** is content loaded once, not per-run state; the
  suspicion that it could go stale across a New Game did not hold.
- **NG+ knob names** used in code (`battery`, `hunter_hearing`, `loot`, `achievements`) all
  exist in `content/ngp_modifiers.json`.
