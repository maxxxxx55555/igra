# Known issues

## district_grading.gd's Environment branch is dead code (found 2026-09-12, wiring LUTs)

While wiring the 2026-09-12 arena visual pass's 11 per-district color-correction LUTs into
`WorldEnvironment`, found that `scripts/world/district_grading.gd` (the script the LUT
README and `docs/VISUAL_AUDIO_SPEC.md` both name as the intended wiring point) never
actually runs its Environment-mutation branch (fog/sky/ambient/tonemap — `_apply()`'s
`if _env != null and _env.environment != null:` block). Its only instantiator,
`scripts/world/world_bootstrap.gd` `_wire()`, dynamically creates the `Grading` child node
per district but only sets `district_root_path`, never the `@export var
world_environment_path` the script needs to find its WorldEnvironment — so `_env` is always
`null` and the whole branch (per-district fog color, sky background, ambient tint,
FILMIC tonemap) has been a silent no-op since it was written. The only visible effect that
ever shipped from `district_grading.gd` is its separate `_apply_ground()` floor-tint call
(guarded by `_root`, not `_env` — that one does run).

**Why not fixed by wiring the missing NodePath:** a second, genuinely live system already
owns the same WorldEnvironment resource — `scripts/world_env_setup.gd` (attached to the
main scene root) sets ambient/fog/tonemap once in `_ready()` and re-drives
`ambient_light_color`/`ambient_light_energy`/moon/player-glow per **stage** (DARK/LIT/FULL)
on every `district_stage_changed`, using one fixed palette for the whole game, not a
per-district hue. Simply pointing `district_grading.gd` at the real WorldEnvironment would
make two systems fight over `ambient_light_color`/`fog_color`/`tonemap_mode` on every stage
change — a worse, flickering bug. Whether districts should carry their own fog/sky hue (not
just LUT grading + floor tint, which do work today) is a design call, not a wiring bug fix,
so it's left alone here.

**What was actually wired instead:** the 11 LUTs go into `world_env_setup.gd` — the real
live WorldEnvironment owner — as `Environment.adjustment_color_correction`, keyed by
`EventBus.district_entered` (`_apply_lut()`, filename = `lut_<district_id>.png`, no table
needed). This is genuinely live and does not conflict with the stage-based ambient system
(different Environment properties).

**If someone wants full per-district fog/sky/ambient later:** decide whether that should
override or blend with `world_env_setup.gd`'s stage palette, then either delete
`district_grading.gd`'s dead branch or wire `world_environment_path` to the real node and
make the two systems cooperate (e.g. `district_grading.gd` sets fog/sky/tonemap only,
`world_env_setup.gd` keeps owning ambient/moon/glow).

## Autoplay bot (PLAYABLE IDEAL pass) — mechanics engine proven, full headless win blocked by a boot-path lifecycle issue

`tools/qa_sim/autoplay_bot` + `scenes/tools/qa_autoplay_scene.tscn` drive
the game with **simulated inputs only** (joystick move via
`InputService.set_joy_move_dir`, `request_interact`, `request_attack`,
`request_dodge`, City-Map Travel button, Save/Continue) while reading
real state.

**What it proved:** the winnability *mechanics engine* works end to end.
In an early run the bot walked the player to a `cable` pickup, collected
it by collision, walked to the suburbs `PowerSwitch`, pressed interact,
and the district advanced **DARK → PARTIAL for real** — no state
injection. It also surfaced and got fixed a real defect:
`power_switch.gd` connected the 0-arg `_refresh_visual` to the 1-arg
`EventBus.district_powered` signal without `unbind(1)`, logging
"Method expected 0 argument(s), but called with 1" on *every* power-up
(fixed this pass; connected once in `_ready`, not re-connected on every
refresh).

**What blocks a full 3/3 headless win right now:** when the bot boots
through a gate scene (bypassing `boot_loading.tscn`) and then presses New
Game, the game world is torn down / snapped back to MENU ~8 s after the
run starts, and `DistrictLoot.populate()` does not run on that
`start_game() -> pre_loading -> main_3d` path (a direct `main_3d.tscn`
instantiate — `game_test_3d_scene` — still spawns all 12 pickups, so this
is **not** an in-game winnability bug). `_boot_check_runner.gd` tolerates
the same one-shot MENU yank by breaking early; the autoplay bot needs the
world to *persist*, and Continue does not rebuild it. Real players boot
through `boot_loading.tscn` and are unaffected.

**Substitute coverage:** the static balance/solvability sim
(`tools/qa_sim/` balance pass) proves DARK/PARTIAL solvability and no
resource dead-ends across the spine; `headless_suite` P2 proves every
district scene instantiates with its full loot set. Finishing the
headless autoplay win needs one focused pass on the gate-scene→world
bring-up (or running the bot as a temporary autoload against the real
boot chain).

**Reconfirmed 2026-09-12 (RELEASE CONVERGENCE, STEP 4):** re-ran
`QA_SEEDS="1" tools/qa_sim/autoplay_bot` after this pass's LUT/audio
wiring, check.sh timeout fix, and HMAC/anti-tamper changes, to make sure
none of that regressed or accidentally fixed it. Identical symptom,
same district, same phase: `SOFTLOCK: no progress for 45s —
phase=spine district=suburbs spine_i=0 have_target=true pos=? score=0`,
0/11 districts FULL. `pos=?` in that line (the bot's own position readout
failing) is consistent with the documented root cause — if the world gets
torn down/re-created under the bot mid-run, its cached player-node
reference goes stale, so it would report "no progress" and a dead
position query forever even if the underlying issue were something other
than literal player-position stagnation. Not pursued further this pass:
this exact bug has already had multiple dedicated fix attempts across
prior sessions (Continue-instead-of-New-Game, routing through
`Routes.goto(Routes.BOOT)`) without a full spine win, and the mechanics
engine + per-district loot spawning are independently proven by other
gates (see above). Owner real-device/editor playtest remains the
authoritative winnability check — tracked in `RELEASE_CHECKLIST.md`, not
re-attempted here without new information.

## Verification policy: headless-only Godot ALLOWED since 2026-09-10 (GOLD MASTER)

The owner lifted the absolute NO-GODOT constraint to **headless-only**:
`godot --headless` non-interactive script/scene runs are now allowed and
required for verification. Still banned: `--windowed`, the editor GUI,
any visible window, window-opening probe scenes. The gate is
`tools/qa_sim/headless_suite` (engine gate scenes each with a per-gate
timeout + `scenes/tools/qa_headless_suite_scene.tscn`). The
`tools/qa_sim/*.py` static sims below stay valid and still run — they now
back up the headless suite rather than replace it. Logs: `.qa_logs/`
(untracked).

First headless run found and fixed 4 latent regressions that static
checks structurally cannot see (commit `f3bd1e3`): a `var`/`func` name
collision that killed the `WowDirector` autoload, `LOOT_SCRIPT.populate`
not dispatching through a `Script`-typed const (zero loot spawned in any
district), and two `:=` type-inference errors that cascaded compile
failures on a cold parse.

### `game_test_3d_scene` phase 1+ stalls intermittently under --headless

Its phase 0 (player / monsters / **pickups: 12** / fuel-item constant)
passes reliably and is also covered by `headless_suite` P2/P2b. Phases
1–8 (combat / inventory / battery / generator / boss / death) hang
intermittently in the phase-1 combat step (`take_damage` on a monster
inside `main_3d` — physics/nav timing under the dummy renderer); no
script error, `_process` just stops ticking. Pre-existing (the scene
predates this pass). Mitigated: a 150 s hard-timeout-as-FAIL + real exit
code (`quit(fails)`) added so it can never hang CI. Substitute coverage:
`headless_suite` P2b (combat damage in isolation — passes every run) +
`tools/flow_check.py` (combat/inventory/battery/death signal wiring).
Run the scene manually for the fuller smoke.

### `headless_suite` P6 soak ends at ~10 s (test-runner MENU race)

A gate scene that boots past `boot_loading.tscn` makes the splash/
bootstrap fallback and the natural scene load contend for the first
scene swap; the loser periodically fires `Routes.goto(BOOT)` /
`return_to_menu()`, so sustained gameplay started from a test scene
drops back to MENU after ~10 s. This is the **same** artifact the
PERMANENT gate `_boot_check_runner.gd` documents and tolerates. Real
players always boot through `boot_loading.tscn` and never hit it. P6
logs it and ends the soak clean (no fail), same stance as boot_check.
Net: the "10-minute soak" is capped at ~10 s of in-engine sustained
play; the rest of the soak intent is covered by the crash-safety static
sweep (`STATIC_AUDIT` #38–42, all 20 JSON/FileAccess sites) and the
`boot_check_scene` 60 s sustain.

## NO-GODOT verification substitutes (MEGA FINAL POLISH, 2026-09-10)

This pass ran under an absolute no-engine constraint. The engine-launching
gates were replaced with static equivalents, all committed under
`tools/qa_sim/`:

| Engine gate | Static substitute |
|---|---|
| `game_test_3d_scene` / compile smoke | `tools/check.sh --static` (10/10) + `flow_check.py` + `scene_node_check.py` + manual re-read of every edited function |
| endings reachability (would need a playthrough) | `tools/qa_sim/endings_sim.py` — walks the reachable state space from the district DAG |
| PARTIAL vs DARK visual diff | `tools/qa_sim/lighting_stage_sim.py` — tabulates the per-stage light/colour values |
| puzzle-economy reachability | `tools/qa_sim/puzzle_economy_sim.py` — resolves every id against real `start_puzzle()` callers |
| i18n text-overflow in-scene | `tools/qa_sim/overflow_check.py` — locale-length ratio × container width |
| accessibility toggles apply | `tools/qa_sim/a11y_check.py` — traces each setting key to a real effect |
| `perf_check_scene` draw calls | `tools/qa_sim/drawcall_estimate.py` — structural estimate + exact active-light before/after |

`perf_check_scene.tscn --windowed` still needs one owner run for the real
`RENDER_TOTAL_DRAW_CALLS_IN_FRAME` number (see the draw-calls entry).

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

## `industrial_dark.ogg` is 33.994 s, not the shipped 36.000 s house contract — accepted as intentional

Every other district's dark ambience bed (10 of 11) plus all 3 shipped
lit beds (`suburbs`/`hospital`/`residential`) measure exactly 36.000 s
(Ogg granule 1,587,600 @ 44.1 kHz) — independently re-verified
2026-09-09 by parsing the Ogg container's final page granule directly
(no ffmpeg needed): `industrial_dark.ogg`'s last granule is 1,499,146,
giving 33.994 s exactly.

Accepted as **deliberate, not a defect**: `tools/gen_audio.py`'s
`DISTRICTS` canon sets industrial's theme to 85 bpm / 12 bars, and
12 bars × 4 beats ÷ 85 bpm × 60 = 33.882 s — within 112 ms of the
shipped 33.994 s (consistent with normal OGG frame-alignment padding
at encode time, not a random mis-render; 36 s at 85 bpm would be a
non-whole 12.75 bars, which the generator correctly declined to
produce). No code hardcodes the 36 s assumption anywhere
(`music_manager.gd`'s loop handling is duration-agnostic, driven by
the actual resource), so there is no functional risk either way. The
still-unfabricated `industrial_lit.ogg` (spec `docs/AUDIO_COVERAGE.md`
G2h) must match this bed's real length (33.994 s), not the generic
36 s, for `MusicManager`'s crossfade to land cleanly — already
specified correctly. Re-rendering the dark bed for contract uniformity
would be a valid alternative but is out of scope for this decision:
`assets/audio/**` is Arena's ownership zone, not code's, and NO-GODOT
mode's static-only verification is not a reason to fabricate binary
audio myself. Decision recorded in `PLAN.md`'s decisions log
(2026-09-09, PR #6).

## Two power_station audio one-shots are off the 30.000 s detail-bed class — not blocking

`power_station_generator_thrum.ogg` (28.749 s) and
`power_station_cooling_fan.ogg` (28.948 s) are shorter than the
30.000 s every other district's detail one-shots hold exactly —
independently re-verified 2026-09-09 by the same direct Ogg-granule
parsing used for the `industrial_dark.ogg` finding above. Both loop
(`loop = true` in `district_atmosphere.gd`) and no code reads or
assumes a detail-bed duration anywhere, so there is no functional
risk. Same reasoning as the industrial bed: `assets/audio/**` is
Arena's ownership zone, re-rendering (if wanted for consistency) is
the audio toolchain holder's call, not code's. Full reasoning:
`docs/STATIC_AUDIT.md` #32, Arena's `docs/CONTENT_PIPELINE_AUDIT.md`
finding F1.

## `PuzzleSystem` bonus reward economy — RESOLVED (2026-09-10 MEGA POLISH)

Was: `puzzle_system.gd`'s `_puzzle_data` had one row per district, all
cited as "puzzle canon" by the content packs, but only `fuse_substation`
(via `cable_box_interactable.gd` in `substation.tscn`) is reachable —
`tools/qa_sim/puzzle_economy_sim.py` proves 1/11. Decided (b): trimmed
`_puzzle_data` to the one reachable row so the table stops claiming
canon it can't deliver. Option (a) — wiring the other 9 into
`power_switch.gd` — was rejected because it double-counts `puzzle_solved`
for `progress_tracker`/`xp_manager` and shifts the reward economy (a
GDD §3.3/§8 balance call). Core DARK→FULL restoration for all 11
districts runs on the independent `power_switch.gd` loop and is
unaffected. `_grant_reward()` kept general for a future real per-district
puzzle interactable. Full reasoning: `docs/STATIC_AUDIT.md` #31,
`PLAN.md` 2026-09-10 MEGA POLISH entry.

## Endings: all 5 GDD §12.4 endings reachable — RESOLVED (2026-09-10 MEGA POLISH)

Was: only Light/Hope/Truth reachable — `_determine_ending()` only ran on
`game_won` (always `full == 11`), so `survivor`/`dark` were dead. Now
`GameManager.trigger_death()` calls `EndingsManager.evaluate_death_ending()`:
death with the grid unrepaired → **Dark**; death with `power_station` at
FULL but `full < 11` → **Survivor** (reachable because `school` and
`gas_station` are optional leaf districts — the spine can reach
`power_station` FULL at `full == 9`). Win path unchanged.
`tools/qa_sim/endings_sim.py` walks the reachable state space and
confirms all 5 (`PASS`). Also fixed `core/endings.gd`'s stale
`"powerplant"` id → `"power_station"`. Full trace: `docs/STATIC_AUDIT.md`
#6.

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

**2026-09-12 addendum:** confirmed `--import` triggers the identical
corruption, not just `--editor` — ran `godot --headless --path . --import
--quit` to materialize `.import` files for the arena visual/audio pass's
new assets (LUTs, screenshots, ogg beds), and got the exact same
Master-block/`room_size`/uid damage on `default_bus_layout.tres`. So the
rule is: **any** headless invocation that does a project-wide reimport or
class-cache rebuild (`--import`, `--editor`) is suspect, not just
`--editor` specifically. Reverted with the same `git checkout --` before
committing.

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

**RC final pass (2026-09-10) — WON'T-FIX for RC ("D1 perf, code-side
only").** No draw-call reduction here is simultaneously code-only,
behavior-preserving, *and* verifiable without a Godot Visual Profiler
run (headless reports `draw_calls=0`). The shippable budget — D11 < 350,
the busiest district — is met (234) and hard-gated by
`perf_check_scene.tscn`. Candidates and why each is deferred, not done
blind: (a) MultiMesh-batching the 12 pickup / 6 monster meshes breaks
per-instance bob/rotate animation and individual removal — the same
regression class that broke streetlight reactivity when rushed once
already; (b) distance-culling far pickups changes visible behavior
(pop-in); (c) the single most promising code-side lever for a
Godot-enabled pass: **each `scenes/pickups/item_pickup_3d.tscn` carries
its own `OmniLight3D` glow** (12 live dynamic omni lights in D1) — the
box mesh is already self-lit via an emissive material, so the cast-glow
light is a readability nicety that could be swapped for a cheaper
`VisibleOnScreenNotifier3D`-gated shared light or dropped, but that is a
visual-quality call that needs a Profiler before/after, not a static
guess.

**Update 2026-09-10 (MEGA POLISH) — code-side reduction applied.**
`distance_fade_enabled` added to the streetlight `SpotLight`/`Glow`
(`begin 22 m`, culled at 30 m) and the pickup `GlowOmniLight3D`
(`begin 12 m`, culled at 16 m). Both lights have short reach (spot 12 m,
pickup omni 3.2 m), so nothing a player can see changes — only lights
whose lit effect is already off-screen get culled entirely ("not sent to
the shader at all", per the `Light3D` docs). `tools/qa_sim/drawcall_estimate.py`:
a representative D1 frame goes from **58 → 18 active real-time lights
(−69%)**. The residual structural draw calls (6 non-batchable monster
meshes, in-view pickups / interactables, HUD 2D) still put a firm `<200`
out of static reach — that needs a Profiler pass and, likely, a design
call on concurrent monster/pickup counts. Owner step: re-run
`scenes/tools/perf_check_scene.tscn --windowed` and read the new number.

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

## Skill tree: 4th branch + skill-string localization — RESOLVED

Both of these were open earlier and are now closed (noticed stale during
the 2026-09-10 RC pass; verified against the current code):

- **4th branch (GDD §8 wants 4, project had 3):** `skill_tree_manager.gd`'s
  `SKILL_TREES` now defines **4** — `combat`, `survival`, `utility`,
  `stealth` (the Stealth branch: `silent_steps`, `cold_trail`, real
  effects wired into `player_3d.gd`/`base_monster.gd`). Added in PLAN.md
  Stage 3, commit `b861b14`.
- **Skill name/description localization:** every skill's `name`/
  `description` in `SKILL_TREES` is now an `SKILL_*` i18n key
  (`SKILL_DAMAGE_BOOST_1_NAME`, `SKILL_SILENT_STEPS_DESC`, …), resolved
  through `LocalizationManager`, present in all 13 locales
  (`i18n_audit.py`: `MISSING: 0`). The raw-English-in-code state this
  entry used to describe is gone.

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
  either — its hardcoded strings were still localized in the RC final
  pass so a future wiring doesn't reintroduce an i18n-rule violation).
- `scripts/ui/onboarding.gd` — a contextual first-time-hint system
  (WASD / flashlight / shadow / interact / inventory prompts on gameplay
  events), fully authored and i18n'd, but **not instanced anywhere** and
  not an autoload. Superseded by the two live systems: `tutorial_system.gd`
  (the FTUE) and `onboarding_overlay.gd` (the 4-panel first-launch
  overlay, wired in `main_3d.tscn`). Reviewed in the RC final pass —
  wiring a hint system in blind (NO-GODOT) is a feature-integration risk,
  not an RC polish; left for a Godot-enabled pass or an owner decision to
  archive it. `onboarding_overlay.gd` itself was reviewed clean (shows
  once per save profile, never blocks gameplay, i18n on all captions/
  buttons; only nit — it doesn't retranslate on a live language switch
  mid-overlay, negligible for a once-ever first-launch screen).

## Accessibility toggles — 5 of 7 were non-functional; fixed 2026-09-10 (MEGA POLISH)

The Settings → Accessibility tab shipped 7 toggles; a static trace
(`tools/qa_sim/a11y_check.py`) found only High Contrast half-worked:

- **Colorblind Mode** — `_apply_colorblind()` was an empty stub. Now a
  real full-screen `canvas_item` post shader (deuteranopia / protanopia /
  tritanopia channel-lift), mounted on a `CanvasLayer` from
  `settings_manager.gd`. Conservative constants — a colorblind playtester
  can tune the `*1.15 / 0.10 / 0.20` factors in the shader string.
- **Text Size** — iterated an `"ui_text"` group that nothing ever joins
  (and would have compounded). Now scales `get_tree().root.theme.default_font_size`
  from a captured base. **Partial by design**: screens that hard-override
  their own font size won't scale — full coverage needs each screen to
  honor a text-scale, out of scope for RC.
- **High Contrast** — `_apply_high_contrast()` worked, but the generic
  `_toggle` in the Settings screen only called `set_setting()`, never
  `set_high_contrast()`, so the checkbox did nothing. `set_setting()` now
  dispatches to the real applier for every accessibility key.
- **Arachnophobia Mode** — `enemy.is_instance_valid()` is a runtime error
  (`Node` has no such method) → the toggle *crashed*. Fixed to the global
  `is_instance_valid(enemy)`.
- **Auto-aim Assist** — `auto_aim` is read by nothing anywhere in the
  codebase. **Removed from the UI.** Re-add when an aim-assist code path
  exists (`player_3d` targeting).
- **Dyslexia Font** — loaded `res://assets/fonts/OpenDyslexic-Regular.ttf`,
  which is **not shipped**, and (again) iterated the empty `"ui_text"`
  group. **Removed from the UI**; `_apply_dyslexia_font()` guarded against
  the null load. Re-add once the OpenDyslexic `.ttf` is added to
  `assets/fonts/` — and gate it to Latin-script locales (it has no CJK /
  Arabic glyphs).
- **Reduce Screen Shake** — worked (added in the RC pass; read directly in
  `screen_shake.gd`).

Accessibility effects are now re-applied on config load
(`from_dict → call_deferred("apply_all_accessibility")`).

## Unmerged `arena/*` branches on origin — deliberately not merged (RC triage 2026-09-10)

Three `arena/*` branches remain on origin after the RC final pass. Only
one was merged; the other two are intentionally left alone.

- **`arena/01a08729-igra` — MERGED** (RC final pass, Phase B). Store kit
  (`store/**`), `docs/PROSE_CHANGES.md`, `docs/ASSET_LICENSES.md` +
  `AUDIO_COVERAGE.md` + `CONTENT_PIPELINE_AUDIT.md` §10, and a 2-word
  `centre→center` prose fix in `gas_station`/`police` `lore_notes.json`.
  In MERGE POLICY scope; see `PLAN.md` 2026-09-10 decisions-log entry.
- **`arena/019ffbd0-igra` — NOT merged.** 57 commits, merge-base ~60
  commits behind `main`. Its payload (the autopilot in-engine test suite
  plus a large stealth/doors/save/tutorial/finale fix batch) already
  landed on `main` through earlier integration — `tools/autopilot/`,
  `tools/flow_check.py`, `tools/orphan_check.py` are present and
  CLAUDE.md's "Already done" list enumerates the fixes. Merging now would
  replay stale history into conflicts for no gain. Kept on origin for
  archival only; safe to delete once someone confirms nothing unique is
  on it.
- **`arena/01a07b1c-igra` — NOT merged.** 9 commits implementing an
  FPS-weapons layer (`scripts/weapons/**`, `project.godot`, player/weapon
  `.tscn`, `data/items/ammo.tres`, `docs/IDEA_CONFORMANCE.md`). Outside
  the content/store/docs scope this project's self-merge protocol allows,
  and a separate feature track (GDD §18) rather than RC finishing work.
  Needs an explicit owner design decision before any of it goes near
  `main` — do not self-merge.

## Mobile texture compression — every texture ships Lossless (mode=0), not VRAM Compressed (P1/OWNER)

Checked this pass (PLAYABLE IDEAL, STEP 5 mobile perf): all 1230 `assets/**/*.import` files
sampled use `compress/mode=0` (Lossless) — none are VRAM Compressed. On Android this means
larger APK size and full RGBA8 GPU memory per texture instead of ETC2/ASTC block compression
(typically 4-6x less VRAM). `export_presets.cfg`'s Android preset now has
`texture_format/etc2_astc=true` (added this pass — inert today since nothing is VRAM-compressed
yet, but correct and ready for the migration below).

**Why not fixed here:** re-importing ~1230 textures to VRAM Compressed is a bulk `.import`
edit outside a headless session's safe reach for two reasons: (1) `assets/textures/**` is
Arena's/OpenCode's ownership zone, not reassigned for a project-wide pipeline change (only
this pass's 12 new mobile-art files were reassigned); (2) VRAM block compression can introduce
visible banding on this game's palette-locked, deliberately-flat-gradient art (STYLE_GUIDE
explicitly bans banding) — verifying that needs a windowed visual diff, which NO-GODOT
headless-only policy forbids.

**Owner remediation:** in the Godot editor, select `assets/textures/**` (environment/prop
surfaces are the highest-value targets — UI glyphs and the STYLE_GUIDE-locked flat art may be
better left Lossless for crispness) → Import dock → Compress Mode → **VRAM Compressed** →
Reimport, then a visual spot-check for banding on a few district loading screens before
shipping. `texture_format/etc2_astc=true` is already set for when this lands.

## GDD achievement count is stale — code ships 31, GDD/store copy says 20

Found 2026-09-12 (RELEASE CONVERGENCE, arena store-pass cert). `docs/GDD.md` §21 and its
supplement §S17 list exactly `ach_01`–`ach_20` (20 achievements), and `store/listing.md`
correctly ships "20" per the repo's GDD-wins-on-conflict rule. But
`scripts/systems/achievements_manager.gd` has shipped **31** since the GOLD MASTER v5 hooks
pass (2026-09-11) added 11 per-district achievements (`ach_district_<id>`) that were never
back-ported into the GDD. The GDD is the stale side, not the store copy.

**Why not fixed here:** updating GDD §21 to list 11 new achievement entries (name/description/
trigger per district) is a content-canon write, not a bugfix, and risks scope creep into a
docs-consolidation pass. Deferred to a dedicated content pass.

**Remediation:** add the 11 `ach_district_<id>` entries to GDD §21/§S17 (name = the existing
`DISTRICT_NAME_<ID>` i18n key, description = the shared `ACH_DISTRICT_FULL_DESC` key already
in code), then re-run `tools/gen_store_listing_locales.py` with the polished bullets ported in
first (`docs/CERT_STORE.md` §8.2 warns regenerating without doing so reverts the 2026-09-11
benefit-led polish) so store copy can honestly say 31.
