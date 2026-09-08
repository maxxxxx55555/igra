# ERROR_LOG_ICONSV2 — UI SKIN V2 session

Format: file/item | attempt | check failed | root cause | fix applied | final status

| File/item | Attempt | Check failed | Root cause | Fix applied | Final status |
|---|---|---|---|---|---|
| DESIGN LANGUAGE V2 canon block | 0 | block absent from brief ("[paste ... verbatim]" placeholder never filled) | brief self-reference to content above that was not included | derived V2 language from brief's inline specs (line-art 1.5–2px olive/bone + brass, textless) + asset_pipeline.md palette lock | DEFAULT_CHOICE |
| olive color | 0 | not in palette lock (#c9a24a/#141b24/#2a3340/#b4452f/#aeb6bf/#d8d2c4/#4a9ab5) | brief demands olive/bone strokes; canon GREEN (95,138,78) too saturated for line-art | OLIVE = #8f9464 (GREEN desaturated toward bone) | DEFAULT_CHOICE |
| ach_medal_v2_96 count | 0 | brief said ×12; grep found ach_01..ach_20 (20) | brief written before achievements 13–20 existed | protocol "counts must equal grepped counts" wins → 20 medals, named ach_medal_v2_[NN]_96.png (DEFAULT_CHOICE naming) | RESOLVED 20 |
| monster id source | 0 | bestiary.json ids are legacy (runner/tank/sniper/phantom/swarm) vs brief's six | bestiary.json predates GDD §9.2 roster | six brief ids (shadow/crawler/watcher/hunter/destroyer/boss) verified 1:1 in data/monsters/*.tres | RESOLVED grep-locked |
| st_wrench (gen crash) | 1 | TypeError: 5-tuple color | helper appended (255,) to already-RGBA PANEL+(60,) | solid OLIVE inner circle | PASS |
| portraits (gen crash) | 1 | alpha_composite on RGB canvas | p_canvas returned RGB, rim() composites RGBA | RGBA canvas + convert at save | PASS |
| thin glyphs readability | 2 | coverage/contrast < thresholds at 24/32/64: hospital cross, school bell, residential blocks, ctrl figures, tools, key, document | 2px strokes dilute on downscale; single-hue glyphs give near-zero luminance std | strokes 3px+, bell/cross enlarged, two-tone brass cores, ctrl figures +15% with ground line | PASS |
| district_power_station bolt | 2 | contrast 0.0 (uniform single-color stroke); degenerate concave polygon outline | PIL polygon outline width on concave shape + one flat color | filled brass polygon + bone outline (two-tone) | PASS |
| medal distinctness | 2 | inner-pattern IoU 1.000 (i%3 groups identical at thumb) | only 3 glyph variants, same spoke counts, tiny rotation delta | spokes=5+(i%5), glyph=(i//5)%4, inner radius 10+g*2, rotation i*0.7 → worst IoU 0.890 | PASS |
| portrait distinctness metric | 2 | IoU 1.000 for every pair (false FAIL) | portraits are RGB → alpha mask all-ones; alpha-silhouette metric inapplicable | metric switched to bright-accent (rim/eyes) luminance mask; worst IoU 0.182 | PASS (metric fix, not art fix) |
| city_iso_2048 coverage | 2 | city filled only top-left quadrant | asymmetric gx/gz loop ranges vs iso screen mapping (u=gx−gz, v=gx+gz) | rewritten in u/v space: u∈[−12,14), v∈[0,46) step 2 → full-canvas coverage, block shade jitter added | PASS |
