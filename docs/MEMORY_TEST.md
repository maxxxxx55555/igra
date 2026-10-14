# Memory test (Session 23, P1)

The directive: a session of two hours, less than 50 MB of growth. The source is the soak of `docs/LONG_SESSION_TEST.md` (launch 19, proof `s23_soak_e562ec9`, head `e562ec9`), which reads the engine's own counters once a minute, and the stress run of `docs/STRESS_TEST.md`, which reads them before and after. The
tables are `python tools/qa_sim/soak_report.py`; the growth of a number is from the median of its first five minutes to the median of its last five.

## 1. The engine's counters over 120 minutes

| Reading | First 5 minutes | Last 5 minutes | Growth | Slope over the run |
|---|---|---|---|---|
| engine static memory (`OS.get_static_memory_usage`) | 112.30 MiB | 127.70 MiB | +15.40 MiB | +6.8 MiB an hour |
| objects | 4,595 | 5,345 | +750 | 6.7 a minute |
| nodes | 1,330 | 1,863 | +533 | 4.7 a minute |
| orphan nodes | 6 | 6 | +0 | none |
| video memory | 103.20 MiB | 99.20 MiB | -4.00 MiB | none |
| texture memory | 75.60 MiB | 71.30 MiB | -4.30 MiB | none |

**Against the criterion: the static memory grew by 15.40 MiB in two hours (10.5 MiB of it after the thirteenth minute), under the 50 MB limit.** Video and texture memory did not grow over 120 district changes; no orphan node was left behind (6 at the start, 6 at the end, from the first minute). The orphans, the
video memory and the texture memory are what a leak of the district build would show first, and they are flat.

## 2. What the process weighed

The working set of the game's process, from the Windows counters once a minute, was 575.1 MiB in the first five minutes and 265.1 MiB in the last five (-310.0 MiB, a slope of -185.2 MiB an hour), with 579.9 MiB at most. It fell in steps (518 to 440 MiB at the 38th minute, to 330 at the 42nd, to about 250 by the 84th; the rows are in the proof file), which is the system
trimming the working set of a process, not the game freeing memory: the working set is the resident part, and a leak would raise it. It shows no growth. The reading to judge is the engine's own static memory of section 1.

## 3. The nodes: a leak the soak found

The nodes and objects did grow, 533 and 750, steadily (the nodes by 4.7 a minute from the first minute to the last). The cause is a drop. A monster killed with 30 % chance leaves a pickup (`scripts/enemies/base_monster.gd:790`, `_maybe_drop_loot`), four nodes with a glow light among them
(`scenes/pickups/item_pickup_3d.tscn`), and it was added to the scene root, not to the district: a change of district freed the monsters and left the drops in the tree for the rest of the session. The soak kills four monsters a minute; 4 kills x 30 % x 4 nodes is 4.8 nodes a minute, the measured 4.7. The static
memory fits the same cause, since each drop also builds a material (`scripts/pickups/item_pickup_3d.gd`, `_apply_tint`); that part is a fit, not a measurement. A drop is a sibling of its monster now (CORRECTION_LOG 235), the district frees it, and LEAK1 rolls 60 drops under a holder and frees the holder.
It also ended a smaller defect: a drop used to stay at its coordinates in the next district, collectible and on the radar.

## 4. The memory of a district change and of a crowd

The 24 district changes of the probe of `docs/STREAMING_TEST.md` read 55.7 to 56.1 MiB of texture memory and 83.2 to 83.7 MiB of video memory in the cold and warm passes at the final head; the 120 minutes of the soak read 70.5 to 75.7 and 98.2 to 103.4 (before the MSAA of the tier was lowered, MSAA-23). The stress run (120 monsters, 45 s) read, at its start, 1,105 nodes, 3,975 objects and
100.0 MiB of static memory; at its peak 2,326 nodes, 6,201 objects and 133.0 MiB; two seconds after the monsters were freed, 1,126 nodes (21 more than at the start), 4,040 objects (65 more), 6 orphans and 116.4 MiB. **The monsters are gone; 16.4 MiB of static memory stays**, which is what the engine keeps after a crowd (pooled effects and
streams, the caches of the resource loader). Its cause was not traced; it does not grow with the length of a session (section 1) and a second crowd is not in the budget.

## 5. After the fix

The soak of 12 minutes at `f2e628a` (launch 23, ledger row 115, proof `s23_final_f2e628a`, `.attach.soak_final.log`; the same cycle as the long run, four monsters shot dead a minute) reads the counters again. The comparison that does not depend on which district stands is the same district a turn of the eleven
apart: minutes 1 and 12 both stand in the first district.

| Reading | Minute 1 | Minute 12 | Change |
|---|---|---|---|
| nodes | 1,299 | 1,300 | +1 |
| orphan nodes | 6 | 6 | +0 |
| video memory | 89.1 MiB | 89.3 MiB | +0.2 MiB |
| texture memory | 61.5 MiB | 61.6 MiB | +0.1 MiB |
| objects | 4,513 | 4,606 | +93 |
| engine static memory | 105.5 MiB | 111.1 MiB | +5.6 MiB |

**The nodes, which the long run grew by 4.7 a minute, are flat** (and the orphans, the video memory and the texture memory with them). The objects and the static memory rose while the eleven districts were visited the first time (the static memory from 105.5 MiB at the first to 111.2 MiB at the eleventh) and stood at 111.2 and 111.1 MiB on the second visit
of the first district: that is what the first visit of a district costs in cached resources, and the second does not, which is the pattern of the probe of `docs/STREAMING_TEST.md` (101.3 to 105.0 MiB over ten cold visits, 104.8 to 105.2 MiB through ten warm ones). **What a run of 12 minutes cannot show** is a growth of the size of the long run's static memory slope (6.8 MiB an hour, 0.1 MiB a minute): the claim of
this document for the final head is the nodes and the flat video and texture memory, and the 15.40 MiB of section 1 stays the reading of a long run, taken on the head before the fixes. The log holds no engine error (the list of `tools/qa_sim/engine_errors.sh` matches nothing).

## 6. The 120 minutes at the final head (launch 24)

The soak of `docs/LONG_SESSION_TEST.md` section 5 (launch 24, ledger row 117, proof `s23_last_a4acbb5`, head `a4acbb5`, `docs/artifacts/rc16/proofs/s23_last_a4acbb5.attach.soak_final.log` and `.attach.soak_final_rss.csv`; the same cycle, four monsters shot dead a minute, the
tier 2 and the quality manager off) reads the counters again, after the fix of section 3.

| Reading | First 5 minutes | Last 5 minutes | Growth | Slope over the run |
|---|---|---|---|---|
| engine static memory | 107.50 MiB | 117.30 MiB | +9.80 MiB | +3.7 MiB an hour (+0.5 MiB an hour from minute 60) |
| objects | 4,552 | 4,697 | +145 | |
| nodes | 1,321 | 1,340 | +19 | (+533 in the first long run) |
| orphan nodes | 6 | 6 | +0 | none |
| video memory | 89.10 MiB | 89.40 MiB | +0.30 MiB | none |
| texture memory | 61.50 MiB | 61.70 MiB | +0.20 MiB | none |

**Against the criterion: the static memory grew by 9.80 MiB in two hours (the summary line, `soak_final.log:246`, reads +9.75), under the 50 MB limit, and it is a plateau, not a slope**: it rose from 105.4 MiB at the first minute to
117.1 MiB at the 40th, while the eleven districts were visited for the first time, and stood between 116.9 and 117.4 MiB in each of the last 81 minutes. The nodes, which the first long run grew by 4.7 a minute, grew by 19 in two hours;
the same district stood at 1,299 to 1,301 nodes at its second to eleventh visit (the suburbs, whose first visit is the start of the run, 1,105 nodes), and each of the ten others held within 12 nodes across its eleven visits
(the ranges, per district, are in the lines of `[probe] stream pass=soak`). The orphans, the video memory and the texture memory are flat, as in section 1.

The working set of the process, from the Windows counters, was 569.8 MiB in the first five minutes and 249.7 MiB in the last five (-320.0 MiB, a slope of -203.7 MiB an hour), with 574.5 MiB at most: it fell, as in section 2, which is the
system trimming the working set of a process and not the game freeing memory; it shows no growth. The log holds no engine error (the list of `tools/qa_sim/engine_errors.sh` matches nothing).
