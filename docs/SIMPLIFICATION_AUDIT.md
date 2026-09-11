# SIMPLIFICATION_AUDIT.md — STEP 5 of the PLAYABLE IDEAL pass (2026-09-11)

The brief asked for four specific rewrites: pathfinding → zone-based travel, physics
interaction → Area2D+raycast, dynamic lighting → baked+additive sprites, AI → a 3-state FSM.
This audit checked each claim against the real code before touching anything — per the
project's own ponytail discipline ("never lazy about understanding the problem" outranks
"shortest diff"). **Verdict: none of the four patterns the brief assumes are actually
present in over-engineered form.** Rewriting them would trade an already-idiomatic,
already-minimal Godot solution for a custom one — the wrong direction on the ponytail
ladder. Files changed this pass: **0**. What follows is the evidence, not an excuse.

## 1. Pathfinding — already `NavigationAgent3D` (Godot's own stdlib solution)

`scripts/enemies/base_monster.gd:35,100-103` uses a plain `NavigationAgent3D` node,
Godot's built-in navigation-mesh pathfinder — not a custom A* or waypoint graph. This is
rung 4 of the project's own ponytail ladder ("native platform feature covers it? use it").
Replacing it with a hand-rolled "zone-based travel" system would mean re-implementing
what Godot's `NavigationServer` already does for free, with a real regression risk (loss of
mesh-aware pathing around dynamic obstacles) and no code-size win — `NavigationAgent3D`
usage is ~5 lines per consumer; a zone graph + traversal logic would be more code, not less.
**Not simplified. Already the simple choice.**

## 2. Physics interaction — targeted raycasts, not a custom framework

Only 3 files in the whole project (`scripts/**/*.gd`, 321 files) call
`PhysicsDirectSpaceState`/`intersect_ray`/`intersect_shape` directly — used for specific
line-of-sight/vision checks, the correct minimal tool for that job in a 3D game. There is
no parallel custom physics system to replace; "Area2D+raycast" is itself what a targeted
raycast already is, just without the unneeded 2D node wrapper this project (a 3D game)
would have to build for no reason. **Not simplified. Already minimal.**

## 3. Dynamic lighting — already budget-capped, not "bake it all"

`scripts/systems/light_limiter.gd` is 51 lines: every 0.25 s it sorts all `OmniLight3D`
nodes by camera distance and keeps only the nearest `MAX_VISIBLE = 8` active, hiding the
rest. This is already the lightweight, native-Godot-Light3D answer to the same problem
"baked + additive sprites" would solve — except sprite-baking would mean building a second,
parallel lighting representation (bake pipeline, sprite atlas, day/night re-bake trigger)
for a game whose entire visual thesis is *dynamic* dark↔lit contrast per streetlight
(`docs/VISUAL_AUDIO_SPEC.md` §2's WowDirector cues, `docs/STYLE_GUIDE.md` §1). Baking would
directly contradict the game's own core visual mechanic. **Not simplified — the requested
direction would break the game's central idea, not just add code.**

## 4. AI — already an FSM, and 8 states are load-bearing, not bloat

`scripts/enemies/base_monster.gd:7` — `enum State { IDLE, PATROL, INVESTIGATE, CHASE,
ATTACK, FLEE, STUN, DEAD }`. The brief's ask ("3-state FSM: idle/patrol/hunt") would collapse
`INVESTIGATE` (heard something, searching, hasn't confirmed) into either IDLE or CHASE, and
`ATTACK` into CHASE. In a stealth game where the whole tension is "did it hear me or does it
know exactly where I am," that distinction is the mechanic, not incidental state — an enemy
in INVESTIGATE is beatable by staying still or breaking line of sound; one in CHASE is not.
Collapsing these is a genre-breaking gameplay change disguised as a code simplification, and
this session — which cannot see or play the result — is exactly the wrong context to make
that call blind. `FLEE`/`STUN` are combat-reaction states with their own real triggers
(low HP flee, hit-stun), not FSM sprawl. **Not simplified — the states encode real,
player-facing behavior; a 3-state collapse belongs to a design decision, not a refactor.**

## What a real simplification pass would target instead (not attempted this session)

Honest flag, not acted on: `scripts/ui/screens.gd` is 1059 lines, the single largest
non-tool script in the project, and its own header comment describes a *past* bug where it
built duplicate copies of every UIManager screen ("two identical menus in one scene, both
intercepting input" — since fixed). Only 4 other files reference it
(`settings_manager.gd`, `_shot_3d.gd`, `workbench.gd`, `puzzle_system.gd`), suggesting its
current live surface may be much smaller than its line count implies. This is a real
candidate for a future audit — but understanding what of it is still load-bearing versus
leftover from that fix needs a dedicated read-through this pass didn't have room for
alongside the other six STEPs, and touching a 1000-line UI-ownership file without a way to
visually confirm nothing broke (NO-GODOT windowed policy) is exactly the kind of change
that needs either a windowed session or a much larger, focused pass of its own.

## Bug-risk / APK-delta accounting (since nothing changed)

No files were rewritten, so there is no bug-risk or APK-size delta to report from this
pass. The counterfactual is worth stating plainly: attempting the four requested rewrites
as specified would have *added* code (custom pathfinding, a parallel bake pipeline) or
*removed real gameplay behavior* (the AI collapse), the opposite of both goals a
"simplification pass" is supposed to serve.
