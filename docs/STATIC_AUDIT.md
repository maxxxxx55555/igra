# Static Audit — defect register

No-Godot RC pass, 2026-09-08. Verification method for every entry: read the
source as text, trace callers/callees and signal graphs by hand, cross-check
ids against `data/`/`content/`/`docs/GDD.md`. No entry here was confirmed by
running the engine — see each fix's own note for what a human should click to
confirm in-game (also collected in the HUMAN 5-MINUTE CHECK at the bottom of
each PLAYER_VISIBLE_CHANGES.md batch).

Status legend: OPEN / FIXED (commit hash) / DOCUMENTED (accepted, not fixed
— reason given).

---

## Severe (gameplay-breaking or currency-for-nothing)

1. **`scripts/ui/ending_screen.gd:81-85`** — a dead, never-shown UI node's
   `_unhandled_input` is unconditionally live (its own early-return guard
   depends on `_tween`, which is only set by `show_ending()`, and nothing
   ever calls `show_ending()`). It listens on `ui_cancel` (Godot's default
   Escape binding, never overridden in `project.godot`) and on every
   Escape press calls `Endings.mark_ended()` + `Routes.to_menu()` — a raw
   scene-file `change_scene_to_file` that bypasses `GameManager`. This
   fires *alongside* the real pause menu's own Escape handler (neither
   calls `set_input_as_handled()`), so every Escape during normal
   gameplay would both open Pause AND yank the player to the main menu.
   Found by static trace (parallel Explore agent), not by playing.
   Status: **FIXED**.
2. **`scripts/systems/skill_tree_manager.gd`** — `max_health`,
   `stamina_boost`, `battery_capacity` skills call
   `player.set_max_health/set_max_stamina/set_max_battery`, none of which
   exist anywhere in the codebase (`grep -rn "func set_max_health"` etc. →
   zero hits). `has_method()` always returns false, so these three skills
   cost real skill points and do *nothing*, in every session, not just
   after a reload. Status: **FIXED** (direct resource-field mutation,
   matching the already-working `move_speed` pattern; `player.stats` is
   `resource_local_to_scene = true` per `scenes/player/player_3d.tscn`,
   confirmed safe to mutate per-instance).
3. **`scripts/systems/skill_tree_manager.gd::load_data()`** — runs during
   `SaveSystem`'s data-parse phase, *before* the player node exists
   (`world_runtime.gd`'s `_place_player()`, which consumes the loaded
   position, runs later during district-scene build). Its effect-replay
   loop calls `_apply_skill_effect()`, which starts with
   `get_tree().get_first_node_in_group("player"); if not player: return`
   — silently a no-op at load time. Every "push once" skill
   (`max_health`, `stamina_boost`, `battery_capacity`, `move_speed`,
   `inventory_space`, and the new `light_radius`) is therefore reset to
   its unboosted base on every Continue, even though `_unlocked_skills`
   itself (and the "read live" skills — `xp_boost`, `silent_steps`,
   `cold_trail`) survive correctly. Root cause, not the secondary
   "only replays 1 of N levels" bug also present in the same loop.
   Status: **FIXED** (moved the replay to `player_3d.gd`'s own `_ready()`,
   which runs exactly once per session after the player node exists;
   fixed the N-levels replay in the same change).
4. **`scripts/weapons/weapon_base.gd` / `skill_tree_manager.gd`** —
   `damage_boost_1`, `damage_boost_2`, `crit_chance`, `fire_rate`,
   `reload_speed` are purchasable (real cost) but nothing in the weapon
   system ever reads `SkillTreeManager.get_skill_level()` for any of them
   (`grep -rn "get_skill_level" scripts/weapons/` → zero hits before this
   fix). Same "pay for nothing" class as #2. Status: **FIXED**.
5. **`scripts/systems/skill_tree_manager.gd`** — `health_regen`,
   `light_radius`, `loot_luck` also purchasable, also never read anywhere
   (`grep -rn "health_regen|light_radius|loot_luck" scripts/` outside the
   skill tree/UI files → zero hits before this fix). Status:
   `health_regen`/`light_radius` **FIXED**, `loot_luck` **FIXED**.
6. **`scripts/systems/endings_manager.gd`** — of GDD's 5 endings, only
   Light/Hope/Truth are reachable; `survivor` and `dark` are dead
   branches. `_determine_ending()` only ever runs after
   `PowerGrid.all_restored()` is already true (both call paths —
   `GameManager.trigger_win()` and `FinaleDirector`'s boss defeat — are
   gated on it), so `full >= total` is always true by construction,
   making the `full == 1` (`survivor`) and fallback (`dark`) branches
   unreachable; `trigger_death()` never emits `game_won` at all, so death
   never reaches `EndingsManager`. Status: **DOCUMENTED** — real fix
   requires a design decision (when exactly is "Survivor" supposed to
   trigage, and should death show a real "Dark" ending screen instead of
   the current static death screen) that this pass isn't authorized to
   invent; logged in KNOWN_ISSUES.md and PLAN.md decisions log instead of
   guessed at.

## Major (wrong/missing designed behavior, not currency-for-nothing)

7. **`scripts/visual/emissive_windows.gd`** — the live emissive-windows
   implementation is pure one-time randomness in `_ready()`; it never
   reads `PowerGrid`/`district_stage_changed` at all, contradicting its
   own design brief (`docs/CONTENT_DISTRICT_RESIDENTIAL.md`'s "map the
   7th-floor watching window to PARTIAL-on"). Status: **DOCUMENTED** —
   see reasoning below (this entry's fix would need per-instance
   MultiMesh color updates keyed by stage, a real feature, not a
   one-line wire-up; flagged rather than rushed).
8. **`docs/GDD.md` PARTIAL stage vs `streetlight_3d.gd`** — GDD and
   `power_switch.gd`'s own comment both describe PARTIAL as "some
   streetlights lit," but `streetlight_3d.gd` only distinguishes
   `stage >= 2`; PARTIAL (stage 1) looks identical to DARK for every
   streetlight in every district. Status: **DOCUMENTED** (same reasoning
   as #7 — a real per-lamp partial-lighting feature, not a wire-up).
9. **`scripts/world_env_setup.gd:133-134`** — the single global
   `WorldEnvironment`/`Moon`/`PlayerGlow` handler reacts to
   `district_stage_changed` from *any* district, not just the one the
   player is standing in (missing the `district_id == current` guard its
   siblings `district_grading.gd`/`music_manager.gd` both have).
   Restoring a district the player isn't in currently overwrites the
   correct global lighting for wherever they actually are. Status:
   **FIXED**.
10. **`scripts/inventory/inventory_manager.gd:198-215`** — regular
    inventory slots restore without checking the item id still exists in
    `ItemDatabase` (equipment slots do check). A renamed/removed item id
    becomes a permanent blank "ghost" slot eating capacity forever.
    Status: **FIXED**.
11. **`scripts/core/endings.gd:7`** — `TOTAL_DOCUMENTS = 13` predates the
    suburbs/residential/park lore-note additions (24 more document ids via
    `DistrictLoot.LORE_DOCS`); "collect all documents" is now trivially
    satisfiable from the first two districts alone, long before real
    completion. Status: **FIXED** (computed from the live spawn tables
    instead of a hand-typed constant).
12. **`scripts/core/save_system.gd:264,266`** — save-slot UI always shows
    "Level: 1" and the 1970-01-01 epoch date: `current_scene` is read for
    the level field but never written to the save payload, and
    `modified` is hardcoded `0.0` instead of reusing the `timestamp`
    field that *is* saved. Status: **FIXED**.

## Minor

13. `scripts/world_env_setup.gd`'s `_sync_stage_from_grid()` — dead code,
    guard condition can never be true since `DistrictManager.get_stage()`
    now purely proxies `PowerGrid.get_stage()` (both sides of its `>`
    comparison are always equal). Status: **FIXED** (deleted the function
    and both call sites — confirmed 100% no-op, safe to remove).
14. `scripts/world/power_grid.gd`'s `reset()`/`from_dict()` mutate stage
    without emitting `district_stage_changed` (unlike `advance_district`/
    `_set_stage_direct`) — not reachable from real Continue/New-Game
    (those always rebuild the scene tree via `Routes.goto()`, so `_ready()`
    re-reads the correct stage anyway) but a real API asymmetry. Status:
    **DOCUMENTED** (latent, unreachable in current player-facing flows).
15. `scripts/world/ftue_generator_3d.gd:21` — redundant duplicate
    `district_stage_changed` emission for the tutorial generator (the
    call it follows already emits it internally). Harmless (every
    listener is idempotent for a repeated identical value) but stale.
    Status: **FIXED** (deleted, trivial/free).
16. `scripts/world/puzzle_base.gd` — dead `Area2D` script (wrong node
    type for this 3D game besides being unreachable; `scenes/props/
    puzzle.tscn` is never instanced). Same "don't delete, might be
    planned" treatment as the already-documented `streetlight.gd`
    fossil. Status: **DOCUMENTED** in `KNOWN_ISSUES.md`.
17. `scripts/world/emissive_windows.gd.uid` — orphaned sidecar file left
    behind after the dead `scripts/world/emissive_windows.gd` (not
    `scripts/visual/...`, the live one) was deleted in an earlier wave.
    Status: **FIXED** (deleted — this one really is pure litter, no
    "might be planned" ambiguity for a `.uid` with no matching script).
18. `scripts/systems/weather_system.gd:23` — calls
    `LocalizationManager.t()` from its own `_ready()`, which runs before
    `LocalizationManager`'s `_ready()` since it's declared earlier in
    `project.godot`'s autoload list; currently harmless (no listener
    displays the returned name string). Status: **DOCUMENTED** (harmless
    today, flagged so nobody assumes the string is safe to start showing
    without also deferring this call).
19. 12 UI files build translated text once with no live-language-switch
    retranslation hook (found via a systematic grep sweep of all of
    `scripts/ui/`, cross-checked against the already-fixed set from
    earlier passes): `stats_ui.gd`, `achievements_ui.gd`, `codex_ui.gd`,
    `win_screen.gd`, `new_game_plus_ui.gd`, `screens.gd` (the shared
    "Close" button used by ~9 screens), `quest_tracker_hud.gd`,
    `tutorial_system.gd`, `minimap.gd`. Status: **FIXED** (all 9 files).
    `scripts/death_screen.gd` (the root-level file, not `scripts/ui/
    death_screen.gd`) has the same bug but is dead code — nothing
    instances `scenes/ui/death_screen.tscn`; the live death screen
    (`scripts/ui/death_screen.gd`) was already fixed in an earlier pass.
    Status: **DOCUMENTED** (dead code, not touched).
20. `content/districts/{suburbs,residential,park}/item_spawns.json` —
    authored stage-gated loot tables, fixed spawns and solvability rules
    are never read by any script (`grep -rln "item_spawns"` under
    `scripts/`/`tools/` → zero hits). `district_loot.gd`'s own
    `REPAIR_PARTS` (2× cable/fuse/transistor, unconditional, every
    district) already guarantees the same puzzle-solvability goal these
    files' `fixed_spawns`/rules describe, via an older, simpler,
    already-working mechanism — so this is a dead-content mismatch, not
    a solvability bug. Status: **DOCUMENTED** — wiring the JSON stage
    tables would mean replacing a working flat spawn system with a new
    stage-aware one; out of scope for a defect-fix pass (would be a new
    system, not a fix).

---

## From Arena's `docs/CONTENT_PIPELINE_AUDIT.md` (2026-09-08, PR #3)

21. **`school`/`gas_station` are leaves of the `powered_by` graph, and
    GDD §4.1's chain text doesn't literally match `data/districts/*.tres`
    from `park` onward** — verified: GDD §4.1 lists a single arrow-chain
    (`suburbs → residential → park → school → hospital → gas_station →
    police → warehouses → industrial → substation → power_station`), but
    the actual `.tres` topology already branches and reconverges before
    this pass touched anything (`park`/`residential` both `powered_by =
    [suburbs]`; `industrial powered_by = [warehouses, police]` — a
    genuine two-parent convergence). This branching predates both Arena's
    and this session's content work; nothing school/gas_station-specific
    was newly introduced. Conclusion: the `.tres` graph is the intentional
    design (a convergent DAG, not a strict chain), and GDD §4.1's prose is
    a narrative/display ordering, not a literal unlock-dependency spec —
    victory still requires all 11 at FULL regardless of graph shape, so a
    leaf district isn't a "cannot complete" bug, just one that gates
    nothing downstream. Status: **DOCUMENTED** (not a defect — verified
    intentional; `.tres` files left untouched. Rewriting the graph to
    match a strict chain would invalidate Arena's own already-audited
    `world_refs` reveal-gate closures in `CONTENT_PIPELINE_AUDIT.md` §3.4,
    which were computed against the real branching topology).
22. **`district_themes.gd`'s per-district `"music"` field disagreed with
    `music_manager.gd`'s `AMBIENT_BY_DISTRICT`** for `school`/`hospital`/
    `gas_station` (e.g. `district_themes.gd` said `residential.wav` for
    `school`; `music_manager.gd` said `abandoned_hallways_alt.mp3`).
    Traced both: `district_themes.gd["music"]` is read NOWHERE
    (`get_theme()`/`apply_to_environment()` only use `sky`/`ambient`/
    `accent`) — confirmed dead, and its values were suspicious copy-paste
    (5 unrelated districts all said `residential.wav`). `music_manager.gd`'s
    `AMBIENT_BY_DISTRICT` is itself a documented fallback, unreachable in
    practice since `AMBIENCE_DARK_BY_DISTRICT`/`AMBIENCE_LIT_BY_DISTRICT`
    already cover all 11 districts. Neither disagreeing value was
    actually live. Status: **FIXED** — deleted the dead `"music"` key
    from every `THEMES` entry rather than pick a "winning" value for a
    field nothing consumes; the real per-district audio source of truth
    stays `AMBIENCE_DARK_BY_DISTRICT`/`AMBIENCE_LIT_BY_DISTRICT`.
23. **`content/districts/suburbs/item_spawns.json` could not reach FULL
    from its own guaranteed spawns** (no transistor in its DARK table,
    only cable/fuse) — found and fixed by Arena's own audit before this
    merge (added `suburbs_fix_puzzle_04`, 2× transistor). No CODE action
    needed: `item_spawns.json` is still unread by any script (#20 above),
    so this was a content-only fix to data nothing currently consumes;
    logged here for completeness since it's Arena's own audit result.
24. **`park_note_05` referenced a residential-gated character
    (`char_babka_manya`) from a district reachable without residential**
    — found and fixed by Arena's own audit (cleared `world_refs` to
    `[]`) before this merge. Worth flagging a real gap this exposed in
    `WorldBible.is_revealed()`: it checks `stage >= min_stage`, and every
    district defaults to stage `DARK` (0) whether or not the player has
    ever visited it — so a `min_stage: 0` reveal is trivially "revealed"
    for a district the player hasn't reached, not just one they have.
    Not a live bug today (Arena's content audit already avoids relying on
    it, and the merged `school`/`hospital`/`gas_station` packs pass the
    same closure check per their own audit §3.4/§4), but the primitive
    itself doesn't enforce "has visited," only "stage progressed." Status:
    **DOCUMENTED** — a real fix (checking district visitation, not just
    stage) is a small addition but touches a shared lookup used by two
    live features (journal Related-lines, radio unlocks); deferred rather
    than risk it without being able to compile-check the change, per this
    pass's no-Godot constraint. Content-side discipline (§3.4's rule) is
    the actual guardrail in place today.

## CONFIRMED WORKING (traced this pass, no defect — do not re-audit)

- `power_switch.gd::interact()`/stage-advance chain, `REPAIR_COST` vs
  `district_loot.gd`'s `REPAIR_PARTS` stock — matches exactly.
- `district_grading.gd`'s ambient-per-stage table vs GDD §4.2/§11.1.
- `quest_manager.gd`/`achievements_manager.gd`'s `district_restored`
  handling (correctly FULL-gated, idempotent).
- Settings: all 5 quality-preset setters hit real, valid RenderingServer/
  Viewport/Environment/Engine/Window APIs; `_find_environment()` null-
  checked at both call sites; all 5 audio buses (Master/Music/SFX/Voice/
  Ambient — Voice *is* in `default_bus_layout.tres`, correcting an
  earlier session's note) resolve without duplicate-bus growth; language
  switch signal chain (`SettingsManager.set_language` →
  `LocalizationManager.set_language` → `language_changed.emit()`) is
  sound; autoload boot order poses no crash risk (`LocalizationManager.t()`
  has a safe empty-dict fallback).
- Save/load: every read in `save_system.gd` uses `.get(key, default)`,
  zero raw indexing; `PowerGrid`/`QuestManager`/`UpgradeSystem.from_dict`
  all degrade gracefully on a removed/renamed id; save payload is fully
  locale-independent (ids/codes only, no translated text); `reset_all()`
  still correctly resets XP + skills.
- `EndingsManager`'s Truth/Light/Hope ordering (`if` chain, Truth checked
  first so it can't be masked).
- `weapon_compare_ui.gd`, `ad_popup.gd`, `craft_station.gd`,
  `ending_screen.gd`'s *content* logic (`_apply_kind`, separate from its
  input-handler bug above), `onboarding.gd`/`onboarding_overlay.gd`,
  `boot_loading.gd` — all rebuild translated text fresh at time of use.
