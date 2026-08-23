# Steam store listing — THE LAST STREETLIGHT

Desktop is the **optional** platform per `docs/GDD.md` §1 (Android is primary,
canon FPS camera). This page assumes a Windows/Linux desktop export of the
same build — no PC-exclusive content is planned.

## Descriptions

### Short description (max 300 chars)
```
A survival horror FPS set in a city stuck in endless night. Restore the
power grid district by district with nothing but a flashlight and a
fading battery — light is your resource, your weapon, and the only thing
standing between you and what's out there.
```

### About this game (long description)
```
THE LAST STREETLIGHT

The city fell into an endless night after the "Architect Project"
disaster. You're a survivor with one flashlight and a battery that's
never as full as you'd like. Restore the power grid district by
district, and the streets you've lit stay lit behind you — safer, but
never safe.

Light is everything here:
- A RESOURCE. Your flashlight runs on battery you manage and craft spares
  for. Run it dry in the wrong place and you're navigating by sound alone.
- A WEAPON. Some of what hunts you in the dark cannot survive being seen.
- NAVIGATION. Lit streets are the path you've already made safe — the map
  tells you exactly how far you've come.
- A REWARD. Every district restored pushes the dark back for good.

FEATURES
- One continuous city map across 11 districts. No procedural filler, no
  loading screens between "levels" — it's one place, and you learn it.
- Stealth-first design: manage noise and visibility, or fight when you
  have no other choice.
- An enemy roster with distinct AI behavior, elemental/status weaknesses,
  and light reactions — some panic when you shine a light on them, some
  are immune to it, one mini-boss slows down under it.
- Crafting, upgrades, and a 5-slot equipment system.
- Five different endings, determined by how much of the city — and how
  much of the truth about the disaster — you actually uncover.
- Fully offline single-player campaign. Optional local-network co-op.
- 13 languages.
- 8-12 hours for one ending; 15+ hours to find them all.

Built in Godot 4, GL Compatibility renderer — this is primarily a mobile
title (Android), and the desktop build shares the exact same content and
save format.
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
Steam uses its own content survey (no IARC). Expect the same content notes
as the Play Store listing (`docs/store/play_store.md` "Rating notes"):
fantasy violence, horror/dark themes, no sexual content, no gambling, no
in-game purchases at launch.

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
