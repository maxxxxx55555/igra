# PROOFS (rc15 closeout)

Every closure is one line: ID | claim | exact command | quoted output or frame path | commit. A claim without a line here
is FAKE and gets reverted with a CORRECTION_LOG row. Quotes are copied from the artifacts under `docs/artifacts/rc15/`
by `gen_proofs` at the time of writing, so they cannot drift from the logs.

## Launch ledger

Budget: 10 Godot launches. One entry per top-level launch command; `tools/check.sh` and an `autoplay_bot` invocation
count as one entry each however many engine processes they start.

| # | command | purpose | result |
|---|---|---|---|
| 1 | `godot --headless --path . res://scenes/tools/compile_gate_scene.tscn` | parse and instantiate everything after the closeout batch | `COMPILE_GATE bad=0` (gd=364 tscn=169 tres=102) |
| 2 | `tools/qa_sim/closeout_check` | first run of the closeout gate | fails=5 plus 2 engine errors, every one in the check script (a `%` in a message, `String(null)`, a disabled process mode took the test monster's collider out of the physics space, wrong aim height on a 0.8 m crawler) |
| 3 | `tools/qa_sim/closeout_check` | after the test-script fixes | fails=3 (auto-aim aimed at the monster's feet: fixed in the game; a pack-weight set-up in the test) |
| 4 | `tools/qa_sim/closeout_check` | after the auto-aim fix (aim at the collider centre) | fails=1 (the test's target had died to the earlier shots) |
| 5 | `tools/qa_sim/closeout_check` | fresh auto-aim target | `DONE checks=114 fails=0` |
| 6 | `QA_SEEDS="1 2 3" tools/qa_sim/autoplay_bot` | IRON RULE for the closeout batch (the harness grants the strobe at the boss door) | 3/3 WIN, 11/11 districts FULL, 0 deaths, 0 softlocks |
| 7 | `godot --editor --quit --path .` | import the ten new item icons | rc=0, ten `.import` files committed |

## Closures

| ID | claim | command | evidence | commit |
|---|---|---|---|---|
| V03 | Headings are Bebas Neue Bold (the family has one weight, so the face is emboldened) in the code theme and the project theme | `tools/qa_sim/closeout_check` | V03 ThemeProvider headings use the emboldened Bebas Neue ; V03 the project theme Button font is the bold variation | 83276c6 |
| G28/D04, N01, I02 | GDD amended: the win goes through the Architect (4.3), the New Game+ rule is written (12.5), the key census is the real 1407 per locale | `git show 3d936da -- docs/GDD.md` | three hunks in `docs/GDD.md` (line 22, line 119, new section 12.5); `python tools/qa_sim/i18n_truth_gate.py` prints `12/12 locales PASS` on 1407 keys per file | 3d936da |
| input-map | Seven dead action blocks left [application]; reload, uv_toggle and workbench are real actions | `python tools/qa_sim/project_input_check.py` | `project_input_check: ok`; against the rc14 file (`git show HEAD~3:project.godot`) it reports 10 errors, among them `action block 'sprint' sits in [application], not [input]` | 83276c6 |
| S02 | Visibility model: light off halves the sight range, the dark caps it at 3 m, running +20%, crouching halves, hiding 0 | `tools/qa_sim/closeout_check` | S02 flashlight on, walking: the monster's own sight (6.0 m) ; S02 running adds 20% (7.2 m) ; S02 light off halves it and the dark caps it at 3 m ((3.0, 1.0)) ; S02 crouching with the light off: 1.5 m | c71b722 |
| S04-hide | Hiding spots are placed (three in each of the 11 districts) and work: enter, visibility 0, dimmed view, step out on the street side | `tools/qa_sim/closeout_check` | S04 power_station has hiding spots (3) ; S04 entering a spot: visibility 0 and the event fired ; S04 the view dims while hidden ; S04 the player steps out on the street side with the collider solid again | c71b722 |
| G25 | Firearms: found in D2/D7/D8, drawn by two quick slots, hitscan damage, shared ammo, reload from the reserve, saved, forged saves clamped | `tools/qa_sim/closeout_check` | G25 the three guns lie in D2, D7 and D8 ({ &"residential": "pistol", &"police": "rifle", &"warehouses": "shotgun" }) ; G25 a pistol hit hurts the monster (50.0 -> 25.8) ; G25 the reload draws the magazine from the reserve (12 in, 12 left) ; G25 quick slot 2 draws the long gun carried (the shotgun) ; G25 a forged save cannot add a weapon or overfill the reserve | c71b722 |
| C03 | Auto-aim has a Settings toggle and a consumer: on, the aim leans toward a living monster near the line; off, it does nothing | `tools/qa_sim/closeout_check; python tools/qa_sim/a11y_check.py` | C03 auto-aim on pulls the aim toward the monster ; C03 auto-aim off leaves the aim alone | c71b722 |
| G21 | Five blueprints in D2/D4/D7/D8/D9, learned on pickup, crafted at workbenches (D1/D7/D9) or the portable one; strobe gated by its recipe; UV, capacity +20%/+40%; a result that does not fit returns the parts | `tools/qa_sim/closeout_check` | G21 a workbench stands in D1, D7 and D9 ([&"suburbs", &"police", &"industrial"]) ; G21 the strobe needs its blueprint and a workbench first ; G21 using it raises the flashlight capacity by 20% (120) ; G21 battery L2 raises the capacity to +40% (140) ; G21 the UV cone hurts what stands in it (50.0 -> 43.9 in 1.3 s) ; G21 the portable workbench key opens the workbench screen ; G21 a result the pack cannot carry gives the parts back | c71b722 |
| G26 | Photo album: a photo for each find, secret, quest, first kill of a kind, artifact and three per district; 203 sources; Photographer at the 50th photo; the Codex has a Photos tab; path-like ids refused | `tools/qa_sim/closeout_check` | G26 the game can give 200 photos or more (203) ; G26 the 50th photo unlocks Photographer ; G26 the album shows the count (50 / 203 photos) ; G26 a photo id that could be a path is refused | c71b722 |
| inventory | Tab opens an inventory screen: grid, detail, use, drop with confirmation, sort and rarity filter; the pause menu offers inventory, shop, upgrades and save and quit | `tools/qa_sim/closeout_check` | V.5 Use consumes one battery and recharges the light ; V.5 the second press throws the stack away ; the pause menu offers PAUSE_SAVE_QUIT | c71b722 |
| settings-back | Back from Settings opened from the main menu returns to the menu (it was a dead end: the button only closed a UIManager overlay) | `tools/qa_sim/closeout_check` | Back returns from Settings to the main menu | c71b722 |
| achievements | Combo Master, Overloaded, Economist, Quiet as a Mouse, Without a Scratch, Who's There, Darkness, Speedrunner, Iron Man, Midsummer Night's Dream and the Shadow id have triggers | `tools/qa_sim/closeout_check` | ach_07 ten combo-3 chains in a row unlock Combo Master ; ach_06 District 3 restored unnoticed unlocks it ; ach_19 sleeping in the bed heals and unlocks Midsummer Night's Dream ; the Shadow carries its own id (quests, the bestiary and Shadow Hunter read it) | c71b722 |
| difficulty | The Difficulty pick scales monsters (Easy 80% health / 75% damage, Hard 120% / 125%) and the screen says so | `tools/qa_sim/closeout_check` | difficulty Easy: monsters at 80% health, 75% damage (40.0 / 15.0) ; difficulty Hard: monsters at 120% health, 125% damage (60.0 / 25.0) | c71b722 |
| IRON-batch1 | The closeout batch did not break winnability | `QA_SEEDS="1 2 3" tools/qa_sim/autoplay_bot` | `autoplay bot: 3/3 seeds won, 0 softlock(s)` (docs/artifacts/rc15/bot_batch1_summary.txt: 11/11 districts FULL, 0 deaths on seeds 1-3) | c71b722 |
