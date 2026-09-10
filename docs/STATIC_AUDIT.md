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
   never reaches `EndingsManager`. Status: **WON'T-FIX (RC)** — closed
   2026-09-10 RC final pass, full reachability trace re-run and confirmed:

   Every live `trigger_win()` path requires all 11 districts FULL —
   `power_grid.gd::_check_victory()` (`if not all_restored(): return`
   before the call) and `finale_director.gd::_on_boss_defeated()` (the
   director only arms, and the boss only spawns, once
   `pg.all_restored()` is true, `finale_director.gd:37`). The other two
   `trigger_win()` references are a comment (`boss_3d.gd:212`) and a
   test (`_game_test.gd:59`). So `EndingsManager._determine_ending()`
   always runs with `full == total == 11` ⇒ `truth` / `light` / `hope`
   are the only reachable results; `survivor` (`full == 1`) and `dark`
   (fallthrough) are dead by construction. `trigger_death()` marks
   `Endings._ended` but emits no `game_won`, so `EndingsManager` never
   evaluates on death.

   The 3 reachable endings match GDD §12.4's 3 *completion* outcomes and
   are correctly ordered (`truth` tested first, cannot be masked — see
   CONFIRMED WORKING). Making `survivor`/`dark` reachable is a design
   decision, not a behavior-preserving fix: `survivor` ("только D11",
   GDD §12.4) needs a finale path that fires with a partial grid, which
   contradicts GDD §4.3 ("Все 11 районов FULL → trigger_win()") and
   GDD §12.3 ("точка невозврата: вход в D10") — is the boss even
   reachable without the full grid? not answerable statically. `dark`
   ("смерть/не починена сеть") has no trigger because the game respawns
   (no terminal-death event) and the finale is unreachable without a
   repaired grid. Both need an owner design call; `survivor`/`dark`
   `ENDING_DATA` rows + their `ENDING_*`/`END_*` i18n keys are retained
   for that pass. Also logged: `KNOWN_ISSUES.md`, `PLAN.md` decisions
   log.

## Major (wrong/missing designed behavior, not currency-for-nothing)

7. **`scripts/visual/emissive_windows.gd`** — the live emissive-windows
   implementation is pure one-time randomness in `_ready()`; it never
   reads `PowerGrid`/`district_stage_changed` at all, contradicting its
   own design brief (`docs/CONTENT_DISTRICT_RESIDENTIAL.md`'s "map the
   7th-floor watching window to PARTIAL-on"). Status: **WON'T-FIX (RC)**
   — closed 2026-09-10 RC final pass. The *rendering* path is already
   solved (`scripts/visual/emissive_windows.gd`'s `MultiMeshInstance3D`
   draws real windows in all 11 `scenes/districts/*.tscn` — see
   `PLAN.md` §Б.2). What remains is making lit windows *react* to power
   stage, which needs per-instance MultiMesh colour updates keyed by
   `district_stage_changed` and visual tuning that NO-GODOT static mode
   cannot verify (a wrong guess ships visibly broken windows). GDD §11.1
   names streetlights + ambient grading + moon as the "darkness →
   restored power" reward channels — all three are live and working
   (`KNOWN_ISSUES.md` streetlights entry, `STATIC_AUDIT.md` CONFIRMED
   WORKING); emissive windows are ambient set-dressing, not a named
   reward. Deferred to a Godot-enabled polish pass;
   `emissive_windows.gd`'s `_ready()` is the one wire-up point.
8. **`docs/GDD.md` PARTIAL stage vs `streetlight_3d.gd`** — GDD and
   `power_switch.gd`'s own comment both describe PARTIAL as "some
   streetlights lit," but `streetlight_3d.gd` only distinguishes
   `stage >= 2`; PARTIAL (stage 1) looks identical to DARK for every
   streetlight in every district. Status: **WON'T-FIX (RC)** — closed
   2026-09-10 RC final pass. GDD §4.2 defines PARTIAL as "часть фонарей"
   (some lamps); a per-lamp lit subset is a lighting feature needing
   visual tuning (which lamps, how many, does it read as intentional)
   that NO-GODOT mode cannot verify. PARTIAL is also transient — a
   player's single `power_switch.gd` repair interaction advances
   DARK → STREETS → FULL (`STAGE_MSG_KEYS`), so the game rarely sits at
   stage 1. DARK and FULL — the stages GDD §4.2 ties ambient/moon values
   to and the ones a player actually dwells in — are fully distinct and
   working. Deferred to a Godot-enabled pass; the stage check in
   `streetlight_3d.gd` is the single edit point if a designer wants
   PARTIAL made visible.
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

## From Arena's `docs/CONTENT_PIPELINE_AUDIT.md` re-run (2026-09-09, PR #4)

25. **`police` (district 7) pack cross-checked against both open data
    facts from #21/#22 — confirmed still resolved, nothing new.** Arena's
    audit re-ran districts 1–7 (0 new defects, see its §1/§3.3/§3.4) after
    adding `police`. Verified independently before wiring: (a) topology —
    `district_police.tres powered_by = [park]`, and `police` is *not* a
    leaf (`industrial.powered_by = [warehouses, police]`), consistent with
    #21's "convergent DAG, not a strict chain" conclusion, no `.tres`
    changes needed; (b) music field — `district_themes.gd`'s `police` row
    (`district_themes.gd:34`) has no `"music"` key at all (colour-only, as
    the audit's §5.3 observation states), so the #22 fix already covers
    it — nothing to delete. `world_refs` reachability re-verified by hand
    against `content/world/{history,factions,characters,radio_transcripts}.json`
    and `content/lore/news_clippings.json`: all 16 distinct ids the pack
    references resolve to a `reveal.district` of `suburbs` or `park`
    (0/16 leak to residential/hospital/school/gas_station), matching the
    pack's own closure claim exactly. Status: **VERIFIED, no fix needed.**

## From Arena's `docs/CONTENT_PIPELINE_AUDIT.md` re-run (2026-09-09, PR #5)

26. **`warehouses` (district 8) pack cross-checked against both open
    data facts from #21/#22 — confirmed still resolved, nothing new.**
    Arena's audit re-ran districts 1–8 (0 new defects, see its §1/§3.4)
    after adding `warehouses`. Verified independently before wiring: (a)
    topology — `district_warehouses.tres powered_by = [hospital]`, and
    `warehouses` is *not* a leaf (`industrial.powered_by = [warehouses,
    police]`, `data/districts/district_industrial.tres:8`), consistent
    with #21's convergent-DAG conclusion; (b) music field —
    `district_themes.gd`'s `warehouses` row (`district_themes.gd:35`) has
    no `"music"` key (colour-only), so #22's fix already covers it.
    `world_refs` reachability re-verified by hand against
    `content/world/{history,factions,characters}.json` and
    `content/lore/news_clippings.json`: all 12 distinct ids the pack
    references resolve to a `reveal.district` of `suburbs`, `residential`
    or `hospital` (0/12 leak to park/school/gas_station/police), matching
    the pack's own closure claim exactly — including the three Act II
    Project Architect ids (`char_architect`, `faction_project_architect`,
    `hist_project_architect`, `news_architect_denied`), legitimately
    guaranteed here for the first time since hospital is warehouses'
    required prerequisite, used only at `min_stage >= 2` in the pack.
    Also verified the Arena-side dark-floor edge-repair
    (`tiles/warehouses_floor.png`, its own audit §3.5): the repaired dark
    tile and both new lit twins load cleanly as valid PNGs, within the
    ≤512²/~500KB prop-texture budget (`docs/PRODUCTION_BIBLE.md` §4).
    Status: **VERIFIED, no fix needed.**

## From Arena's `docs/CONTENT_PIPELINE_AUDIT.md` re-run (2026-09-09, PR #6)

27. **`industrial` (district 9, first two-parent convergence) pack
    cross-checked against both open data facts from #21/#22 — confirmed
    still resolved, nothing new.** Arena's audit re-ran districts 1–9
    (0 new defects — its own §3.6 traced 4 initial audit-script false
    positives to checker regex bugs, not pack content, and fixed them
    tooling-side). Verified independently before wiring: (a) topology —
    `district_industrial.tres powered_by = [warehouses, police]`, a
    genuine two-parent convergence (both required at FULL per GDD §4.3,
    not either), consistent with #21; (b) music field —
    `district_themes.gd`'s `industrial` row has no `"music"` key
    (colour-only). `world_refs` reachability re-verified by hand: all 22
    distinct ids the pack references resolve to a `reveal.district` of
    `suburbs`, `residential`, `park` or `hospital` (0/22 leak to
    school/gas_station/substation/power_station) — exactly the
    six-district union closure the pack claims (both parent branches
    walked to their own root). The 4 Act II Architect ids and the 9
    Keeper/radio ids are both legitimately used together for the first
    time (this is the first district reachable via both branches at
    once); Architect ids stay at `min_stage >= 2` matching their own
    gate. Status: **VERIFIED, no fix needed.**
28. **`content/districts/industrial/lore_notes.json`'s `en.text` fields
    contain a literal double-escaped `\"` (backslash + quote) instead of
    a plain `"` wherever a note quotes in-world dialogue** — confirmed
    in all 8 notes (`industrial_note_01` through `_08`), absent from
    every prior district's equivalent file (checked `warehouses` as a
    control: uses plain `"` throughout). This is a content-source
    authoring artifact, not a code bug — the raw JSON is Arena's
    reference source for what to translate, not what ships to players;
    the actual in-game text lives in `data/i18n/*.json` under the
    `LORE_INDUSTRIAL_*` keys. Status: **WORKED AROUND** — wrote the
    i18n key content with the stray backslashes stripped (clean quotes),
    so no player ever sees the artifact; not hand-edited in
    `content/districts/industrial/lore_notes.json` itself since that
    file is outside this session's ownership zone (`content/**` is
    Arena's). Logged as an open question in `docs/HANDOFF.md` for Arena
    to clean up the source file's escaping in a future pass — cosmetic
    only, no further action needed from CODE.

## From Arena's `docs/CONTENT_PIPELINE_AUDIT.md` final release certificate (2026-09-09, PR #7)

29. **`substation` (D10) and `power_station` (D11, chain terminal) packs
    verified against the full closure chain — the last two districts,
    completing 11/11.** Arena's audit ran a final 1–11 re-run (0 defects
    — 2 initial checker-tooling false positives found and fixed, not
    pack issues) plus a 15-point CONTENT RELEASE CERTIFICATE. Verified
    independently rather than trusted: (a) `district_substation.tres
    powered_by = [industrial]`, closure = industrial's own six-district
    union plus industrial itself (seven districts); (b)
    `district_power_station.tres powered_by = [substation]`, closure =
    substation's seven plus substation itself (eight districts) — every
    packed district except the two confirmed-terminal leaves
    (school/gas_station). Hand-checked all `world_refs` in both packs
    (18 distinct substation ids, 20 distinct power_station ids): 0 leaks
    outside each closure. `radio_02_grid_crew_relay` (gate:
    substation/min_stage 1) used at `substation_note_07`/min_stage 2 —
    respects the gate; `radio_03_keeper_reversal` (gate: power_station/
    min_stage 1) used at `power_station_note_03`/min_stage 1 — meets the
    gate exactly, the pack's intentional finale front-load. Independently
    re-counted note/fixed-spawn ids across all 11 packs: 88 notes, 103
    fixed spawns, both 100% unique (matches the certificate). Both new
    item ids (`transformer`, used as an optional-salvage fixed spawn in
    both packs) verified to exist in `data/items/*.tres`. Status:
    **VERIFIED, no fix needed.**
30. **Power_station's `reactor_power_station` puzzle citation
    (`puzzle_system.gd:29`, `reward: "ending"`) traced read-only per the
    merge directive's step 2 — confirmed the pack does not touch
    endings logic, and confirmed no endings-logic change was made here
    either.** `_grant_reward()`'s `"ending"` branch only emits a toast
    ("Reactor online!"); no ending is triggered directly by
    `puzzle_system.gd` — victory is `PowerGrid._check_victory()`
    (all 11 districts FULL) → `GameManager.trigger_win()`, unrelated to
    this dictionary. Status: **CONFIRMED READ-ONLY, no code change
    needed** (satisfies the merge directive's explicit "no ending logic
    changes" instruction).
31. **`puzzle_system.gd`'s `_puzzle_data` reward economy (coins/battery/
    medkit/ending, one entry per district, cited as canon by every
    content pack's `item_spawns.json`) is reachable for only 1 of 11
    districts.** Traced the full call graph: `PuzzleSystem.start_puzzle()`
    (the only entry point that leads to `mark_solved()` → `_grant_reward()`)
    has exactly one live, non-test caller in the entire codebase —
    `cable_box_interactable.gd`, a single hardcoded instance
    (`PUZZLE_ID = "fuse_substation"`) placed only in
    `scenes/districts/substation.tscn` (added in an earlier "WAVE 6 P3"
    pass to fix a previously-uncompletable quest objective). The other
    10 `_puzzle_data` entries (`generator_suburbs`, `fuse_residential`,
    `transformer_park`, `switch_school`, `generator_hospital`,
    `fuse_gas_station`, `transformer_police`, `switch_warehouses`,
    `generator_industrial`, `reactor_power_station`) have no interactable
    node anywhere that calls `start_puzzle()` with their id — nothing
    reaches them. This is **separate from and does not affect the core
    district-restoration loop**, which is fully live for all 11
    districts via `power_switch.gd` (item-cost repair, its own
    independent `DISTRICT_RESTORED_TOAST`/`puzzle_solved` emission,
    already `CONFIRMED WORKING` below) — a player restores every
    district normally regardless of this finding. What's unreachable is
    a separate bonus layer (extra coins/battery/medkit/a "Reactor
    online!" flourish) that 10 content packs describe as their
    district's "puzzle canon" believing it live. Status: **DOCUMENTED,
    not fixed** — a real design decision, not a one-line bug: either (a)
    build 9 more `cable_box_interactable`-style nodes + district scene
    edits (real scene-editing work, higher risk without visual
    verification, same class the suburbs wave already declined to
    attempt blind), or (b) wire `power_switch.gd`'s own FULL-completion
    path to additionally call `PuzzleSystem.mark_solved()` with each
    district's canonical id (the minimal code-only fix candidate, but
    changes what every player receives on every district completion —
    a balance/design call, not mine to make unilaterally). Deferred
    pending that decision; not blocking the IDEAL BAR since the core
    loop is unaffected and this predates the current content pipeline
    entirely.
    **Status update — WON'T-FIX (RC), closed 2026-09-10 RC final pass.**
    Neither path (a)/(b) is "simplest behavior-preserving": (a) can't be
    visually verified in NO-GODOT mode; (b) changes the reward economy
    for every player on every completion, which GDD §3.3/§8 balance owns.
    Core restoration (GDD §4.2/§4.3, live `power_switch.gd`) and victory
    (GDD §12.4, all 11 FULL) are unaffected. The 10 unreachable
    `_puzzle_data` rows stay as forward-looking design data (content
    packs cite them). **What the RC pass fixed in `puzzle_system.gd`:**
    the four `_grant_reward()` toasts — live today for the one wired
    puzzle (`fuse_substation`) — were hardcoded English, now localized
    (`TOAST_COINS_GAINED`/`TOAST_ITEM_FOUND`/`TOAST_REACTOR_ONLINE`, ×13
    locales); and the redundant `_on_district_restored` handler, which
    fired a second untranslated "District restored!" toast alongside
    `power_switch.gd`'s already-localized `DISTRICT_RESTORED_TOAST` on
    every FULL restore, was deleted — one localized toast per restore
    now, not two.
32. **Audio finding F1 (Arena's, independently re-verified): two
    power_station detail one-shots are off the 30.000 s class every
    other detail bed holds** — `power_station_generator_thrum.ogg`
    (28.749 s) and `power_station_cooling_fan.ogg` (28.948 s), both
    confirmed via direct Ogg-container final-page-granule parsing (same
    method as the industrial_dark.ogg check, #22/KNOWN_ISSUES.md). Both
    loop (`loop = true`) and no code reads or assumes a duration for
    detail beds (`district_atmosphere.gd` grepped, confirmed). Same
    reasoning as the industrial bed length: not my ownership zone
    (`assets/audio/**`), no functional risk either way. Status:
    **DOCUMENTED, not fixed** — re-render is the audio toolchain
    holder's call, not blocking.

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
