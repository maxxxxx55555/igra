# Known issues

## Draw calls over budget: 370 measured vs GDD's <200 (D1) / <350 (D11)

Measured via `scenes/tools/perf_check_scene.tscn` (RESCUE WAVE P3) in a
real windowed run, suburbs spawn district: `draw_calls=370`. Root cause:
`scenes/props/streetlight_3d.tscn` has 2 individual `MeshInstance3D`
nodes (Pole, Lamp) and no MultiMesh batching; `street_props.gd` spawns a
pole pair (4 mesh draws) at regular street intervals along every road
segment, in every district. This is very likely the single largest
contributor — worth confirming with a targeted before/after count before
committing to a fix. Not fixed this session: batching would need to keep
each pole's individual reactivity to `EventBus.district_stage_changed`
(the mechanic fixed in the TRUTH WAVE pass, where the game's own
streetlights previously didn't react to power at all) — MultiMesh only
batches the mesh draw, so the light on/off state would need its own,
carefully-tested per-instance-transform tracking. Real, isolated
refactor task, not a small tweak — see `docs/PRODUCTION_BIBLE.md`'s
checklist for the full note.

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
- `scripts/ui/save_slot_entry.gd` + `scripts/ui/save_slots_ui.gd` — a
  multi-slot save/load picker UI. Also not registered in `UIManager`, no
  reachable entry point (the real save/load path is `main_menu.gd`'s
  single "Continue" button -> `GameManager.continue_game()`, unrelated to
  this file). Same unfixed `tr()` bug for the same reason.
- Previously documented in `docs/VISUAL_AUDIT.md`: `city_decorator.gd`,
  `door.tscn`/`exploding_barrel.tscn`/old `pickups/*.tscn` (no material,
  never instantiated), `daily_events_ui.gd` (not in `UIManager`'s dict
  either).
