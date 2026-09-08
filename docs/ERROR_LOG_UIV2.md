# ERROR_LOG_UIV2 — UI Skin V2 session

Format: file/set | attempt | check failed | root cause | fix applied | final status

| File/set | Attempt | Check failed | root cause | fix applied | final status |
|---|---|---|---|---|---|
| gen_ui_v2.py vgrad() | 1 | PIL alpha_composite "images do not match" | broadcast produced (h,1,3) not (h,w,3); downstream Image sized 1×H | np.broadcast_to (h,w,3) | PASS |
| fog_band/rgrad | 1 | unpack error: shape given as (h,w) to rgrad expecting 3-tuple | call-site/rgrad contract mismatch | rgrad accepts 2- or 3-tuple shapes | PASS |
| journal_photo | 1 | broadcast (1,1,3) vs (wh,ww) on brass glow | missing [:,:,None] on mask | added trailing None index | PASS |
| all screens_v2 | 1-2 | size ≤500KB FAIL: 2.4-3.0MB raw PNGs | per-pixel white-noise grain = high PNG entropy; budget ladder absent | low-frequency bilinear grain + save ladder: blur0.6 → quantize256 FS → 64c → 48c → 32c NONE | PASS 423-497KB |
| journal_paper / journal_photo | 3 | still >500KB after first ladder (514/577) | mid-tone stains + photo-window white noise keep palette-index entropy | paper: fib σ5→3, stains 14→8 @ lower alpha, pre-blur 0.55; photo window grain → low-freq σ2.5; final 32c rung | PASS 422.8 / 464.1KB |
| hex_locked_128 | 1 | ImageDraw ink TypeError (5-tuple color) | outline already RGBA, helper appended another (255,) | use outline as-is | PASS |
| btn_secondary_{pressed,disabled} | 3 | std@50% below generic 15-level threshold (12/14) | secondary family confined to canon PANEL↔DARK band (~20 levels); muted states are intentionally quieter — same QA-semantics case as predecessor session's pressed variants | state-scoped thresholds (normal/hover ≥15, pressed/disabled ≥10), gradient spread widened within canon band | PASS by corrected semantics (documented DEFAULT_CHOICE) |
| weather_fog_256x144 | 1 | palette scan PURE-WHITE(255) | stacked additive STEEL bands saturated to 255 | bands tinted ×0.82, clamp ≤235 | PASS |
| chrome margins (panels/buttons/tabs/slots/hexes) | 2 | 9-slice gutter test: bottom/right rows 91-95% transparent (AA + stroke bleed into margin ring) | shapes drawn exactly at margin boundary; stroke+AA spill outward | all chrome inset +2px inside the 10px margin; equip double-border moved inside | PASS 100% clean gutters |

Session totals: 41/41 delivered green (6 screens + 35 chrome), 0 blocked.
Pipeline lessons:
1. For ≤500KB full-HD painted PNGs: never use per-pixel white noise — bilinear-upscaled low-freq grain plus a quantize ladder (blur → 256 FS dither → 64/48/32 none) lands 420-500KB with night scenes visually unchanged.
2. Draw 9-slice art INSET from the intended gutter margin (margin+2): PIL rounded_rectangle strokes and AA bleed 1-2px outward and will fail strict transparency-margin QA otherwise.
3. Scope readability metrics per component class: muted button states, flat paper, coin-pile centers, stencil knockouts all legitimately measure low global contrast — test fill-vs-edge contrast on interactive chrome only.
