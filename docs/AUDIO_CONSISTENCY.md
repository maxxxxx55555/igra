# Audio: mix rules and consistency (Session 23)

## Ducking

When a cue the player must hear arrives, the Music and Ambient buses drop 12 dB for 2 s: down in 0.15 s, held, back in 0.6 s (`scripts/systems/audio_ducker.gd`,
a child named Ducker of AudioManager). It is an Amplify effect appended to each of the two buses, so the volume sliders (`SettingsManager.set_volume`) keep
their own say and never fight the dip. Cues: a boss spawning or changing phase (`boss_spawned`, `boss_phase_changed`), the final night, the ending
(`game_won`), and every voice line (`voice_line`: the radio, for when it is reachable). A second cue inside the hold restarts the dip from where it is. Check
AUD1 (`CLOSEOUT_ONLY=s23`) reads -12.0 dB 0.5 s after a cue, the slider unchanged, 0.00 dB 3.5 s after.

## Reverb: the rays, and zones

The reverbs on the Footsteps, Combat and Environment buses follow what five rays from the player's head meet (open sky 0, walled in 1:
`AudioManager._sense_reverb`). A reverb zone (`scripts/world/reverb_zone.gd`, an Area3D box) replaces the rays while the player is inside it:

| Preset | wet | room size | damping | Meant for |
|---|---|---|---|---|
| room | 0.28 | 0.45 | 0.6 | a shelter, a booth, a stairwell |
| tunnel | 0.45 | 0.95 | 0.30 | an underpass, a pipe, a culvert |
| outdoors | 0.04 | 0.35 | 0.5 | an open yard that the rays would read as walled in |

Another zone's exit does not release the zone the player is in; leaving hands the reverb back to the rays on the next sensing tick (0.25 s). Check AUD2.

## Footsteps by surface

`FootstepSystem._detect_material` reads the surface from the metadata `surface` of the collision shape the foot ray met (a street strip is one body of many
shapes), then of the body, then the property `surface_material`, then the body's name. Surfaces: asphalt_dry, asphalt_wet, puddle (the water), concrete,
metal, wood, grass, gravel, tile, glass; each has a sample, six of them one per speed (`assets/audio/sfx/footsteps`). In a shower the dry road reads as
asphalt_wet, in a storm as a puddle (`WeatherSystem.rain_strength` 0.5 and 0.9). Tagged in the game today: the road strips (asphalt_dry) and the sidewalk
strips (concrete) of `street_builder.gd`, and the manhole covers (`scripts/world/manhole.gd`, metal). Wood, grass, gravel and tile are read from metadata
when something walkable carries it; no shipped geometry does yet (`docs/DISTRICT_SIGNATURES.md`). Check AUD3 builds a floor of each kind and reads it.

## Ambient layers

| Layer | Source | Level | Trigger |
|---|---|---|---|
| Base | the district bed `<district>_dark.ogg` or its lit twin (MusicManager) | -18 LUFS canon | the district the player stands in |
| Detail | one of the district's detail loops (DistrictAtmosphere, `DETAIL_BEDS`) | -20 dB under the bed | one at random per district switch |
| Weather | wind, rain on metal, thunder (AudioManager) | rain follows `rain_strength`; thunder 6 to 14 s apart in a storm | WeatherSystem |
| Events | the UI stings (achievement, secret, boss, power restored) | -6 to -16 dB on the UI bus | EventBus |

No constant hum bed exists (owner, rc14). The lit twins of eight districts are still missing: owner rows with their briefs in `docs/MUSIC_BRIEF.md`.
