# REPORT_ASSETS — agent B (textures + audio)

Phase-2 update: 2026-08-23. Scope: assets/textures/{enemies,items,tiles,ui,surfaces,items_legacy}, assets/store, assets/shaders, assets/audio/{sfx,ambience}, docs trio.

## Phase-2 audit summary

- Rescan vs Phase-1 manifest: all 92 claimed files existed at audit time; 0 corrupt.
- INCIDENT: a parallel actor deleted 7 of my sfx WAVs (footstep_concrete/metal/wood, monster_shadow_click, monster_crawler_scrape, monster_watcher_breath, monster_destroyer_hum) between phases. Regenerated from the deterministic generator; names coexist with legacy mon_*/step_* files.
- Enemy portraits at 64px: silhouette coverage 13-29% - all read as silhouettes; no regen needed.
- Item icons audited at 32px (coverage + luminance contrast): ancient_key, coin, fuse FAILED -> regenerated with darker fills + brighter accents (contrast now lstd 24-48). Other 24 passed.
- The 26 replaced Phase-1 originals copied to assets/textures/items_legacy/.
- Palette scan over ALL generated PNGs: pure #000000/#ffffff pixels = 0, neon = 0. No regens required (Task 6 clean pass).
- Audio budget fixed via ffmpeg 8.1.2: 5 long loops -> OGG Vorbis q4 mono, all <1 MB; full-length WAV masters archived under ambience/wav_src/. Details: docs/AUDIO_CONVERT.md.

## Enemy portraits 512x512 RGBA

| File | Size | Status | Fix notes |
|---|---|---|---|
| assets/textures/enemies/sniper_512.png | 24.0 KB | OK | 64px silhouette verified |
| assets/textures/enemies/brute_512.png | 23.5 KB | OK | 64px silhouette verified |
| assets/textures/enemies/burner_512.png | 22.2 KB | OK | 64px silhouette verified |
| assets/textures/enemies/rotter_512.png | 16.8 KB | OK | 64px silhouette verified |
| assets/textures/enemies/hound_512.png | 36.6 KB | OK | 64px silhouette verified |
| assets/textures/enemies/tvar_512.png | 48.5 KB | OK | 64px silhouette verified |
| assets/textures/enemies/architect_512.png | 20.3 KB | OK | 64px silhouette verified |

## Item icons 128x128 RGBA brass-outline

| File | Size | Status | Fix notes |
|---|---|---|---|
| assets/textures/items/ammo.png | 0.5 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/ancient_key.png | 0.9 KB | REGENERATED P2 | 32px contrast fix; original in items_legacy |
| assets/textures/items/backpack.png | 0.7 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/bandage.png | 0.7 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/battery.png | 0.5 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/blueprint.png | 0.4 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/cable.png | 1.0 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/can_food.png | 0.6 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/circuit.png | 0.6 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/coin.png | 1.2 KB | REGENERATED P2 | 32px contrast fix; original in items_legacy |
| assets/textures/items/explosive.png | 0.7 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/flashlight.png | 0.5 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/fuse.png | 0.5 KB | REGENERATED P2 | 32px contrast fix; original in items_legacy |
| assets/textures/items/gear.png | 0.8 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/key.png | 0.5 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/medkit.png | 0.6 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/molotov.png | 0.7 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/motor.png | 0.5 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/radio_part.png | 0.8 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/scope_lens.png | 1.0 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/serum.png | 0.4 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/taser.png | 0.4 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/tool.png | 0.7 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/transformer.png | 0.5 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/transistor.png | 0.4 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/water.png | 0.7 KB | OK | replaced existing icon; original in items_legacy |
| assets/textures/items/wiring.png | 0.7 KB | OK | replaced existing icon; original in items_legacy |

## District tilesets 256x256 RGB seamless

| File | Size | Status | Fix notes |
|---|---|---|---|
| assets/textures/tiles/suburbs_floor.png | 48.1 KB | OK | - |
| assets/textures/tiles/suburbs_wall.png | 45.3 KB | OK | - |
| assets/textures/tiles/residential_floor.png | 53.1 KB | OK | - |
| assets/textures/tiles/residential_wall.png | 44.1 KB | OK | - |
| assets/textures/tiles/park_floor.png | 60.0 KB | OK | - |
| assets/textures/tiles/park_wall.png | 46.2 KB | OK | - |
| assets/textures/tiles/school_floor.png | 46.6 KB | OK | - |
| assets/textures/tiles/school_wall.png | 45.8 KB | OK | - |
| assets/textures/tiles/hospital_floor.png | 46.4 KB | OK | - |
| assets/textures/tiles/hospital_wall.png | 47.1 KB | OK | - |
| assets/textures/tiles/gas_station_floor.png | 49.9 KB | OK | - |
| assets/textures/tiles/gas_station_wall.png | 44.3 KB | OK | - |
| assets/textures/tiles/police_floor.png | 46.4 KB | OK | - |
| assets/textures/tiles/police_wall.png | 43.7 KB | OK | - |
| assets/textures/tiles/warehouses_floor.png | 49.4 KB | OK | - |
| assets/textures/tiles/warehouses_wall.png | 46.8 KB | OK | - |
| assets/textures/tiles/industrial_floor.png | 49.1 KB | OK | - |
| assets/textures/tiles/industrial_wall.png | 45.1 KB | OK | - |
| assets/textures/tiles/substation_floor.png | 55.7 KB | OK | - |
| assets/textures/tiles/substation_wall.png | 59.2 KB | OK | - |
| assets/textures/tiles/power_station_floor.png | 51.8 KB | OK | - |
| assets/textures/tiles/power_station_wall.png | 44.3 KB | OK | - |

## UI elements chamfered RGBA

| File | Size | Status | Fix notes |
|---|---|---|---|
| assets/textures/ui/btn_normal.png | 0.2 KB | OK | - |
| assets/textures/ui/btn_hover.png | 0.2 KB | OK | - |
| assets/textures/ui/btn_pressed.png | 0.2 KB | OK | - |
| assets/textures/ui/btn_disabled.png | 0.2 KB | OK | - |
| assets/textures/ui/progress_frame.png | 0.2 KB | OK | - |
| assets/textures/ui/progress_fill.png | 0.2 KB | OK | - |
| assets/textures/ui/tooltip_panel.png | 0.6 KB | OK | - |
| assets/textures/ui/inventory_slot.png | 0.4 KB | OK | - |
| assets/textures/ui/bar_health.png | 0.2 KB | OK | - |
| assets/textures/ui/bar_stamina.png | 0.2 KB | OK | - |
| assets/textures/ui/bar_battery.png | 0.3 KB | OK | - |
| assets/textures/ui/status_bleed.png | 0.3 KB | OK | - |
| assets/textures/ui/status_burn.png | 0.4 KB | OK | - |
| assets/textures/ui/status_poison.png | 0.4 KB | OK | - |
| assets/textures/ui/status_slow.png | 0.4 KB | OK | - |
| assets/textures/ui/status_stun.png | 0.4 KB | OK | - |

## SFX WAV 44.1kHz mono 16-bit

| File | Size | Status | Fix notes |
|---|---|---|---|
| assets/audio/sfx/ui_click.wav | 7.8 KB | OK | sample import; low latency |
| assets/audio/sfx/ui_hover.wav | 4.3 KB | OK | sample import; low latency |
| assets/audio/sfx/ui_error.wav | 25.9 KB | OK | sample import; low latency |
| assets/audio/sfx/ui_save.wav | 24.2 KB | OK | sample import; low latency |
| assets/audio/sfx/ui_achievement.wav | 66.8 KB | OK | sample import; low latency |
| assets/audio/sfx/footstep_concrete.wav | 13.0 KB | REGENERATED P2 | sample import; low latency |
| assets/audio/sfx/footstep_metal.wav | 27.6 KB | REGENERATED P2 | sample import; low latency |
| assets/audio/sfx/footstep_wood.wav | 17.3 KB | REGENERATED P2 | sample import; low latency |
| assets/audio/sfx/shot_light.wav | 43.1 KB | OK | sample import |
| assets/audio/sfx/shot_heavy.wav | 73.3 KB | OK | sample import |
| assets/audio/sfx/monster_shadow_click.wav | 73.3 KB | REGENERATED P2 | sample import |
| assets/audio/sfx/monster_crawler_scrape.wav | 81.9 KB | REGENERATED P2 | sample import |
| assets/audio/sfx/monster_watcher_breath.wav | 258.4 KB | REGENERATED P2 | sample import |
| assets/audio/sfx/monster_hunter_step.wav | 36.2 KB | OK | sample import |
| assets/audio/sfx/monster_destroyer_hum.wav | 224.0 KB | REGENERATED P2 | sample import |

## Ambience loops

| File | Size | Status | Fix notes |
|---|---|---|---|
| assets/audio/ambience/ambient_dark_loop.ogg | 186.4 KB | CONVERTED P2 | OGG q4 mono <1MB; stream import, loop=true |
| assets/audio/ambience/ambient_lit_loop.ogg | 950.9 KB | CONVERTED P2 | OGG q4 mono <1MB; stream import, loop=true |
| assets/audio/ambience/threat_low_loop.ogg | 415.3 KB | CONVERTED P2 | OGG q4 mono <1MB; stream import, loop=true |
| assets/audio/ambience/threat_high_loop.ogg | 297.2 KB | CONVERTED P2 | OGG q4 mono <1MB; stream import, loop=true |
| assets/audio/ambience/action_sting_loop.ogg | 100.7 KB | CONVERTED P2 | OGG q4 mono <1MB; stream import, loop=true |
| assets/audio/ambience/wav_src/ambient_dark_loop.wav | 10336.0 KB | ARCHIVED | full-length master; exclude from export/import |
| assets/audio/ambience/wav_src/ambient_lit_loop.wav | 10336.0 KB | ARCHIVED | full-length master; exclude from export/import |
| assets/audio/ambience/wav_src/threat_low_loop.wav | 5168.0 KB | ARCHIVED | full-length master; exclude from export/import |
| assets/audio/ambience/wav_src/threat_high_loop.wav | 3445.4 KB | ARCHIVED | full-length master; exclude from export/import |
| assets/audio/ambience/wav_src/action_sting_loop.wav | 1378.2 KB | ARCHIVED | full-length master; exclude from export/import |

## Legacy item icons (Phase-1 originals)

| File | Size | Status | Fix notes |
|---|---|---|---|
| assets/textures/items_legacy/ammo.png | 1.5 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/ancient_key.png | 5.2 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/backpack.png | 1.2 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/bandage.png | 7.2 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/battery.png | 3.2 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/cable.png | 5.8 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/can_food.png | 1.3 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/circuit.png | 2.9 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/coin.png | 8.7 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/explosive.png | 5.0 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/flashlight.png | 6.6 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/fuse.png | 1.6 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/gear.png | 9.8 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/key.png | 4.5 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/medkit.png | 2.4 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/molotov.png | 4.3 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/motor.png | 4.3 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/radio_part.png | 4.6 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/scope_lens.png | 8.6 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/serum.png | 2.6 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/taser.png | 3.4 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/tool.png | 6.2 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/transformer.png | 2.8 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/transistor.png | 3.3 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/water.png | 1.1 KB | ARCHIVED | read-only reference |
| assets/textures/items_legacy/wiring.png | 4.4 KB | ARCHIVED | read-only reference |

## Shaders GL Compatibility single-pass mobile-safe

| File | Size | Status | Fix notes |
|---|---|---|---|
| assets/shaders/fog_depth.gdshader | 1.2 KB | OK | exp distance fog #1a2133 d=0.012 start=5m via view-dist varying |
| assets/shaders/flashlight_cone.gdshader | 1.5 KB | OK | blend_add unshaded brass cone, axial+rim falloff, flicker uniform |
| assets/shaders/grain_overlay.gdshader | 1.4 KB | OK | hint_screen_texture grain 10% animated + vignette |
| assets/shaders/damage_vignette.gdshader | 1.2 KB | OK | ember #b4452f vignette, 60bpm pulse, script-driven strength/fade 3s |
| assets/shaders/ui_panel.gdshader | 2.0 KB | OK | chamfered SDF panel #141b24 border #2a3340 + grain |

## Surface textures 512x512 RGB seamless night-muted

| File | Size | Status | Fix notes |
|---|---|---|---|
| assets/textures/surfaces/concrete_512.png | 194.4 KB | OK | wrapped speckles/cracks; pattern period divides 512 |
| assets/textures/surfaces/brick_512.png | 189.5 KB | OK | wrapped speckles/cracks; pattern period divides 512 |
| assets/textures/surfaces/metal_rust_512.png | 261.4 KB | OK | wrapped speckles/cracks; pattern period divides 512 |
| assets/textures/surfaces/asphalt_512.png | 224.5 KB | OK | wrapped speckles/cracks; pattern period divides 512 |
| assets/textures/surfaces/wood_512.png | 209.1 KB | OK | wrapped speckles/cracks; pattern period divides 512 |
| assets/textures/surfaces/tile_white_512.png | 171.2 KB | OK | wrapped speckles/cracks; pattern period divides 512 |

## Store key art — one composition: streetlight warm cone #c9a24a vs cold dark #1a2133, small human silhouette, no text/logos/ratings

| File | Size | Status | Fix notes |
|---|---|---|---|
| assets/store/play_icon_512.png | 52.8 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/feature_graphic_1024x500.png | 42.6 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/capsule_header_460x215.png | 29.7 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/capsule_main_616x353.png | 48.4 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/capsule_small_231x87.png | 10.7 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/library_hero_1920x620.png | 72.7 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/background_1920x1080.png | 120.4 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/screenshot_01.png | 104.0 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/screenshot_02.png | 105.4 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/screenshot_03.png | 110.8 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/screenshot_04.png | 69.1 KB | OK | crop/resize of shared master; <=500KB |
| assets/store/screenshot_05.png | 64.3 KB | OK | crop/resize of shared master; <=500KB |

## Import recommendations

Audio per-file loader table: docs/AUDIO_CONVERT.md. Textures: tiles/surfaces -> VRAM compression; UI/icons/portraits -> lossless (alpha crisp).

## Missing / blocked

None. All deliverables present after regeneration of the 7 deleted sfx. Retry budget used: 3 rounds (icon contrast x1, store PNG size x2) - none exhausted.
