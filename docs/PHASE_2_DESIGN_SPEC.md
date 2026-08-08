# Phase 2 Design Spec — 3D Player, Combat, Enemies, Music

Repository: `C:\Users\Maxsim\Desktop\TLS_Build\THE_LAST_STREETLIGHT`

## Approved constraints

- Preserve `scripts/player/player.gd` and `scenes/player/player.tscn`; do not rename or delete them.
- Add parallel 3D files and switch only `scenes/main_3d.tscn` to the 3D player.
- Preserve existing autoload declarations; do not modify the autoload manifest.
- Use flashlight color `Color(0.788235, 0.635294, 0.290196)`.
- Update only flashlight upgrade prices in the existing upgrade manager.
- Keep changes surgical, TAB-indented, UTF-8 without BOM.
- After every phase, run the four mandated headless gates. If Godot is unavailable, record NOT RUN and perform static verification.
- One commit per phase; final PR contains four phase commits.

## Reference-scan requirement

Before creating files, scan all `.tscn`, `.gd`, and `.tres` references to the legacy 2D player. Scenes outside `main_3d.tscn` remain on the 2D player. Only `main_3d.tscn` and managers explicitly requiring 3D are migrated.

## Phase order

1. 2.1 — 3D player and SpotLight3D.
2. 2.2 — combo and dodge.
3. 2.3 — enemies and Architect boss.
4. 2.4 — five-layer adaptive music.

## Phase 2.1 implementation target

Add `scripts/player/player_fps_3d.gd` and `scenes/player/player_fps_3d.tscn`, wire `scenes/main_3d.tscn`, and correct only upgrade prices. The player must implement the approved GDD §2–§3 parameters, including captured mouse look, ±90° pitch, FOV, coyote/jump buffering, movement multipliers, crouch geometry/modifiers, interaction ray, battery/flicker/strobe/blackout, HUD segments, and player/flashlight groups.
