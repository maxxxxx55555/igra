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
`scripts/world/power_grid.gd:49`; the runner calls it at `scripts/tools/_density_frames_runner.gd:82`) and shoots five views of each. Frames land in `store/screenshots/recipes/<district>_<view>_<lang>_<hash>_<UTC>.png`
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
| 8 | The last streetlight: the cooling towers' halo over a lit grid | power_station, FULL | `power_station_04_block` | (0, 0.1, 0) to (16, 1.5, -16), pitch -0.05 | off |

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

## 6. Status

The frames are shot by the two commands at the final hash of the pass, READ one by one and checked by `store_frames_check.py`; the result of that reading is in `docs/RUN_STATE.md`
(the S23 store frames row). Until a frame is read it is a candidate. The upload itself (Play Console) is the owner's (`docs/store/HUMAN_CHECKLIST.md`).
