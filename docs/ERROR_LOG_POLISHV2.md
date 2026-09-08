# ERROR_LOG_POLISHV2 — POLISH V2 session

Format: file/item | attempt | check failed | root cause | fix applied | final status

| File/item | Attempt | Check failed | Root cause | Fix applied | Final status |
|---|---|---|---|---|---|
| thumbs_v2/* (generator) | 1 (pre-run) | would have saved blank bases | main loop created its own thumb_base canvas; th_* motifs draw on a second internal canvas | th_* now return their img; loop saves the returned canvas | PASS (caught by inspection before write) |
| rim_light() helper | 1 (pre-run) | dead conditional line (no-op) | leftover from draft | removed | PASS |
| ending stings ×5 + ach_unlock | 1 | seam +3.4..+8.3dB (head≫tail); TP −1.30 > −1.5 | env_adsr treated note START time as attack LENGTH → all voices sounded from t=0 (head-heavy); OGG peak overshoot over −1.5 limiter | envelope rewritten with start-offset (attack 0.6s from `start`); limiter ceiling −2.0 dBFS (OGG overshoot margin ≈0.2dB measured) | partial 5/8 |
| ending_survivor/dark/truth stings | 2 | seam +2.17..+5.57dB still | bed tones detuned 0.15% → multi-second beat envelope → bed RMS differs between head and tail windows | bed rebuilt from pure sines (no detune); detune kept on interior swell voices only | PASS all 8: seam ≤0.73dB, TP ≤−1.5, I −14±0.5 |
| skills health_regen vs max_health | 1 | pairwise IoU 0.945 > 0.90 (same heart silhouette; pulse line interior-only) | both glyphs shared identical outline | health_regen: circular refresh arrow + ECG line (new silhouette); worst pair now damage_boost_1/2 at 0.891 | PASS |
| cycle streetlight_64 | 2 | 64px contrast 17.4/17.7 < 18 | cone fill single brass RGB dominates visible-pixel luminance (std flat) | attempt A: cone alpha 70→130 + outlines (17.4, insufficient); attempt B: 3-tone olive/bone/brass (17.4 — cone pixels still dominate); attempt C: vertical bone→brass gradient cone + olive pole/ground → real tonal spread | PASS (attempt 3, at fix limit) |
| qa_polish_v2.py worst() | 1 | TypeError missing sigfn | no default for metric arg | default = alpha-silhouette metric | PASS (tooling fix, not an asset) |

## DEFAULT_CHOICE marks (silent detail → closest canon default)

- Sting keys/chords/tempos: GDD §12.4/endings give mood adjectives only → light=A-major warm resolve 12s, hope=D rising fifths 10s, survivor=E sparse open fifth 10s, dark=F# cold drone 12s, truth=C/C# tension→open fifth 12s; all bookended by identical quiet drone bed (loop-safe by construction, seam-verified).
- Rain streak hue (188,208,216)/(150,190,205) — brief said "thin cold streaks", exact tone silent.
- Thumb compositions follow the brief's per-district motif list; exact geometry/camera DEFAULT_CHOICE (iso night vignette, one light source each).
- Render style: stylized dark product shot (procedural shading + brass rim) — no photoreal renderer available in toolchain.
- ach_medal-style naming not needed here; jingle filenames taken verbatim from brief.
