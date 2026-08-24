# Google Play Store listing — THE LAST STREETLIGHT

Source of truth for every gameplay claim below: `docs/GDD.md`. Every
number in this file traces to a specific GDD section (cited inline) — if
a claim can't be traced, it isn't in this file. Update this file whenever
the referenced GDD section changes.

## Short description (max 80 chars)
```
Restore the light. Stealth horror FPS where every streetlight is life.
```
(71 chars)

## Full description

```
BLACKOUT CITY. YOU ARE THE GRID ENGINEER.

The "Architect Project" disaster plunged the city into permanent night.
You're a survivor with one flashlight, a fading battery, and a job no
one else is left to do: get the power grid running again, district by
district, street by street.

WHAT'S ACTUALLY IN THE BOX
- 11 connected districts, one continuous city map — no procedural
  filler, no level-select screen (GDD §4.1)
- 12 enemy types, including a mini-boss and a final boss, each with
  distinct senses, weaknesses, and behavior (GDD §6.2)
- 5 different endings, decided by how much of the city — and how much
  of the truth — you actually recover (GDD §12.4)
- 13 languages, fully localized (GDD, i18n)
- A 5-layer adaptive music system that shifts with the danger around
  you — dark ambient, restored-district warmth, rising threat, and a
  combat layer, crossfading as you go (GDD §13)
- Stealth built on noise and visibility, not a detection meter — stay
  quiet, stay out of the light's reach, or don't (GDD §7)
- Equipment, crafting, and a workbench for upgrading your one real
  tool: the flashlight (GDD §9)
- A save system with checksum-verified integrity and automatic backup
  recovery — a corrupted save doesn't cost you the run (GDD §10)

LIGHT IS THE REWARD, NOT JUST THE TOOL
Every district you restore stays lit. The contrast between the black
streets you haven't reached yet and the ones you've already saved is
the whole shape of the game — GDD calls it flat out: darkness turning
to light is the main reward. Stealth here isn't a mechanic bolted on
top; the flashlight is simultaneously your only weapon against some of
what hunts you, your only way to see, and the thing that gives you away
every time you use it.

CONTROLS
Touch: virtual joystick plus action buttons, with a double-tap dodge
gesture built for one-handed play. PC: WASD and mouse, same game, same
save file.

Free updates as the city gets built out further — no paywalled content
split, no season pass.
```

## Keywords
blackout, survival horror, stealth, power grid, night city, flashlight
horror, stealth FPS, atmospheric horror

## Category / tags
- Category: **Games → Action** (secondary: Adventure)
- Tags: survival horror, FPS, stealth, atmospheric, single-player,
  offline, crafting, exploration

## Requirements
Derived from the graphics-tier presets (GDD §14/§15 — Low/Medium/High/
Ultra, target 30-60 FPS, degrading shadows/particles/LOD below 30):
- Minimum: any device capable of 720p @ 30fps on the Low preset
  (fog/particles/shadows reduced, dynamic lights capped)
- Recommended: a device capable of 1080p @ 60fps on the High preset

## Data Safety (placeholder — confirm before submission)
- **No personal data collected.** The game is offline-first; no account
  system, no analytics SDK in the current build.
- **No data shared with third parties.**
- Local-network multiplayer (`scripts/net/lan_network.gd`) only talks to
  devices on the same LAN the player explicitly connects to — no
  telemetry leaves the device.
- AppLovin MAX ad SDK is integrated behind `AdService` (see
  `docs/store/HUMAN_CHECKLIST.md`) — once a real SDK key is in place,
  this section needs the AppLovin data-collection disclosure added
  before submission. Currently ships with no key set, falling back to a
  debug stub that collects nothing.
- Privacy policy URL: **TODO — publish a policy page and paste the URL
  here before submitting.**

## Rating note
Expected: **PEGI 16** — sustained horror tension, stylized violence
against former-human enemies including visible blood/bleed status
effects (GDD §6.5: `BLEED` status, melee combat), and a narrative thread
about a deliberately-caused mass-casualty disaster (Truth/Истина
ending). No sexual content, no gambling, no real-money purchases beyond
optional ad-based rewards (see Data Safety above).

## Build steps
Full walkthrough: `docs/ANDROID_BUILD.md`. Summary for this listing:
1. `powershell -ExecutionPolicy Bypass -File tools/make_keystore.ps1` once,
   for local debug builds. **Generate a separate release keystore** before
   the first Play Store upload and store it outside the repo.
2. Export via Godot editor (Project → Export → **Android** preset) or
   headless: `godot --headless --export-release "Android" build/TLS.aab`.
   Play Store requires **AAB**, not APK (`docs/release_checklist.md`
   "Build Format").
3. Confirm `export_presets.cfg`: `min_sdk=29`, `target_sdk=34`,
   `package/unique_name="com.tls.game"`, launcher icons and
   `permissions/internet=true` (LAN co-op) are all present — already
   committed in this repo.
4. Run `bash tools/check.sh` clean before every submission build.
5. Work through `docs/release_checklist.md` top to bottom (Data Safety
   form, IARC questionnaire, ASO assets, versionCode bump) before
   uploading to a testing track.
