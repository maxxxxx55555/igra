# ERROR_LOG_BUGHUNT — asset bug-hunt session (2026-08-25)

Format: file/item | attempt | check failed | root cause | fix applied | final status

## Audio seam repairs (8 loops)

| File | Attempt | Check failed | Root cause | Fix applied | Final status |
|---|---|---|---|---|---|
| detection layer (tooling) | — | naive head/tail seam proxy flagged 50+ loops incl. known-clean park_dark (66.9dB) | proxy measures envelope variance between distant windows, NOT wrap discontinuity (ERROR.md lesson re-learned) | replaced with boundary-jump detector: \|x[-1]−x[0]\| vs internal p9999 transient distribution + tile-boundary control for rhythmic loops | honest verdicts: 8 real clicks, rest clean |
| all 8 target loops | 1 | ffprobe "Invalid packet"; decoded samples ±90 | raw f32le piped via stdin into libvorbis in one ffmpeg invocation produced corrupt OGG (muxer never saw proper EOF framing; -write_xing is mp3-only noise) | restored from _BACKUPS + _pre_norm backups; switched to file-based pipeline: decode→s16le wav on disk → numpy edit → encode from file. Lesson: temp artifacts MUST be real files with audio extensions (asset_pipeline.md rule applies to intermediates too) | RESTORED |
| all 8 | 2 | wrap jump unchanged or worse (layer_dark 0.96→0.66 amp) | circular in-place crossfade joins x[n-f:] into x[:f] — but the WRAP pair is still (x[n-1], x[0]); blending head/tail without continuation material cannot fix a wrap (ERROR_LOG lesson 2 requires source beyond dur, which regenerated stereo layers don't have) | restored again | RESTORED |
| all 8 | 3 | decoded wrap jumps exploded (21810 int16) | correlation-splice replaced tail with x[0:L] — new wrap pair became (x[L−1], x[0]) which are NOT adjacent in source; my continuity argument confused rotated and replaced material | restored again | RESTORED |
| all 8 | 4 | — | correct construction: choose cut K so that x[n−K..] best matches x[0..W] (normalized correlation over 6s window + direct join-step term); truncate tail at n−K → wrap pair (x[n−K−1], x[0]) is phase-matched by construction; sample-resolution refine minimizes join step | cut-and-join: layer_dark −2.00s, layer_lit −1.51s, industrial_dark −2.01s, threat_high_loop −2.01s, cooling_fan −1.05s, generator_thrum −1.25s, generator_run_loop −0.99s, heartbeat −1.00s | **PASS 8/8**: decoded wrap ≤ body p9999 for every file (278/242, 128/438, 289/283, 39/12115, 18/1226, 291/354, 245/476, 33/381) |
| durations ledger | — | documented lengths no longer exact (36s bed → 34.0s etc.) | deliberate cost of repair method: removing ~1–2s of tail trades duration metadata for click-free wraps; MusicManager loops by stream, length-agnostic | deviation logged here + REPORT_BUG_HUNT A4 table | ACCEPTED with measured values |

## Texture repairs

| File/set | Attempt | Check failed | Root cause | Fix applied | Final status |
|---|---|---|---|---|---|
| ui/ legacy chrome ×19 | 1 | zero transparent gutter [0,0,0,0]; ERROR_LOG open failure "strip drift 2–4 @margin 5–12" | kit drawn edge-to-edge pre-dating 9-slice QA | btn_tex_quad (WIRED theme_provider.gd margin=16): opaque regen, chamfer+border complete inside 14px ring, slice-line strip test passes at 16; other 15 (unwired): 10px gutter + shapes inset 12px (ui_v2 recipe) | PASS |
| progress_frame.png | 2 | gutter [4,4,10,10] vs 10px rule; first regen produced inverted box | thin bar (200×20): uniform 12px inset exceeds half-height → degenerate polygon | class-corrected rule: vertical inset = max(2, min(4, h//6)) | PASS |
| crests ×11 | 1 | coverage 0.97–0.98 > 0.70 cap; police/suburbs distinctness 0.0076 (open failures inherited) | opaque full-canvas plates; near-identical badge glyphs | redesigned: transparent field, Ø72 panel disc + brass ring (coverage 0.44), 11 distinct two-tone bone+brass district glyphs (house/blocks/tree/bell/cross/pump/shield/crates/gear/pylon/tower) | PASS |
| crest distinctness metric | 2 | whole-silhouette IoU 1.000 suburbs-vs-residential (false FAIL) | identical outer discs dominate alpha mask (ERROR_LOG lesson 3 again: crop to glyph region) | glyph mask = visible ∧ inner-disc ∧ lum>60; worst pair school/hospital IoU 0.525 < 0.90 cap; police-vs-suburbs 0.1931 | PASS |
| ui_v2/flashlight_render_512.png | 1 | 11028 pure-black px (canon: none), file IS wired (screens.gd:465) | vignette floor saturated to 0 at delivery despite V2 QA claim | visible-pixel channel floor lifted to ≥8 | PASS 0 pure-black |
| items icon_ammo/battery/health/stamina | 1 | neon 273–888 px each (documented legacy violations now in-scope) | pre-V2 legacy icons | offending px remapped to luminance-preserving muted brass | PASS 0 neon |
| items wrench/fabric/paper | 1 | white px 250/10/16 (≥253) | same | clamped ≤240 | PASS |

## GAP-FILL

| Set | Attempt | Check failed | Root cause | Fix applied | Final status |
|---|---|---|---|---|---|
| tiles `<district>_{floor,wall}_lit.png` ×16 | 1 | lit variants existed only for suburbs/hospital/power_station (3/11 districts) | T7 delivery stopped at 3 sets | per-channel linear grade fitted from all 6 existing pairs: gain=(1.300,1.161,0.862) offset=(13.6,15.4,19.4) applied to 8 remaining districts; every result warmer (R−B shift positive), max channel ≤246, series-consistent | PASS 11/11 districts |

## Sidecar cleanup

| Item | Attempt | Check failed | Root cause | Fix applied | Final status |
|---|---|---|---|---|---|
| assets/audio/music/*.wav.import ×9 | 1 | source_file missing (editor import error state) | WAV sources deleted after OGG transcode, sidecars left | removed (age 22939+ min — timestamp guard clear) | PASS |
| post_process.gdshader.uid | — | orphan uid, shader gone | external actor already removed it between scan and write | nothing to do | OBSOLETE |

## Tooling lessons (for asset_pipeline.md owner)

1. Loop-wrap QA must use sample-level boundary-jump vs internal transient stats; any RMS-window proxy lies on sparse/event beds.
2. Wrap repair without continuation material = cut-and-join at the correlation-matched point; crossfades cannot fix a wrap pair they don't touch.
3. Raw PCM piped stdin → libvorbis corrupts output; intermediate files must keep real audio extensions even outside loudnorm.
4. Crest/icon distinctness metrics must crop to glyph region whenever a shared plate/disc exists.
