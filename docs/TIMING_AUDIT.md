# Timing audit (rc16, O2)

Question: does gameplay run at the same speed at 30, 60 and 120 FPS? Method: `tools/qa_sim/timing_equiv` runs the probe scene `res://scenes/tools/timing_equiv_scene.tscn`
headless three times with the engine's `--fixed-fps` set to 30, 60 and 120 (simulated time, no wall clock), measures 15 quantities of the real game objects, and
`tools/qa_sim/timing_compare.py` compares each against its tolerance. The static side is `tools/qa_sim/timing_inventory.py`: it lists every per-frame constant step in
`scripts/` and fails on one that is neither fixed nor whitelisted with a reason (`tools/qa_sim/timing_whitelist.json`).

## Before (`e4bb4df` plus the harness, launch 8 of Session 16)

Raw: `docs/artifacts/rc16/proofs/timing_before.out` (exit 1) and the three logs attached to it. `TIMING_EQUIV verdict=FAIL keys=15 failures=1`.

| quantity | 30 FPS | 60 FPS | 120 FPS | max deviation | tolerance | verdict |
|---|---|---|---|---|---|---|
| pistol_shots_per_s | 3.0000 | 3.1579 | 3.3333 | 0.0556 | rel 0.050 | FAIL |
| the other 14 quantities | agree | | | | | ok |

## Fixes

- `0dd072a` the weapon cooldown and the reload tick in `_physics_process` (`scripts/weapons/weapon_base.gd:135`), the step that polls the trigger, instead of `_process`.
- `6196c1f` the camera interior blend follows seconds (`CAM1` in the closeout: the same share of the way in 0.1 s at 30 and at 120 FPS, 0.953 and 0.953).
- `a5a40c3` the inventory gate, wired into `tools/check.sh --static`.

## After (`4c9b3fd`, launch 18)

Raw: `docs/artifacts/rc16/proofs/s7_closeout_timing_4c9b3fd.out` (the closeout group of the same command is described in RUN_STATE), table `docs/artifacts/rc16/proofs/s7_closeout_timing_4c9b3fd.attach.timing_after.txt`,
logs `...attach.timing_after_30.log`, `_60.log`, `_120.log`. `TIMING_EQUIV verdict=PASS keys=15 failures=0`.

| quantity | 30 FPS | 60 FPS | 120 FPS | max deviation | tolerance |
|---|---|---|---|---|---|
| timer_1s | 1.0333 | 1.0000 | 1.0083 | 0.0333 | abs 0.050 |
| tween_1s | 1.0000 | 0.9833 | 1.0000 | 0.0167 | abs 0.050 |
| walk_mps | 2.9921 | 2.9682 | 2.9684 | 0.0081 | rel 0.030 |
| sprint_mps | 4.7107 | 4.7109 | 4.6912 | 0.0042 | rel 0.030 |
| stamina_drain_per_s | 22.4125 | 22.4125 | 22.3195 | 0.0041 | rel 0.050 |
| battery_drain_per_s | 0.2222 | 0.2222 | 0.2225 | 0.0010 | rel 0.030 |
| rifle_shots_per_s | 7.5000 | 7.5000 | 7.5000 | 0.0000 | rel 0.050 |
| pistol_shots_per_s | 3.1579 | 3.1579 | 3.1579 | 0.0000 | rel 0.050 |
| rifle_reload_s | 2.2000 | 2.2000 | 2.2000 | 0.0000 | abs 0.050 |
| melee_swings_per_s | 1.4938 | 1.4969 | 1.4969 | 0.0021 | rel 0.050 |
| monster_hits_per_s | 0.6648 | 0.6657 | 0.6662 | 0.0009 | abs 0.100 |
| monster_damage_per_s | 6.6482 | 6.6574 | 6.6620 | 0.0014 | rel 0.100 |
| player_damage_per_s | 2.2022 | 2.2053 | 2.2068 | 0.0014 | rel 0.150 |
| pickup_reach_m | 1.2500 | 1.2500 | 1.2500 | 0.0000 | abs 0.250 |
| boss_ttk_s | 20.3000 | 20.2833 | 20.2833 | 0.0008 | rel 0.050 |

The pistol rate is the same at the three frame rates: 3.1579 shots a second is 19 physics steps of 1/60 s between shots.

## Static inventory

`python tools/qa_sim/timing_inventory.py` at `4c9b3fd`: 93 scripts with timing sites, `_process` 51, `_physics_process` 12, Tween 64, Timer 22, suspects 16, open 0, stale whitelist rows 0. `tools/check.sh --static` runs it with `--demo` and `--gate`.

## AF2 pairing

The same command fails on the code before the fix (`timing_before.out`: pistol 3.0000 / 3.1579 / 3.3333, verdict FAIL) and passes after it (verdict PASS), both outputs kept.

## Not measured

Simulated time on the dev machine: a phone's frame pacing, vsync and thermal throttling are not part of it (UNVERIFIABLE-HERE, `docs/UNVERIFIABLE_HERE.md` U1; owner action: play 10 minutes on the phone and compare the pistol and the walking speed with the numbers above).
