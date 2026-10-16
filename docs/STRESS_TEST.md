# Stress test (Session 23, P1)

The directive asks for proof with 100 entities or more and for the worst-case scenarios. This is what was run, and what it shows.

## 1. A crowd of monsters

`tools/qa_sim/soak stress <hash> 1 300 <monsters>` (`scripts/tools/_soak_runner.gd`, `_stress`) puts N monsters (a crawler, a shadow, a hound and a rotter in turn) in a ring of 10 to 40 m round the player in the first district, their AI running, the player given 100,000 health so that nothing ends the run, and
reads every frame for 45 s, windowed at 1280 x 720, muted. The game's own cap is 8 monsters alive in a district (`scripts/enemies/enemy_pool.gd:53`, `max_active`); the runs go to 2, 4 and 15 times that. The 120 came with the soak (launch 19, proof `s23_soak_e562ec9`, head `e562ec9`), the 16 and the 32 with launch 20
(`s23_fix_3cef1de`, head `3cef1de`); the logs are `.attach.soak_stress.log`, `.attach.soak_stress16.log` and `.attach.soak_stress32.log` of the two proofs.

| Monsters | Times the cap | Frames in 45 s | Mean | p95 | p99 | Worst | Frames a second | Over 50 ms | Alive at the end | Moved |
|---|---|---|---|---|---|---|---|---|---|---|
| 16 | 2 | 2,692 | 16.72 ms | 16.67 ms | 16.67 ms | 52.9 ms | 59.8 | 1 | 16 | 15 |
| 32 | 4 | 2,697 | 16.69 ms | 16.67 ms | 16.67 ms | 49.9 ms | 59.9 | 0 | 32 | 32 |
| 120 | 15 | 353 | 127.88 ms | 142.49 ms | 146.67 ms | 147.8 ms | 7.8 | 353 | 120 | 116 |

What stood in the tree before, at the peak and after the monsters were freed (two seconds later):

| Monsters | Nodes before, peak, after | Objects before, peak, after | Static memory before, peak, after |
|---|---|---|---|
| 16 | 1,105, 1,266, 1,106 | 3,975, 4,261, 3,977 | 100.0, 102.9, 101.5 MiB |
| 32 | 1,105, 1,430, 1,110 | 3,975, 4,560, 3,991 | 100.0, 105.6, 102.6 MiB |
| 120 | 1,105, 2,326, 1,126 | 3,975, 6,201, 4,040 | 100.0, 133.0, 116.4 MiB |

## 2. Reading

- **It survives.** In the three runs every monster was alive at the end, 94 % or more of them had moved (15 of 16, 32 of 32, 116 of 120), the log holds no script error, the orphan nodes stayed at 6 and the process left cleanly. The nodes came back to within 1 to 21 of their start.
- **Up to four times the cap the game holds 60 frames a second** (16.7 ms is the vertical sync of a 60 Hz display; the worst frames, 52.9 ms at 16 monsters and 49.9 ms at 32, are single frames). **At 15 times the cap it does not: 7.8 frames a second, every frame over 50 ms.** The cost does not grow in a line: it is nothing visible at 32
  and 111 ms more at 120. A knee lies between, and where was not measured (a run at 64 or 80 is one more launch). The cause was not traced. The group alert is a noise event that reaches every monster (`scripts/enemies/base_monster.gd:830`), and 120 monsters in a ring about 1.3 m apart, all chasing, make a
  crowd the game never builds: that is the first place to look, not a finding.
- **The design cap holds the game in the flat part.** At 8 monsters alive the pool cannot reach either run; no district asks for more (`MIN_ENEMIES_PER_DISTRICT` is 3 at `scripts/enemies/enemy_pool.gd:11` and a dark district adds 3 in `_target_count`, `:94-103`). If a later design lifts the cap (waves, a swarm boss), the number to measure at is the new one: `tools/qa_sim/soak stress <hash> 1 300 <n>`.
- **On a phone** the same crowd is not measured (U1 of `docs/UNVERIFIABLE_HERE.md`).

## 3. The other worst cases of the pass

| Case | Where it is held | Reading |
|---|---|---|
| every pooled effect in flight at once | check VFX6 (`scripts/tools/rc16/fx_checks.gd`) | 426 particles with every pooled burst in flight and the world's 154, under the budget of 500 (the mutation that raises the pool to 9 a scene reads 662 and fails) |
| the finale: the boss, its waves and a lit city | the 3-seed bot (`docs/AI_STEALTH.md`, `tools/qa_sim/autoplay_bot`) | 149 to 213 s of finale per seed, every seed won, no softlock (launch 6 and the closeout of `docs/RUN_STATE.md`); at launch 22 the boss jumped outside its district and seed 2 stalled (CORRECTION_LOG 237), fixed and held by BOSS1, then 3 of 3 won at launch 23 |
| a long session with the same drops lying about | `docs/MEMORY_TEST.md`, check LEAK1 | the soak found the drops that outlived their district: 533 nodes in two hours; fixed |
| 120 district changes | `docs/LONG_SESSION_TEST.md` | all ok, none over 761 ms until settled |
| 11 districts built and counted | check DENS1, `docs/STREAMING_TEST.md` | every block holds its floor; a district stands in 188 to 388 ms |
