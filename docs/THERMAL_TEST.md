# Thermal test (Session 23, P1)

The directive: simulate thermal throttling and hold 60 frames a second for 30 minutes. What this environment can and cannot do: it has no phone, and the dev machine gives the game neither a CPU or GPU temperature nor a battery (U19 of `docs/UNVERIFIABLE_HERE.md`). So the test reads what a throttle shows first, the frame time and the clock of the
processor, over a load longer than the 30 minutes asked for (the 120-minute soak of `docs/LONG_SESSION_TEST.md`, launch 19, proof `s23_soak_e562ec9`), and checks the game's own answer to a slow frame by a logic check. **The 60 frames a second were not reached on this machine in any state of that run, so the criterion is not met and is not claimed.**

## 1. The frame rate and the clock, in windows of 30 minutes

`tools/qa_sim/soak` samples the processor once a minute with Windows' performance counters (`% Processor Performance`, a value under 100 is a clock below the base clock, the first sign of a throttle; `% Processor Utility`).

| Minutes | Frames a second (median, least) | p95 of a minute (median) | Frames over 50 ms | Processor performance (median, least) | Processor utility (median) |
|---|---|---|---|---|---|
| 1 to 30 | 29.6, 27.0 | 45.2 ms | 1,836 | 142 %, 127 % | 68 % |
| 31 to 60 | 28.5, 25.8 | 47.0 ms | 1,763 | 152 %, 138 % | 56 % |
| 61 to 90 | 29.8, 29.1 | 33.3 ms | 505 | 111 %, 94 % | 31 % |
| 91 to 120 | 29.9, 29.8 | 33.3 ms | 140 | 98 %, 93 % | 18 % |

Over the whole run the processor performance was 139 % at the median (93 % at the least, 180 % at most), under 100 % in 19 of 115 samples, and 140 % in the first ten samples against 99 % in the last ten.

## 2. What it shows, and what it does not

- **No slowing over time that a throttle would explain.** A throttle makes the frame time rise while the load stays; here the frame time did not rise from the first window to the last (29.6 and 29.9 frames a second at the median), and the last windows are the ones with the least work for the processor (a utility of 31 % and 18 %).
- **The clock fell with the load, not before it.** In the first two windows the processor ran at 142 % to 152 % of its base clock under a utility of 56 % to 68 %; in the last two it ran at 111 % and 98 % under 31 % and 18 %. That is the power plan lowering the clock of a lightly used processor. A reading under 100 % (93 % at the least) is in the last window only, and it is a reading
  of 19 samples that the sampler cannot tell from the plan's own saving.
- **The frame rate is not the processor's.** From the 54th minute every minute sat on one 30 Hz interval (29.0 to 30.0 frames a second, p95 and p99 33.3 ms) while the processor was nearly idle. Something other than the game's work set the rate, and the most probable thing is the game's own quality manager: it had stepped the tier down in the loaded minutes, a lowered tier caps the frame rate at 30, and it could not step up again under that cap
  (CORRECTION_LOG 241, fixed afterwards); the log carries no tier, so it is a reading. The display, the system's treatment of the window and the power plan stay as candidates.
  A phone is a different machine: U1 and U19 ask for the 20 minutes there.
- **On a quiet machine the game is near 60.** The 12-minute soak at the final head (launch 23, proof `s23_final_f2e628a`, `docs/LONG_SESSION_TEST.md` section 4) read 58.2 frames a second at the median minute (50.3 at the least, 59.7 at the most) with the processor at 103 to 147 % of its base clock (none of 11 samples under 100). Twelve minutes are not thirty, and that run is no throttle test; it
  says what the game costs when the machine does not interfere, which the long run could not.
- **The game's own answer to a slow frame is tested by logic.** Checks QM1 to QM4 step the quality manager (`scripts/systems/quality_manager.gd`: the tier down after 5 s under 30 FPS, up again after the wait, the player's own tier kept apart), and check PERF1 steps the dynamic resolution governor (`scripts/systems/dynamic_resolution.gd`) with fake frame times through every edge: under 30 frames a second for 2 s the 3D scale drops to 0.7, over 45 for 4 s it comes back, the band between holds
  (`docs/PERF_PASS.md`, Session 23). It is on by default on a phone and off on the desktop, so this run, a desktop, did not use it.

## 3. Owner row

**TH-1.** On a mid-range phone, play the power station for 20 minutes from a full charge and write down the frame time at the start and at the end, the heat of the back of the phone and the battery used. If the frame time rises over the 20 minutes, set Render Scale to 0.7 for the rest of the test and note whether the heat falls: that tells whether the governor
or a lower tier is the answer (`docs/RELEASE_RUNBOOK.md` section 4 has the smoke test this belongs to).
