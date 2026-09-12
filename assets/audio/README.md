# assets/audio — README (AUDIO agent owns this tree; CODE wiring advisory)

Scope: every playable audio byte + this file. Build script in `_build/`
(excluded from Godot import via `.gdignore`; never shipped).

## What shipped 2026-09-11 (audio 100/100 pass)

8 lit-bed twins (all 11 districts now have dark+lit pairs):

| File | Contract |
|---|---|
| `ambience/districts/residential_lit.ogg` | 36.000 s, -18 LUFS, TP <= -1.5 |
| `ambience/districts/park_lit.ogg` | 36.000 s, -18 LUFS, TP <= -1.5 |
| `ambience/districts/school_lit.ogg` | 36.000 s, -18 LUFS, TP <= -1.5 |
| `ambience/districts/gas_station_lit.ogg` | 36.000 s, -18 LUFS, TP <= -1.5 |
| `ambience/districts/police_lit.ogg` | 36.000 s, -18 LUFS, TP <= -1.5 |
| `ambience/districts/warehouses_lit.ogg` | 36.000 s, -18 LUFS, TP <= -1.5 |
| `ambience/districts/industrial_lit.ogg` | **33.994 s** (matches `industrial_dark` twin exactly, per G2h) |
| `ambience/districts/substation_lit.ogg` | 36.000 s, -18 LUFS, TP <= -1.5 |

3 wow-moment cues (one-shots, zero-ended, -18 LUFS music-layer class):

| File | Length | Arc (verified on decode) |
|---|---|---|
| `music/cue_first_light.ogg` | 60.000 s | swell peaks 30-37 s |
| `music/cue_grid_cascade.ogg` | 90.000 s | 4 rising waves, climax ~68-79 s, resolve |
| `music/cue_victory.ogg` | 120.000 s | swells @30/60/90 s, resolve to quiet |

All 11: OGG q4 (nominal 86k) mono 44.1 kHz, no voices (pure synth, no
samples). Facts + per-gap verdicts: `docs/CERT_AUDIO.md`. Attempt log:
`docs/LEDGER_AUDIO.md`. Render recipe: `_build/gen_audio_pass.py` (fixed seeds).

## Bus routing for CODE (advisory — CODE owns all wiring)

Buses (`default_bus_layout.tres`): `Master -> Music | SFX | Voice | Ambient | UI`.
`Music` carries a compressor + light reverb; `Ambient` is dry.

1. **Lit beds** — add 8 rows to `AMBIENCE_LIT_BY_DISTRICT` in
   `scripts/systems/music_manager.gd`, following the 3 existing rows:
   `&"residential"`, `&"park"`, `&"school"`, `&"gas_station"`, `&"police"`,
   `&"warehouses"`, `&"industrial"`, `&"substation"` ->
   `res://assets/audio/ambience/districts/<district>_lit.ogg`.
   Bodies already loop (`AudioStreamOggVorbis.loop`); beds are whole-cycle
   synth with 3 ms zero edges, seamless. `district_atmosphere.gd` needs no
   change (detail offsets untouched).
2. **Cues** — route to the **`Music`** bus as **one-shots** (`loop = false`):
   - first `EventBus.streetlight_activated` per run -> `cue_first_light`
     (pairs with `WowDirector` "first_light": trauma 0.30, amber flash 0.5 s).
   - all-restored (`PowerGrid.all_restored`) -> `cue_grid_cascade`
     (pairs with "cascade": trauma 0.55, slow-mo 0.5x, FOV -4).
   - `EventBus.game_won` -> `cue_victory` (pairs with "ending": trauma 0.45,
     slow-mo 0.4x; bittersweet cue suits all 5 endings).
   Do NOT put cues on `Ambient` (beds live there) or `SFX`. Unity gain —
   cues already sit at -18 LUFS integrated like the `layer_*` class.
3. **Untouched**: `SFX`/`UI`/`Voice` buses, `AMBIENCE_DARK_BY_DISTRICT`,
   detail one-shot offsets, `power_station` F1 details (28.749/28.948 s,
   retained as recorded — finding, not a gap).

## Re-render (bit-auditable)

`python3 _build/gen_audio_pass.py [beds|cues|all]` (needs `numpy`,
`soundfile`, static ffmpeg 7.x with `libvorbis` + `loudnorm`; seeds
1101-1108 beds, 1201-1203 cues). Output chain per file: 44.1 k mono master
-> dual-pass `loudnorm=I=-18:TP=-1.8:LRA=11` -> `libvorbis -q:a 4`.
TP target -1.8 gives post-encode margin so decoded TP stays <= -1.5.
