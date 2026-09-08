# BUGS_FOR_CLAUDE — routed from asset bug-hunt (2026-08-25)

Code-side only. Asset-side fixes are in docs/REPORT_BUG_HUNT.md.

## BUGS

### 1. 17 orphan `.import` sidecars at top-level `audio/` — sources deleted
`audio/ambient/ambient.wav.import`, `audio/music/{gas_station,hospital,industrial,
park,police,power_station,residential,school,substation,suburbs,warehouses}.wav.import`,
`audio/sfx/{click,deny,hover,pickup,stinger}.wav.import` all point at
`source_file` paths that no longer exist (verified: 17/17 source missing).
Symptom: Godot editor scan errors / import noise; breaks the 0-ERROR headless gate.
Fix: delete the 17 stale `.import` files (nothing can reference imported artifacts
of deleted sources; no `res://audio/...` path exists anywhere in scripts/scenes/data).
Not done by asset session: outside `assets/**` write scope.

### 2. One editor import pass needed for 60 new media files
`assets/audio/one_shots/*` (5), `assets/textures/docs_v2/*` (6),
`assets/textures/picto_v2/*` (13), `assets/textures/stages_v2/*` (4),
`assets/textures/renders_v2/bundle_survivor_256.png` (1), store/v2 subfolders (31:
ab 4, coming_soon 2, devices 12, itch 5, vertical 3, yandex 3, youtube 2).
Symptom: any code/scenes wiring these later gets `ResourceLoader.exists()==false`
until imported; encyclopedia/stats/city_map already reference some V2 sets that
DO have imports — these newer folders don't.
Fix: run the editor import once: `godot --headless --editor --quit --path .`
(asset sessions must not run it — it re-serializes tracked .tres).

### 3. `music_combat.ogg` is a dead file
`assets/audio/music/music_combat.ogg` has zero consumers (not even comments;
the other 8 old-layer OGGs are at least named in music_manager.gd comments).
Its stale `.wav.import` was removed by the asset session.
Fix decision needed: wire as an alternate combat layer or delete with owner sign-off.

## WIRING BACKLOG (documented consumers never implemented)

### 4. district_atmosphere.gd loads nothing
`scripts/world/district_atmosphere.gd` has no asset loading at all, yet
docs/REPORT_AUDIO_DETAIL.md T2 documents it as consumer of
`assets/audio/ambience/district_details/<district>_<event>.ogg` (40 beds) WITH a
per-file LUFS offset column (+1.8..+5.8 dB) to apply in-engine.
Minimal fix: under the `<district>_dark.ogg` bed, add a second looping player per
district loading its detail beds at `volume_db = offset_table[file]`.

### 5. MusicManager weather switch has no hooks
`scripts/systems/music_manager.gd` crossfades district beds and layers but never
touches `assets/audio/ambience/weather/{rain_loop,wind_loop}.ogg`
(docs/ERROR_LOG.md marks wind_loop "safe to wire" since W1).
Minimal fix: on EventBus weather change, crossfade the matching loop under the bed.

### 6. Ending stings / jingles unwired
`assets/audio/jingles/ending_{light,hope,survivor,dark,truth}_sting.ogg`,
`ach_unlock.ogg`, `quest_complete.ogg`, `skill_unlock.ogg` have no loader.
Consumer hints: endings_manager.gd `_evaluate_ending` (no audio call today),
achievements unlock path, quest tracker, skill tree node unlock.
Minimal fix: one-shot play at the existing state-change call sites.

### 7. Per-district loading backgrounds unwired
`assets/textures/loading/<district>_loading.png` ×11 (CONTENT_WAVE says
"loading screen background per district_id"); screens.gd:128 hardcodes only
`screens_v2/loading_street.png`.
Minimal fix: in build_Loading, try
`res://assets/textures/loading/%s_loading.png % district_id`, fall back to street.

### 8. Small texture orphans need owner decision
`textures/environment/{floor_concrete,wall_brick,wall_concrete}.png`,
`ui/minimap_enemy_blip_16.png`, `sky/moon_glow_256.png` — zero consumers.
moon_glow was delivered as "separate sprite" for world_env.tscn (only panorama
is wired there); enemy blip completes the wired minimap kit (frame+arrow ARE used
by minimap.gd).
Minimal fix options: wire moon_glow into world_env sky, blip into minimap.gd's
enemy marker, or delete the environment trio after owner review.
