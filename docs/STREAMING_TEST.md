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
(`hitches`, `HITCH_MS` in line 9), the worst frame, the milliseconds spent over the 33.3 ms budget, and the memory. Launch 110 (`s23_gates_0aae342`, `docs/artifacts/rc16/proofs/s23_gates_0aae342.attach.rc16_probe_after.log`),
head `0aae342`, High tier, the dev iGPU, the rest of the machine idle for the probe:

| Pass | Switches | Load to the new district | Until settled | Hitches (frames over 50 ms) | Worst frame | Over the 33.3 ms budget, summed |
|---|---|---|---|---|---|---|
| cold (the first visit) | 10 | 235 to 332 ms (median 260) | 294 to 456 ms | 1 to 3 | 128 to 145 ms | 102 to 202 ms |
| warm (the second visit) | 10 | 215 to 267 ms (median 245) | 280 to 364 ms | 1 to 3 | 133 to 145 ms | 122 to 170 ms |

The 20 switches of the two passes (and the 4 of the perf and frame passes) all ended in the district asked for (`ok=true`).

**Verdict against the criterion: every transition is under 2 s, by a factor of four to nine** (the slowest settles in 456 ms). The cost is one freeze of about 0.13 to 0.15 s at the switch: the
longest frame of every transition is 128 to 145 ms and 1 to 3 frames of it exceed 50 ms. Where it goes (the `stats` of the same lines, cold, median of ten): the props phase builds in 112.6 ms (105.8 to 139.0), the loot 21.8 ms,
the enemies 6.8 ms, the streets 1.6 ms, the scene 0.9 ms. The props phase, which also builds the dressing of this pass (the batches, the landmark, the pools, the rest spot, the manholes), is the whole hitch; it
was 135 ms at its median in the Session 6 probe (`s6_reimport_probe_after_c3e79e5`, 86 to 197 ms), so the dressing did not make the switch dearer in a way this probe can see.

## 2. Memory across the switches

Over the 24 switches of the run the texture memory stood at 69.7 to 70.2 MiB and the video memory at 97.3 to 97.8 MiB. Two industrial frames of the polish pass read 130.0 and 159.6 MiB of video memory; that
was not traced to a cause, so none is claimed here. The nodes of the tree stood at 1,105 to 1,152 and the orphan nodes at 6 throughout: a district leaves nothing behind. The engine's static memory rose from 100.5 to
105.7 MiB over those 24 switches, 0.22 MiB a switch; it is read again over the switches of the soak in `docs/MEMORY_TEST.md`.

## 3. Pop-in

Nothing is requested by distance after the switch: the street and prop phases run a frame later than the scene (`streets_ms` and `props_ms` of `get_last_load_stats`, `scripts/world/world_runtime.gd:16`) and are
done inside the 1.5 s the probe records. What the probe cannot see is a picture: it measures times, and no frame in this document was taken in the first frame after a switch, so a pop-in of one frame is neither
shown nor ruled out. A freeze of 0.14 s with the map open or behind the travel is a hitch; whether it or a one-frame gap is felt on a phone is **U1 and U19** of `docs/UNVERIFIABLE_HERE.md`.

## 4. Decisions and owner rows

- No streaming distance, LOD or occluder is added: nothing in a district is far enough to stream, and the reasons for LOD and occluders are in DEFER-23. The preload strategy stands (the two nearest districts are asked for ahead).
- **Owner row ST-1:** the one 0.14 s freeze per switch could be spread over a few frames by building the props in batches (the dressing is a set of independent MultiMeshes); not done blind, because the district build is
  ordered (the loot and the player placement read the props). Executable action: if the freeze is felt on a phone at the map's Travel button, give `StreetProps` a per-frame budget and re-run `tools/qa_sim/rc16_probe after <hash>`.
