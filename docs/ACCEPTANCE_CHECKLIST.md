# Acceptance checklist (rc15 closeout)

Source: `docs/GDD.md` (the owner's specification), plus the read-only explorer audit of Appendix V, sections 24-25 and the
screen list against the code. One row per player-visible promise. **Result** values: `PASS(...)` proven by the
evidence named (see `docs/PROOFS.md`), `BATTERY` proven by a gate that the sign-off battery re-runs, `PT-<step>` proven
by the play-through step, `DECIDED` a recorded deviation (docs/TZ_DECISIONS.md), `OWNER` needs the owner or an asset,
`ROADMAP` the GDD itself tags it M4 or vision, `NOT-VERIFIABLE` no honest measurement exists, `OPEN` promised and not built.

Play-through steps (GUI-engine input injection, a frame read at each; the step logs are `docs/artifacts/rc15/playthrough_A/V/B/S.txt`):
mode A **A01** boot to menu, **A02** Play, **A03** onboarding, **A04** first repair and the controls, **A05** first monster,
**A06** inventory, pause menu, shop and upgrades, **A07** map travel, **A08** battery low, **A09** the skill tree, **A12** graphics tiers,
**A13** 13 languages; mode V (the bot plays on) **V09** the Architect, **V10** victory, **V11** New Game+, **V14** Save and quit;
mode B **B01** relaunch, **B02** Continue, **B03** hardcore, **B04** daily challenge, **B05** achievements; mode S **S_codex_*** every
Codex tab, **S_hud_*** the HUD buttons, **S_workbench**, **S_credits**.


## 1. Overview (GDD 1)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| OV1 | One fixed map of 11 districts, not procedural | 1 | closeout_check: DistrictLoot.populate on all 11 districts; bot 11/11 FULL | BATTERY |
| OV2 | 13 languages, every user string translated, no mixed script | 1, CLAUDE.md | i18n_truth_gate 12/12 + hardcoded_text_gate + PT language sweep | PT-A13 |
| OV3 | Android first, desktop optional, offline | 1 | signed AAB (`jarsigner -verify`); device run is an owner step | OWNER |
| OV4 | 8-12 h for one ending | 1 | design estimate: the bot clears the whole game in about 10 min; no gate measures a human's time | NOT-VERIFIABLE |

## 2. Camera and controls (GDD 2)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| CT1 | FPS camera at eye height, pitch limited | 2.1 | tz_verify G01 + game_test_3d (camera follows the player) | BATTERY |
| CT2 | Head bob 0.1 while sprinting, FOV 80 (+5 sprint) | 2.1 | tz_verify G02, G03 | BATTERY |
| CT3 | Flashlight is a SpotLight on the camera | 2.1 | tz_verify G08 frame; PT frames | PT-A04 |
| CT4 | Interaction by a 3 m ray | 2.1 | DECIDED DR-1: proximity + facing cone, 3.2 m (a tighter reach is on the REJECTED list) | DECIDED |
| CT5 | Touch: drag = camera, double tap = dodge, right buttons = action/flashlight/jump | 2.2 | hud_3d + virtual_joystick; DR-2 left 35% is the stick | DECIDED |
| CT6 | Touch: swipe down = crouch | 2.2 | closeout_check CT6 (quick swipe down in the look zone toggles the crouch; slow, short and joystick-side swipes do not) | PASS(closeout CT6) |
| CT7 | Touch: pinch = camera zoom (optional) | 2.2 | not built; the GDD marks it optional | ROADMAP |
| CT8 | PC keys WASD, Space, Shift, F, E, Ctrl, C, Esc | 2.3 | project_input_check (blocks only in [input]) + suite P1b every action exercised | BATTERY |
| CT9 | Coyote time 0.1 s, jump buffer 0.1 s | 2.4 | constants in player_3d.gd | BATTERY |
| CT10 | Sprint x1.6 | 2.4 | tz_verify G06 | BATTERY |
| CT11 | Crouch: speed x0.4, noise x0.3 | 2.4 | player_3d constants; bot never crouches | BATTERY |
| CT12 | Crouch: visibility x0.5 | 2.4 | closeout_check S02 (crouching halves the sight range) | PASS(closeout S02) |
| CT13 | Crouch: capsule height 1.2 m (with a ceiling check) | 2.4 | closeout_check CT13 (capsule 1.6 -> 1.2 m, eye 1.7 -> 1.3, a ceiling at 0.6 m keeps the crouch until it is gone) | PASS(closeout CT13) |

## 3. Flashlight and battery (GDD 3)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| FL1 | Cone 45 deg, colour #c9a24a | 3.1 | tz_verify G08 + docs/stills/evidence/g08_*.png (DR-3 keeps range 16 m / energy 24) | BATTERY |
| FL2 | Battery shown on the HUD and dimming as it drains | 3.1 | PT frame at low battery | PT-A08 |
| FL3 | Flicker below 20% (cleared by Stability L5) | 3.1 | tz_verify G12b + suite P2r | BATTERY |
| FL4 | Strobe: STUN 1.5 s, cooldown 10 s, a crafted blueprint | 3.1, 9 | closeout_check G21 (gated by its recipe; built strobe works) | PASS(closeout G21) |
| FL5 | Drain 1% / 2 s; battery item +25% | 3.2 | DECIDED DR-3 (boss-fight failure; balance_sim fails at +25) | DECIDED |
| FL6 | At 0% the light goes out and the world is almost black | 3.2 | PT frame at 0% battery | PT-A08 |
| FL7 | Upgrade tree: 5 branches x L1-L5, price 100-2000, 19 250 coins in all | 3.3 | closeout_check upgrade table + PT purchase from the pause menu | PT-A06 |

## 4. Power grid (GDD 4)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| PG1 | 11 districts restored in the fixed chain, unlock graph by prerequisites | 4.1, 4.3 | bot 11/11 FULL x3 + suite P2j (locked travel refused) | BATTERY |
| PG2 | Stage effects DARK 0.03/0.12, STREETS 0.11/0.25, FULL 0.16/0.40 | 4.2 | tz_verify D03 + frames | BATTERY |
| PG3 | A locked district says what to restore first | 4.3 | suite P5c (district name in 12 locales) | BATTERY |
| PG4 | Switches and puzzles toggle STREETS/DARK; parts repair a district | 4.3 | PT first repair (real input) | PT-A04 |
| PG5 | All 11 FULL -> final night -> the Architect -> win -> ending | 4.3, 6.3, 12.3 | GDD amended rc15 (G28); bot win x3; PT V09 (the Architect appears) and V10 (the victory screen follows the win) | PT-V10 |
| PG6 | Stages are saved and loaded | 4.3, 10 | suite P3 + PT continue | PT-B02 |

## 5. Combat (GDD 5)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| CB1 | Combo of three hits, window 1.2 s, stamina cost, flashlight bonus, backstab x1.5 | 5.1 | the swing lands on every monster kind (`closeout_check` MELEE1) with the GDD damage 8/12/20 (G13); bot 3/3 | BATTERY |
| CB2 | Dodge: 15 stamina, i-frames 0.35 s, cooldown 0.8 s | 5.2 | constants + bot dodges | BATTERY |
| CB3 | Hitboxes: capsule 1.6 m; attack volume | 5.3 | DECIDED DR-3 (attack box 1.4x0.8x3.4 + 2.7 m sphere) | DECIDED |
| CB4 | Death: fall, then a screen with cause, time, % districts, documents | 5.4 | PT death frame | PT-A05 |
| CB5 | Respawn at the district entry, HP 50%, battery kept | 5.4 | suite P2r | BATTERY |
| CB6 | Hardcore: one life, death deletes the save | 5.4 | tz_verify G17 + PT toggle | PT-B03 |

## 6. Monsters and the boss (GDD 6)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| MN1 | FSM IDLE/PATROL/INVESTIGATE/CHASE/ATTACK/FLEE/STUN/DEAD | 6.1 | base_monster.gd State enum; bot encounters | BATTERY |
| MN2 | 11 types + boss with the GDD HP and damage | 6.2 | closeout_check MN2: all 12 scenes at the GDD 6.2 health and damage (NG+ factors applied) | PASS(closeout MN2) |
| MN3 | Boss: three phases at 70/30%, falling beams 40 | 6.3 | bot boss phases x3 (log) + PT V09 boss frames | PT-V09 |
| MN4 | Loot: 30% chance from a corpse | 6.2 | closeout_check MN4: 163 of 600 corpses dropped loot (30% +-8); every drop is battery/medkit/scrap, the Sharpshooter drops ammo | PASS(closeout MN4) |
| MN5 | Damage types and resistances applied in damage code | 6.4 | base_monster.take_damage reads the matrix; closeout shotgun/pistol hits (BULLET) | PASS(closeout G25) |
| MN6 | Statuses BLEED/BURN/POISON/SLOW/STUN reach the player | 6.5 | closeout_check MN6: BLEED (Crawler, Hunter), STUN (Destroyer), BURN (Burner), POISON (Rotter) reach the player; SLOW halves speed; STUN holds the player; H3.12 icons follow. SLOW has no inflicting monster in GDD 6.2 (DECIDED) | PASS(closeout MN6) |
| MN7 | Group behaviour: flanks and a shout that alerts allies | 6.2, 25.2 | closeout_check MN7: Hunter/Hound shout (PACK_CALLERS, 15 m) and every noise (shot 22 m, run 8 m) sends unaware monsters to the spot; 40 m / 60 m away does not hear. Flanking is emergent: allies arrive from their own bearing (DECIDED, no scripted pincer) | PASS(closeout MN7) |
| MN8 | Shadow counts as a Shadow (quests, bestiary, Shadow Hunter) | 6.2, 21 | closeout_check `the Shadow carries its own id` (quests, the bestiary and Shadow Hunter read it) | PASS(closeout) |

## 7. Stealth and noise (GDD 7)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| SN1 | Noise: run 8 m/0.8, overload +30% | 7 | player_3d + noise bar | BATTERY |
| SN2 | Noise: hit 5 m/1.0, dodge 3 m/0.4 | 7 | DECIDED DR-3 (S01: the bot went 0/3 with them) | DECIDED |
| SN3 | Visibility: light on +100%, darkness 3 m, behind a wall 0, run +20% | 7, 2.4 | closeout_check S02 (relative to light-on walking), line of sight for walls | PASS(closeout S02) |
| SN4 | Ember vignette pulses with noise | 7 | tz_verify S03 frame | BATTERY |
| SN5 | Hiding spots: lockers, bushes, car trunks, dark corners; search 10 s within 5 m | 7 | closeout_check S04 (placed, enter/exit, visibility 0, dimming); suite P2q constants | PASS(closeout S04) |

## 8. Economy, progression, quests (GDD 8)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| EC1 | Coins from caches, achievements, rewards; sell loot | 8 | GDD 8 amended: there is no vendor in the dead city, loot is spent at the workbench and coins buy upgrades and skins | DECIDED |
| EC2 | Spending: flashlight upgrades, blueprints, merchant items, skins | 8 | PT: buy an upgrade and a shop item from the pause menu | PT-A06 |
| EC3 | No hunger, no pay to win | 8 | design; no such system exists | PASS(design) |
| EC4 | Weapons and ammo exist (FPS layer over melee) | 8, 18 | closeout_check G25 | PASS(closeout G25) |
| EC5 | Quests MQ/SQ/BQ/EQ, journal, up to 3 objectives on the HUD | 8 | quest tracker HUD + journal in PT | PT-A04 |
| EC6 | Coin curve 0-200 (D1) to 8000+ (D11) | 8 | DR-4 district reward 200..1200; bot 8718-8975 | BATTERY |
| EC7 | XP, levels, skill tree of 4 branches | 19 | skill tree screen (T); suite P2e | BATTERY |

## 9. Workbench and blueprints (GDD 9, 20)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| WB1 | Five blueprints in D2, D4, D7, D8, D9 | 9 | closeout_check (placement) | PASS(closeout G21) |
| WB2 | A workbench to craft at; recipes need the blueprint and the parts | 9 | closeout_check (station, learn on pickup, craft, once-only) | PASS(closeout G21) |
| WB3 | Enhanced battery +20%, battery L2 +40% | 9 | closeout_check (capacity 120 / 140) | PASS(closeout G21) |
| WB4 | Ultraviolet: 5 damage a second in the cone | 9 | closeout_check (UV cone damage) | PASS(closeout G21) |
| WB5 | Portable workbench opens the screen anywhere | 9 | closeout_check (B key path) | PASS(closeout G21) |
| WB6 | A craft that cannot be stored gives the parts back | 9 | closeout_check | PASS(closeout G21) |

## 10. Saving (GDD 10)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| SV1 | 3 manual slots + 1 autosave | 10 | owner archived the slot picker (PLAN.md stage 1); Continue loads the latest | DECIDED |
| SV2 | What is saved: position, vitals, battery, inventory, upgrades, blueprints, stages, quests, bestiary, stats, settings | 10 | suite P3 + save_integrity + closeout_check SV2 (health, stamina and battery were not saved before rc15) + PT relaunch | PT-B02 |
| SV3 | Autosave on district change, lamp, puzzle, purchase, secret, death, every 60 s | 10 | suite P2m | BATTERY |
| SV4 | A forged save cannot add weapons, blueprints or ammo | 10 | closeout_check G25 (a forged save cannot add a weapon or overfill the reserve), SV2 (a forged number is clamped); attack_sim | PASS(closeout) |

## 11. Style (GDD 11)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| ST1 | Permanent night, no day | 11.1 | V01 + frames | BATTERY |
| ST2 | Palette tokens; no pure black/white, no neon | 11.2 | `tools/check.sh --static` (visual_truth_gate on the sign-off and beauty frames), `visual_gate_mutations.txt` | PASS(static) |
| ST3 | Fonts: Bebas Neue Bold, Roboto Condensed, Share Tech Mono | 11.3 | closeout_check (emboldened heading font) | PASS(closeout V03) |
| ST4 | Panels: 1 px edge, chamfered, no rounded corners | 11.4 | StyleBoxFlat radius 0; collection cards were 6 (fixed) | BATTERY |
| ST5 | Grain and vignette over the view | 11.4 | frames | PT-A04 |
| ST6 | ACES tonemap, fog #1a2133, moon shadow 2048 | 11.6 | tz_verify | BATTERY |

## 12. Screens and story (GDD 12)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| SC1 | Flow BOOT, SPLASH, MENU, LOADING, PLAYING, PAUSE, DEAD, VICTORY, CREDITS | 12.1 | boot_check + PT | PT-A01 |
| SC2 | MAIN_MENU, LOADING, HUD, PAUSE, SETTINGS | 12.2 | PT frames | PT-A01 |
| SC3 | CITY_MAP, JOURNAL, BESTIARY, ACHIEVEMENTS, STATS (Codex) | 12.2 | PT frames (map, codex tabs) | PT-A07 |
| SC4 | INVENTORY and CHARACTER (Tab) | 12.2 | closeout_check inventory screen; PT frame | PT-A06 |
| SC5 | SHOP and FLASHLIGHT_UPGRADE | 12.2 | reachable from the pause menu (closeout_check); PT purchase | PT-A06 |
| SC6 | WORKBENCH, PHOTO_MODE, DEATH, PUZZLE_CABLES | 12.2 | closeout_check (workbench); PT | PT-A04 |
| SC7 | POWER_GRID, EVENTS, RADIO, STORY_SCENE, FINAL_NIGHT, WEATHER, CONTROLS_TOUCH | 12.2 | The seven cards (POWER_GRID, EVENTS, RADIO, STORY_SCENE, FINAL_NIGHT, WEATHER, CONTROLS_TOUCH) are static design mockups with sample data; showing them would put fake data in front of the player. The real functions: City Map (power per district), finale_director (final night), weather_system, touch settings. DECIDED, kept unreachable | DECIDED |
| SC8 | Three acts, radio voice, documents, point of no return at D10 | 12.3 | documents + gate (suite P2q); the game has no voiced radio content, the story reaches the player as documents, quests and the journal (DECIDED) | DECIDED |
| SC9 | Five endings reachable | 12.4 | endings_sim + suite P4 | BATTERY |
| SC10 | New Game+ rule | 12.5 | GDD written rc15 from the shipped behaviour; PT V11 to V11f (setup, activate, modifier, menu, confirm, scaled monsters) | PT-V11 |

## 13. Audio (GDD 13)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| AU1 | Bus graph Master: Music, SFX (Footsteps, Combat, UI, Environment), Voice | 13 | audio_bus_check | BATTERY |
| AU2 | Adaptive layers with a 2 s crossfade | 13 | tz_verify A02 + audio_truth_gate | BATTERY |
| AU3 | Dark-ambient music without melodic themes | 13 | owner music per OWNER_HANDOFF | OWNER |
| AU4 | Footsteps: 6 surfaces x 3 speeds | 13 | footstep_check (DECIDED DR-5 for per-speed recordings) | DECIDED |
| AU5 | Nothing plays before the first input | 13 | audio_hum_check | BATTERY |

## 14. Settings and accessibility (GDD 14)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| AC1 | Graphics Low/Medium/High/Ultra (fog, particles, shadows, resolution) | 14 | settings_persist_probe + PT four frames | PT-A12 |
| AC2 | Colourblind modes (3) | 14 | a11y_check | BATTERY |
| AC3 | Text size | 14 | closeout_check AC3: Text Size Large sets content_scale_factor 1.15, Medium 1.0 (a window-wide factor, screens pin their sizes) | PASS(closeout AC3) |
| AC4 | High contrast | 14 | closeout_check AC4: High Contrast re-applies 0.5 s after a graphics tier change or a new WorldEnvironment | PASS(closeout AC4) |
| AC5 | Auto-aim toggle | 14 | closeout_check C03 + a11y_check | PASS(closeout C03) |
| AC6 | Arachnophobia mode (Crawler becomes Blind Dogs) | 14 | tz_verify C04 | BATTERY |
| AC7 | Hints on/off | 14 | closeout_check AC7: Hints off and the Keeper's Pact modifier both silence every hint (HUD _hints_on) | PASS(closeout AC7) |
| AC8 | Settings Back returns to the menu | V.2 5.4 | closeout_check `Back returns from Settings to the main menu`; PT B03 (Settings opened from the main menu) | PASS(closeout) |

## 15. Performance (GDD 15)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| PF1 | Draw calls < 200 (D1) / < 350 (D11) | 15 | windowed perf_check_scene on the running game with the quick bar, two runs: D1 167 / 166, D11 166 / 168 (the same tree with the pre-`a57f9dd` moon shadow: D1 214; the 169 / 168 of `perf_rc15.txt` were a paused tree, CORRECTION_LOG 93); `perf_rc15_final.txt` | PASS(perf) |
| PF2 | Particles < 500, RAM < 800 MB, VRAM < 400 MB | 15 | windowed perf_check_scene, two runs of the running game with the quick bar: 140 particles, 100.5 / 100.6 MiB static, 153.4 MiB video, 127.9 MiB textures (`perf_rc15_final.txt`) | PASS(perf) |
| PF3 | 30-60 FPS | 15 | windowed p95 frame time on the running game (AMD iGPU), four runs: D1 20.37 to 32.02 ms (31 to 49 fps), D11 20.37 to 26.67 ms (37 to 49 fps); the 60 and 55 fps of rc15 were a paused scene (CORRECTION_LOG 93); `perf_rc15_final.txt` | PASS(perf, 31 fps in the worst D1 run: a 4% margin over the floor on this iGPU; a phone is T01) |
| PF4 | Polygons < 50K per district | 15 | the whole frame measures 44 205 / 44 141 primitives at D1 and 45 301 / 45 429 at D11 with the quick bar (39.7K to 50.2K in the earlier runs; 76 551 on the paused tree, 106 829 with the pre-`a57f9dd` moon shadow, 1.34 M before the prop mesh cut; `perf_rc15_final.txt`) | PASS(perf; every run of the final tree is under 50K) |

## 17-24. Items, weapons, skills, achievements, album, daily, ads, toasts, stats, exit

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| IT1 | Item database (consumables, materials, keys, lore, ammo, blueprints) | 17 | asset_check + ItemDatabase | BATTERY |
| WP1 | Pistol, rifle, shotgun with GDD parameters, reload, shared ammo | 18 | closeout_check G25 | PASS(closeout G25) |
| WP2 | Weapons found in the world; two weapon quick slots | 18, 24.1 | closeout_check (placement, slot cycling) | PASS(closeout G25) |
| WP3 | Weapon comparison shown on switching | V.5 9.9 | weapon_compare_ui on weapon_switched | PT-A06 |
| AH1 | Achievement: first light, electrician, beacon, librarian | 21 | achievements_manager triggers | BATTERY |
| AH2 | Shadow hunter (50), quiet as a mouse (D3), combo master (10), overloaded (5 min) | 21 | closeout_check ach_06 (quiet as a mouse), ach_07 (combo master), ach_08 (overloaded) and `the Shadow carries its own id` (Shadow Hunter) | PASS(closeout) |
| AH3 | Photographer 50, seeker 100, collector 200 photos | 24.2 | closeout_check (50th photo; total >= 200) | PASS(closeout G26) |
| AH4 | Economist (5000), without a scratch (D4), architect, truth, darkness | 21 | closeout_check ach_11 (economist), ach_12 (without a scratch), ach_13 (architect, in the ach_16 / ach_18 win check), ach_14 (truth, with the Truth ending's conditions), ach_15 (darkness) | PASS(closeout) |
| AH5 | Speedrunner, iron man, midsummer night (bed), who is there (hallucinations) | 21 | closeout_check ach_16 / ach_18 (speedrunner, iron man), ach_19 (the bed), ach_20 (five hallucinations) | PASS(closeout) |
| AH6 | Achievements screen | 21 | PT frame | PT-B05 |
| QS1 | Six quick slots on the HUD, keys 1-6 | 24.1 | closeout_check H3.2 (six slots in the GDD order), G25 (keys 1 and 2 draw and lower the weapons) + suite P1b (every action exercised) | PASS(closeout) |
| QS2 | Drag an item from the inventory to a quick slot | 24.1 | quick slots hold an item kind; the inventory Use button and the number keys serve it (DECIDED) | DECIDED |
| PH1 | Photo album: 200 photos, 3 categories | 24.2 | closeout_check (sources, categories, count, Codex tab) | PASS(closeout G26) |
| DL1 | Daily challenge | 24.3 | menu card + streak reward (daily_challenge_manager) | PT-B04 |
| DL2 | Streak multiplier x1.5/x2/x3 at 3/5/7 days, a temporary special district | 24.3 | closeout_check DL2: x1.5 / x2 / x3 at 3 / 5 / 7 days; the fifth day pays 2 x the base; the menu card shows the multiplier | PASS(closeout DL2) |
| AD1 | Rewarded ad (+100) with a 1 per hour cooldown | 24.4 | suite P2q cooldown; stub on PC | BATTERY |
| AD2 | Watch / skip (-100) modal | 24.4 | BY-DESIGN-ABSENT (the GDD names no trigger) | DECIDED |
| TO1 | Toasts, 3 s, types | 24.5 | toast_manager (top-left, to keep clear of the quest tracker) | DECIDED |
| ST7 | Statistics screen: Overall/Combat/Exploration/Collection, 20+ rows | 24.6 | closeout_check ST7: 4 tabs, 30 rows, forged counters clamped, counters fed by kills/shots/jumps/distance/crafting | PASS(closeout ST7) |
| EX1 | Exit confirmation: save and quit / quit / cancel | 24.7 | PT V14 (Esc offers Save and quit, then the process ends); the main menu's Quit confirmation is built (`main_menu.gd`) and no step clicks it | PT-V14 |

## Appendix V. HUD sheet (V.1)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| H3.1 | HP / stamina / energy bars | V.1 | PT frame | PT-A04 |
| H3.2 | Six quick slots: weapon x2, battery, medkit, grenade, special | V.1 | closeout_check H3.2 (the bar holds two weapons, battery, medkit, grenade and the light as the special) | PASS(closeout) |
| H3.3 | Up to 3 active objectives | V.1 | quest_tracker_hud | PT-A04 |
| H3.4 | Minimap with legend | V.1 | minimap legend chip (player, district, stages) | PT-A07 |
| H3.5 | Toast with a [m.ss] timestamp | V.1 | toast_manager | PT-A04 |
| H3.6 | Crosshair changes colour by target | V.1 | hud_3d aim scan | PT-A05 |
| H3.7 | Interaction prompts | V.1 | interactor + HUD label | PT-A04 |
| H3.8 | Context hints | V.1 | closeout_check H3.8: fading light, low health and loud steps each show a hint once per run | PASS(closeout H3.8) |
| H3.9 | Virtual joystick on touch | V.1 | virtual_joystick (touch only) | BATTERY |
| H3.10 | Visibility bar | V.1 | closeout_check (value follows the visibility model) | PASS(closeout S02) |
| H3.11 | Noise bar | V.1 | hud_3d | PT-A05 |
| H3.12 | Status icons | V.1 | closeout_check H3.12: the status row shows the STUN icon and drops it when the status ends | PASS(closeout H3.12) |
| H3.13 | Weapon info: magazine / reserve | V.1 | closeout_check (HUD reads WeaponManager) | PASS(closeout G25) |
| H3.14 | Message log with timestamps | V.1 | closeout_check H3.14: pickup and quest notices are kept in the log with a [m.ss] stamp | PASS(closeout H3.14) |
| H3.15 | Damage direction indicator | V.1 | monsters now pass their position | PT-A05 |
| H3.16 | Quest progress (n/m) | V.1 | quest_tracker_hud | PT-A04 |
| H3.17 | Quick wheel (hold Q) | V.1 | quick_wheel_ui | BATTERY |
| H3.18 | Temperature stat (light form) | V.1, 8 | [M4] roadmap | ROADMAP |

## Appendix V. Menu sheet (V.2)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| M5.1 | Main-menu background: day / night / generator on | V.2 | GDD 11 has no day; the menu keeps the night background | DECIDED |
| M5.4 | Settings with 9 tabs | V.2 | Game, Controls, Graphics, Audio and Accessibility carry every control; the spec's inventory, subtitles and tutorial tabs would be empty (no voiced lines, hints are a switch in Game, inventory has its own screen) | DECIDED |
| M5.5 | Load-game screen (district, date, progress) | V.2 | owner archived the slot picker | DECIDED |
| M5.6 | New game with difficulty descriptions | V.2 | closeout_check (difficulty scaling) + PT frame | PT-A02 |
| M5.7 | Confirm: delete save, exit | V.2 | Settings > Reset Progress dialog; Quit confirm | BATTERY |
| M5.8 | Pause: resume / settings / quit (+ inventory, shop, upgrades, save and quit) | V.2 | closeout_check `the pause menu offers` inventory, SHOP_COINS, CRAFT_UPGRADE, PAUSE_SAVE_QUIT; PT A06d | PASS(closeout) |
| M5.9 | Info windows: item received, quest updated, low energy, level up | V.2 | item received, quest updated, low energy and level up show as the HUD notice line and the stamped log (H3.14, H3.8) | DECIDED |

## Appendix V. Enemies sheet (V.3)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| E7.14 | Resistances by damage type | V.3 | closeout_check / base_monster | PASS(closeout G25) |
| E7.15 | Danger levels | V.3 | closeout_check E7.15: Shadow/Watcher Low, Crawler/Hound Medium, Hunter/Brute High, Architect/Tvar Critical | PASS(closeout E7.15) |
| E7.16 | Encyclopedia: type, danger, habitat, tips, loot | V.3 | closeout_check E7.16: the detail shows danger, habitat (districts of the roster) and drops | PASS(closeout E7.16) |

## Appendix V. Inventory sheet (V.5)

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| I9.1 | Overview with equipment | V.5 | closeout_check inventory screen + PT frame | PT-A06 |
| I9.2 | Item detail: weight, effect, type | V.5 | closeout_check I9.2 (the detail shows name, rarity, weight and effect) | PASS(closeout) |
| I9.3 | Stacking | V.5 | InventoryManager | BATTERY |
| I9.4 | Actions: use, drop, disassemble (equip is built and no item sets an equip slot: see I9.5) | V.5 | closeout_check V.5 (Use consumes one battery; Drop asks, then throws the stack away), I9.4 (the workbench Salvage tab returns half the parts of an enhanced battery) | PASS(closeout) |
| I9.5 | Equipment slots head/body/legs/holster/backpack | V.5 | GDD 17 defines no head/body/legs/holster item; the slots show on the inventory screen and save; the backpack capacity comes from the shop upgrade (UpgradeSystem) | DECIDED |
| I9.6 | Backpack capacity x / max | V.5 | inventory screen header | PT-A06 |
| I9.7 | Drag to a quick slot | V.5 | quick slots hold an item kind; the inventory Use button and the number keys serve it (DECIDED) | DECIDED |
| I9.8 | Sort by type / weight / rarity | V.5 | closeout_check I9.8 (sorting by weight puts the heaviest stack first) | PASS(closeout) |
| I9.12 | Confirm on drop | V.5 | closeout_check V.5 (the first press of Drop only asks, the second throws the stack away) | PASS(closeout) |
| I9.13 | Rarity filter | V.5 | closeout_check I9.13 (the Common filter leaves the one common stack of two, All shows both) | PASS(closeout) |

## 25. Play-through findings (wave 3, rc15)

Rows the first play-through added: each was a defect a frame or a measured number showed, none a promise a gate had covered. Evidence is `docs/artifacts/rc15/closeout_check_wave3.txt` (212 checks, 0 fails) and, for the old behaviour, `closeout_mutation_wave3.txt` (the same checks fail on the code before the fix).

| ID | Promise | GDD | Proof | Result |
|---|---|---|---|---|
| MV1 | One second of the stick forward walks a person's pace, 1.4 to 3.5 m/s (3.00 m measured; 170.60 m on the old file) | 2.4 | closeout_check MV1 | PASS(closeout) |
| MV2 | A fall gathers speed and ends on the ground (1.35 m in half a second; g = 9.8 gives 1.2) | 2.4 | closeout_check MV2 | PASS(closeout) |
| MV3 | The block between four streets is floor and the building fronts are walls | 2.1 | closeout_check MV3 (ray hits GroundBody; wall at x 31.8) | PASS(closeout) |
| MV4 | Holding a direction is not a dodge; a quick second press after a release is (3 m dash) | 2.4 | closeout_check MV4 | PASS(closeout) |
| FL6b | A light that died with the battery lights again with the next charge; one switched off by hand stays off | 3.2 | closeout_check FL6 | PASS(closeout) |
| ON1 | A fresh profile's first game opens the onboarding cards, holds the game, and remembers after the seventh | 12 | closeout_check ON1 | PASS(closeout) |
| MENU1 | One menu: the overlay is gone once Settings, Difficulty or Credits is the scene | 12 | closeout_check MENU1 (old `ui_manager.gd` fails it) | PASS(closeout) |
| SH1 | The Shop card lists every catalog item, an empty wallet buys nothing, coins buy it, grant it and mark the card | 12.2 | closeout_check SH1 (old `screens.gd`: `-1 cards of 7`) | PASS(closeout) |
| CB4b | The death screen names the monster that landed the hit, the time, the districts and the documents | 5.4 | closeout_check CB4 | PASS(closeout) |
| BOT3 | The bot at a person's pace (3.0 m/s, solid ground, strobe held back, batteries picked up) wins 3 of 3, 0 deaths | 5, 6.3 | `docs/artifacts/rc15/bot_wave3_summary.txt` (QA_TIME_SCALE=4) | PASS(bot) |
| MN2s | Each monster chases at the GDD 6.2 multiple of the 3.0 m/s walk (margin 0.45 m/s) | 6.2 | closeout_check MN2 (Hunter 2.7, was 5.5) | PASS(closeout) |
| MAP1 | One city map exists; Close leaves none on screen | 12 | closeout_check MAP1 (the old `MapController` made a second) | PASS(closeout) |
| LANG1 | A save or settings file written while the game shows German carries German, not the settings default `en` | 14 | closeout_check LANG1 | PASS(closeout) |
| HUD1 | The message-log button covers nothing in the HUD stat panel | V.1 | closeout_check HUD1 | PASS(closeout) |
| ON1b | The onboarding card sits in the middle of the screen | 12 | closeout_check ON1 (220 px off before) | PASS(closeout) |
| SH1b | Every shop row ends above the Close button | 12.2 | closeout_check SH1 | PASS(closeout) |
| RESP1 | Retry respawns the new player at half health with the battery it died with (the dead player of the scene being left does not take it) | 5.4 | closeout_check RESP1; play-through A05c | PASS(closeout) |
| HP1 | Health comes back in peace (2.5 HP/s from 5 s after the last hit), not in a fight; a player can die | 5.3 | closeout_check HP1 (the old 18 HP/s gives 68 HP a second after 50) | PASS(closeout) |
| SV2b | Health, stamina and battery are saved, a forged number is clamped, a dead player saves none | 10 | closeout_check SV2 | PASS(closeout) |
| LOOT2 | What is left on the street when a district is rebuilt (death, Continue, travel back) is still there; what was picked up is not | 7 | closeout_check LOOT2 | PASS(closeout) |
| FIN1 | A game loaded with every district FULL starts the final night and the Architect comes; a new game does not | 6.3 | closeout_check FIN1 | PASS(closeout) |
| DIFF1 | A Difficulty pick is a setting: it starts nothing and wipes nothing | V.2 | closeout_check DIFF1 | PASS(closeout) |
| HC1 | Hardcore belongs to the run: the box is locked in a running game and a mid-run toggle changes neither the wipe nor Iron Man | 5.4 | closeout_check HC1 | PASS(closeout) |
| SET1 | Settings changes reach the config file by themselves; a Continue keeps the device's volume and text size | 14 | closeout_check SET1 | PASS(closeout) |
| INV2 | The pack the skill or the shop grew is as big after a load, with its items | 17 | closeout_check INV2, UPG1 | PASS(closeout) |
| PUZ1 | A solved puzzle is saved and a new game clears it | 12 | closeout_check PUZ1 | PASS(closeout) |
| DEAD1 | A dead player and a won game are not at the controls; a hit after the victory does nothing | 5.4 | closeout_check DEAD1, WIN1 | PASS(closeout) |
| STROBE1 | The strobe stuns the 52 degree cone it says, not 162 | 3.1 | closeout_check STROBE1 | PASS(closeout) |
| MELEE1 | A swing lands on every monster kind, whatever it is doing; the nearest body that takes damage is hit | 5.1 | closeout_check MELEE1 (the Area3D it replaced fails it for all eight kinds, `closeout_mutation_batch10.txt`); play-through A05 on a spawned crawler | PASS(closeout) |
| G13b | The combo deals the GDD damage 8 / 12 / 20 | 5.1 | closeout_check G13; bot 3/3 with these values (`bot_batch10_canon_combo_summary.txt`) | PASS(closeout) |
| CRAWL1 | A crawler stops when idle and goes to the spot it heard (it ran on at its last velocity) | 6.2 | closeout_check CRAWL1 | PASS(closeout) |
| TUT1 | The flashlight hint is skipped while the light is on (it starts on) and stays while it is off | 12 | closeout_check TUT1 | PASS(closeout) |
| TUT2 | Each hint ends on the real key, click, stick or double tap (flashlight, move, crouch, dodge, attack, inventory) | 12 | closeout_check TUT2 (all six fail on the old code, `closeout_mutation_batch10.txt`) | PASS(closeout) |
| A04h | No pale translucent square comes and goes in the lower-right corner of the world frame | V.1 | play-through A04h (4 of 8 frames before the dust fix, 0 after) | PT |
| STREET1 | The road markings stand above the road tiles (no z-fighting stripes on the lit road) | V.1 | closeout_check STREET1 (fails on the old height); frames `docs/artifacts/rc15/frames/A07_street_all.jpg` (stripes) and `A07_street_markings_raised.jpg` (clean) | PASS(closeout) |
| SCROLL1 | A scroll list longer than its window shows a scroll bar | V.2 | closeout_check SCROLL1 (the bar was 0 px wide); play-through A07 note on the map list | PASS(closeout) |
| WIN2 | The victory screen shows the ending this win earned (11 FULL and few documents: Hope), not the one left from before | 12.4 | closeout_check WIN2 (fails on the old code with Darkness); play-through V10 | PASS(closeout) |
| HELP1 | The Help screen's rows name real actions and carry translated text without a format placeholder | V.2 | closeout_check HELP1 (the old `sprint` row fails it); play-through S_codex_help | PASS(closeout) |
| UIS1 | Every Codex tab opens by a click, its scroll list has a window of a third of the screen, and no raw format specifier is on screen | V.2 | play-through S_codex_* (the achievements list failed it at 31%) | PT |
| TIER1 | The Graphics Tier names follow the language (Low / Medium / High / Ultra were English in every locale) | 14, V.2 | closeout_check TIER1 (ru: Низкое, Среднее, Высокое, Ультра; the English names fail it, `closeout_mutations.py`) | PASS(closeout) |
| VG1 | The visual gate fails the four committed corruption frames and passes the sign-off, beauty and clean evidence frames; every threshold mutation fails | V.1 | `tools/check.sh --static` (visual_truth_gate x3), `visual_gate_mutations.txt` | PASS(static) |
| G3D2 | The 3D scene test's real swing lands on a fresh profile: the onboarding overlay no longer holds the tree paused under the swing | 5.1 | `tools/check.sh` gate "прогон 3D-сцены" (`the tree runs while the swing plays`, `melee swing damages the monster in front`), `docs/artifacts/rc15/check_full_signoff.txt`; failed 20 -> 20 before (CORRECTION_LOG 90) | BATTERY |
| DL3 | The closeout leaves the daily challenge as it found it, so a later gate on the same profile reads a consistent file (boot, closeout, touch in order) | 24 | `docs/artifacts/rc15/signoff_gate_sequence.txt` (before and after), the touch probe in `tools/check.sh` | BATTERY |
