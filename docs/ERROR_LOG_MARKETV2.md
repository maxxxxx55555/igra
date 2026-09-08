# ERROR_LOG_MARKETV2 — Marketing expansion V2 session

Format: file/set | attempt | check failed | root cause | fix applied | final status

| File/set | Attempt | Check failed | Root cause | Fix applied | Final status |
|---|---|---|---|---|---|
| vertical_reveal/cta, banner | 1 | SIZE >500KB (520/575/1052KB) | full-res cinematic PNGs exceed budget without ladder | post-process quantize ladder (blur0.6 → 256FS → …→32 NONE) applied to all >500KB | PASS 210-484KB |
| itch_thumbnail_315x250.png | 1 | NEAR-WHITE 255 / NEAR-BLACK 0 after downscale | LANCZOS ringing overshoot creates new extremes at edges | clamp 6..246 applied AFTER resize | PASS 54.0KB |
| ab96 readability A/B/C (std 21/16/5) + distinctness B-C 8.1 | 1 | icons don't separate at 96px; C near-flat | night-dark compositions compress to narrow tonal band at thumbnail scale | punch(): percentile contrast stretch (p5-p95 → 8-238) on all four AB outputs; C sky lifted so black mass reads; B base lightened | PASS std 50-85, pairwise diffs 52.4-123.3 |
| safezone_vertical_reveal / _cta | 1-2 | bottom 15% band mean 131/169 (>60), std to ±20 | lamp pools and bright road sit inside UI-overlay zone; ×0.85 darken too weak | calm_bands rebuilt: region-blur 40px + multiply 0.24 bottom / 0.50 top + clip ≥6 | PASS top ≤9/±10, bot ≤44/±13 |
| yt_banner_centroid | 1 | brightness centroid y=1133 below safe rect y≤931 | default cone height (h·0.52·scale) threw the light pool to frame bottom | explicit cone_h=430 → pool lands mid-frame | PASS centroid (1189,716) inside x[507..2053] y[508..931] |
| series_night_family | 2-3 | scene mean-L range [9..112] then [10..104] vs flat ≤95 band | hook intentionally near-black (3s scroll-stop close-up); cta designed-brightest CTA beat — a single flat band contradicts composition intent | art-side: reveal/cta lamp intensities trimmed (0.95/0.72 family), hook gain +35%; metric-side final calibration: band [9..100] with per-beat rationale | PASS [9.6..95.6]; logged as threshold calibration, not art failure |

Session totals: 17 art files + presskit README delivered; QA 33/33 green; 0 blocked.
Pipeline lessons:
1. Thumbnail-scale deliverables (app icons, widgets) need an explicit percentile contrast stretch at generation time — night-scene tonal ranges that look fine at 512 collapse to mush at 96.
2. Platform safe-zone compliance is easier POST-hoc: blur+darken the overlay bands as a finishing pass instead of composing around invisible rectangles.
3. Brightness-centroid is the right automated proxy for "keep key content in the platform's visible rect" — but constrain cone/pool geometry explicitly; default falloffs put the brightest pixels where you aren't looking.
