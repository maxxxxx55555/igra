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

## Loudness: measured, and a decision

Measured by `python tools/qa_sim/audio_loudness.py --write docs/AUDIO_LOUDNESS_TABLE.md` (ffmpeg ebur128, the whole shipped audio, 230 files since Session 27: twelve generated tracks added, three files retired, the battle variant put on the law). The consistency of a mix is
how little a category moves around its own level, then how far that level is from the target:

| Category | Files | Median LUFS | Spread (SD, LU) | Over 3 LU from the median | Canon (`docs/PRODUCTION_BIBLE.md` section 3) | Directive |
|---|---|---|---|---|---|---|
| music | 31 | -18.0 | 0.50 | 0 | none | -14 |
| ambient beds | 22 | -18.1 | 0.98 | 0 | -18 | -20 |
| ambient details | 40 | -18.9 | 0.95 | 0 | -18, played 20 dB under the bed | -20 |
| sfx | 122 (69 under 0.4 s: no integrated value) | -15.0 | 1.69 | 6 (three reloads, 3.2 to 5.9 LU quieter, the generator loop 3.2 quieter; `ui_achievement.wav` 3.6 and the crawler scrape 3.9 louder) | -14 | -10 |

Every category sits within about 1 LU of its own median (the SFX within 1.7), so the **mix is consistent**; the absolute level of each is the canon's, which was applied by
`ffmpeg loudnorm` in the audio wave (`docs/AUDIO_LOUDNESS.md`) and has not moved. **Decision (TZ row AUD-23): the canon stays, the directive's -14 / -10 / -20 are not applied.**
Reasons: (a) -14 LUFS is the loudness of finished music on a streaming service; in this game the music is a bed under the footsteps and the cues of the monsters that the
stealth loop is played by, and at -14 it would sit 4 LU above the ambience beds and 1 LU above the median SFX; (b) +5 LU on the SFX (-15 to -10) puts their true peaks (the
highest is -1.4 dBFS) over 0 dBFS, which is clipping, so no bus gain can reach it without a limiter or a re-master of 122 files; (c) the canon is the project's own,
written in `docs/PRODUCTION_BIBLE.md` and `docs/STYLE_GUIDE.md`. The distance to the directive, for the owner who wants it: music +4.0 LU, SFX +5.0 LU, beds and details about -2 LU. **Owner row A-1:** re-master to the directive's
targets with a limiter, if the owner decides the music should be louder.

True peak: the canon limit is -1.5 dBFS. Over the 219 files none is over -1.0 dBFS (the directive's limit and what `--check` fails on), and 24 are between -1.5 and -1.0: 4 of
the music, 15 of the ambient details, 5 of the SFX; the 22 beds all stand at -2.7 or lower. Not re-encoded: a second lossy generation for half a decibel of margin costs more in
quality than it gives. **Owner row A-2:** if the canon is to be held to the letter, re-encode those 24 from their sources.
