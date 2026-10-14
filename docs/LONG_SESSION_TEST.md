# Long-session test (Session 23, P1)

The directive asks for a session of two hours or more with no crash and no leak. This is the reading of one: launch 19 (ledger row 111, proof `s23_soak_e562ec9`, head `e562ec9`), `tools/qa_sim/soak soak e562ec9 120`, windowed at 1280 x 720, muted, High tier, on the dev machine
(Windows 11, a Ryzen 5 5500U, integrated Vega 7, `gl_compatibility`). Nobody played it: `scripts/tools/_soak_runner.gd` repeats a cycle of about 60 s, 120 times, in one process. A cycle is a district change as the game makes it (the eleven districts in turn), four monsters
spawned near the player and shot dead, the inventory, the map and the pause screen opened and closed, the flashlight switched, a walk of 6 s, and every ten minutes a save and a load. One `[soak] minute` line a minute carries the frame time, the engine's memory and its node counts;
`python tools/qa_sim/soak_report.py` turns the lines into the tables of this document and of `docs/MEMORY_TEST.md`, `docs/THERMAL_TEST.md` and `docs/STRESS_TEST.md`. Evidence: `docs/artifacts/rc16/proofs/s23_soak_e562ec9.attach.soak_soak.log`, `.attach.soak_soak_rss.csv`
and `.attach.soak_stress.log`.

## 1. Did it hold?

| | Reading |
|---|---|
| the process | ran 120 minutes (120 `[soak] minute` lines and `[soak] SUMMARY minutes=120`), quit on its own, and the row ends `# EXIT=0` |
| script errors | none: no `SCRIPT ERROR` line; the list of `tools/qa_sim/engine_errors.sh` matches 1,245 lines of the log, and every one is of the two kinds in the next row |
| engine errors | two kinds, both found by reading this log: 1,243 deferred calls the engine refused (UISFX, CORRECTION_LOG 234) and one shader that did not compile (the fog card, CORRECTION_LOG 233); the rest are the leaks the engine reports at every exit |
| district changes | 120, all `ok=true`: the new district stood in 298 ms at the median (588 ms at most) and was settled in 379 ms (761 ms at most), every one far under the 2 s of the directive, under the load described in section 2 |
| saves | a save and a load every ten minutes (eleven or twelve pairs: the log prints none of them) and no `SaveSystem` warning |
| the worst frame | 141.8 ms at the median of the minutes (150.0 ms at most): the one freeze of a district change (`docs/STREAMING_TEST.md`), not a stall in between |

**Verdict against the criterion "two hours without a crash": met on `e562ec9`.** The run found three defects that the short runs had not (CORRECTION_LOG 233 to 235); they were fixed after it, in the commit that records them, and each has a check (SHADER1, UISFX1, LEAK1). The soak itself was not repeated for two more hours
at the final head (the launch budget is 24); the effect of the fixes on a long run is read in section 4, on a run of 12 minutes.

## 2. The frame rate over the run, and why it is not a verdict

The mean frame rate of a minute never reached 55: 0 of 120 minutes, the median 29.8 frames a second, the best minute 52.7. The run had three states, and only the first is the game on a quiet machine:

| Minutes | State | Frames a second (median) | p95 of a minute (median) |
|---|---|---|---|
| 1 to 12 | the machine quiet | 50.7 (mean 19.7 ms) | 30.9 to 49.2 ms, 36.8 at the median (the district change is in every minute) |
| 13 to 53 | the machine shared (a one-off sample of the process list, kept in no file, read Chrome at 220 % of a core, the system process at 128 % and AutoClaw at 45 %, the game at 56 %) | 28.3 | 49.5 ms |
| 54 to 120 | every minute on one 30 Hz interval: 29.0 to 30.0 frames a second; the p95 of 13 of the 67 minutes above 33.4 ms (47.3 at most) and the p99 of 31 of them (63.0 at most); the processor at a median 104 % of its base clock (93 % at the least) and a utility of 25 %, and 98.5 % and 18.5 % in the last 30 minutes against 152 % and 56 % in minutes 31 to 60 (`docs/THERMAL_TEST.md`) | 29.9 | 33.3 ms |

Frames over 50 ms: 4,244 of 225,837 (1.9 %), 3,488 of them in the first 53 minutes. **The last state has a probable cause that was found after the run (CORRECTION_LOG 241), and no proof.** The game's quality manager (T17, on by default, and the soak runner left it on) steps the graphics tier down after 5 s under 30 FPS, and Low and Medium cap the frame rate at 30
(`SettingsManager.GRAPHICS_TIERS`): in the shared minutes 13 to 53 the mean was 28.8 frames a second, so the manager stepped down, and from then on the 45 FPS it needed to step up could not come under a cap of 30 (and 29.x at the cap counted as "under 30", so it went on down). A frame time on one 30 Hz
interval with the processor nearly idle is what that cap looks like. The log of this run carries neither the tier nor the cap, so it is a reading of the code against the log and not a repeat; the soak of the last launch prints both. The other candidates stay (the system lowering the priority of a window in the
background, the power plan, the refresh rate of the display, a thermal or power limit; the dev machine exposes no temperature and the sampler runs without administrator rights). So the table says what the machine did, not what the game costs: the cost of the game is read from the quiet minutes and from the ablation of `docs/PERF_PASS.md`. **The target of 60 frames a second sustained is not met on this machine in any state of this run** and is not claimed;
on a phone it is U1 and U19 of `docs/UNVERIFIABLE_HERE.md`.

## 3. The numbers over the run

| Reading | First 5 minutes (median) | Last 5 minutes (median) | Growth |
|---|---|---|---|
| engine static memory (MiB) | 112.30 | 127.70 | +15.40 |
| objects | 4,595 | 5,345 | +750 |
| nodes | 1,330 | 1,863 | +533 |
| orphan nodes | 6 | 6 | +0 |
| video memory (MiB) | 103.20 | 99.20 | -4.00 |
| texture memory (MiB) | 75.60 | 71.30 | -4.30 |

The memory and the nodes are read in `docs/MEMORY_TEST.md`.

## 4. After the fixes

The defects of section 1 were fixed after the run (CORRECTION_LOG 233 to 235), and a fourth, the boss's jump landing outside the wall of its district, which the bot found at launch 22 (CORRECTION_LOG 237), after that. A soak of 12 minutes at `f2e628a` (launch 23,
ledger row 115, proof `s23_final_f2e628a`, `.attach.soak_final.log` and `.attach.soak_final_rss.csv`; the same cycle, 1280 x 720, muted, High, four monsters shot dead a minute) reads:

| | Reading |
|---|---|
| engine errors | none: the list of `tools/qa_sim/engine_errors.sh` matches no line of the log (1,245 in the long run) |
| the same district a turn of the eleven apart (minutes 1 and 12) | nodes 1,299 and 1,300, orphan nodes 6 and 6, video memory 89.1 and 89.3 MiB, texture memory 61.5 and 61.6 MiB: flat, where the long run grew the nodes by 4.7 a minute |
| the frame rate of a minute | 50.3 at the least, 58.2 at the median, 59.7 at the most; 9 of 12 minutes at 55 or more; the p95 within 33 ms in 11 of 12 |
| frames over 50 ms | 133 of 41,139 (0.3 %); the worst frame of a minute 142.1 ms at the median (149.5 ms at most): the district change |
| the processor | performance 103 to 147 % of the base clock (median 138), none of 11 samples under 100 |

The machine behaved as in the first twelve minutes of the long run (50.7 frames a second there at the median, 58.2 here), so the frame rate is the game's cost on a quiet machine, and it is near 60. A run of 12 minutes does not reach the states of section 2. It shows that the one leak measured
is gone (the nodes); it cannot show a growth of the size of the long run's static memory slope (6.8 MiB an hour), which is read in `docs/MEMORY_TEST.md`.
