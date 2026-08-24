# Steam store listing — THE LAST STREETLIGHT

Desktop is the **optional** platform per `docs/GDD.md` §1 (Android is primary,
canon FPS camera). This page assumes a Windows/Linux desktop export of the
same build — no PC-exclusive content is planned.

## Descriptions

### Short description (max 300 chars)
```
Restore the light. A stealth horror FPS where every streetlight is
life — blackout city, and you're the grid engineer with one flashlight
and a fading battery standing between you and what the dark hides.
```

### About this game (long description)
```
BLACKOUT CITY. YOU ARE THE GRID ENGINEER.

The "Architect Project" disaster plunged the city into permanent night.
You're a survivor with one flashlight, a fading battery, and a job no
one else is left to do: get the power grid running again, district by
district, street by street.

WHAT'S ACTUALLY IN THE BOX
- 11 connected districts, one continuous city map — no procedural
  filler, no level-select screen
- 12 enemy types, including a mini-boss and a final boss, each with
  distinct senses, weaknesses, and behavior
- 5 different endings, decided by how much of the city — and how much
  of the truth — you actually recover
- 13 languages, fully localized
- A 5-layer adaptive music system that shifts with the danger around
  you — dark ambient, restored-district warmth, rising threat, and a
  combat layer, crossfading as you go
- Stealth built on noise and visibility, not a detection meter — stay
  quiet, stay out of the light's reach, or don't
- Equipment, crafting, and a workbench for upgrading your one real
  tool: the flashlight
- A save system with checksum-verified integrity and automatic backup
  recovery — a corrupted save doesn't cost you the run

LIGHT IS THE REWARD, NOT JUST THE TOOL
Every district you restore stays lit. The contrast between the black
streets you haven't reached yet and the ones you've already saved is
the whole shape of the game. Stealth here isn't a mechanic bolted on
top; the flashlight is simultaneously your only weapon against some of
what hunts you, your only way to see, and the thing that gives you away
every time you use it.

CONTROLS
Mouse and keyboard: full support, WASD movement. This is primarily a
mobile title (Android) built in Godot 4 with a GL Compatibility
renderer; the desktop build shares the exact same content and save
format.

Free updates as the city gets built out further — no paywalled content
split, no season pass.
```

## Tags (Steam tag list, order matters for discovery)
Survival Horror, FPS, Atmospheric, Stealth, Dark, Exploration, Crafting,
Singleplayer, First-Person, Horror, Indie, Story Rich

## Genre
Action, Adventure, Indie

## System requirements (placeholder — fill in after a perf pass)
GL Compatibility renderer keeps the floor low; these are conservative
placeholders pending real benchmark numbers from `QualityManager`'s tier
presets (`scripts/systems/settings_manager.gd` `GRAPHICS_TIERS`).

**Minimum**
- OS: Windows 10 64-bit
- Processor: dual-core, 2.0 GHz
- Memory: 4 GB RAM
- Graphics: GPU with OpenGL 3.3 / GLES3 support
- Storage: 2 GB available space

**Recommended**
- OS: Windows 10/11 64-bit
- Processor: quad-core, 3.0 GHz
- Memory: 8 GB RAM
- Graphics: dedicated GPU, 2 GB VRAM
- Storage: 2 GB available space (SSD)

## Controller / input support
- Mouse + keyboard: full support (see `project.godot` `[input]` — WASD move,
  Shift sprint, Ctrl crouch/stealth, E interact, F flashlight, R reload,
  C strobe, Q quick wheel, 1-6 quick slots).
- Gamepad: `InputService` reads through Godot's action map, so any
  configured controller works via `move_*`/`interact`/`attack`/etc. actions;
  no gamepad-specific prompts/glyphs are drawn yet — track as a follow-up
  if Steam Deck verification is a goal.
- Touch-only mobile controls (virtual joystick, quick wheel, action
  buttons) are disabled on desktop (`OS.has_feature("pc")` gate) and never
  appear in the Steam build.

## Achievements
`AchievementManager` (autoload, `scripts/systems/achievements_manager.gd`)
already tracks unlock conditions in-game (see `ACH_01`.."ACH_20" in
`data/i18n/en.json`). Wiring these to Steamworks achievements requires the
GodotSteam (or equivalent) plugin — **not integrated yet**; the in-game
achievement screen works standalone regardless of Steam integration.

## Age rating
Steam uses its own content survey (no IARC). Expected: **PEGI 16**
equivalent — sustained horror tension, stylized violence against
former-human enemies including visible blood/bleed status effects (GDD
§6.5), and a narrative thread about a deliberately-caused mass-casualty
disaster (Truth/Истина ending). No sexual content, no gambling, no
in-game purchases at launch. See `docs/store/play_store.md` "Rating
note" for the full citation.

## Privacy / data collection
Same as Play Store: offline-first, no accounts, no analytics SDK in the
current build, LAN-only multiplayer with no telemetry. Steam's own privacy
policy covers platform-level data (achievements, playtime) — no additional
first-party collection from this game.

## Build steps
There is no dedicated desktop export preset in `export_presets.cfg` yet
(only `Android` is configured). To ship on Steam:
1. Add a `Windows Desktop` (and/or `Linux`) preset via Godot's Export
   dialog, pointing at installed export templates for 4.7.
2. Reuse the same GL Compatibility rendering settings already in
   `project.godot` (`renderer/rendering_method="gl_compatibility"`) — no
   renderer-specific content branches exist, so no extra work there.
3. Run `bash tools/check.sh` clean before packaging.
4. Package via `steamcmd`/Steamworks SDK per Valve's standard upload flow
   (out of scope for this repo — no Steamworks credentials or app ID are
   configured here).
