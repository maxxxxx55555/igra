# Trailer script: Last Streetlight (45 seconds, 16:9, plus a 30 second vertical cut)

No trailer video exists yet (`store/trailer.md`). This script is for the person who records it from the final build: every shot says where to stand, what to switch on, which sound plays and for how long.
It replaces `docs/TRAILER_STORYBOARD.md`, which was written for a third-person camera; the game is first person. Spoiler ceiling: the first three districts and the lit power station. No ending footage, no death screen,
no menu text in any language but English.

## Before recording

1. A windowed run of the final bundle's game on a desktop, 1920x1080, a new profile, the language English.
2. Settings: Trailer Mode on (hides the HUD), Graphics tier High or Ultra (`docs/PERF_PASS.md`), music and effects at 100, Reduce Screen Shake off, Subtitles off.
3. Record at 60 FPS lossless, capture the audio of the game alone.
4. The three poses below are the same as the density frames (`tools/qa_sim/density_frames`: a street at the eye height of the player, a block, the skyline), so the shots can be lined up against `docs/stills/ultimate/`.

## The cut

| # | Time | Shot | How to get it | Sound | On screen |
|---|---|---|---|---|---|
| 1 | 0:00-0:05 | A dark street, nothing moves; the camera stands still | District `suburbs`, power DARK, the flashlight off, the player at the south end of the west street, looking north | `layer_dark.ogg` alone, low | black, then nothing |
| 2 | 0:05-0:10 | The flashlight turns on; the beam finds the lamp posts | Press the flashlight; walk five steps | `sfx_flashlight_on.wav` at 0:05, footsteps on asphalt | none |
| 3 | 0:10-0:16 | A power switch; the first lamps of the street come on | Walk to the switch at the corner (8, 8) and use it; stay on the street | `cue_first_light.ogg`, `layer_dark.ogg` crossfades to `layer_lit.ogg` | none |
| 4 | 0:16-0:22 | A monster at the edge of the light, then the beam off it | District `residential`, power DARK; stand still until a monster walks in the beam; the shot ends before it reacts | `layer_threat_low.ogg` rises, a breath of `monster_watcher_breath.wav` | none |
| 5 | 0:22-0:28 | A thrown noise bomb pulls the monster away | Craft is not needed: use a noise bomb from the pack; film the throw and the monster turning to the sound | `layer_threat_high.ogg` for two bars, the pop of the bomb | none |
| 6 | 0:28-0:36 | The city lights up district by district | District `power_station`, power FULL, the cooling-tower landmark in frame, the player on the south street | `cue_grid_cascade.ogg`, `layer_lit.ogg` | none |
| 7 | 0:36-0:41 | The map with eleven rings, most of them lit | Open the city map (key K) after restoring the districts of a saved profile with many restored | `ui_achievement_sting.ogg` very low | none |
| 8 | 0:41-0:45 | The title | Cut to black; the logo and the tagline "Restore the light. Every streetlight is life." in the brass of the palette (`#c9a24a` on `#0c1016`) | the last note of `layer_lit.ogg`, a lamp hum | LAST STREETLIGHT, the tagline |

Grading: none beyond the game's own stack (district grading, bloom, vignette). No overlay, no letterbox, no film grain added in the edit. Palette check: no pure black or white frame (`docs/STYLE_GUIDE.md` section 2).

## The vertical cut (30 s, 9:16)

Shots 2, 3, 6 and 8, each cropped to the middle 9:16 of the 16:9 frame (the street runs down the middle), 7 seconds each, the sound of the same shots; the tagline in the last two seconds.

## Notes for the editor

- Shot 5 uses the noise bomb: it exists in the build (`docs/AI_STEALTH.md`) and is crafted at a workbench from gunpowder and a case; for the take, add it to the pack on a test profile.
- Shot 6 shows the landmark of the district (a cooling tower); the landmarks are in `docs/DISTRICT_SIGNATURES.md`.
- UNVERIFIABLE-HERE: how the take looks and sounds on a phone, and the licence of any music added in the edit. The music named above is the game's own (AI-generated, Google Lyria: `docs/ASSET_LICENSES.md`); its commercial rights are UNVERIFIABLE-HERE (owner step 1 of `RELEASE_CHECKLIST.md` section 10).
