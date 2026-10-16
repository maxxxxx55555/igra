# ERROR_LOG_DEVICESV2 — Device variants + Coming Soon session

Format: file/set | attempt | check failed | root cause | fix applied | final status

| File/set | Attempt | Check failed | Root cause | Fix applied | Final status |
|---|---|---|---|---|---|
| gen_devices_v2.py | 1 | NameError: random / TypeError ember_eyes() 7 args (helpers take arr-first, no w,h) | missing import in standalone script; signature mismatch vs store module | added `random` import; call fixed to G.add(G.ember_eyes(a,...)) | PASS |
| tv4k_sharpness | 1 | edge_density 0.007 < self-imposed 0.05 threshold | absolute threshold never calibrated to this art family — smooth night gradients measure ~0.002-0.007 even when crisp; the accepted 1080p master itself scores 0.0043 | metric corrected to reference-relative: 4K must match-or-beat the accepted desktop_hero on BOTH edge density and std. Measured: 4K=0.0069/84 vs master=0.0043/77 → 4K is SHARPER (native render, zero upscale) | PASS by calibrated reference-relative test |

Session totals: 14 device files + 2 coming-soon files delivered; QA 20/20 green; 0 blocked.
Pipeline lessons:
1. "Sharpness" QA must be reference-relative for stylized-gradient art: absolute edge-density thresholds flag correct renders as soft because flat night skies dominate the histogram.
2. Render large formats NATIVELY from the parametric scene functions instead of upscaling masters — the size-parameterized builder made the 4K a free variant with per-pixel detail, sidestepping upscale artifacts entirely.
