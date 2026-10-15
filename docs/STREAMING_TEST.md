# Streaming test (Session 23, P1)

The directive's question: traverse all districts at normal speed, verify that nothing visibly pops in, measure the load time of each district transition (it must be under 2 s), and adjust the
streaming distance or the preload strategy if something does. The honest first fact: **this game does not stream.** A district is built whole, on the main thread, in the frame of the switch
(`DistrictSceneFactory.build`, called at `scripts/world/world_runtime.gd:70` from `load_district`, line 55), the old one is taken out of the tree at once, and the two districts next to it in the
order of `DistrictSceneFactory.DISTRICTS` are asked for ahead of time with three street textures (`district_preloader.request_around`, called at line 76, defined at `scripts/world/district_preloader.gd:10`). The
streets of a district stand on a 16 m grid (`scripts/world/street_builder.gd:20`) and its dressing, props and landmark are built with it; there is no world cell that loads while the player walks, so there is
no distance to adjust, and no texture is streamed in by distance (the Compatibility renderer has no texture streaming, DEFER-23 in `docs/TZ_DECISIONS.md`). What can be measured is the
cost of the switch, and that is what the probe reads.

## 1. The measurement

`tools/qa_sim/rc16_probe after <hash>` (windowed, muted, `scripts/tools/_rc16_probe_runner.gd:43`, `_transition`) switches the real `WorldRuntime` to each of the eleven districts, once cold and once warm,
records every frame from the switch until 1.5 s after it, and prints per district: the time to the new district (`load_ms`), the time until three more frames have drawn (`settled_ms`), the frames over 50 ms
(`hitches`, `HITCH_MS` in line 9), the worst frame, the milliseconds spent over the 33.3 ms budget, and the memory. Launch 24 (row 117, `s23_last_a4acbb5`, `docs/artifacts/rc16/proofs/s23_last_a4acbb5.attach.rc16_probe_after.log`, lines 7 to 26),
head `a4acbb5`, High tier, the dev iGPU, the machine not checked for other load (launch 23 at `f2e628a` read 234 to 308 ms cold and 188 to 388 ms warm, launch 18, row 110 at `0aae342`, 235 to 332 ms cold):

| Pass | Switches | Load to the new district | Until settled | Hitches (frames over 50 ms) | Worst frame | Over the 33.3 ms budget, summed |
|---|---|---|---|---|---|---|
| cold (the first visit) | 10 | 218 to 342 ms (median 265) | 267 to 455 ms | 1 to 4 | 130 to 150 ms | 105 to 260 ms |
| warm (the second visit) | 10 | 198 to 258 ms (median 218.5) | 255 to 330 ms | 1 to 2 | 135 to 149 ms | 110 to 133 ms |

The 20 switches of the two passes (and the 4 of the perf and frame passes) all ended in the district asked for (`ok=true`).

**Verdict against the criterion: every transition is under 2 s, by a factor of four to eight** (the slowest settles in 455 ms). The cost is one freeze of about 0.13 to 0.15 s at the switch: the
longest frame of every transition is 130 to 150 ms and 1 to 4 frames of it exceed 50 ms. Where it goes (the `stats` of the same lines, cold, median of ten): the props phase builds in 116.8 ms (95.2 to 147.2), the loot 21.1 ms,
the enemies 6.6 ms, the streets 1.6 ms, the scene 1.0 ms. The props phase, which also builds the dressing of this pass (the batches, the landmark, the pools, the rest spot, the manholes), is the whole hitch; it
was 135 ms at its median in the Session 6 probe (`s6_reimport_probe_after_c3e79e5`, 86 to 197 ms) 112.6 ms in launch 18 and 132.0 ms in launch 23, so the dressing did not make the switch dearer in a way this probe can see
(the spread between two runs of the same code is as wide as the difference).

**The one cold visit that stood apart in launch 23, the power station with 11 frames over 50 ms and 454 ms over the budget in its 1.5 s, did not repeat:** in launch 24 it had 1 hitch and 105 ms over the budget (`s23_last_a4acbb5.attach.rc16_probe_after.log:16`), as in launch 18 (1), and the perf pass that came back to it read 1 (`:29`).
The cause of the 11 is not traced (a first use of something in that district, or the machine; the worst cold visit of launch 24 is the school, 4 hitches and 260 ms over the budget, `:9`): the row of `docs/KNOWN_ISSUES.md` that held it was closed as not reproduced, not as explained, and is open again after the next probe (below).

**The probe of the fix chain (ledger row 120, head `0752c9b`, `docs/artifacts/rc16/proofs/s23_fixenv_0752c9b.attach.rc16_probe_after.log`, lines 7 to 26) agrees on the switches and not on that visit.** All 20 switches of the cold and warm passes ended in the district asked for: cold 267 to 333 ms to the new district (median 287), settled in 338 to 426 ms, 1 to 2 hitches each (18 in the ten), the worst frame 133 to 148 ms; warm 226 to 267 ms (median 243), settled in 288 to 363 ms, 1 to 2 hitches each (18). The medians are 22 and 24 ms above launch 24's and the ranges lie inside launch 23's (234 to 308 ms cold, 188 to 388 warm): the spread between two runs of the same code is that wide, and the handler that lights a district entered by its own stage (CORRECTION_LOG 252) adds a few property writes, which this probe cannot separate from the spread. **The perf pass came back to the power station and read 10 hitches and 592 ms over the budget** (`:29`, against 1 and 113 ms in launch 24), so the 11 hitches of launch 23 are not gone: the effect has shown at the power station in 2 of 3 probes, in different passes (the cold visit in launch 23, the perf visit now), and its cause is still not traced (CORRECTION_LOG 256). The pass's own lines read a p95 of 33.33 ms and a GPU mean of 12.66 ms there (`:30-31`; 16.67 and 8.45 in launch 24), and the first visit to the suburbs, which no district-entered signal precedes, read 10.03 ms against 13.59 (`:5`): the spread of the probe between two runs (3.6 ms) is as wide as that difference (4.2 ms). The probe enters every district at stage 0, where the handler writes the dark values and switches nothing; the one cost that is new at a dark-to-FULL entry, the moon's shadow switching on (`scripts/world_env_setup.gd:141`), is measured by no run.

## 2. Memory across the switches

Over the 20 switches of the cold and warm passes the texture memory stood at 55.7 to 56.1 MiB and the video memory at 83.2 to 83.7 MiB (69.7 to 70.2 and 97.3 to 97.8 in launch 18; the 14 MiB lower reading in both
fits the MSAA of the tier, which is 2x at High since MSAA-23 in `docs/TZ_DECISIONS.md`: a fit, not a measurement). The industrial state of the frames pass reads 98.3 and 127.9 MiB (the polish pass of Session 6 read 130.0
and 159.6 MiB of video memory in two industrial frames); that was not traced to a cause, so none is claimed here. The nodes of the tree stood at 1,107 to 1,152 and the orphan nodes at 6 throughout: a district leaves nothing
behind. The engine's static memory rose from 101.9 to 105.3 MiB over the ten cold visits and stood at 105.2 to 105.6 MiB through the ten warm ones: what the first visit of a district costs, and the second does not. It is
read again over the district changes of the soak in `docs/MEMORY_TEST.md`.

## 3. Pop-in

Nothing is requested by distance after the switch: the street and prop phases run a frame later than the scene (`streets_ms` and `props_ms` of `get_last_load_stats`, `scripts/world/world_runtime.gd:16`) and are
done inside the 1.5 s the probe records. What the probe cannot see is a picture: it measures times, and no frame in this document was taken in the first frame after a switch, so a pop-in of one frame is neither
shown nor ruled out. A freeze of 0.14 s with the map open or behind the travel is a hitch; whether it or a one-frame gap is felt on a phone is **U1 and U19** of `docs/UNVERIFIABLE_HERE.md`.

## 4. Decisions and owner rows

- No streaming distance, LOD or occluder is added: nothing in a district is far enough to stream, and the reasons for LOD and occluders are in DEFER-23. The preload strategy stands (the two nearest districts are asked for ahead).
- **Owner row ST-1:** the one 0.14 s freeze per switch could be spread over a few frames by building the props in batches (the dressing is a set of independent MultiMeshes); not done blind, because the district build is
  ordered (the loot and the player placement read the props). Executable action: if the freeze is felt on a phone at the map's Travel button, give `StreetProps` a per-frame budget and re-run `tools/qa_sim/rc16_probe after <hash>`.
