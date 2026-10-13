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

## 6. Status and the swap log

The frames were shot by the two commands at `f2e628a` (launch 23, ledger row 115, `docs/artifacts/rc16/proofs/s23_final_f2e628a.attach.density_frames_store_en.log` and `.attach.density_frames_store_ru.log`): 50 frames, five views of each of the ten recipes' districts, all READ on contact
sheets and checked by `store_frames_check.py`. **Nine of the 50 fail the rules** (a luminance deviation under 0.04: `hospital_03_street`, `hospital_05_skyline`, `park_05_skyline`, `power_station_05_skyline`; a mean luminance under 0.06: `industrial_02_rest`, `industrial_03_street`, `industrial_04_block`,
`industrial_05_skyline`, `residential_05_skyline`), among them two of the eight recipe frames (#2, #4). The frames kept in `store/screenshots/recipes` are six, and the other 44 were taken out of the tree (they are the same frames at the same hash, reproducible by the commands of section 1):

| Kept | Replaces | Why |
|---|---|---|
| `gas_station_02_rest_en` | recipe #5, as written | a bench under a lit lantern in the dark: the one recipe frame that read as a place |
| `warehouses_02_rest_en` | recipe #3 (`warehouses_05_skyline`, dark with nothing to look at) | the same rest spot with a bench, in the warm light of its lantern |
| `hospital_02_rest_en` | recipe #4 (`hospital_03_street`, a fault) | the rest spot with the cold light of the hospital's lantern |
| `power_station_03_street_en` | recipe #8 (`power_station_04_block`, the towers' halo does not show in it) | a lit street with the lamp pool leading the eye |
| `residential_04_block_ru` | R2, as written | the lit windows of a restored block with the HUD, the brightest frame of the set |
| `suburbs_03_street_ru` | R1, as written | the first street with the objective list and a pickup caption in Russian |

Left out without a replacement: recipes #1 (`residential_04_block` in English: the view of R2 without the HUD, with a fifth of its lit pixels), #2 (`industrial_04_block`, a fault), #6 (`police_04_block`) and #7 (`park_03_street`), whose subjects (the blue windows, the ferris wheel)
are lost in the dark of the frame. **The English frames are dim, dimmer than the game**: each is 18 to 75 % as bright as the pair frame of the same district and view at the same head (`docs/stills/density`, shot in the same Trailer Mode), and the Russian frames, with the HUD on, 87 to 95 % of them. The cause was not traced (`docs/KNOWN_ISSUES.md`, Session 23): the weather rolls a new state every 45 s and was not pinned. The runner pins it now (`_pin_world`) and prints a state line per view, and the last launch shoots the set again. A page that needs brighter art is better served by the eight composed frames of `store/screenshots` (`shot01` to `shot08`, `shot_p1` to `shot_p3`), which stay; these six are the in-engine captures of the build, and which of them go to the store is the owner's choice (`docs/store/HUMAN_CHECKLIST.md`). The upload itself (Play Console) is the owner's.
