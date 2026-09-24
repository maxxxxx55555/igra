# TZ compliance — live ledger (C4 TZ-CLOSE)

Source: `docs/TZ_COMPLIANCE_AUDIT.md` (static read, 2026-09-21), TZ = `docs/GDD.md`. This file tracks
what C4 changed and how each row was verified. `docs/TZ_DECISIONS.md` holds the DR reasoning.

Verdicts: **MET** (run evidence: a check in `scenes/tools/tz_verify_scene.tscn` passed on a real
windowed run AND the frame below was read by eye) · **MET-STATIC** (code/data matches, no run
evidence) · **DECIDED** (a DR rule kept the current behavior, reason in TZ_DECISIONS) ·
**DEFERRED-STRUCTURAL** · **NEEDS-EYES** (subjective feel only) · **GAP-OWNER** · **GAP-DEV** (open).

Verify run: `godot --path . --rendering-method gl_compatibility res://scenes/tools/tz_verify_scene.tscn`
→ 13 checks, `DONE fails=0` (2026-09-25, HEAD `2547fff`). Frames: `docs/stills/tzverify/` (half-res
copies, all PASS `visual_truth_gate.py`).

| ID | Requirement (short) | Verdict | Run evidence / frame | Commit |
|---|---|---|---|---|
| A02 | Music crossfade 2.0 s | MET-STATIC (audio: numeric check only, no frame possible) | probe: `FADE_TIME=2.0` | `fa5fee4` |
| V02 | No neon / #fff | MET | `V02_energy_ball.png` - ember-rimmed warm ball, no magenta | `fa5fee4` |
| V05 | Moon shadow 2048² | MET | probe `size=2048`; `baseline.png` clean at 2048 (A/B vs 1024: equal) | `fa5fee4` |
| G02 | Sprint headbob 0.1 | MET | probe: eye-height span 0.049 while running; `G03_sprint_fov.png` | `fa5fee4` |
| G03 | Sprint FOV +5° | MET | probe: FOV 80.0 -> 85.0; `G03_sprint_fov.png` | `fa5fee4` |
| G06 | Sprint x1.6 | MET | probe: run 272 = walk 170 x 1.6; bot 3/3 | `c0817d8` |
| G07 | Crouch speed/noise/visibility/capsule | MET-STATIC (noise x0.3, speed x0.4) / DEFERRED-STRUCTURAL (visibility x0.5, 1.2 m capsule) | — | `c0817d8` |
| G08 | Flashlight 45° / `#c9a24a` | MET (colour, cone) / NEEDS-EYES (8 m range, energy 2.0 - renderer-unit mismatch) | probe `c9a24a / 45.0`; `G08_flashlight.png` | `63179a7` |
| G12b | Flicker <20%, cleared by Stability L5 | MET | probe: light_energy spread 13.7 at 10% battery; `G12b_low_battery.png` | `547afd3` |
| C06 | Tiers: fog, particles 50–150% | MET | probe: fog 0.012 (low) / 0.015 (ultra), 6/6 emitters at 150%; `C06_tier_low.png`, `C06_tier_ultra.png` | `2547fff` |
| G17 | Hardcore: death deletes save | MET | probe: save before=true after=false; `G17_hardcore_death.png` | `f738e99` |
| E03/T02 | Ad: 1 h cooldown, skip -100 | MET-STATIC (cooldown, skip mechanism) / DECIDED (modal: see below) | — | `f738e99` |
| C04 | Arachnophobia renames Crawler | MET | probe: label "Слепые псы"; `C04_arachnophobia_label.png` | `f738e99` |
| S03 | Noise = ember vignette pulse | MET | probe: vignette alpha 0.5 while running; `S03_noise_vignette.png` | `40fd8a8` |
| C03 | Auto-aim | MET | probe: bends to an 8° target only when on (not visual, numeric) | `40fd8a8` |
| G09 | Drain 1%/2 s | DECIDED (DR-3) | recorded boss-fight failure at a milder value | — |
| G10 | Battery item +25% | DECIDED (DR-3) | `balance_sim` FAILs at +25 | — |
| G13 / G15 | Combo 8/12/20, attack box, capsule 1.6 | DECIDED (DR-3) | recorded winnability tuning | — |
| V03 | Bebas Neue Bold | GAP-OWNER (residual: no Bold font file exists; owner supplies it) | — | — |
| G01 | FPS canon / TPS option | DECIDED (DR-2, already true) | `baseline.png` is first-person | — |
| D02 | District unlock graph | DECIDED (DR-2, consistent with D01 order) | — | — |
| A04 | Audio size caps | MET-STATIC (re-scored by role) | — | — |
| G28/D04, N01, I02, T01 | owner rows | GAP-OWNER | see TZ_DECISIONS | — |

## Still open

GAP-DEV not yet reached: G04, G15-capsule, G16, G18, G19, G20, G21, G22, G24, G25, G26, G27,
G31-G34, S01, S02, S04, A01, A03 (re-score pending), D03/V01.
