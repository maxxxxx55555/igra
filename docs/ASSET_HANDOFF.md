# ASSET_HANDOFF.md — OX ALPHA asset department → integration owners
Session: ultra-autonomous marathon (same day as Phase-4 VFX pass). All sizes verified on disk at write time.

## New deliverables and suggested consumers

| File / set | Size | Suggested consumer |
|---|---|---|
| assets/textures/grading/night_grade.png (+ alias lut_night.png) | 1 KB | Color correction: use as GradientMap/ColorCorrectRamp in a post CanvasLayer, or sample in grain_overlay.gdshader. Alias kept because an external pruner deleted night_grade.png twice earlier; if it vanishes again, prefer lut_night.png. Regen recipe lives in REPORT_ASSETS.md. |
| assets/audio/sfx/mon_{sniper,brute,burner,rotter,hound,tvar}_{attack,hit,death,step}.wav | 24 files, 25–137 KB | scripts/enemies/<new>_3d.gd via base_monster._set_cues(). Contract verified from code: flat path res://assets/audio/sfx/<file>.wav; entry shape {&"cue": {"file": "<bare name>", "db": -6.0}}; play via play_cue(&"attack") etc. Suggested db: attack -4, hit -6, death -2, step -12 (steps loop often). |
| assets/textures/ui/{ui_divider_brass,ui_corner_accent,rarity_common,rarity_rare,rarity_epic,hitmarker_64,crosshair_64,crosshair_dot,interact_icon_64,save_icon_brass_64}.png | <1 KB each | HUD theme (crosshair/hitmarker → player weapon node; rarity frames → inventory slot overlay; divider/corner → StyleBoxFlat Texture under-panel). Note: SESSION_REPORT says UI currently draws via StyleBoxFlat — these are optional crisp overlays. |
| assets/textures/surfaces/{door_metal,door_wood,cabinet_wood,powerbox_metal}_512.png | 199–287 KB | Prop albedo slots per docs/PROP_SPECS.md material conventions (M_base/M_metal/M_accent). |
| assets/textures/surfaces/{concrete_wall,gravel}_512.png | ~220 KB | District environment materials (interior concrete walls, substation/street ground blend). |
| assets/textures/fx/{flashlight_cookie_256,muzzle_flash_alt_64,spark_alt_64,poison_cloud_64,strobe_flash_128}.png | 3–27 KB | SpotLight3D light_texture (cookie), weapon flash particles, taser spark GPUParticles, rotter/tvar poison wisps, tvar weakness strobe (PointLight2D/3D energy burst). |
| assets/store/press/{banner_discord_1280x640,banner_twitter_1500x500,press_cover_1920x1080,emblem_brass_512}.png | 28–120 KB | Marketing only; do not import into game scenes. |
| assets/audio/sfx + ambience loudness survey | docs/AUDIO_LOUDNESS.md | Audio owner: apply listed gains (37 files >3 dB off target) or ask asset agent to bake at generation. No wired file was modified. |
| docs/TRAILER_STORYBOARD.md (earlier) | — | Capture team. |

## Blocked list

None open. Previously blocked grading/night_grade.png resolved this session (pruner was transient; canonical + alias both survived a 63 s watch).

## Next-session backlog

1. VISUAL_AUDIT.md still does not exist — when Claude publishes it, run the regen pass against every owned asset flagged ugly/mismatched.
2. Wire monster cue dicts for the six new enemies (snippets above) and confirm play_cue keys match AI states (attack/death likely need new state hooks).
3. Apply AUDIO_LOUDNESS.md gains (or request baked-loudness regeneration).
4. Optional: bake lit-tile variants into district TileSets as alternate sources for DAY/GENERATOR mode.
5. If pruner returns on grading/: switch consumer to lut_night.png and re-run the sentinel diagnosis before recreating files.

## Generator provenance

All deterministic generators live in %TEMP%/opencode/tls_gen/ (gen_textures.py, gen_audio.py, gen_phase2_art.py, gen_final_store.py, gen_vfx.py, gen_ui_crisp.py, gen_props2.py, gen_gamefeel.py, gen_press.py, gen_monster_sfx.py, append_report.py, write_report.py). Copy them into the repo or back them up — temp storage does not survive OS cleanup.


## W1 — endings warmth fix + wind unblock

| File / set | Size | Suggested consumer |
|---|---|---|
| assets/store/endings/ending_{light,hope,dark}.png | 14–114 KB | EndingScreen/win_screen + marketing. GDD §12.4 warmth gradient now canon-ordered: dark=blackout+lone ember (COLDEST) → truth (teal bunker) → survivor (neutral lone light) → hope (partial warm lights + faint cold dawn hint) → light (whole city brass, WARMEST/best). truth/survivor untouched (already canon). Deterministic regen: %TEMP%/opencode/tls_gen/fix_endings_warmth.py (seeds 201/202/203); pre-fix copies in _BACKUPS/2026-08-24_*/. |
| assets/audio/ambience/weather/wind_loop.ogg | 380 KB | UNBLOCKED (was BLOCKED 4 attempts, ERROR_LOG): attempt-5 stationary filtered-noise carrier, 45.00s 44.1k mono, I=−18.19 LUFS TP=−10.55 LRA=1.30 seam=−1.08dB. Safe to wire into MusicManager weather switch (rain PASS / wind PASS). |

## Mega-wave A additions (audio + atmosphere)

| File / set | Size | Suggested consumer |
|---|---|---|
| assets/audio/ambience/districts/[district]_dark.ogg x11 | 36 s seamless, 55-324 KB | MusicManager/AmbiencePlayer district switch: crossfade 1.5 s on district_id change; loop=true in import; all RMS -18 dBFS |
| assets/audio/ambience/districts/{suburbs,hospital,power_station}_lit.ogg | 36 s | same player, DAY/GENERATOR mode variant |
| assets/textures/sky/night_sky_panorama_2048x1024.png | 45 KB indexed | WorldEnvironment PanoramaSky backdrop; horizon glow at bottom edge (v=1.0); NO moon baked |
| assets/textures/sky/moon_glow_256.png | 27 KB RGBA | separate Sprite3D/billboard if a moon event is ever staged (design says no permanent moon) |
| assets/textures/fx/{burn_loop,poison_drip,stun_stars,slow_trail,bleed_pulse,loot_glint,save_sparkle,taser_arc}_*.png | 1-3 KB | StatusEffects VFX (particles/HUD): burn/poison/stun/slow/bleed map 1:1 to GDD status ids; loot_glint -> pickup pulse; save_sparkle -> checkpoint flash; taser_arc -> projectile sprite |
| assets/audio normalization | done | 37 files now -14/-18 LUFS in place; originals in assets/audio/_pre_norm/ (exclude from import); 10 legacy files upsampled 22.05k->44.1k (list in AUDIO_LOUDNESS.md) |

### Wiring snippet for new-roster monster cues

```gdscript
_set_cues({
    &"attack": {"file": "mon_<name>_attack", "db": -4.0},
    &"hit": {"file": "mon_<name>_hit", "db": -6.0},
    &"death": {"file": "mon_<name>_death", "db": -2.0},
    &"step": {"file": "mon_<name>_step", "db": -12.0},
})
```


## Truth-wave additions (music + footsteps final)

| File / set | Size | Suggested consumer |
|---|---|---|
| assets/audio/music/layer_{dark,lit}.ogg | 120 s, ~200 KB | MusicManager layered stack: preload order dark -> lit -> threat_low -> threat_high -> action; all start on a downbeat and use exact bar-multiple lengths, so crossfade at bar boundaries (or simple equal-power 2 s) never clashes; loop=true import; -18 LUFS |
| assets/audio/music/layer_threat_{low,high}.ogg | 60 s | same stack; low = 15 bars @60bpm, high = 90 beats @90bpm |
| assets/audio/music/layer_action.ogg | 60.1 s, -14 LUFS | combat layer; 30 bars @120 bpm (DEFAULT_CHOICE bpm — spec gave none) |
| assets/audio/sfx/footsteps/{concrete,metal,wood,grass,gravel,tile}_{walk,jog,sprint}.wav | 0.16-0.24 s, -14 LUFS | DEFAULT_CHOICE: current scripts/systems/footstep_system.gd has NO per-speed naming — it plays flat step_*/footstep_* singles with volume+pitch speed mult. To use these, extend MATERIALS with per-speed sample lookup or map surface->folder + state suffix (WALK/JOG/SPRINT). grass/gravel/tile have no MATERIALS keys yet (code covers asphalt/concrete/wood/metal/puddle/glass). |
| assets/audio/sfx/tvar_sting.wav / architect_sting.wav | 12 s / 15 s, -14 LUFS | Boss intro one-shots (base_monster play_cue or dedicated boss music stinger); WAV format mandated by task so both exceed the general 1 MB audio cap (1009 KB / 1262 KB) — convert to OGG if the cap wins over format |
| assets/audio/sfx/ui_back.wav / ui_tab.wav | <0.3 s | UI theme: back navigation / tab switch ticks |

Normalization: all 27 new files loudnorm'd to canon (-14 LUFS sfx / -18 LUFS music), TP <= -1.5 dBFS; pre-normalization copies in assets/audio/_pre_norm/{music,sfx}/.

## Session 2 deliverables (audio detail: weapons + district details + interact)

All 78 files verified on disk at write time: 44.1kHz mono, sizes 3.5-281.5KB, loudness measured per file in docs/REPORT_AUDIO_DETAIL.md (offsets column for engine volume_db compensation). Raw pre-norm masters under assets/audio/_pre_norm/{sfx/weapons,sfx/interact,ambience/district_details}/ — do NOT import those into Godot.

| File / set | Size | Suggested consumer |
|---|---|---|
| assets/audio/sfx/weapons/{pistol,rifle,shotgun}_{fire,reload,empty,draw,holster,distant}.wav | 3.5-100.9KB, 18 files | scripts/weapons/: weapon_pistol.gd const SHOOT/RELOAD (:5-6) and weapon_rifle.gd/weapon_shotgun.gd _sfx.stream (:13-15) currently preload legacy generic sfx_shoot.wav/sfx_reload.wav - rewire per weapon; fire/reload also fit weapon_base.gd exported fire_sound/reload_sound via AudioManager.play_sound_3d; *_empty on empty trigger; *_draw/*_holster on weapon_manager.gd slot switch; *_distant as far-field layer for enemy hearing/AI alert |
| assets/audio/ambience/district_details/<district>_<detail>.ogg | ~220-280KB each, 40 files, 30.00s seamless loops, -18 LUFS target | scripts/world/district_atmosphere.gd (EventBus.district_entered); layer UNDER existing assets/audio/ambience/districts/<id>_dark.ogg; district slugs are canon IDs from scripts/district_manager.gd DISTRICTS (suburbs, residential, park, school, hospital, gas_station, police, warehouses, industrial, substation, power_station); event-sparse beds list a +dB offset in REPORT_AUDIO_DETAIL - apply as AudioStreamPlayer volume_db if full loudness wanted |
| assets/audio/sfx/interact/door_{open,close}_{wood,metal}.wav | 17-36KB | scripts/gameplay/door.gd + scripts/electronic_door.gd (pick by door material) |
| assets/audio/sfx/interact/generator_start.wav / generator_run_loop.ogg / generator_stop.wav | 86-225KB | scripts/generator.gd state machine (start crank -> run loop [30s seamless, -18 LUFS loop target] -> stop sputter); ftue_generator variants can reuse |
| assets/audio/sfx/interact/workbench_open.wav / workbench_craft_success.wav / workbench_craft_fail.wav | 22-31KB | scripts/gameplay/craft_station.gd open/success/fail |
| assets/audio/sfx/interact/loot_pickup_generic.wav / loot_pickup_rare.wav | 14-24KB | scripts/inventory/item_pickup.gd by rarity (rare = pitched-up sparkle) |
| assets/audio/sfx/interact/save_success.wav / save_fail.wav | 29-36KB | save UI (scripts/ui/save_slots_ui.gd) confirm/error paths |
| assets/audio/sfx/interact/cabinet_open.wav / cabinet_close.wav | 14-26KB | container/inspectable cabinets (scripts/inspectable.gd consumers) |
| assets/audio/sfx/interact/fuse_insert.wav / fuse_box_close.wav | 5-30KB | scripts/fuse_box.gd insert + cover close (close includes faint hum fade-in hint) |
| assets/audio/sfx/interact/cable_connect.wav | 15.6KB | scripts/world/cable_box_interactable.gd + puzzle success (scripts/ui/puzzle_cables.gd) |
| assets/audio/sfx/interact/item_drop.wav | 17.3KB | inventory drop action |

Wiring notes: all one-shots are dry (no reverb tail) - add bus reverb in engine per audio canon. Loops import with loop=true. Naming matches backlog spec verbatim; no invented IDs.
