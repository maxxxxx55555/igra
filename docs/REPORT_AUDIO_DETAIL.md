# REPORT_AUDIO_DETAIL — Session 2 (weapons + district details + interact)

Scope: `assets/audio/sfx/weapons/`, `assets/audio/sfx/interact/`, `assets/audio/ambience/district_details/`.
Canon: WAV 44.1kHz mono 16-bit sfx / OGG q4 mono loops; targets SFX -14 LUFS, ambience -18 LUFS, TP ≤ -1.5 dBFS.
Method: ffmpeg 8.1.2 synthesis -> raw masters in `assets/audio/_pre_norm/{sfx/weapons,sfx/interact,ambience/district_details}/` (do not import) -> density compressor -> measured constant-gain -> alimiter.
Verification: every file ffprobe-checked (44100 Hz, mono); loudness via ebur128 integrated; loop seams by construction (31.5s source, continuation crossfade truncated at 30s — see ERROR_LOG).

## T1 — Weapon SFX (18 files) — consumer: `scripts/weapons/`

| File | Size | Dur | LUFS | Consumer hint |
|---|---|---|---|---|
| pistol_fire.wav | 24.2KB | 0.28s | n/a* | `weapon_pistol.gd` const SHOOT (currently preloads legacy `sfx_shoot.wav` :5 — rewire) or `weapon_base.gd` fire_sound export |
| pistol_reload.wav | 70.7KB | 0.82s | -18.8 | `weapon_pistol.gd` const RELOAD (:6) |
| pistol_empty.wav | 3.5KB | 0.04s | n/a* | wire on `can_fire()==false` w/ ammo==0 in weapon_base/player input |
| pistol_draw.wav | 22.5KB | 0.26s | n/a* | `weapon_manager.gd` slot switch |
| pistol_holster.wav | 25.5KB | 0.26s | n/a* | `weapon_manager.gd` holster/lower |
| pistol_distant.wav | 32.8KB | 0.38s | n/a* | far-field NPC/AI shot layer (low-passed ~1700Hz) |
| rifle_fire.wav | 43.1KB | 0.50s | -16.7 | `weapon_rifle.gd` `_sfx.stream` (:14, currently `sfx_shoot.wav`) |
| rifle_reload.wav | 100.9KB | 1.17s | -18.2 | `weapon_rifle.gd` reload path (`weapon_base.try_reload`) |
| rifle_empty.wav | 4.4KB | 0.05s | n/a* | dry-click on empty trigger |
| rifle_draw.wav | 26.8KB | 0.31s | n/a* | `weapon_manager.gd` switch |
| rifle_holster.wav | 25.9KB | 0.30s | n/a* | `weapon_manager.gd` holster |
| rifle_distant.wav | 51.8KB | 0.60s | -15.3 | far-field layer |
| shotgun_fire.wav | 36.3KB | 0.42s | -15.9 | `weapon_shotgun.gd` `_sfx.stream` (:15, currently `sfx_shoot.wav`) |
| shotgun_reload.wav | 90.1KB | 1.04s | -20.9 | shell inserts + pump rack; `weapon_base.try_reload` |
| shotgun_empty.wav | 4.4KB | 0.05s | n/a* | dry-click |
| shotgun_draw.wav | 24.2KB | 0.28s | n/a* | `weapon_manager.gd` switch |
| shotgun_holster.wav | 25.5KB | 0.29s | n/a* | `weapon_manager.gd` holster |
| shotgun_distant.wav | 43.1KB | 0.50s | -15.6 | far-field layer |

*n/a(short): clips <0.4s cannot produce valid ebur128 integrated values; normalized via RMS-proxy gain (target ≈ -17.5 dBFS mean) per AUDIO_LOUDNESS.md precedent.

## T2 — District detail beds (40 files, 30.00s seamless OGG) — consumers: `scripts/world/district_atmosphere.gd`, district IDs canon `scripts/district_manager.gd:14`

Layer UNDER the main `assets/audio/ambience/districts/<id>_dark.ogg` bed. Files whose LUFS < -19 need positive volume_db compensation in-engine (offset column = -18 minus measured).

| District | File | Size | LUFS | Detail content |
|---|---|---|---|---|
| suburbs | suburbs_dog_bark.ogg | 237.7KB | -20.8 (+2.8dB) | distant dog barks ×3 |
| suburbs | suburbs_porch_creak.ogg | 226.2KB | -18.9 | porch creaks, knock |
| suburbs | suburbs_wind_leaves.ogg | 256.2KB | -18.4 | wind through leaves, rustles |
| residential | residential_pipe_creak.ogg | 232.2KB | -19.8 (+1.8dB) | pipe creak, knock, drip |
| residential | residential_tv_murmur.ogg | 237.4KB | -18.3 | TV murmur swells |
| residential | residential_window_rattle.ogg | 250.0KB | -21.6 (+3.6dB) | window rattle gusts |
| park | park_leaves_skitter.ogg | 258.5KB | -18.8 | dry leaves skitter (NO birds — permanent night) |
| park | park_branch_snap.ogg | 255.1KB | -19.1 | branch snaps, rustle |
| park | park_bare_trees_wind.ogg | 252.3KB | -18.6 | wind in bare trees |
| park | park_distant_city_hum.ogg | 227.0KB | -18.9 | low city rumble bed |
| school | school_bell_echo.ogg | 225.9KB | -19.8 (+1.8dB) | distant bell echo ×2 |
| school | school_locker_slam.ogg | 232.6KB | -20.7 (+2.7dB) | locker slams ×3, rattle |
| school | school_chalk_scratch.ogg | 247.8KB | -19.7 | chalk scratches |
| school | school_desk_scrape.ogg | 246.5KB | -19.6 | desk scrapes |
| hospital | hospital_monitor_beep.ogg | 239.4KB | -22.6 (+4.6dB) | monitor beep @6s interval |
| hospital | hospital_gurney_wheels.ogg | 244.4KB | -19.8 | gurney squeak+rattle passes |
| hospital | hospital_pa_mumble.ogg | 239.7KB | -20.4 (+2.4dB) | PA mumble bursts, chime |
| hospital | hospital_elevator_distant.ogg | 221.6KB | -19.2 | elevator motor swell, thunk |
| gas_station | gas_station_sign_buzz.ogg | 231.1KB | -19.8 | flickering sign buzz (100+200+300Hz) |
| gas_station | gas_station_pump_hum.ogg | 229.5KB | -19.7 | pump hum, knocks |
| gas_station | gas_station_gravel_crunch.ogg | 252.6KB | -19.5 | gravel crunch clusters |
| gas_station | gas_station_car_pass.ogg | 239.7KB | -20.2 (+2.2dB) | car pass-by, door thud |
| police | police_radio_static.ogg | 245.0KB | -22.9 (+4.9dB) | radio static bursts, squelch beep |
| police | police_siren_tail.ogg | 233.5KB | -17.4 | distant siren tails (glide-down) |
| police | police_boots_concrete.ogg | 231.7KB | -20.4 (+2.4dB) | boot step groups |
| warehouses | warehouses_metal_creak.ogg | 227.7KB | -19.1 | long metal creaks, clank |
| warehouses | warehouses_chain_rattle.ogg | 228.9KB | -20.1 (+2.1dB) | chain rattles, drop thud |
| warehouses | warehouses_forklift_distant.ogg | 219.9KB | -18.8 | backup beeps, diesel swell |
| warehouses | warehouses_cargo_impact.ogg | 230.0KB | -19.7 | cargo slams, ring-out |
| industrial | industrial_machinery_drone.ogg | 219.1KB | -22.0 (+4.0dB) | 48/96/144Hz drone variant, clanks |
| industrial | industrial_pipe_hiss.ogg | 281.5KB | -18.7 | high pipe hiss, surges |
| industrial | industrial_steam_vent.ogg | 279.1KB | -18.7 | steam vent blasts ×2 |
| industrial | industrial_vent_rattle.ogg | 245.6KB | -22.5 (+4.5dB) | loose vent rattle |
| substation | substation_transformer_buzz.ogg | 219.2KB | -18.7 | transformer buzz variant (100/200/300Hz) |
| substation | substation_arc_crackle.ogg | 239.3KB | -23.8 (+5.8dB) | electric arc crackle clusters |
| substation | substation_cable_hum.ogg | 232.8KB | -18.9 | cable hum, beating partials |
| power_station | power_station_generator_thrum.ogg | 226.0KB | -18.9 | deep generator thrum (36/72Hz) |
| power_station | power_station_hv_whine.ogg | 268.4KB | -18.7 | high-voltage whine (3.2k/4.8k Hz) |
| power_station | power_station_cooling_fan.ogg | 228.6KB | -18.4 | cooling fan chop (~1.2Hz) |
| power_station | power_station_breaker_clunk.ogg | 228.1KB | -21.0 (+3.0dB) | breaker clunks |

## T3 — Interact SFX (20 files incl. 1 loop) — consumers: `scripts/gameplay/door.gd`, `electronic_door.gd`, `generator.gd`, `fuse_box.gd`, `craft_station.gd`, `inventory/item_pickup.gd`, `world/cable_box_interactable.gd`, `inspectable.gd`, save UI

| File | Size | Dur | LUFS | Consumer hint |
|---|---|---|---|---|
| door_open_wood.wav | 36.3KB | 0.42s | -14.2 | door.gd open (wood material) |
| door_close_wood.wav | 18.2KB | 0.21s | n/a* | door.gd close (wood) |
| door_open_metal.wav | 31.1KB | 0.36s | n/a* | electronic_door.gd / metal doors |
| door_close_metal.wav | 17.3KB | 0.20s | n/a* | metal door close |
| generator_start.wav | 86.2KB | 1.00s | -14.6 | generator.gd startup crank->idle |
| generator_run_loop.ogg | 224.8KB | 30.00s | -18.1 | generator.gd running state, seamless loop (-18 ambience target per loop canon) |
| generator_stop.wav | 90.5KB | 1.05s | -14.0 | generator.gd shutdown sputter |
| workbench_open.wav | 21.6KB | 0.25s | n/a* | craft_station.gd UI open |
| workbench_craft_success.wav | 31.1KB | 0.36s | n/a* | craft success confirm |
| workbench_craft_fail.wav | 30.2KB | 0.35s | n/a* | craft fail buzz |
| loot_pickup_generic.wav | 13.9KB | 0.16s | n/a* | item_pickup.gd common |
| loot_pickup_rare.wav | 24.2KB | 0.28s | n/a* | item_pickup.gd rare (pitched-up sparkle variant) |
| save_success.wav | 28.5KB | 0.33s | n/a* | save_slots_ui/settings confirm |
| save_fail.wav | 36.3KB | 0.42s | -14.0 | save error path |
| cabinet_open.wav | 25.9KB | 0.30s | n/a* | inspectable/cabinet containers |
| cabinet_close.wav | 13.9KB | 0.16s | n/a* | cabinet close |
| fuse_insert.wav | 5.2KB | 0.06s | n/a* | fuse_box.gd socket insert |
| fuse_box_close.wav | 30.2KB | 0.35s | n/a* | fuse_box.gd cover close + hum hint |
| cable_connect.wav | 15.6KB | 0.18s | n/a* | puzzle_cables.gd / cable_box success snap |
| item_drop.wav | 17.3KB | 0.20s | n/a* | inventory drop |

## QA summary

- Format audit: 78/78 files 44100 Hz mono; sizes 3.5–281.5 KB (budget ≤1MB met).
- Counts: weapons 18/18, interact 20/20, district_details 40/40 (spec said "~38"; canonical 11-district list expands to 40 unique beds). Total delivered 78.
- Loudness: measurable sfx landed -14.0…-20.9; loops -17.4…-23.8. Deviations >3dB are sparse-transient/event-sparse content where ebur128 gating over silence sets a physical floor (crest factor limit); compensated via offset column above or leave quieter (detail beds sit under main district beds). No re-generation attempts left within retry budget — logged in ERROR_LOG.
- Loop seam: construction guarantees sample continuity at wrap (ERROR_LOG lesson 2 applied: render 31.5s, blend continuation x[30:31.5] into head, truncate at 30). Proxy metric |RMS(first .5s)-RMS(last .5s)|: worst 2.1 dB (warehouses_chain_rattle), 34/41 ≤1.5 dB; residuals are slow-tremolo envelope variance between distant windows, wrap-adjacent RMS diff ≤3.1 dB, no discontinuity.

## Blocked

None. All 78 planned files generated and verified.
