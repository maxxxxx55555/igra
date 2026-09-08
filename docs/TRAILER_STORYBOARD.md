# TRAILER_STORYBOARD.md — THE LAST STREETLIGHT (60–90 s target cut: ~75 s)
For human capture/recording. All referenced assets exist in-repo. No text overlays except the existing game logo at shot 10 (added in edit, frame left clear). Palette lock for grading: warm brass #c9a24a vs cold night #1a2133; apply assets/shaders/grain_overlay.gdshader look (grain 10%, vignette 35%) over all footage.

| # | Time | Camera | Action | Lighting note | Asset reference |
|---|---|---|---|---|---|
| 1 | 0:00–0:06 | Slow aerial push-in over rooftops | Dead city under fog; nothing moves; a dog barks far away | Cold only: #1a2133 haze, no warm sources yet | assets/store/screenshot_01.png mood; shaders/fog_depth.gdshader |
| 2 | 0:06–0:12 | Low angle at street end | THE streetlight buzzes, flickers twice, then holds warm | One practical: brass cone cuts fog, moths enter beam | shaders/flashlight_cone.gdshader; audio/sfx/amb_lamp_hum.wav; textures/enemies none |
| 3 | 0:06–0:12 alt | — | (beat shared with #2) | Pool of light forms ellipse on wet asphalt | assets/textures/surfaces/asphalt_512.png |
| 4 | 0:12–0:20 | Tracking dolly, knee height | Survivor walks into the pool, stops, looks up at the lamp | Rim-light bone edge on coat from lamp side; face stays dark | assets/textures/ui none; audio ambience/ambient_dark_loop.ogg under everything |
| 5 | 0:20–0:27 | First-person POV, handheld sway | Raise flashlight, click ON — beam reveals street | Beam = additive brass cone; grain ramps 8→12% | shaders/flashlight_cone.gdshader; audio/sfx/sfx_flashlight_on.wav; footstep_concrete.wav |
| 6 | 0:27–0:34 | POV freeze, slight zoom | Two ember eyes ignite at beam edge; scrape-scurry off-frame | Only eyes + weak beam; cold fills rest | textures/enemies/hound_512.png (eyes); audio/sfx/monster_crawler_scrape.wav |
| 7 | 0:34–0:42 | POV combat, whip-pans | Hound lunges through cone; one shot; recoil; red pulse on hit | Muzzle flash whites the beam for 2 frames; ember vignette heartbeat | audio/sfx/shot_light.wav; monster_hunter_step.wav; shaders/damage_vignette.gdshader |
| 8 | 0:42–0:50 | Over-shoulder onto UI | Crouch behind dumpster; inventory triage: medkit, battery swap; battery bar segments drop | Chamfered panels glow faint brass; world dims 40% behind panel | textures/ui/{inventory_slot,tooltip_panel,bar_battery}.png; items/{medkit,battery,bandage}.png; audio/sfx/ui_click.wav, ui_save.wav |
| 9 | 0:50–0:58 | Cut to abstract overhead map | Player reroutes power: teal objective pings cascade along avenue; threat pulse slows | Warm avenue line brightens block-by-block; tension layer fades | assets/store/screenshot_03.png composition; audio ambience/threat_low_loop.ogg → threat_high_loop.ogg crossfade |
| 10 | 0:58–1:08 | Crane up from alley, tilt down | Streetlights ignite one by one into the distance; last light reveals a tall silhouette watching; hard cut to logo | Cascade warm vs deep cold; boss rim-lit teal, glyph dots pulse | textures/enemies/architect_512.png; audio/sfx/monster_destroyer_hum.wav; ambience/ambient_lit_loop.ogg swell |

Timing total: 68–75 s depending on hold on shot 10. Capture order suggestion: 4→5→7→8 in-engine first person; 1,3,9,10 as diorama flythroughs; 2,6 staged.
