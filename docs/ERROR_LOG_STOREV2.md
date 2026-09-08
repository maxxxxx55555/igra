# ERROR_LOG_STOREV2 — Store/Press V2 session

Format: file/set | attempt | check failed | root cause | fix applied | final status

| File/set | Attempt | check failed | root cause | fix applied | final status |
|---|---|---|---|---|---|
| gen_store_v2.py | 1 | SyntaxError (walrus in call arg) / putalpha(ndarray) TypeError / streetlamp kwarg mismatch (`a=` vs `arr`) | draft-stage slips | literal tuple; np.dstack RGBA build; unified param name + guard | PASS |
| icon_512_v2.png | 1-2 | NEAR-WHITE 255 / NEAR-BLACK 0 in palette scan | lamp glows saturated to 255; QA read transparent corners as black | emblem glow levels reduced + hard clip 244; QA made alpha-aware (visible px only) | PASS 35.9KB |
| ALL compositions | 2 | washed-out frames; feature/press/combat means 100-220 vs designed ~20-50; NEAR-WHITE on multiple | **glow() treated imax as linear RGB multiplier** → BRASS×165 added per channel instead of BRASS×(165/255); every light source blew out its frame | glow() normalized: imax is peak add level 0..255, color×(imax/255)×falloff; float32 enforced | PASS — single root-cause fix restored intended night exposure everywhere |
| feature_1024x500_v2.png | 3 | persistent NEAR-WHITE255 (315k px, blue-white) after glow fix | leftover "no-op" line parsed as `a *= a` → pixel values SQUARED, ≥16 clipped to white | junk block deleted; clean left-third darkening ramp (0.55→1.0) for store-title calm zone | PASS 237.9KB |
| ending_truth.png | 2 | warmth gradient order break: truth(39.6) > survivor(25.9), canon requires ascending dark<truth<survivor<hope<light | bunker monitor glows too bright/large → L-term dominated index | monitor glow 120→55, ambient teal 22→9, screen fill darkened | PASS truth=0.6; full gradient 0.1<0.6<18.8<54.2<69.7 |
| storyboard series | 1-3 | mean-L spread 204 → then 81 → then 62 vs flat ≤28 band | (a) first metric read P-mode indices as luminance (QA bug); (b) real variance = storyboard-MANDATED hero beats (02 'holds warm', 10 'ignition cascade warm') can't sit in a cold band; (c) exposure clamp too weak | QA reads via RGB→L; frame_02 intensity 1.3→1.05, cascade falloff steepened; colorist pass added: per-frame P95 matched to series median, asymmetric gain clamp (−38% hot / +18% lift) | PASS: cold-frame spread 5.5 (≤12), beats 31.5/57.7 within cmed+55 |

Session totals: 31 delivered (7 listing / 5 shots / 4 social / 5 endings / 10 storyboard), 31 verified green, 0 blocked.
Pipeline lessons:
1. Glow/bloom helpers must define intensity as fraction-of-color (imax/255), never raw multiplier — raw multipliers × RGB(0-255) whites out frames silently while all bounded-QA (palette extrema) still passes on the DARK pixels elsewhere.
2. Ternary-as-statement dead branches are not no-ops when written `x *= (A if False else B)` — B executes; audit any `if False else` left in generators before trusting output.
3. Series consistency for cinematic sets: verify grade family on comparable shots (cold set spread) and bound hero beats separately; absolute-luminance bands contradict storyboards that mandate brightness arcs. Exposure-match via P95 gains (asymmetric clamp) before re-shooting anything.
