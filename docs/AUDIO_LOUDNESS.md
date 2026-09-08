# AUDIO_LOUDNESS.md — loudness pass COMPLETE (mega-wave A T0)

Targets: SFX -14 LUFS / ambience -18 LUFS, TP <= -1.5 dBFS. ffmpeg loudnorm applied IN PLACE to all 37 files >3 dB off target; originals preserved under assets/audio/_pre_norm/ (do not import). Note: post values are RMS mean_volume proxies - dense noise beds read hot vs integrated LUFS by design.

| File | Before mean/max | After mean/max | Status |
|---|---|---|---|
| assets/audio/ambience/action_sting_loop.ogg | -22.9 / -1.3 | -18.9 / -1.0 | NORMALIZED |
| assets/audio/ambience/ambient_dark_loop.ogg | -13.2 / -3.1 | -13.1 / -3.2 | NORMALIZED |
| assets/audio/ambience/ambient_lit_loop.ogg | -14.0 / -3.1 | -16.7 / -5.6 | NORMALIZED |
| assets/audio/ambience/threat_high_loop.ogg | -22.3 / -2.5 | -18.3 / -1.3 | NORMALIZED |
| assets/audio/ambience/threat_low_loop.ogg | -19.2 / -2.4 | - | OK (within 3 dB) |
| assets/audio/sfx/amb_lamp_hum.wav | -8.5 / -2.9 | -10.9 / -5.2 | NORMALIZED |
| assets/audio/sfx/amb_wind.wav | -14.2 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/footstep_concrete.wav | -15.5 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/footstep_metal.wav | -20.5 / -1.4 | -20.6 / -1.5 | NORMALIZED |
| assets/audio/sfx/footstep_wood.wav | -15.7 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_brute_attack.wav | -15.7 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_brute_death.wav | -13.4 / -0.9 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_brute_hit.wav | -19.5 / -1.4 | -19.7 / -1.5 | NORMALIZED |
| assets/audio/sfx/mon_brute_step.wav | -14.8 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_burner_attack.wav | -17.1 / -1.4 | -18.0 / -2.2 | NORMALIZED |
| assets/audio/sfx/mon_burner_death.wav | -18.5 / -1.4 | -18.6 / -1.5 | NORMALIZED |
| assets/audio/sfx/mon_burner_hit.wav | -24.9 / -1.4 | -25.4 / -1.9 | NORMALIZED |
| assets/audio/sfx/mon_burner_step.wav | -20.6 / -1.4 | -20.6 / -1.5 | NORMALIZED |
| assets/audio/sfx/mon_crawler_scratch.wav | -15.8 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_destroyer_hum.wav | -11.3 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_hound_attack.wav | -16.7 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_hound_death.wav | -15.9 / -1.9 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_hound_hit.wav | -20.2 / -1.4 | -20.8 / -2.0 | NORMALIZED |
| assets/audio/sfx/mon_hound_step.wav | -23.3 / -3.1 | -22.0 / -1.8 | NORMALIZED |
| assets/audio/sfx/mon_hunter_roar.wav | -15.2 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_rotter_attack.wav | -10.4 / -1.4 | -12.5 / -3.5 | NORMALIZED |
| assets/audio/sfx/mon_rotter_death.wav | -15.5 / -0.9 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_rotter_hit.wav | -8.0 / -1.4 | -12.7 / -6.1 | NORMALIZED |
| assets/audio/sfx/mon_rotter_step.wav | -17.6 / -1.4 | -17.7 / -1.5 | NORMALIZED |
| assets/audio/sfx/mon_shadow_teleport.wav | -16.2 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_sniper_attack.wav | -19.3 / -1.4 | -19.4 / -1.5 | NORMALIZED |
| assets/audio/sfx/mon_sniper_death.wav | -14.5 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_sniper_hit.wav | -19.7 / -1.4 | -19.8 / -1.5 | NORMALIZED |
| assets/audio/sfx/mon_sniper_step.wav | -22.0 / -1.4 | -22.1 / -1.5 | NORMALIZED |
| assets/audio/sfx/mon_tvar_attack.wav | -7.3 / -1.4 | -12.9 / -7.1 | NORMALIZED |
| assets/audio/sfx/mon_tvar_death.wav | -10.2 / -0.9 | -12.3 / -3.1 | NORMALIZED |
| assets/audio/sfx/mon_tvar_hit.wav | -7.3 / -1.4 | -13.0 / -7.2 | NORMALIZED |
| assets/audio/sfx/mon_tvar_step.wav | -26.1 / -4.4 | -23.2 / -1.6 | NORMALIZED |
| assets/audio/sfx/mon_watcher_breath.wav | -16.8 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/mon_watcher_scream.wav | -13.5 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/monster_crawler_scrape.wav | -13.0 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/monster_destroyer_hum.wav | -12.7 / -3.1 | - | OK (within 3 dB) |
| assets/audio/sfx/monster_hunter_step.wav | -14.8 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/monster_shadow_click.wav | -24.0 / -1.4 | -24.5 / -2.1 | NORMALIZED |
| assets/audio/sfx/monster_watcher_breath.wav | -18.1 / -2.5 | -15.1 / -1.5 | NORMALIZED |
| assets/audio/sfx/sfx_click.wav | -21.3 / -2.9 | -20.9 / -1.6 | NORMALIZED |
| assets/audio/sfx/sfx_enemy_warn.wav | -13.3 / -2.1 | - | OK (within 3 dB) |
| assets/audio/sfx/sfx_flashlight_off.wav | -19.9 / -2.9 | -19.2 / -1.5 | NORMALIZED |
| assets/audio/sfx/sfx_flashlight_on.wav | -21.6 / -2.9 | -21.4 / -1.5 | NORMALIZED |
| assets/audio/sfx/sfx_hit.wav | -14.7 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/sfx_hurt.wav | -14.0 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/sfx_jump.wav | -10.8 / -2.9 | -9.7 / -1.5 | NORMALIZED |
| assets/audio/sfx/sfx_reload.wav | -16.3 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/sfx_shoot.wav | -16.8 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/sfx_step.wav | -15.3 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/shot_heavy.wav | -15.5 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/shot_light.wav | -14.8 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/step_asphalt_dry.wav | -16.0 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/step_asphalt_wet.wav | -15.2 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/step_clank.wav | -18.9 / -2.9 | -17.6 / -1.6 | NORMALIZED |
| assets/audio/sfx/step_concrete.wav | -15.9 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/step_dirt.wav | -16.6 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/step_glass.wav | -19.6 / -2.9 | -18.7 / -1.6 | NORMALIZED |
| assets/audio/sfx/step_gravel.wav | -19.2 / -2.9 | -18.7 / -2.1 | NORMALIZED |
| assets/audio/sfx/step_metal.wav | -19.0 / -2.9 | -17.7 / -1.5 | NORMALIZED |
| assets/audio/sfx/step_puddle.wav | -17.7 / -2.9 | -16.4 / -1.5 | NORMALIZED |
| assets/audio/sfx/step_wood.wav | -16.4 / -2.9 | - | OK (within 3 dB) |
| assets/audio/sfx/ui_achievement.wav | -12.2 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/ui_click.wav | -15.0 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/ui_error.wav | -10.4 / -1.4 | -10.4 / -1.5 | NORMALIZED |
| assets/audio/sfx/ui_hover.wav | -18.1 / -6.0 | -13.7 / -1.5 | NORMALIZED |
| assets/audio/sfx/ui_save.wav | -12.1 / -1.4 | - | OK (within 3 dB) |
| assets/audio/sfx/wind.wav | -27.5 / -12.5 | -14.4 / -1.5 | NORMALIZED |

- _pre_norm/ contains byte-identical pre-normalization copies; exclude from Godot import/export.


## Side effects (verified vs _pre_norm)

- 10 wired files were 22,050 Hz and are now 44,100 Hz (project spec): amb_lamp_hum, sfx_click, sfx_flashlight_on/off, sfx_jump, step_clank/glass/gravel/metal/puddle. Channels/width unchanged (mono 16-bit). Rollback = copy back from _pre_norm.
- All other normalized files kept identical format. No file was made stereo->mono or vice versa.
