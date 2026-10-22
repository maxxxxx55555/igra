# Loudness of the shipped audio (Session 23)

Measured by `python tools/qa_sim/audio_loudness.py --write docs/AUDIO_LOUDNESS_TABLE.md` (ffmpeg ebur128, integrated loudness and true peak of each file).

| Category | Files | Integrated LUFS: min / median / max | Mean | Spread (SD, LU) | Files over 3 LU from the median | True peak max (dBFS) | Files over -2 dBFS | Files over -1.5 dBFS (canon) | Gated (under 0.4 s) | Directive target |
|---|---|---|---|---|---|---|---|---|---|---|
| music | 25 | -18.1 / -18.0 / -17.9 | -18.0 | 0.06 | 0 | -1.9 | 0 | 0 | 0 | -14 LUFS |
| ambient beds | 14 | -18.1 / -17.9 / -16.0 | -17.6 | 0.69 | 0 | -1.9 | 0 | 0 | 0 | -20 LUFS |
| ambient details | 31 | -21.3 / -18.8 / -16.9 | -19.0 | 0.92 | 0 | -1.6 | 0 | 0 | 0 | -20 LUFS |
| sfx | 119 | -20.9 / -14.9 / -11.4 | -15.1 | 1.74 | 6 | -1.5 | 0 | 0 | 71 | -10 LUFS |
| ui | 8 | -24.2 / -23.4 / -22.5 | -23.4 | 0.64 | 0 | -6.0 | 0 | 0 | 2 | none |
| jingles | 8 | -14.4 / -13.5 / -13.4 | -13.7 | 0.34 | 0 | -1.8 | 0 | 0 | 0 | none |

Files over the peak limit:

none
