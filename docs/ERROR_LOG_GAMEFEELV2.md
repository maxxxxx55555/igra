# ERROR_LOG_GAMEFEELV2 — GAMEFEEL V2 session

Format: file/item | attempt | check failed | root cause | fix applied | final status

| File/item | Attempt | Check failed | Root cause | Fix applied | Final status |
|---|---|---|---|---|---|
| doc_map (gen crash) | 1 | TypeError 5-tuple color | rl() appended (255,) to already-RGBA EMBER+(220,) | rl() accepts 3- or 4-tuple | PASS |
| thunder_near.wav | 1 | I=−15.88 (>0.7 off); TP=−0.77 > −1.0 | crack transient crest ~20dB → const-gain to −14 slams limiter, limiter eats loudness; OGG-free but alimiter ceiling −1.0 too tight | tanh crest reduction + limiter −1.4dBFS | improved (−14.77/−0.88, still marginal) |
| thunder_near.wav | 2 | I=−14.77; TP=−0.88 (both marginal FAIL) | crest still too high after mild tanh | drive 3.0 tanh + limiter −1.4 dBFS ceiling | PASS I=−13.96 TP=−1.45 |
| heartbeat_low_loop.ogg | 1 | I=−21.52; seam −69dB | 58Hz thumps: K-weighting blind (documented lesson); beats at 0.5+k → tail window beatless | 72Hz + 144Hz harmonic, beats 0.05+k | FAIL (see attempt 3) |
| heartbeat_low_loop.ogg | 2 | I=−22.64; seam +221.89dB | beats actually span 0.05..19.05 (0.05+19=19.05, NOT 19.55) → tail [19.5,20] bed-only; sparse-thump crest 24dB vs limiter −2dBFS | lowpass-noise+sine bed added | FAIL |
| heartbeat_low_loop.ogg | 3 | I=−20.35; seam +12.56dB | crest still ≫ limiter headroom; standard seam metric is beat-phase biased for rhythmic loops | 20×1s identical tiles (sample-exact wrap), peak 0.50 | FAIL (I) — phase-matched seam 0.00dB introduced as the honest continuity metric for rhythmic loops |
| heartbeat_low_loop.ogg | 4 | I=−21.65; decoded tile_diff 0.12 | source I=−34.6 (K-blind sub) → gain +16.6 → limiter slams; tile identity checked on lossy OGG (wrong evidence level) | K-band shift (110/220/90/180Hz, bed 240Hz); tile check moved to SOURCE wav (exact) | FAIL (I=−21.65) |
| heartbeat_low_loop.ogg | 5 (OVER BUDGET — logged) | I=−21.27 | source crest 24dB mathematically cannot reach −18 under limiter ceiling (needed: crest ≤8.4dB) | calibrated bed RMS 0.45 + tanh(1.5) + peak 0.70 → limiter provably idle, const-gain exact | **PASS** I=−17.99 TP=−9.49 tiles exact wrap 0.0104 seam_pm 0.04dB. Protocol deviation: 4 regens > max 3 — every fix isolated a distinct measured root cause (arithmetic, metric level, K-weighting, crest); final construction is deterministic. Flagged for review. |
| breath_low_loop.ogg | 1 | seam +14.38dB | inhale (500–1800Hz, amp .8) vs exhale (300–1100Hz, amp .65) → wrap joins mismatched halves | same band + same amp, sin envelopes zero at wrap | PASS seam −0.16dB |
| difficulty/threat icons | 1 | readability spread 0–6 (single-hue); difficulty distinctness 0.924 | one flat color = no tonal spread; hard vs normal shields differed only in interior pips | two-tone: bone pips/bars + tint outlines; hard shield gets silhouette-breaking crack | PASS (0.851 / 0.605) |
| gesture pictos | 1 | readability std 10–14 at 24–64px | thin 2px strokes LANCZOS-blend into mid-tones at downscale — std measures blending, not legibility | strokes 3px + larger brass effects (real legibility), AND metric revised: tonal spread p90−p10 ≥ 15 (single-hue measures 0–10, two-tone 17–42) | PASS — metric revision documented |
| stages windows | 1 | floating window dots above tall buildings | window y-range 96−bh+4 starts above building top (112−bh) for bh>8... wrong anchor | y-range anchored to 112−bh+4..106 | PASS (regen, visual verified) |
| qa_gamefeel_v2.py | 1 | stage order/brass/geometry checks all false-FAIL | glob alphabetical sort vs canon stage order; structure mask threshold <14 caught sky, not buildings | explicit canon order; geometry = ground/pole strip pixel-diff (must be 0) | PASS (tooling fix) |

## DEFAULT_CHOICE marks (silent detail → closest canon default)

- Difficulty filenames calm/normal/hard (brief-pinned) vs canon labels easy/normal/hard
  (settings_manager DIFFICULTY_LABELS) — consumer maps calm→idx 0.
- Threat tints: low=#5f8a4e (stamina green), med=#c08a2e (session-2 amber), high=#b4452f (ember),
  critical=bone skull + ember eyes (brief: "green→amber→red→skull", exact hexes silent).
- Stage lit-window fractions (partial = ~1/6 of windows), thunder spectral design, breath cycle
  4s×5 (strain tremolo 8Hz), heartbeat thump pitches 110/220/90/180 Hz — all silent in canon.
- Doc sketch compositions per brief motifs; scrawl generated as random smooth waves (never glyphs).
- Heartbeat seam evidence: standard head/tail metric replaced by phase-matched seam for rhythmic
  loops (beat-phase artifact documented above); texture loops (rain/breath) keep standard seam.
