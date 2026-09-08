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
| hospital | abandoned_hallways_alt.mp3 ✔ | hospital_dark ✔ | hospital_lit ✔ | 4/4 ✔ |
| gas_station | downtown.wav ✔ | gas_station_dark ✔ | **MISSING** | 4/4 ✔ |
| police | downtown.wav ✔ | police_dark ✔ | **MISSING** | 3/3 ✔ |
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

### G3 — remaining lit beds (same template as G1/G2b, theme params from `gen_audio.py` DISTRICTS)
- `school_lit.ogg` — major, 100 bpm; bell echoes softened to warm room tone.
- `gas_station_lit.ogg` — blues, 110 bpm; sign buzz replaced by warm pump hum.
- `police_lit.ogg` — minor, 120 bpm; radio static calmed, boots fade.
- `warehouses_lit.ogg` — dorian, 75 bpm; metal creak slowed, forklift fades.
- `industrial_lit.ogg` — minor, 85 bpm; machinery drone −6 dB, steam vents gentler.
- `substation_lit.ogg` — phrygian-dominant, 100 bpm; arc crackle removed, cable hum warms.
All: 36 s seamless, −18 LUFS, TP ≤ −1.5 dBFS, OGG q4 mono.

### Optional (flavor, not canon-required)
- G4 — 4th residential detail bed `residential_courtyard_echo.ogg` (swing-chain creak /
  courtyard echo), 30 s loop, −18 LUFS; would join `DETAIL_BEDS["residential"]` with a
  +dB offset row in `district_atmosphere.gd` (currently 3 details, within the shipped 3–4 range).

## Non-gaps (checked, fine)
- All 40 detail one-shots referenced by `district_atmosphere.gd` exist on disk.
- residential detail offsets (1.8 / 0.0 / 3.6 dB) already compensate file loudness.
- No wired path references a missing audio file (asset gate will confirm post-wiring).
