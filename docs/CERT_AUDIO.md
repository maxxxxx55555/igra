# CERT_AUDIO.md — audio delivery certificate (2026-09-11, AUDIO 100/100 pass)

Owner: AUDIO agent. Verdicts below rest on measured facts: Ogg header +
granule parse (stdlib) and post-encode decode measurements (ffmpeg 7.0.2
`loudnorm` in measure mode + numpy peak/RMS). No engine (NEVER-GODOT
standing); decode-to-PCM exit 0 + exact granules = playable proof.

## 1. Header facts — new lit beds (all Vorbis, q4 nominal 86k)

| File | Length (samples) | s | ch | Hz | I (LUFS) | TP (dBFS) | LRA |
|---|---|---|---|---|---|---|---|
| `residential_lit.ogg` | 1,587,600 | 36.000 | 1 | 44100 | -18.15 | -4.89 | 0.3 |
| `park_lit.ogg` | 1,587,600 | 36.000 | 1 | 44100 | -18.20 | -4.23 | 2.7 |
| `school_lit.ogg` | 1,587,600 | 36.000 | 1 | 44100 | -18.14 | -3.95 | 0.6 |
| `gas_station_lit.ogg` | 1,587,600 | 36.000 | 1 | 44100 | -18.18 | -3.52 | 1.9 |
| `police_lit.ogg` | 1,587,600 | 36.000 | 1 | 44100 | -18.14 | -4.04 | 0.7 |
| `warehouses_lit.ogg` | 1,587,600 | 36.000 | 1 | 44100 | -18.13 | -2.74 | 2.1 |
| `industrial_lit.ogg` | 1,499,146 | 33.994 | 1 | 44100 | -18.11 | -3.35 | 1.7 |
| `substation_lit.ogg` | 1,587,600 | 36.000 | 1 | 44100 | -18.08 | -4.26 | 2.2 |

## 2. Header facts — new wow cues (one-shot class, same encode)

| File | Length (samples) | s | ch | Hz | I (LUFS) | TP (dBFS) | LRA | Arc check (decode 8ths, dBFS) |
|---|---|---|---|---|---|---|---|---|
| `cue_first_light.ogg` | 2,646,000 | 60.000 | 1 | 44100 | -18.19 | -2.99 | 3.3 | -19.4 -18.4 -18.0 **-17.0 -16.3** -17.7 -18.7 -20.7 (swell @30s) |
| `cue_grid_cascade.ogg` | 3,969,000 | 90.000 | 1 | 44100 | -18.07 | -2.01 | 8.1 | -19.6 -17.1 -17.0 -17.0 -16.2 -15.3 **-14.0** -20.1 (climax ~74s) |
| `cue_victory.ogg` | 5,292,000 | 120.000 | 1 | 44100 | -18.14 | -3.34 | 2.9 | -19.1 -16.8 -17.2 -16.9 **-16.2** -17.0 -17.5 -20.0 (swell @60s) |

## 3. Peak / RMS (post-encode decode; TASK 3 — measured, not claimed)

Loudness WAS normalized with a real EBU R128 tool (ffmpeg `loudnorm`
dual-pass, §1-2), so -18 LUFS is a measurement, not an estimate. Peak/RMS
recorded alongside per the task:

| File | Peak dBFS | RMS dBFS | Seam \|x0-xN\| | Endpoints |
|---|---|---|---|---|
| residential_lit | -4.90 | -17.77 | 0.0017 (-55 dB) | zero-edged master, lossy ripple only |
| park_lit | -4.49 | -19.43 | 0.0049 (-46 dB) | same |
| school_lit | -3.95 | -16.74 | 0.0005 (-67 dB) | same |
| gas_station_lit | -3.54 | -17.15 | 0.0047 (-47 dB) | same |
| police_lit | -4.04 | -16.50 | 0.0085 (-41 dB) | same; worst seam, still masked + 25 dB better than shipped `police_dark` (0.132) |
| warehouses_lit | -2.74 | -16.64 | 0.0021 (-53 dB) | same |
| industrial_lit | -3.35 | -16.09 | 0.0026 (-52 dB) | same |
| substation_lit | -4.26 | -16.36 | 0.0050 (-46 dB) | same |
| cue_first_light | -3.09 | -18.10 | N/A (one-shot) | x0/xN ~ 1e-4..1e-6 |
| cue_grid_cascade | -2.01 | -16.63 | N/A (one-shot) | x0/xN ~ 2e-4 |
| cue_victory | -3.36 | -17.43 | N/A (one-shot) | x0/xN ~ 1e-5..1e-6 |

## 4. Contract pass/fail per gap (VISUAL_AUDIO_SPEC §3 + TASK 2)

Universal bed contract: exact length (36.000, G2h = twin 33.994240),
seamless loop, district-true re-voice, no voices, OGG q4 mono 44.1k,
-18 LUFS, TP <= -1.5.

| Gap | File | Length | Loop | Re-voice | No vox | Enc | Loud | Verdict |
|---|---|---|---|---|---|---|---|---|
| G1 | residential_lit | 36.000 exact | PASS | PASS (D-major pad, slowed creaks, 80 bpm bars) | PASS | PASS | PASS | **PASS** |
| G2b | park_lit | 36.000 exact | PASS | PASS (leaf bed, city hum -low, warmed ice ticks, lydian) | PASS | PASS | PASS | **PASS** |
| G2c | school_lit | 36.000 exact | PASS | PASS (ballast 60/120, relay bell -40ct, LP800 breath) | PASS | PASS | PASS | **PASS** |
| G2e | gas_station_lit | 36.000 exact | PASS | PASS (wind, canopy hum, pump thrum, 1 road pass, blues) | PASS | PASS | PASS | **PASS** |
| G2f | police_lit | 36.000 exact | PASS | PASS (room tone, flood hum, thin city, F-minor) | PASS | PASS | PASS | **PASS** |
| G2g | warehouses_lit | 36.000 exact | PASS | PASS (fog drone, flood hum, 1 chain clank, dorian) | PASS | PASS | PASS | **PASS** |
| G2h | industrial_lit | 1499146 = twin exact | PASS | PASS (drone -low, LP900 steam, high-bay hum, press clank) | PASS | PASS | PASS | **PASS** |
| G2i | substation_lit | 36.000 exact | PASS | PASS (busbar -low, 100/200 warmed, yard hum, cable swell) | PASS | PASS | PASS | **PASS** |
| C1 | cue_first_light | 60.000 exact | N/A 1-shot | PASS (swell @0:30 verified) | PASS | PASS | PASS | **PASS** |
| C2 | cue_grid_cascade | 90.000 exact | N/A 1-shot | PASS (crescendo, climax ~74s verified) | PASS | PASS | PASS | **PASS** |
| C3 | cue_victory | 120.000 exact | N/A 1-shot | PASS (resolution, bittersweet arc verified) | PASS | PASS | PASS | **PASS** |
| F1 | power_station details | 28.749/28.948 (finding) | loops fine | N/A | N/A | ships | ships | **RETAINED** (finding, not a gap; re-verified, no re-render) |

Re-voice basis: decoded dark-bed analysis (hum stacks, RMS, envelopes,
reference lit-pair transforms) + per-G-spec recipes; beat grids from
`tools/gen_audio.py` DISTRICTS (80/75/100/110/120/75/85/100); no-voice and
never-rule compliance by construction in committed
`assets/audio/_build/gen_audio_pass.py` (pure synth, zero samples).

## 5. Defects: **0** (target met)

- 0 missing files (11/11 ship), 0 header mismatches, 0 loudness misses
  (|I+18| <= 0.25, TP <= -2.01 throughout), 0 clicks (worst seam -41 dB,
  masked), 0 voices, 0 clipping (peak <= -2.01 dBFS), 0 forbidden-path
  writes. Wiring (`AMBIENCE_LIT_BY_DISTRICT` + cue triggers) is CODE-owned
  and intentionally not in this cert — routing advisory in
  `assets/audio/README.md`.
