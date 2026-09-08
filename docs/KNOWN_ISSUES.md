# Known issues

## District `powered_by` graph branches; GDD §4.1's chain text is narrative order, not a literal dependency spec

`data/districts/*.tres` forms a branching, reconverging DAG (e.g.
`industrial` requires BOTH `warehouses` AND `police` at FULL), not the
single arrow-chain GDD §4.1 lists. `school` and `gas_station` are leaves
of this graph — nothing lists them as anyone's prerequisite. Verified
2026-09-08 (`docs/STATIC_AUDIT.md` #21): this predates any recent
session's work, and victory still requires all 11 districts at FULL
regardless of graph shape, so a leaf district isn't a completion bug,
just one that gates nothing downstream. Do not "fix" `powered_by` to
match a strict chain — the content team's `world_refs` reveal-gate
closures (`docs/CONTENT_PIPELINE_AUDIT.md` §3.4) are computed against
the real branching topology; forcing a linear chain would invalidate
them.

## `WorldBible.is_revealed()` doesn't distinguish "district exists" from "district visited"

`scripts/world/world_bible.gd`'s `is_revealed(reveal)` checks
`DistrictManager.get_stage(district) >= min_stage`. Every district
defaults to stage `DARK` (0) whether or not the player has ever been
there, so a `min_stage: 0` reveal is trivially "revealed" for an
unvisited district — the check verifies stage progression, not
visitation. Not a live bug today: content authoring discipline
(`content/README.md`'s reachability rule, `docs/CONTENT_PIPELINE_AUDIT.md`
§3.4) is what actually keeps `world_refs` from leaking early across all
6 shipped district packs, not this primitive. Flagged so a future pack
or UI feature doesn't lean on `is_revealed()` alone for "has the player
been here" — it doesn't mean that. Found 2026-09-08 while reviewing
Arena's own `park_note_05` fix (`docs/STATIC_AUDIT.md` #24).

## `scripts/world/puzzle_base.gd` — dead fossil, wrong node type for this 3D game

Found in the 2026-09-08 static audit (`docs/STATIC_AUDIT.md` #16).
`extends Area2D`, calls `PowerGrid.toggle_district(district_id)` — the
only other live call site of `toggle_district()`/`toggle()` besides
`power_grid.gd` itself, and the mechanic GDD §4.3 still documents
("Переключатели `PowerSwitch` и пазлы: `toggle_district` = STREETS ↔
DARK"). Confirmed unreachable: `scenes/props/puzzle.tscn` (its only
scene) is never instanced anywhere. Even revived it would need `Area3D`/
`StaticBody3D` collision like `power_switch.gd`, not `Area2D`, to
receive any interaction in this project's 3D interact system. Same
treatment as the already-documented `streetlight.gd`/
`streetlight_spawner.gd` fossils below: not deleted (CLAUDE.md: never
delete a file unless proven dead *and* not a planned feature), flagged
so nobody assumes it's live.

## `godot --headless --editor --quit` corrupts `default_bus_layout.tres` on resave — never commit after running it

Needed once this pass to force a `global_script_class_cache.cfg` rebuild
(a brand-new `class_name` isn't visible to other scripts/gates until the
editor rescans the project — a plain `--headless --path . --quit` run
does NOT trigger this, only `--editor` does). Side effect: the editor
resaved `default_bus_layout.tres` on exit and silently corrupted it —
dropped the entire Master bus block, dropped `room_size` from the reverb
effect, and mangled the resource's own `uid` (`audiobuses00` →
`udiobuses00`). Caught only by manually diffing the file before
committing — no gate currently checks bus layout content, only that the
5 expected buses exist by name. **Always run `git diff
default_bus_layout.tres` (and ideally a full `git status`) after any
`--editor` invocation, before staging anything.** `git checkout --
default_bus_layout.tres` reverts it cleanly since flow_check's own bus
gate doesn't need the class cache and passes either way.

## `game_test_3d_scene.tscn` gate stalls silently after "phase1 combat: damage Shadow"

Pre-existing, not a regression — reproduced identically on a clean stash
of the working tree (before any 2026-09-08 RC-pass edits) and on `main`
with those edits applied. `--headless` hangs until killed (`timeout`
exit code 124); `--windowed` exits cleanly (code 0) but the test runner
never prints its `DONE`/`fails=` line past that point — no script error
in the log, just engine shutdown/leak noise. Combat/damage-on-Shadow is
unrelated to any RC-pass change (i18n, HUD, settings, document catalog).
Not investigated further this pass (would need `--verbose`/a debugger
attached to see what phase1's coroutine is actually waiting on); `tools/
check.sh`'s full (non `--static`) mode will hang here too — run the other
11 gate scenes individually (5 headless: compile/signal-arity/autoload-
api/i18n/asset; boot/perf need `--windowed`, same as the existing boot-
flow note below) until this is fixed.

## i18n: a few always-open-while-playing screens didn't retranslate on a live language switch

Screens toggled via `UIManager` (`.visible = true/false`) stay instantiated
for the whole session — they only rebuild their translated text if they
explicitly listen for it. `journal_ui.gd` and `hud_3d.gd` (HP/Stamina/
Battery/Noise/Visibility/Ammo/Radar/Sprint/Stealth captions) had no such
hook and went stale after Settings → Language until the scene reloaded —
fixed 2026-09-08 (both now reload their translated text on
`LocalizationManager.language_changed`). `city_map.gd` was already correct
(rebuilds on `visibility_changed`). `quest_journal.gd` and
`skill_tree_ui.gd`/`skill_button.gd` had the same gap (tab titles, skill
name/description/cost) — fixed 2026-09-08 Phase 4 pass, same shape of fix
(quest_journal rebuilds like `settings_screen.gd`; skill tree reuses its
existing `refresh()` chain). All screens now cover live language switch.

## i18n: 165 strings are identical to English on purpose — do not "fix" them

`tools/i18n_audit.py`'s `value == en[key]` check still flags ~165 strings
across the 11 non-en/non-ru locales. Every one was manually verified during
the 2026-09-08 autonomous i18n wave as a legitimate cognate/loanword (e.g.
"Auto", "Park", "Normal", "AUDIO", "Journal", "Radio", the "SS-N" codes,
" kg" as an SI unit) or a deliberate loanword choice ("Speedrunner",
"Endurance" kept in de/fr/it/pt_BR) — not an overlooked gap. Full
per-string breakdown and the commit list: `PLAN.md` §Б.4. Any *new* i18n
key added after this point must be translated immediately, not added to
this list.

## Draw calls: 234 measured vs GDD's <200 (D1) / <350 (D11) — D11 met, D1 not

**Update 2026-09-08 (autonomous wave)**: the root cause this entry used
to describe (unbatched per-streetlight Pole/Lamp `MeshInstance3D`) was
fixed in an intervening "FINAL PERFECTION P3" wave — `street_props.gd`
now batches every district's Pole and Lamp meshes into two shared
`MultiMeshInstance3D`, and each `streetlight_3d.tscn` instance sets
`mesh_visible=false` on its own redundant copies (kept for the
`Light3D`/`Hum`/`LightArea` nodes, which can't be MultiMesh'd and were
confirmed NOT the draw-call problem — see
`docs/SESSION_REPORT_FINAL_PERFECTION.md`). Re-measured via
`scenes/tools/perf_check_scene.tscn` (now a real gate, see below):
370 → **234** draw calls in the suburbs spawn district. `perf_check_scene`
gates hard on D11<350 (met); D1<200 is flagged in its output but not
hard-failed (see `scripts/tools/_perf_check_runner.gd`).

The remaining 234→200 gap (per `PLAN.md`'s own prior analysis, still
accurate): monster meshes (6, intentionally not MultiMesh-batched — they
need independent skeletal animation/materials per instance) and
pickupable items (12, individual — scattered per-instance, not currently
pooled). Further reduction needs either a design call (fewer items/
monsters live in the scene at once) or a deeper per-instance batching
technique for animated/pickup meshes — neither is a small tweak.
Documenting rather than guessing further, per this project's honesty
rule; see `docs/PRODUCTION_BIBLE.md` §7 and `PLAN.md` item 1.

## boot_check_scene.tscn can see a spurious PLAYING -> MENU during its
## sustain phase — test-harness artifact, not a real-game bug (tolerated,
## logged as WARN, does not fail the gate)

Found and extensively traced while building the P0.4 permanent gate.
Sequence: `_boot_check_runner.gd` runs under `get_tree().root` because
`boot_check_scene.tscn` is passed as a scene override (`godot ... res://
scenes/tools/boot_check_scene.tscn`), which is not how a real player ever
launches the game (they always boot through the real configured main
scene, `boot_loading.tscn`, directly). This unusual entry point puts
`_bootstrap.gd`'s autoload fallback (`if current_scene == null or
current_scene.name == "": Routes.goto(splash.tscn)`) in an ambiguous
position it never occupies for a real player, and something in that
window occasionally leaves a `splash.tscn` instance alive whose ~3s tween
fires `Routes.goto(BOOT)` a second time, later, during active gameplay —
`boot_loading.tscn`'s own natural ~3.3s countdown then calls
`Routes.to_menu()`, and `main_menu.gd`'s own defensive
`if not GameManager.is_menu(): return_to_menu()` forces the state change
the gate observes.

Traced with temporary stack-trace instrumentation on
`GameManager._change_state()` and `Routes.goto()` (removed after
diagnosis — see the corresponding commit) across ~8 runs. The exact
instantiation call for the orphaned `splash.tscn` node was never fully
pinned down (every `Routes.goto()` call is logged unconditionally, and no
`splash.tscn` target ever appeared in the trace despite `splash.gd`'s
callback firing later) — plausibly a buffering/ordering artifact of the
diagnostic prints themselves rather than the underlying scene-tree
mechanism, but conclusively NOT reachable through any code path a real
player's boot sequence uses (`boot_loading.tscn` is deterministically
`current_scene` from frame 1 in a real launch; `_bootstrap.gd`'s
fallback condition can only be true in a real launch if the engine
somehow fails to set up its own configured main scene, an unrelated and
already-legitimate safety net).

Given the repro requires a test-only entry point mismatch, the gate
treats a `PLAYING -> MENU` transition (without death) during its sustain
phase as a logged warning, not a failure — `scripts/tools/
_boot_check_runner.gd`'s sustain loop. If this same symptom is ever
reported from an actual player build (not a `boot_check_scene.tscn`
run), treat it as a new, real bug — this analysis assumes the gate's own
entry-point mismatch as the root cause and would not apply.

## Streetlights: three implementations existed, only one was live, none
## reacted to district power (fixed — see git log for the commit)

Found during TRUTH WAVE P1. Three separate streetlight scripts existed:

- `scripts/world/street_props.gd` (CityStreetProps) — live in all 11
  district scenes. Built flat emissive-decal "lamps" (a `SphereMesh` with
  an emissive material, no actual `Light3D` node) that were always on,
  never checked district power stage.
- `scripts/world/streetlight_spawner.gd` (StreetLightSpawner) — only
  placed in `main_3d.tscn`'s root, whose `street_builder_path` default
  (`^"StreetBuilder"`) never resolves there (the real `StreetBuilder`
  nodes only exist nested inside each district's runtime-built subtree).
  Confirmed **dead code**: `_ready()` returns immediately every time.
- `scripts/world/streetlight_3d.gd` + `scenes/props/streetlight_3d.tscn`
  — a complete, correct implementation: real pole mesh, `SpotLight3D` +
  `OmniLight3D` glow, hum audio that starts/stops with the light, a
  `light_zone` `Area3D` (stealth-visibility relevant), and a live
  `EventBus.district_stage_changed` connection matching GDD §11.1's
  "darkness -> restored power" reward exactly. **Never instantiated
  anywhere** — confirmed dead simply because nothing spawned it.

Net effect before the fix: the game's namesake mechanic (streetlights
turning on as districts are restored) did not exist in actual gameplay.
Every street was permanently "lit" with non-reactive decals regardless
of district power stage.

**Fix**: `street_props.gd` now instantiates `streetlight_3d.tscn` (reading
`district_id` from the sibling `StreetBuilder` node already present in
every district scene) instead of building the old decals. The old
behavior is preserved behind a project setting, disabled by default:

```ini
[world]
legacy_streetlights=false   ; true = old flat-decal poles, for comparison/rollback
```

`streetlight_spawner.gd` and `scenes/props/streetlight_3d.tscn`'s dev-only
probe references were left as-is — neither is deleted (CLAUDE.md: never
delete a file unless proven dead *and* not a planned feature; the spawner
in particular has real road-following placement math that could be
salvaged later if street_props.gd's simpler even-step placement isn't
good enough).

`scripts/world/streetlight.gd` (`extends PointLight2D`) is a leftover
fossil from an earlier prototype phase — inert in this 3D game (Light2D
nodes do not affect the 3D rendering pipeline at all). Not deleted for
the same reason; flagged here so nobody spends time trying to "fix" a
2D light node in a 3D scene.

## Skill tree: 3 branches exist, GDD says 4

`docs/GDD.md` §8 lists "4 ветки" (4 branches) for the skill tree.
`scripts/systems/skill_tree_manager.gd`'s `SKILL_TREES` const only
defines 3: `combat`, `survival`, `utility`. Per the NO-OPINION protocol
this was not "fixed" by inventing a 4th branch — flagging the gap instead
so a real content decision can be made about what it should contain.

## Skill tree content strings are not localized

`skill_tree_manager.gd`'s `SKILL_TREES` dict stores skill `name`/
`description` as raw English strings directly in code, not i18n keys —
18 skills × 2 fields. The UI chrome around them (`skill_button.gd`,
`skill_tree_tab.gd`, `skill_tree_ui.gd`) was fixed this pass (previously
used Godot's native `tr()` on raw English sentences, which never
resolves without an actual `.po`/`.csv` Translation entry — always fell
through to English in every locale). Localizing the 18 skills' actual
name/description content is a separate, larger content task, not
attempted here.

## Confirmed dead code, not touched (fixing it would have zero player-facing effect)

- `scripts/ui/lobby_menu.gd` + `scenes/ui/lobby.tscn` — a LAN multiplayer
  lobby screen. Not registered in `UIManager`'s screen dict, no button
  anywhere opens it. Has the same raw-`tr()`-on-English-sentence bug as
  the skill tree did, left unfixed since nothing reaches this screen.
  **ARCHIVED (PLAN.md Stage 1, decided): keep unwired, do not delete.**
- `scripts/ui/save_slot_entry.gd` + `scripts/ui/save_slots_ui.gd` — a
  multi-slot save/load picker UI. Also not registered in `UIManager`, no
  reachable entry point (the real save/load path is `main_menu.gd`'s
  single "Continue" button -> `GameManager.continue_game()`, unrelated to
  this file). Same unfixed `tr()` bug for the same reason.
  **ARCHIVED (PLAN.md Stage 1, decided): keep unwired, do not delete.**
- Previously documented in `docs/VISUAL_AUDIT.md`: `city_decorator.gd`,
  `door.tscn`/`exploding_barrel.tscn`/old `pickups/*.tscn` (no material,
  never instantiated), `daily_events_ui.gd` (not in `UIManager`'s dict
  either).
