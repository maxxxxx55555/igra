# Audio Coverage — district theme/ambience audit & gap list

Owner: CONTENT/assets agent. Audit of what exists vs. canon (PRODUCTION_BIBLE §3,
`scripts/systems/music_manager.gd`, `scripts/world/district_atmosphere.gd`,
`tools/gen_audio.py`). **This document lists gaps with exact specs; it deliberately ships no
binary audio.** Implementation path for whoever generates them: `tools/gen_audio.py`
(deterministic) + `ffmpeg loudnorm` per docs/AUDIO_LOUDNESS.md; every delivered binary must
be added to docs/ASSET_LICENSES.md and verified playable (ffprobe) before commit.

Global targets: ambience −18 LUFS integrated, true peak ≤ −1.5 dBFS; SFX/stings −14 LUFS;
OGG q4 mono; beds = 36 s seamless loops (loop points 0.000–36.000, matched zero-crossings).

## Coverage matrix (verified on disk 2026-09-08)

| District | Music theme (MusicManager) | Dark bed | Lit bed | Detail one-shots |
|---|---|---|---|---|
| suburbs | music_ambient.wav ✔ | suburbs_dark ✔ | suburbs_lit ✔ | 3/3 ✔ |
| residential | residential.wav ✔ (major, 80 bpm, root 62, 14 bars ≈ 42 s) | residential_dark ✔ | **MISSING** | 3/3 ✔ |
| park | park.wav ✔ | park_dark ✔ | **MISSING** | 4/4 ✔ |
| school | abandoned_hallways_alt.mp3 ✔ | school_dark ✔ | **MISSING** | 4/4 ✔ |
| hospital | abandoned_hallways_alt.mp3 ✔ | hospital_dark ✔ (1ch/44.1k/36.000 s) | hospital_lit ✔ (1ch/44.1k/36.000 s, header-verified 2026-09-08) | 4/4 ✔ (all 30.000 s) |
| gas_station | downtown.wav ✔ | gas_station_dark ✔ (1ch/44.1k/36.000 s) | **MISSING** → spec G2e | 4/4 ✔ (all 30.000 s) |
| police | downtown.wav ✔ | police_dark ✔ (1ch/44.1k/36.000 s, header-verified 2026-09-08) | **MISSING** → spec G2f | 3/3 ✔ (all 30.000 s) |
| warehouses | harbor.wav ✔ | warehouses_dark ✔ | **MISSING** | 4/4 ✔ |
| industrial | industrial.wav ✔ | industrial_dark ✔ | **MISSING** | 4/4 ✔ |
| substation | music_ambient_dark.wav ✔ | substation_dark ✔ | **MISSING** | 3/3 ✔ |
| power_station | music_ambient_dark.wav ✔ | power_station_dark ✔ | power_station_lit ✔ | 4/4 ✔ |

Layers (dark/lit/threat_low/threat_high/action), weather (rain/wind) and action sting:
all present ✔. MusicManager falls back to the dark bed for districts without a lit twin
(documented DEFAULT_CHOICE in `music_manager.gd`).

## Gaps (priority order)

### G1 — `assets/audio/ambience/districts/residential_lit.ogg` (this district)
- Type: 36 s seamless ambience loop, OGG q4 mono, −18 LUFS, TP ≤ −1.5 dBFS.
- Mood: "lit twin" of `residential_dark.ogg` (STYLE_GUIDE §5): same material re-voiced
  warmer — cold drone −6 dB, warm pad raised, pipe-creak motif kept but slowed; pulse (if
  any) aligned to 80 bpm bars (residential theme canon) for clean 2 s crossfades.
- Reference pair for structure: `suburbs_dark.ogg` → `suburbs_lit.ogg`.
- Wiring note: add row to `AMBIENCE_LIT_BY_DISTRICT` (CODE agent, after delivery).

### G2 — Global relight riser `assets/audio/sfx/power_returns_riser.wav` (one-shot)
- 4–6 s, −14 LUFS; warm brass riser into a soft streetlight-ignition chime; played on
  `streetlight_activated` (carried over from suburbs manifest gap #4; reusable all districts).

### G2b — `assets/audio/ambience/districts/park_lit.ogg` (park pass, full spec)
- Type: 36 s seamless ambience loop, OGG q4 mono, 44.1 kHz; loop points 0.000–36.000,
  matched zero-crossings; −18 LUFS integrated, true peak ≤ −1.5 dBFS.
- Mood: "lit twin" of `park_dark.ogg` (STYLE_GUIDE §5): bare-trees wind softened to a calm
  leaf bed, branch-snap motif removed, `park_distant_city_hum` component −6 dB, warm pad
  raised; frozen-pond ice-crack transients kept but slowed and warmed.
- Pulse alignment: 75 bpm bars (park theme canon: lydian, root MIDI 60, 14 bars ≈ 44.8 s in
  `tools/gen_audio.py` DISTRICTS) so the 2 s MusicManager crossfade lands on the downbeat.
- Reference pair for structure: `suburbs_dark.ogg` → `suburbs_lit.ogg`.
- Wiring note: add `&"park"` row to `AMBIENCE_LIT_BY_DISTRICT` (CODE agent, after delivery).
- Status: **spec only — binary not fabricated** (asset pass delivered tiles/pond ice only).

### G2c — `assets/audio/ambience/districts/school_lit.ogg` (school pass, full spec)
- Type: 36 s seamless ambience loop, OGG q4 mono, 44.1 kHz; loop points 0.000–36.000,
  matched zero-crossings; −18 LUFS integrated, true peak ≤ −1.5 dBFS.
- Mood: "lit twin" of `school_dark.ogg` (STYLE_GUIDE §5): the corridor stops being a
  cave and becomes a building that is merely empty. Cold room-tone drone −6 dB; add a warm
  ballast hum for the restored ceiling bank (60 Hz + 120 Hz pair, −24 dBFS, gentle 0.2 Hz
  amplitude wobble); the dark bed's distant-bell tail is kept but detuned down ~40 cents and
  slowed so it reads as a relay, not a bell; locker-slam transients removed entirely (they
  belong to `school_locker_slam.ogg`, which `district_atmosphere.gd` layers separately at
  +2.7 dB); breath/pipe component low-passed at 800 Hz and dropped −8 dB.
- Pulse alignment: 100 bpm bars (school theme canon: major, root MIDI 64, 14 bars ≈ 33.6 s
  in `tools/gen_audio.py` DISTRICTS) → 36 s ≈ 60 bars of 0.6 s, so the 2 s MusicManager
  crossfade lands on a downbeat at 0/6/12/18/24/30/36 s.
- Never in the lit bed: children's voices, counting, whispering. The counting is a scripted
  story beat (`school_note_07`), not ambience — putting it in a loop would make it wallpaper.
- Reference pair for structure: `suburbs_dark.ogg` → `suburbs_lit.ogg`.
- Wiring note: add `&"school"` row to `AMBIENCE_LIT_BY_DISTRICT` (CODE agent, after delivery).
- Status: **spec only — binary not fabricated** (school asset pass delivered textures only).

### G2d — hospital: **no lit-bed gap** (verified, district 5 pass)
- `assets/audio/ambience/districts/hospital_lit.ogg` already ships. Statically verified by
  parsing the Ogg/Vorbis identification header and the final page granule (no engine, no
  ffprobe in this sandbox): **1 channel, 44,100 Hz, 36.000 s exactly, nominal 86 kbps,
  279,412 B** — matches the house bed contract (36 s seamless loop, OGG q4 mono).
  Its dark twin `hospital_dark.ogg` measures identically (1 ch, 44.1 kHz, 36.000 s).
- `music_manager.gd` already maps `&"hospital"` in `AMBIENCE_LIT_BY_DISTRICT`; no wiring
  action needed.
- Detail one-shots verified present and all exactly 30.000 s / mono / 44.1 kHz:
  `hospital_monitor_beep` (+4.6 dB offset), `hospital_pa_mumble` (+2.4),
  `hospital_gurney_wheels` (0.0), `hospital_elevator_distant` (0.0).
- **Not verifiable statically here:** integrated loudness (−18 LUFS) and true peak of the
  shipped hospital beds — no ffmpeg/ffprobe in this sandbox. Flagged for whoever holds the
  audio toolchain; docs/AUDIO_LOUDNESS.md remains the authority.
- Optional (flavor, not canon-required) — `hospital_ward_curtain_drag.ogg`: 30 s loop,
  OGG q4 mono, −18 LUFS, TP ≤ −1.5 dBFS. Rail-runner rattle plus fabric drag, sparse, one
  event per 8–12 s; would join `DETAIL_BEDS["hospital"]` at −2.0 dB and play only in
  `z_ward_b` (see `content/districts/hospital/prop_manifest.md`). Status: **spec only,
  not fabricated.**
- Content constraint for any future hospital audio: no PA words, no monitor rhythm in the
  lit bed. The PA "almost-words" beat is scripted at STREETS (manifest stage table); the
  Act II reveal must stay in documents, never in a loop.

### G2e — `assets/audio/ambience/districts/gas_station_lit.ogg` (gas_station pass, full spec)
- Type: 36 s seamless ambience loop, OGG q4 mono, 44.1 kHz; loop points 0.000–36.000,
  matched zero-crossings; −18 LUFS integrated, true peak ≤ −1.5 dBFS.
- Verified on disk this pass (Ogg header + final granule): `gas_station_dark.ogg` is
  1 ch / 44,100 Hz / **36.000 s** / 82,126 B, and all four detail one-shots
  (`sign_buzz`, `pump_hum`, `gravel_crunch`, `car_pass`) are 1 ch / 44.1 kHz / 30.000 s.
  Only the lit twin is missing — this is a **real gap**.
- Mood: "lit twin" of `gas_station_dark.ogg` (STYLE_GUIDE §5). The forecourt stops being a
  wind tunnel and becomes a working station with nobody in it: open-air wind bed −4 dB,
  add a warm sodium ballast hum for the canopy pair (60/120 Hz, −24 dBFS, slow 0.15 Hz
  wobble), add a low continuous pump-motor thrum at −26 dBFS (the district's cruel joke —
  see `gas_station_note_04`), keep the distant road event but warm and slower.
- **Remove in the lit twin:** the fault buzz. The dark bed's sign-buzz component is the
  *fault*, not the sign (manifest stage table: "the buzz was the fault"); at STREETS+ the
  sign runs clean, so the buzz motif drops out and `gas_station_sign_buzz.ogg` continues to
  be layered separately by `district_atmosphere.gd` at 0.0 dB for one-shot flavour only.
- Pulse alignment: 110 bpm bars (gas_station theme canon: blues, root MIDI 52, 16 bars ≈
  34.9 s in `tools/gen_audio.py` DISTRICTS) → 36 s ≈ 66 bars of ~0.545 s; place the loop
  seam on a bar line so the 2 s MusicManager crossfade lands clean.
- Never in the loop: fire crackle. The scavenger drum fire is a positional prop sound
  (`z_scavenger_camp`), not ambience — putting it in the bed would make the whole district
  smell of smoke at every stage.
- Reference pair for structure: `suburbs_dark.ogg` → `suburbs_lit.ogg`.
- Wiring note: add `&"gas_station"` row to `AMBIENCE_LIT_BY_DISTRICT` (CODE, after delivery).
- Status: **spec only — binary not fabricated** (asset pass delivered textures only).

### G2f — `assets/audio/ambience/districts/police_lit.ogg` (police pass, full spec)
- Type: 36 s seamless ambience loop, OGG q4 mono, 44.1 kHz; loop points 0.000–36.000,
  matched zero-crossings; −18 LUFS integrated, true peak ≤ −1.5 dBFS.
- Verified on disk this pass (Ogg/Vorbis identification header + final page granule; no
  engine, no ffprobe): `police_dark.ogg` is **1 ch / 44,100 Hz / 36.000 s / nominal 86 kbps /
  343,937 B**. Detail one-shots all 1 ch / 44.1 kHz / **30.000 s**:
  `police_radio_static` (4.9 dB offset, 254,990 B), `police_siren_tail` (0.0, 238,645 B),
  `police_boots_concrete` (2.4, 238,195 B). Only the lit twin is missing — this is a
  **real gap**. Loudness (−18 LUFS / TP) of the shipped files is **not** verifiable here
  (no ffmpeg); `docs/AUDIO_LOUDNESS.md` remains the authority.
- Mood: "lit twin" of `police_dark.ogg` (STYLE_GUIDE §5). The station stops being a
  cave of static and becomes a working precinct with nobody in it: cold room-tone drone
  −6 dB; add a warm sodium ballast hum for the restored court flood (60/120 Hz, −24 dBFS,
  slow 0.15 Hz wobble); keep a thin distant-city bed.
- **Remove in the lit twin:** radio-static hiss and boot-fall transients. Both belong to
  the detail one-shots (`police_radio_static` stays layered by `district_atmosphere.gd` at
  +4.9 dB, `police_boots_concrete` at +2.4). The dark bed's static is the *fault*; at
  STREETS+ the dispatch rack is merely empty, not broken.
- Pulse alignment: 120 bpm bars (police theme canon: minor, root MIDI 53, 14 bars ≈ 28.0 s
  in `tools/gen_audio.py` DISTRICTS) → 36 s = 72 bars of 0.5 s; place the loop seam on a
  bar line so the 2 s MusicManager crossfade lands clean.
- Never in the loop: voices on channel 3, a siren that starts, cell-door slams. Channel 3
  is a scripted story beat (`police_note_07`); the siren tail is a positional one-shot on
  the front lot (`z_station_front`); putting either in the bed would wallpaper the east
  wing, which must stay quiet (cells unlit at every stage).
- Reference pair for structure: `suburbs_dark.ogg` → `suburbs_lit.ogg`.
- Wiring note: add `&"police"` row to `AMBIENCE_LIT_BY_DISTRICT` (CODE, after delivery).
- Status: **spec only — binary not fabricated** (asset pass delivered textures only).

### G3 — remaining lit beds (same template as G1/G2b/G2c/G2e/G2f, theme params from `gen_audio.py` DISTRICTS)
- `school_lit.ogg` — **superseded by G2c above (full spec)**.
- `gas_station_lit.ogg` — **superseded by G2e above (full spec)**.
- `police_lit.ogg` — **superseded by G2f above (full spec)**.
- `warehouses_lit.ogg` — dorian, 75 bpm; metal creak slowed, forklift fades.
- `industrial_lit.ogg` — minor, 85 bpm; machinery drone −6 dB, steam vents gentler.
- `substation_lit.ogg` — phrygian-dominant, 100 bpm; arc crackle removed, cable hum warms.
All: 36 s seamless, −18 LUFS, TP ≤ −1.5 dBFS, OGG q4 mono.

### Optional (flavor, not canon-required)
- G4 — 4th residential detail bed `residential_courtyard_echo.ogg` (swing-chain creak /
  courtyard echo), 30 s loop, −18 LUFS; would join `DETAIL_BEDS["residential"]` with a
  +dB offset row in `district_atmosphere.gd` (currently 3 details, within the shipped 3–4 range).
- G5 — 5th school detail one-shot `school_pipe_whisper.ogg` (school pass, optional):
  6–9 s one-shot, OGG q4 mono, −18 LUFS, TP ≤ −1.5 dBFS. Heating-riser resonance with a
  breath-like formant sweep just under the noise floor — *felt*, never intelligible: no
  words, no numbers, no child's voice (the counting stays a scripted beat, see G2c). Would
  join `DETAIL_BEDS["school"]` at −4.0 dB offset alongside `school_bell_echo` (1.8),
  `school_locker_slam` (2.7), `school_chalk_scratch` (0.0), `school_desk_scrape` (0.0).
  Restrict playback to `z_boiler_room` / `z_basement_shelter` (see
  `content/districts/school/prop_manifest.md`). Status: **spec only, not fabricated.**

## Non-gaps (checked, fine)
- All 40 detail one-shots referenced by `district_atmosphere.gd` exist on disk.
- residential detail offsets (1.8 / 0.0 / 3.6 dB) already compensate file loudness.
- No wired path references a missing audio file (asset gate will confirm post-wiring).
