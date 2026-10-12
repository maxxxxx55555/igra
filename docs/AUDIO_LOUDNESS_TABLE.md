# Loudness of the shipped audio (Session 23)

Measured by `python tools/qa_sim/audio_loudness.py --write docs/AUDIO_LOUDNESS_TABLE.md` (ffmpeg ebur128, integrated loudness and true peak of each file).

| Category | Files | Integrated LUFS: min / median / max | Mean | True peak max (dBFS) | Files over -1 dBFS | Gated (under 0.4 s) | Directive target |
|---|---|---|---|---|---|---|---|
| music | 22 | -21.9 / -18.0 / -16.5 | -18.0 | -1.1 | 0 | 0 | -14 LUFS |
| ambient beds | 22 | -19.6 / -18.1 / -16.0 | -18.2 | -2.7 | 0 | 0 | -20 LUFS |
| ambient details | 40 | -21.3 / -18.9 / -16.9 | -19.1 | -1.0 | 0 | 0 | -20 LUFS |
| sfx | 122 | -20.9 / -15.0 / -11.1 | -15.0 | -1.4 | 0 | 69 | -10 LUFS |
| ui | 5 | -24.2 / -24.2 / -22.5 | -23.6 | -6.0 | 0 | 2 | none |
| jingles | 8 | -14.4 / -13.5 / -13.4 | -13.7 | -1.8 | 0 | 0 | none |

Files over the peak limit:

none
