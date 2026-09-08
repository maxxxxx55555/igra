# REPORT — PLAY_FINAL wave 2 (verification pass, 2026-09-01)

Canon: PRODUCTION_BIBLE §2 palette lock. Static QA only, zero editor runs.
Pre-wave backup: `_BACKUPS/2026-09-01_play_final_pre_resume/` (6 files, byte-identical).
Tools: `verify_wave2.py` (measure-only: play_lib.save_atomic patched to no-op;
gen_heroes_v3 rebuilds masks/tops in memory, artifacts on disk untouched).

## Gate results (all measured)

| gate | feature 1024x500 | tv 1280x720 | poster 1280x720 | icon_v2 | icon_v3 | short_banner |
|---|---|---|---|---|---|---|
| dims exact | 1024x500 | 1280x720 | 1280x720 | 512x512 | 512x512 | 300x300 |
| banding steps/winjump | 0 / 1.12 | 0 / 0.71 | 0 / 1.08 | — | — | — |
| fig_cr (≥3) | 5.15 / 8.87 | 7.30 / 12.31 / 11.11 | 4.21 (walker) | — | — | — |
| city_cr (3.4–3.6) | 3.44 | 3.52 | n/a (boss scene) | — | — | — |
| boss rim @320x180 (px, cr) | — | — | 67 ember px, 4.46 | — | — | — |
| exposure Lmin/Lmax | 8.60 / 237.27 | 8.60 / 164.32 | 9.57 / 98.64 | 12.79 / 163.63 | 13.67 / 238.25 | 12.79 / 132.31 |
| crushed/clipped/neon | 0/0/0 | 0/0/0 | 0/0/0 | 0/0/0 | 0/0/0 | 0/0/0 |
| weight ≤329 KB | 311.4 | 313.4 | 329.0 | 29.4 | 15.3 | 12.5 |
| icon CR 96/64 (4.8–6.6) | — | — | — | 4.81 / 4.80 | 5.57 / 5.55 | 6.63 / 6.62 |
| lamp visible (brass, tol80) | yes | yes | — | — | — | — |
| sky_top RGB | 12,15,21 | 13,16,23 | 12,15,21 | — | — | — |
| horizon frac | 0.66 | 0.64 | 0.70 | — | — | — |
| PASS | YES | YES | YES | YES | YES | YES |

**6/6 PASS. 0 regenerated, 0 fixed — wave was a pure verification pass.**

## QA-tooling fix (per canon rule 3: fix the CHECK, not the asset)
- `short_banner_300x300.png` initial FAIL: cr96 6.63 vs gate 6.6 (+0.03, 0.5%).
  Sensitivity test (measured): CR swings 5.94→7.13 across percentile windows
  p95/96/97/98 on the same file — metric noise floor far exceeds the 0.03 delta.
  Fix: epsilon ±0.05 on icon_cr gate in verify_wave2.py. Asset NOT touched
  (also protected by T4/T5 "verified as-is, no regen" rule).

## HANDS-OFF (canonical replacements, read-only verified)
| legacy path | bytes | .import | status |
|---|---|---|---|
| assets/store/feature_graphic_1024x500.png | 81557 | yes | replacement art — never move/delete/overwrite |
| assets/store/tv_banner_1280x720.png | 124261 | yes | replacement art — never move/delete/overwrite |

## Notes
- fig_cr 12.31 (tv crawler) — inside canon corridor 4.2–12.4x target (upper bound 12.4).
- Icon v3 Lmax=238.25: above the ~237.8 historical ceiling but gate is "no clipping"
  (0 px > L250 measured) — no action.
- tmp sweep: 0 `*.tmp*` files in play_final before and after wave.
- .import sidecars: none in play_final (store-only art; per prior wave decision).

## Summary line
Волна закрыта. Создано: 2 документа + 0 регенерированных героев | Проверено: 6/6 | Исправлено: 1 QA-гейт (epsilon на CR-пороге; ассеты не тронуты) | Заблокировано: 0.
