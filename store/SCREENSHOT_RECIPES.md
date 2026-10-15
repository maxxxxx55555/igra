# Store screenshot recipes (Session 23, S1)

Eight English frames and two Russian ones, each a recipe that a command carries out: which district, which power stage (the game has no day; "lit" is the restored stage FULL and "night"
the stage DARK: `docs/GDD.md`, section 11.1 "permanent night"), where the camera stands and looks, whether the flashlight is on, whether Trailer Mode is on, the language, how a player
reaches the same place, and the command that takes it. The older plan (`store/screenshot-plan-detailed.md`) and the eight composed frames of `store/screenshots` stay as they are; these
recipes are the in-engine capture of the same idea at the final build, so a store page can show what the shipped game draws.

## 1. The commands

```bash
# the eight English frames: Trailer Mode on (no HUD), English, a PNG without alpha, one process for the districts named
TLS_FRAMES_PNG=1 bash tools/qa_sim/proof_run --launch store_en_<hash> -- bash tools/qa_sim/density_frames store <hash> residential,industrial,warehouses,hospital,gas_station,police,park,power_station
# the two Russian frames: the HUD stays, the language is Russian
TLS_FRAMES_LANG=ru TLS_FRAMES_HUD=1 TLS_FRAMES_PNG=1 bash tools/qa_sim/proof_run --launch store_ru_<hash> -- bash tools/qa_sim/density_frames store <hash> suburbs,residential
python tools/qa_sim/store_frames_check.py
```

`<hash>` is the short hash of the build that is shot (it is part of every file name). The run is windowed and muted, under the user-data guard (`tools/qa_sim/density_frames`), the game starts a
new profile in the language asked (English unless `TLS_FRAMES_LANG` says otherwise), skips the onboarding and the tutorial, moves to each district, raises its power as the view asks (`PowerGrid.advance_district`,
`scripts/world/power_grid.gd:49`; the runner calls it at `scripts/tools/_density_frames_runner.gd:94`, after it has marked the districts that power the one it shoots FULL) and shoots five views of each. Frames land in `store/screenshots/recipes/<district>_<view>_<lang>_<hash>_<UTC>.png`
at **960 x 540 (exactly 16:9), RGB, no alpha**. A recipe names one of the five views; the other four are there to pick from when a frame reads badly.

## 2. Composition rules

- 960 x 540 PNG, RGB, no alpha; the mean luminance 0.06 to 0.40; not blank; at most 0.3 % of the pixels blown out to white (the style guide bans pure white). These are held by
  `python tools/qa_sim/store_frames_check.py` (`--demo` proves it; it exits 1 on a violation).
- The 16:9 safe margin: the subject (a lit window block, the landmark, the lantern) stands inside the middle 80 % of the width and the middle 70 % of the height; Play crops the edges of a
  wide frame. The poses below were chosen for it, and each frame is looked at for it (no tool can judge a subject).
- No text, arrows or logo are burned into a frame. A title overlay is optional and belongs to the store page, never to the file (`store/screens_spec/shotlist.json`, the contract line).
- A frame that is black, cluttered or off the palette is replaced by another view of the same district and the swap is logged.

## 3. The eight English frames (Trailer Mode on, flashlight as stated)

| # | The selling point | District, power | View (file stem) | Camera at, looking at, pitch | Flashlight |
|---|---|---|---|---|---|
| 1 | Light against the dark: a restored street between two blocks | residential, FULL | `residential_04_block` | (0, 0.1, 0) to (16, 1.5, -16), pitch -0.05 | off |
| 2 | Industry back on, steam and haze | industrial, FULL | `industrial_04_block` | (0, 0.1, 0) to (16, 1.5, -16), pitch -0.05 | off |
| 3 | The crane in the fog | warehouses, FULL | `warehouses_05_skyline` | (0, 0.1, 18) to (0, 1.7, -60), pitch 0.22 | off |
| 4 | A street that leads to the lit cross of the hospital | hospital, FULL | `hospital_03_street` | (-8, 0.1, 21) to (-8, 1.7, -30), pitch 0 | off |
| 5 | Somewhere safe: a bench under a lantern | gas_station, DARK | `gas_station_02_rest` | (6, 0.1, 15.5) to (13.5, 1.5, 13.5), pitch 0 | off |
| 6 | The blue district: the station's windows and the lamp pools | police, FULL | `police_04_block` | (0, 0.1, 0) to (16, 1.5, -16), pitch -0.05 | off |
| 7 | The ferris wheel above a lit street | park, FULL | `park_03_street` | (-8, 0.1, 21) to (-8, 1.7, -30), pitch 0 | off |
| 8 | The last streetlight: the cooling towers' halo over a lit grid | power_station, FULL | `power_station_05_skyline` | (0, 0.1, 18) to (0, 1.7, -60), pitch 0.22 | off |

The poses are `VIEWS` of `scripts/tools/_density_frames_runner.gd`; a dark frame with the flashlight on is the view `01_dark` of any district, if a store page wants the beam.

## 4. The two Russian frames (the HUD stays, `--tlang=ru`)

| # | Shows | District, power | View | What is Russian |
|---|---|---|---|---|
| R1 | the first street at the first light, with its objectives | suburbs, FULL | `suburbs_03_street` | the objective list, the caption of a pickup, the notices |
| R2 | a restored block with the HUD | residential, FULL | `residential_04_block` | the same, in a restored block |

## 5. How a player reaches the same frame

Nothing here is a developer's trick: every state is one a player can reach. A district by the City Map's Travel button (the bot presses it: `scripts/tools/_qa_autoplay_runner.gd:517`,
`Travel -> %s (map button)`), its power by the power switch of the district (the stages DARK, PARTIAL, STREETS, FULL), Trailer Mode by the toggle of the Settings screen
(`_toggle(parent, LocalizationManager.t("Trailer Mode"), "trailer_mode")`, `scripts/ui/settings_screen.gd:116`), the language by the Settings language row, and the camera by walking to the
spot (the poses are ground-level points of the street grid that every district shares). Trailer Mode hides the HUD, the objective list, the notices and the toast stack (check TRLR1,
`scripts/tools/rc16/hud_checks.gd`).

## 6. Status and the swap log

The English frames were shot again at `0752c9b` in the fix chain (ledger row 120, `s23_fixenv_0752c9b`, `docs/artifacts/rc16/proofs/s23_fixenv_0752c9b.attach.density_frames_store_en.log` and `..._ru.log`). Two defects had made the earlier ones dark: the recipe shot frames of the DARK stage, because `PowerGrid.advance_district` refuses a district whose parents are not FULL and the command's eight districts start at residential (CORRECTION_LOG 249: the runner marks the parents FULL first now and fails when a view's stage does not rise), and a district entered kept the lighting of the one left (CORRECTION_LOG 252). The state lines of the new run read weather 0 and tier 2 in all 40 views, the ambient 0.030 in the 10 stage 0 views and 0.160 in the 30 stage 3 views (`docs/artifacts/rc16/proofs/s23_ambient_states_l25.out`; at `85b55ed` 8 of those 10 read 0.160); views 01 and 02 of warehouses, police and park read stage 3 (each is the parent of an earlier district in the list), those of the other five stage 0. The 50 frames (40 English, 10 Russian) pass `store_frames_check.py` with 0 faults (`s23_store_frames_check_l25.out`), and against the pair frame of the same district and view of the same chain the English ones come to 70 to 110 % (median 100 %) of its mean luminance where both runs shot the view at stage 3 (24 frames), 100 to 101 % at stage 0 (10 frames) and 106 to 163 % in the six views that the store run shot at stage 3 and the pair run at stage 0 (`s23_store_luminance_l25.out`). The Russian run (the suburbs, then residential) read the ambient right in 4 of 4 stage 0 views; at `a4acbb5` its two dark views of residential were under the light of the suburbs, like the English ones (2 of 4), and the two Russian frames kept are lit views that this did not touch.

All 40 English and 10 Russian frames were READ on contact sheets. The frames kept in `store/screenshots/recipes` are eight (six English and two Russian, all at `0752c9b`); the other 42 were taken out of the tree (they are the same frames, reproducible by the commands of section 1):

| Kept | Recipe | Reading |
|---|---|---|
| `residential_04_block_en` | #1 as written | two lit blocks across a crossing, warm and white windows, the lamp pools on the street: the strongest frame |
| `industrial_04_block_en` | #2 as written | lit blocks, the rims of the smokestacks at the left, crates in the lamp light |
| `hospital_03_street_en` | #4 as written | the street runs to the lit cross of the hospital between two lit blocks |
| `gas_station_02_rest_en` | #5 as written (DARK) | a bench and a sign in the pool of a lit lantern in the dark: the one dark frame, and the one that reads as a place; it is a stage 0 frame under the dark light of its own stage now (mean luminance 0.144), which it was not at `85b55ed` |
| `police_04_block_en` | #6 as written | the blue district: blue-black blocks with lit windows and blue lamp pools |
| `power_station_05_skyline_en` | #8, swapped from `power_station_04_block` | the cooling towers' halo shows above a lit grid; the 04 view does not show it and has the edge of a large white arc in its top-left corner |
| `suburbs_03_street_ru` | R1 as written | the first street with the objective list and the notice in Russian |
| `residential_04_block_ru` | R2 as written | the lit block of #1 with the HUD |

Left out: #3 (`warehouses_05_skyline`: a wide dark lot with a row of lit windows far off and nothing to look at; `warehouses_04_block` is no better) and #7 (`park_03_street`: the ferris wheel is a thin ring at the top centre of a dark frame).
The English frames are as bright as the game now, and they show no film grain, because Trailer Mode hides the HUD's own grain pass (`docs/KNOWN_ISSUES.md`, the row on Trailer Mode). A page that needs brighter art is better served by the eight
composed frames of `store/screenshots` (`shot01` to `shot08`, `shot_p1` to `shot_p3`), which stay; these are the in-engine captures of the build, and which of them go to the store is the owner's choice (`docs/store/HUMAN_CHECKLIST.md`). The
upload itself (Play Console) is the owner's.
