# Audio Coverage — district theme/ambience audit & gap list

Owner: CONTENT/assets agent. Audit of what exists vs. canon (PRODUCTION_BIBLE §3,
`scripts/systems/music_manager.gd`, `scripts/world/district_atmosphere.gd`,
`tools/gen_audio.py`). **This document lists gaps with exact specs; it deliberately ships no
binary audio.** Implementation path for whoever generates them: `tools/gen_audio.py`
(deterministic) + `ffmpeg loudnorm` per docs/AUDIO_LOUDNESS.md; every delivered binary must
be added to docs/ASSET_LICENSES.md and verified playable (ffprobe) before commit.

Global targets: ambience −18 LUFS integrated, true peak ≤ −1.5 dBFS; SFX/stings −14 LUFS;
OGG q4 mono; beds = 36 s seamless loops (loop points 0.000–36.000, matched zero-crossings).

## Coverage matrix (verified on disk 2026-09-08; warehouses + industrial rows header-verified 2026-09-09; lit beds completed + header/loudness-verified 2026-09-11)

| District | Music theme (MusicManager) | Dark bed | Lit bed | Detail one-shots |
|---|---|---|---|---|
| suburbs | music_ambient.wav ✔ | suburbs_dark ✔ | suburbs_lit ✔ | 3/3 ✔ |
| residential | residential.wav ✔ (major, 80 bpm, root 62, 14 bars ≈ 42 s) | residential_dark ✔ | residential_lit ✔ (1ch/44.1k/36.000 s, −18 LUFS, delivered 2026-09-11) | 3/3 ✔ |
| park | park.wav ✔ | park_dark ✔ | park_lit ✔ (1ch/44.1k/36.000 s, −18 LUFS, delivered 2026-09-11) | 4/4 ✔ |
| school | abandoned_hallways_alt.mp3 ✔ | school_dark ✔ | school_lit ✔ (1ch/44.1k/36.000 s, −18 LUFS, delivered 2026-09-11) | 4/4 ✔ |
| hospital | abandoned_hallways_alt.mp3 ✔ | hospital_dark ✔ (1ch/44.1k/36.000 s) | hospital_lit ✔ (1ch/44.1k/36.000 s, header-verified 2026-09-08) | 4/4 ✔ (all 30.000 s) |
| gas_station | downtown.wav ✔ | gas_station_dark ✔ (1ch/44.1k/36.000 s) | gas_station_lit ✔ (1ch/44.1k/36.000 s, −18 LUFS, delivered 2026-09-11) | 4/4 ✔ (all 30.000 s) |
| police | downtown.wav ✔ | police_dark ✔ (1ch/44.1k/36.000 s, header-verified 2026-09-08) | police_lit ✔ (1ch/44.1k/36.000 s, −18 LUFS, delivered 2026-09-11) | 3/3 ✔ (all 30.000 s) |
| warehouses | harbor.wav ✔ | warehouses_dark ✔ (1ch/44.1k/36.000 s, header-verified 2026-09-09) | warehouses_lit ✔ (1ch/44.1k/36.000 s, −18 LUFS, delivered 2026-09-11) | 4/4 ✔ (all 30.000 s, header-verified 2026-09-09) |
| industrial | industrial.wav ✔ (1ch/22.05 kHz/24.0 s — downtown/harbor legacy class) | industrial_dark ✔ **but 33.994 s, not the 36.000 s house contract** (1ch/44.1k/86 kbps/55,718 B, header-verified 2026-09-09 — see G2h) | industrial_lit ✔ (1ch/44.1k/33.994 s twin-exact, −18 LUFS, delivered 2026-09-11) | 4/4 ✔ (all 30.000 s, header-verified 2026-09-09) |
| substation | music_ambient_dark.wav ✔ | substation_dark ✔ (1ch/44.1k/36.000 s, header-verified 2026-09-09) | substation_lit ✔ (1ch/44.1k/36.000 s, −18 LUFS, delivered 2026-09-11) | 3/3 ✔ (all 30.000 s, header-verified 2026-09-09) |
| power_station | music_ambient_dark.wav ✔ | power_station_dark ✔ (1ch/44.1k/36.000 s, header-verified 2026-09-09) | power_station_lit ✔ (1ch/44.1k/36.000 s, header-verified 2026-09-09 — sparse encode, 59,320 B) | 4/4 ✔ (**two off the 30 s class** — see F1) |

Layers (dark/lit/threat_low/threat_high/action), weather (rain/wind) and action sting:
all present ✔. MusicManager falls back to the dark bed for districts without a lit twin
(documented DEFAULT_CHOICE in `music_manager.gd`). 2026-09-11: all 11 lit twins now ship (cert `docs/CERT_AUDIO.md`); the fallback stays as safety until CODE wires the 8 new `AMBIENCE_LIT_BY_DISTRICT` rows.

### F1 — power_station detail durations (finding, recorded 2026-09-09, not a gap)
Header-verified this pass (Ogg/Vorbis identification header + final page granule; no
engine, no ffprobe): `power_station_generator_thrum.ogg` is **28.749 s** (granule
1,267,829, 220,543 B) and `power_station_cooling_fan.ogg` is **28.948 s** (granule
1,276,622, 222,943 B) — both off the 30.000 s detail-bed class every other district's
details hold exactly (`power_station_hv_whine` and `power_station_breaker_clunk` are
30.000 s as expected; all four are 1 ch / 44.1 kHz). Same finding class as the
industrial dark bed (G2h): `district_atmosphere.gd` loops whatever length ships
(`AudioStreamOggVorbis.loop = true`, no duration read anywhere), so both files play
correctly — the 30 s figure is a house norm ("30s seamless loops" in the script's own
comment), not a code requirement. If the audio toolchain holder prefers class
uniformity, re-render the two at 30.000 s; otherwise they stand as recorded. Not a gap
(both files exist and wire), so no G-spec is appended. Loudness (−18 LUFS / TP) remains
unverifiable in this sandbox (no ffmpeg) for all power_station files.

## Gaps (priority order)

### Finishing-pass note (2026-09-09, Task 2 — CC0 sourcing attempted, spec retained)

Every gap below (lit beds G1, G2b/c/e/f/g/h/i; the F1 detail class; optional G2/G4/G5 and
`hospital_ward_curtain_drag.ogg`) was re-opened for real CC0/CC-BY sourcing this pass. Genuine
web searches were run per gap class; no CC0/CC-BY track satisfies the lit-twin contract
(faithful re-voice of the district's own dark bed, exact loop length, district-true material,
no voices/people, −18 LUFS) and no binary could be delivered/verified in this sandbox (no
`ffmpeg`/`ffprobe`). All gaps below therefore **remain spec-only — no binary fabricated**. Full
search record and reasoning: `docs/ASSET_LICENSES.md` §"finishing pass: CC0 audio sourcing
attempts".

### Mega-final-pass note (2026-09-10, Task 1 — ladder re-run, spec retained)

Step (a): no audio-generation skill exists in this session (`.opencode/skills/` =
code/process/texture skills only; `docs/external_skills/` = behavior doc only; sandbox
offers spoken-word TTS, which outputs voices every lit-bed spec forbids and cannot render
seamless instrumental loops — recorded honestly, not skipped). Step (b): CC0/CC-BY
exact-match search re-run for every gap class; nearest hits are generic CC0 loops at wrong
lengths / not re-voices of the in-repo dark beds, or Standard-licensed (non-qualifying)
tracks — no source adopted; no `ffmpeg`/`ffprobe` in sandbox to normalize/verify any
candidate. Step (c): all gaps **remain spec-only — no binary fabricated**. Static
re-verification this pass: all shipped beds/details measure identically to the 2026-09-09
record (see `docs/ASSET_LICENSES.md` §"mega final pass: audio gap re-attempt"). This note
does not re-open any §9/§10 audit row.

### Final-audio-pass note (2026-09-10, Task 1 — music-generation skills attempted, spec retained)

Step (a) — skill and tool discovery (full inventory this session): `.claude/skills/` =
`ponytail`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`, `ponytail-help`,
`ponytail-review` (coding-discipline skills); `.opencode/skills/` = `art-pipeline`,
`asset_pipeline.md`, `council`, `godot-gates`, `self-commit`, `surgical-edit`, `yagni`
(code/process/texture skills); `.pi/skills/` = `gdd-canon`, `godot-gates`, `self-commit`,
`surgical-edit`; `docs/external_skills/` = `karpathy-behavior.md` (LLM-behavior doc only).
Repository-wide search for music-generation (Suno/Udio/MusicGen/lit-bed generators) matches
only prose mentions in docs and plans — **no music-generation skill, tool binding, or API
access exists in this repo or sandbox**. The sandbox's only audio tool is spoken-word TTS
(`add_voice`/`generate_speech`), whose own contract is spoken word only (it cannot render
melodic/musical output or seamless instrumental loops) — and every lit-bed spec below forbids
voices, so it fails the G1/G2* contract by design. Recorded honestly, not attempted into a
fake delivery.

Step (b) — generation briefs designed this pass for the first session that does hold a
music-generation skill (Suno/Udio-class). Contract for every brief: instrumental
"brighter/warmer lit variant" re-voice of THAT district's own dark bed mood, seamless loop,
36.000 s ±0.1 (G2h: 33.994 s to match its shipped dark twin), target −18 LUFS (metadata
intention; normalize on receipt per `docs/AUDIO_LOUDNESS.md`), OGG q4 mono house encode, no
voices/people, plus that bed's own never-rules in the specs below. Prompts reference the dark
bed's mood/tempo/instrumentation (theme canon per `tools/gen_audio.py` DISTRICTS):

- **G1 `residential_lit.ogg`** — "Warm lit-variant bed of a cold residential-night drone:
  slow 80 bpm pulse, warm analog pad raised over a quiet empty street, slowed wooden
  pipe-creak motif, safe and homely; major tonality; no voices; seamless 36-second loop."
- **G2b `park_lit.ogg`** — "Calm lit-variant park-night ambience: wind softened to a calm
  leaf bed, distant city hum tucked low, frozen-pond ice-crack transients slowed and warmed;
  lydian tonality, 75 bpm; no branch snaps, no voices; seamless 36-second loop."
- **G2c `school_lit.ogg`** — "Empty lit school corridor at night: soft room-tone with a warm
  60/120 Hz ballast hum for the restored ceiling bank, a faint detuned-and-slowed distant
  bell tail reading as a relay; major tonality, 100 bpm; no locker slams, no children's
  sounds, no voices; seamless 36-second loop."
- **G2e `gas_station_lit.ogg`** — "Lit empty gas-station forecourt at night: soft open-air
  wind, warm sodium canopy ballast hum (60/120 Hz), a low continuous pump-motor thrum, one
  warm and slow distant road pass; blues tonality, 110 bpm; no fault buzz, no fire crackle,
  no voices; seamless 36-second loop."
- **G2f `police_lit.ogg`** — "Lit empty police precinct at night: cold room-tone lowered,
  warm sodium flood hum for the court, a thin distant-city bed; minor tonality, 120 bpm; no
  radio static, no boot steps, no sirens, no voices; seamless 36-second loop."
- **G2g `warehouses_lit.ogg`** — "Lit empty freight yard in fog: cold fog drone lowered,
  warm sodium flood hum over the yard, one distant slowed dock-chain clank; dorian tonality,
  75 bpm; no forklift, no machinery start, no voices; seamless 36-second loop."
- **G2h `industrial_lit.ogg`** — "Lit empty factory: cold machinery drone lowered, steam
  vents gentler and low-passed, warm sodium high-bay hum, one distant slowed press-clank;
  minor tonality, 85 bpm; no roll-call rhythm, no voices; seamless 33.994-second loop
  (must match its shipped dark twin exactly)."
- **G2i `substation_lit.ogg`** — "Lit working substation yard: cold busbar drone lowered,
  transformer hum warmed (100/200 Hz pair raised, 3 kHz edge softened), warm sodium yard
  flood hum, one slow cable-hum swell; phrygian-dominant tonality, 100 bpm; no arc crackle,
  no voices; seamless 36-second loop."

Step (c) — why no deterministic-fallback delivery either: `tools/gen_audio.py` (the pipeline's
deterministic renderer) synthesizes only district MUSIC THEMES (22.05 kHz WAV); it has no
ambience/lit-bed generator. The sandbox has no OGG/Vorbis encoder, no `ffmpeg`/`ffprobe`
(verified absent this session), so no −18 LUFS normalization or verification is possible, and
the shipped dark beds cannot even be decoded here (no Vorbis decoder) to check that a re-voice
is faithful. Emitting unverifiable WAVs renamed to `.ogg` would violate both the pipeline rule
(every delivered binary must be header- AND loudness-verified before commit) and the standing
"no fabricated audio / no fake metadata" rule. **All gaps remain spec-only — no binary
fabricated.** F1 unchanged (finding, not a gap). Static re-verification this pass (stdlib
Ogg/Vorbis identification-header + final-page-granule parse; no engine, no ffprobe): all 14
shipped beds measure exactly as recorded — 1 ch / 44,100 Hz / 36.000 s (`industrial_dark`
33.994 s per G2h); the 8 lit files above confirmed absent on disk. Zero drift.

### Audio-delivery note (2026-09-11 — gaps closed: beds 8/8 + cues 3/3)

Ladder re-run honestly: (a) no music-gen skill exists (same inventory as
2026-09-10 — coding/process/texture skills + behavior doc only; TTS rejected,
voices forbidden); (b) 3 genuine CC0/CC-BY searches, nearest hits rejected
(wrong lengths/licenses, nothing can re-voice our own dark beds) — recorded in
`docs/LEDGER_AUDIO.md` L2; (c) delivery via the repo-canonical deterministic
pipeline (`asset_pipeline.md`): pip-installed numpy 2.4.6 + static ffmpeg 7.0.2
(libvorbis + loudnorm verified) rendered 44.1 k mono masters from fixed seeds,
dual-pass loudnorm I=−18/TP=−1.8/LRA=11, OGG q4. All 8 lit beds + 3 wow cues
(60/90/120 s, arcs verified on decode) header- and loudness-verified
post-encode (|I+18| ≤ 0.25, TP ≤ −2.01, granules exact, seams ≤ −41 dB).
Renderer committed: `assets/audio/_build/gen_audio_pass.py`. F1 retained as
recorded (finding, not a gap — re-verified 28.749/28.948 s). Wiring remains
CODE-owned (routing: `assets/audio/README.md`). Verdicts: `docs/CERT_AUDIO.md`.

### G1 — `assets/audio/ambience/districts/residential_lit.ogg` (this district)
- Type: 36 s seamless ambience loop, OGG q4 mono, −18 LUFS, TP ≤ −1.5 dBFS.
- Mood: "lit twin" of `residential_dark.ogg` (STYLE_GUIDE §5): same material re-voiced
  warmer — cold drone −6 dB, warm pad raised, pipe-creak motif kept but slowed; pulse (if
  any) aligned to 80 bpm bars (residential theme canon) for clean 2 s crossfades.
- Reference pair for structure: `suburbs_dark.ogg` → `suburbs_lit.ogg`.
- Wiring note: add row to `AMBIENCE_LIT_BY_DISTRICT` (CODE agent, after delivery).
- Delivery (2026-09-11): ships — 1ch/44.1k/36.000 s, I −18.15, TP −4.89. Cert `docs/CERT_AUDIO.md` §1/§4.

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
- Delivery (2026-09-11): `park_lit.ogg` ships — 1ch/44.1k/36.000 s, I −18.20, TP −4.23. Cert `docs/CERT_AUDIO.md` §1/§4.

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
- Delivery (2026-09-11): `school_lit.ogg` ships — 1ch/44.1k/36.000 s, I −18.14, TP −3.95. Cert `docs/CERT_AUDIO.md` §1/§4.

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
- Delivery (2026-09-11): `gas_station_lit.ogg` ships — 1ch/44.1k/36.000 s, I −18.18, TP −3.52. Cert `docs/CERT_AUDIO.md` §1/§4.

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
- Delivery (2026-09-11): `police_lit.ogg` ships — 1ch/44.1k/36.000 s, I −18.14, TP −4.04. Cert `docs/CERT_AUDIO.md` §1/§4.

### G2g — `assets/audio/ambience/districts/warehouses_lit.ogg` (warehouses pass, full spec)
- Type: 36 s seamless ambience loop, OGG q4 mono, 44.1 kHz; loop points 0.000–36.000,
  matched zero-crossings; −18 LUFS integrated, true peak ≤ −1.5 dBFS.
- Verified on disk this pass (Ogg/Vorbis identification header + final page granule; no
  engine, no ffprobe): `warehouses_dark.ogg` is **1 ch / 44,100 Hz / 36.000 s / 197,976 B**.
  Detail one-shots all 1 ch / 44.1 kHz / **30.000 s**: `warehouses_cargo_impact` (0.0 dB
  offset, 235,569 B), `warehouses_chain_rattle` (2.1, 234,952 B),
  `warehouses_forklift_distant` (0.0, 286,113 B), `warehouses_metal_creak` (0.0,
  231,912 B). Only the lit twin is missing — this is a **real gap**. Loudness (−18 LUFS /
  TP) of the shipped files is **not** verifiable here (no ffmpeg);
  `docs/AUDIO_LOUDNESS.md` remains the authority.
- Mood: "lit twin" of `warehouses_dark.ogg` (STYLE_GUIDE §5). The yard stops being a dead
  depot in fog and becomes a working freight yard with nobody in it: cold fog-drone −6 dB;
  add a warm sodium ballast hum for the yard flood pair (60/120 Hz, −24 dBFS, slow 0.15 Hz
  wobble — the floods of `warehouses_note_02`); keep a thin open-air fog bed and one very
  distant dock-chain clank per loop, slowed and warmed.
- **Remove in the lit twin:** the forklift motif (fades — a running forklift would mean
  people, and there are none) and the cold creak's edge (softened, kept as structure).
  `warehouses_forklift_distant.ogg` stays layered by `district_atmosphere.gd` at 0.0 dB
  for one-shot flavour only; `warehouses_metal_creak.ogg` (0.0) and
  `warehouses_chain_rattle.ogg` (2.1) stay separate as before.
- Pulse alignment: 75 bpm bars (warehouses theme canon: dorian in `tools/gen_audio.py`
  DISTRICTS) → 36 s = 45 bars of 0.8 s; place the loop seam on a bar line so the 2 s
  MusicManager crossfade lands clean.
- Never in the loop: the sorter belt starting or counting, rhythmic chain counts, voices,
  the quarantine-cage hum that means something is live. The belt is a scripted story beat
  (`warehouses_note_03`/`_04`/`_08`) and the cage must stay silent at every stage — the
  warehouses pack's own R-rule (prop_manifest R8: cold storage and cage never relight,
  never speak). Putting either in the bed would wallpaper the anomaly.
- Reference pair for structure: `suburbs_dark.ogg` → `suburbs_lit.ogg`.
- Wiring note: add `&"warehouses"` row to `AMBIENCE_LIT_BY_DISTRICT` (CODE, after delivery).
- Status: **spec only — binary not fabricated** (asset pass delivered lit tiles + floor
  repair only).
- Delivery (2026-09-11): `warehouses_lit.ogg` ships — 1ch/44.1k/36.000 s, I −18.13, TP −2.74. Cert `docs/CERT_AUDIO.md` §1/§4.

### G2h — `assets/audio/ambience/districts/industrial_lit.ogg` (industrial pass, full spec)
- Type: seamless ambience loop, OGG q4 mono, 44.1 kHz; loop points 0.000–33.994,
  matched zero-crossings; −18 LUFS integrated, true peak ≤ −1.5 dBFS. **Length = the
  shipped dark bed, not the generic 36 s** — see the finding below.
- Verified on disk this pass (Ogg/Vorbis identification header + final page granule; no
  engine, no ffprobe): `industrial_dark.ogg` is **1 ch / 44,100 Hz / 33.994 s / nominal
  86 kbps / 55,718 B**. Detail one-shots all 1 ch / 44.1 kHz / **30.000 s**:
  `industrial_machinery_drone` (4.0 dB offset, 231,027 B), `industrial_pipe_hiss` (0.0,
  299,508), `industrial_steam_vent` (0.0, 285,838), `industrial_vent_rattle` (4.5,
  254,976). Only the lit twin is missing — this is a **real gap**. Loudness (−18 LUFS /
  TP) is **not** verifiable here (no ffmpeg); `docs/AUDIO_LOUDNESS.md` remains the
  authority.
- **Finding (recorded, not fixed here — no binary audio is fabricated by this pipeline):**
  `industrial_dark.ogg` is the **only** district bed off the 36.000 s house contract —
  every other dark bed and all three shipped lit beds measure exactly 36.000 s (granule
  1,587,600). Two readings, both recorded: (a) defect — a render off the house target;
  (b) deliberate — the industrial theme canon in `tools/gen_audio.py` DISTRICTS is
  minor / **85 bpm** / root MIDI 46 / **12 bars**, and 12 bars of 4 beats at 85 bpm =
  33.88 s ≈ the shipped 33.994 s (36 s at 85 bpm is 12.75 bars — not a whole number, so
  the generator may have followed the theme instead of the contract). Either way the
  lit twin must match its dark bed for MusicManager's 2 s crossfade to land, so G2h
  specs 33.994 s. If the audio toolchain holder prefers contract uniformity, re-render
  the dark bed and the lit twin **together** at 36.000 s and update this spec + G3.
- Mood: "lit twin" of `industrial_dark.ogg` (STYLE_GUIDE §5). The plant stops being a
  dead cathedral of iron and becomes a lit factory with nobody in it: cold machinery
  drone −6 dB; add a warm sodium ballast hum for the relit high-bays and yard floods
  (60/120 Hz, −24 dBFS, slow 0.15 Hz wobble); steam vents gentler (−6 dB, low-passed
  ~900 Hz); keep one distant press-clank per loop, slowed and warmed.
- **Keep separate in the lit twin:** all four detail one-shots stay layered by
  `district_atmosphere.gd` as today (`machinery_drone` +4.0, `vent_rattle` +4.5,
  `pipe_hiss`/`steam_vent` 0.0) — the bed must not double them.
- **Never in the loop:** the generator's 22:00 hum motif (that hum is the scripted
  story beat of `doc_factory_log` / `industrial_note_01`), the sorting line starting or
  counting (`industrial_note_03`/`_07` — the anomaly must not become wallpaper, same
  rule as the warehouses sorter belt), voices, names, roll-call rhythm (`industrial_note_07`).
- Pulse alignment: 85 bpm → bar = 2.8235 s; the 33.994 s loop = 12 bars + ~0.11 s tail;
  place events on the 12 in-loop bar lines (0 … 31.06 s) and let the seam fall on the
  sustained pad tail; MusicManager's 2 s crossfade ≈ 0.71 bars — cleanest across bar
  boundaries.
- Reference pair for structure: `suburbs_dark.ogg` → `suburbs_lit.ogg`.
- Wiring note: add `&"industrial"` row to `AMBIENCE_LIT_BY_DISTRICT` (CODE, after delivery).
- Status: **spec only — binary not fabricated** (asset pass delivered lit tiles only).
- Delivery (2026-09-11): `industrial_lit.ogg` ships — 1,499,146 smp/33.994 s twin-exact, I −18.11, TP −3.35. Cert `docs/CERT_AUDIO.md` §1/§4.

### G2i — `assets/audio/ambience/districts/substation_lit.ogg` (substation pass, full spec)
- Type: 36 s seamless ambience loop, OGG q4 mono, 44.1 kHz; loop points 0.000–36.000,
  matched zero-crossings; −18 LUFS integrated, true peak ≤ −1.5 dBFS.
- Verified on disk this pass (Ogg/Vorbis identification header + final page granule; no
  engine, no ffprobe): `substation_dark.ogg` is **1 ch / 44,100 Hz / 36.000 s / nominal
  86 kbps / 318,861 B** — on the house contract (unlike the industrial bed). Detail
  one-shots all 1 ch / 44.1 kHz / **30.000 s**: `substation_transformer_buzz` (0.0 dB
  offset, 226,836 B), `substation_arc_crackle` (5.8, nominal 110 kbps, 316,363 B),
  `substation_cable_hum` (0.0, 237,816 B). Only the lit twin is missing — this is a
  **real gap**. Loudness (−18 LUFS / TP) of the shipped files is **not** verifiable here
  (no ffmpeg); `docs/AUDIO_LOUDNESS.md` remains the authority.
- Mood: "lit twin" of `substation_dark.ogg` (STYLE_GUIDE §5). The yard stops being a dead
  switchyard in fog and becomes a working substation with nobody in it: cold busbar drone
  −6 dB; the transformer buzz warms (raise the 100/200 Hz pair, soften the 3 kHz edge);
  add a warm sodium ballast hum for the relit yard floods (60/120 Hz, −24 dBFS, slow
  0.15 Hz wobble); keep a thin open-air fog bed and one slow cable-hum swell per loop.
- **Remove in the lit twin:** the arc-crackle motif. The dark bed's crackle is the
  *fault* (the arc cage, `z_arc_cage` — manifest stage table: "the only thing burning in
  D10 is the thing that is broken"); at FULL the fault is starved silent by the restored
  grid, so the crackle drops out of the bed and `substation_arc_crackle.ogg` continues
  to be layered separately by `district_atmosphere.gd` at +5.8 dB for one-shot flavour
  only. The bed must also not double `substation_transformer_buzz` (0.0) or
  `substation_cable_hum` (0.0).
- Pulse alignment: 100 bpm bars (substation theme canon: phrygian-dominant, root MIDI 50,
  14 bars in `tools/gen_audio.py` DISTRICTS) → 36 s = 15 bars of 2.4 s; place the loop
  seam on a bar line so the 2 s MusicManager crossfade lands clean.
- Never in the loop: voices in the wires, relay counts, the 03:00 door. The guard's door
  is a scripted story beat (`substation_note_01`); the cage must fall silent at FULL
  (the substation pack's own R-rule — prop_manifest R8: the cage never relights, never
  speaks past the fault). Putting either in the bed would wallpaper the anomaly.
- Reference pair for structure: `suburbs_dark.ogg` → `suburbs_lit.ogg`.
- Wiring note: add `&"substation"` row to `AMBIENCE_LIT_BY_DISTRICT` (CODE, after delivery).
- Status: **spec only — binary not fabricated** (asset pass delivered lit tiles only).
- Delivery (2026-09-11): `substation_lit.ogg` ships — 1ch/44.1k/36.000 s, I −18.08, TP −4.26. Cert `docs/CERT_AUDIO.md` §1/§4.

### G3 — remaining lit beds (same template as G1/G2b/G2c/G2e/G2f/G2g, theme params from `gen_audio.py` DISTRICTS)
- `school_lit.ogg` — **superseded by G2c above (full spec)**.
- `gas_station_lit.ogg` — **superseded by G2e above (full spec)**.
- `police_lit.ogg` — **superseded by G2f above (full spec)**.
- `warehouses_lit.ogg` — **superseded by G2g above (full spec)**.
- `industrial_lit.ogg` — **superseded by G2h above (full spec)**.
- `substation_lit.ogg` — **superseded by G2i above (full spec)**.
All: 36 s seamless, −18 LUFS, TP ≤ −1.5 dBFS, OGG q4 mono. (Exception: industrial per
G2h — 33.994 s to match its shipped dark bed, or re-render the pair at 36 s.)

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
