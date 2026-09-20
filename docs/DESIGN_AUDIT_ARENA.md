# RC design audit — Arena

**Date:** 2026-09-20 · **Source revision:** `d736c377ef0be60b7a315d32039d04a5e5029bb2` · **Method:** documentation, source tracing, engine-free checks.

**Disposition:** eight proposals for implementation review, not implemented balance changes. Only this new document is owned by this pass. No Godot run, playtest, new bot result, code/data/localization edit, or claim of release certification.

## Evidence contract

- Start with `docs/GAME_AUDIT.md:26-90` (the nine landed fixes), then follow runtime consumers rather than similarly named data. References below are repository-relative, at the source revision above. “Absent” means an addition, not an undocumented existing default.
- Follow the checked-in `docs/GAMEFEEL_SPEC.md:3-46`. `docs/QA_MATRIX.md` and `docs/BALANCE_MATRIX.md` are **absent** in this checkout; `docs/RUN_STATE.md:63-64` references them on an unmerged branch. Do not invent their contents or import another branch's canon. Available QA tables: `docs/RELEASE_READINESS_REPORT.md:85-104`, `docs/KNOWN_ISSUES.md:171-198,262-280`, and native-language findings in `docs/NATIVE_QA_FINDINGS.md`.
- Ponytail default: repair consumers, expose existing mechanics, retain balance where evidence is insufficient. Terse tables and this published Markdown are the artifact-design/token-saver treatment; no corresponding local skill files were found. Spec-kit checklist was not invoked; no feature scaffolding or additional artifact is required. Frontend-design was not used.
- Numerical deltas are recommendations, not measured outcomes. Derived arithmetic is labelled. Each proposal includes its riskiest assumption, verification, risk, bot impact and acceptance criteria. All implementation criteria remain open.

### Corrections made during this pass

| Initial assumption | Grep/read verification | Corrected conclusion |
|---|---|---|
| Both existing stealth skills are already effective end to end | `player_3d.gd:518-530` under `scripts/player/`; `scripts/systems/noise_propagation.gd:13-45`; `scripts/enemies/base_monster.gd:389-394,446-463`; repository search for `get_noise_at`, `get_sources_in_range`, `noise_detected` finds definitions but no consumer | `silent_steps` reduces emitted radius, while base monsters read a different scalar. Investigation arrival resets the shortened timer. Fix these before adding ranks; P1. |
| Crouch uses the full walking speed, making a stealth-speed perk redundant | `scripts/player/player_3d.gd:87,531-538,658-666` | Corrected before proposing: crouch has a further ×0.4 multiplier. Unloaded crouch is 0.68 m/s, not 1.7 m/s. P2 can improve the separate STEALTH state. |
| A battery shop guarantees the simulator's shortfall coverage | `tools/qa_sim/balance_sim.py:199-210`; `scripts/systems/shop.gd:8-40`; search for `Shop.add_coins` / `Shop.buy` finds no runtime caller | That shop has a private wallet and no inventory grant in `buy()`. Rewards fund `CoinWallet`, not `Shop._coins`. Presence of the price literal is not supply evidence; P5. |
| Catalog prices top out at a payable 4,000 coins | `data/shop/bundle_starter.tres:9-11`; `scripts/economy/shop_item.gd:13-14` | Sticker price is 4,000, but the 30% discount makes the payable bundle price 2,800. Distinguish sticker, payable and component value; P6. |
| Routing P1 through `warn()` proves a visible warning | `scripts/enemies/monster_telegraph.gd:14-36`; `scripts/enemies/base_monster.gd:137-164`; `scenes/enemies/boss_architect_3d.tscn:12-28` | The warning node searches direct mesh children before runtime visuals exist; the scene has no mesh child. Static trace supports a missing visual cue, despite the real callback delay. P8. |
| The audit's `victory_screen.gd` is the live NG+ entry | Repository scene/script-reference search; `scripts/ui/ui_manager.gd:10,24,271-272`; `scripts/ui/win_screen.gd:56-64`; `scripts/ui/new_game_plus_ui.gd:90-96` | Corrected during final target validation: live victory opens the NG+ screen; activation refreshes that screen rather than routing to menu. No `victory_screen.tscn` exists. P3 targets the real surfaces and makes the remaining menu step explicit. |
| Historical bot wins apply to this RC revision | `docs/KNOWN_ISSUES.md:171-189` versus `docs/GAME_AUDIT.md:35-42,62-68` | The recorded 6/10 wins predate the speed conversion and P1 delay. They are historical evidence only, not a current-build baseline. |

## TOP-8 decision table

Order is implementation priority, not additional proposals.

| ID | Implementable decision | Target owner/files | Expected bot-winnability impact |
|---|---|---|---|
| P1 | Make existing stealth effects reach live hearing/search paths | Gameplay: `scripts/player/player_3d.gd`, `scripts/enemies/base_monster.gd` | Skill users should lose pursuit more reliably; arrival-reset repair also affects unskilled actors. **Rebaseline AI evidence.** |
| P2 | Add `low_profile` and `quiet_pace`; keep combat unchanged | Gameplay: `scripts/systems/skill_tree_manager.gd`, player/base-monster consumers; locale owner | Neutral without purchases; improved avoidance with purchases. **Existing bot does not establish skilled-route success.** |
| P3 | Label activation separately from starting NG+; disclose reset | UI: victory/main-menu/NG+ scripts and scenes; locale owner | Mechanically neutral if routing is retained. **A new start/Continue routing bug could break the bot.** |
| P4 | Pause all procedural audio with gameplay, explicitly | Audio: `scripts/audio/proc_audio.gd` | No combat/stat change; bot normally does not pause. Pause/resume regression coverage required. |
| P5 | Honor battery capacity, and replace the optimistic battery ledger | Gameplay + QA: player/skill manager and `tools/qa_sim/balance_sim.py` | Neutral at base capacity; helps purchased capacity. **Battery/strobe supply is a known boss-win dependency.** |
| P6 | Model reachable coin income and optional secrets before repricing | QA: `tools/qa_sim/balance_sim.py`; economy/content owners review | No runtime delta. Do not fund mandatory progress with assumed secret discovery or imaginary kill income. |
| P7 | Scope the duration target instead of shortening levels on paper | Design: `docs/PRODUCTION_BIBLE.md`; QA simulator reporting | No runtime delta. **Reject speed, loot or stage cuts made solely to hit the estimate.** |
| P8 | Retain boss timing; repair/verify the warning presentation | Gameplay/audio/accessibility: `scripts/enemies/monster_telegraph.gd`, boss callback | Cue-only change should be neutral to bot inputs. **Never carry historical wins across a timing/damage change.** |

## P1 — Repair the existing stealth investment

**Riskiest assumption:** radius-based noise and scalar hearing represent the same live mechanic; grep disproves this, so this proposal aligns only the existing scalar consumer and search timer, not a new hearing simulation.

| File / key | Current + source | Proposed value / behavior | Reason and risk |
|---|---|---|---|
| `scripts/systems/skill_tree_manager.gd`, `stealth.silent_steps` | cost 1, max 3, effect 0.15 (`:142-148`); radius scales by `1−0.15L` in `scripts/player/player_3d.gd:527-530` | **Retain** 1 SP/rank, 3 ranks, 0.15/rank; scalar locomotion noise also gets the same factor | Delivers purchased quietness to `base_monster._detect_ambient`; medium risk: walking can cross the hearing threshold. |
| `scripts/player/player_3d.gd`, `noise_level` | `speed_noise + overload_noise_penalty`; walk 0.4, run 0.8, stealth 0.3, crouch 0.15, overload +0.3 (`:510-518`) | `speed_noise × (1−0.15L) + overload_noise_penalty`; at max rank, unloaded walk **0.4→0.22**, run **0.8→0.44**, stealth **0.3→0.165**, crouch **0.15→0.0825** | Derived from retained skill. Keep weather addition in `:731-736` and overload penalty unchanged; overloaded walk remains 0.52. Do not multiply the same signal twice. |
| `scripts/enemies/base_monster.gd`, `noise_threshold` | 0.3 (`:21`), strict `noise_val > noise_threshold` (`:451`) | **0.3→0.3** | Max-rank running still exceeds the threshold; quiet walking is earned, not immunity. Light, sight and attack damage remain independent. |
| Same file, investigation initialization/arrival | shared timer `5×(1−0.2L)` (`:458-463`), but arrival resets to 5 every tick (`:389-394`); other entry paths set 5 (`:324-326,579-581`) | Keep base **5 s**, reduction **0.2/rank**, max **2** (`skill_tree_manager.gd:150-156`); all genuine entries use the shared helper; arrival **reset-to-5→no reset** | With no new stimulus, rank 0/1/2 expires after **5/4/3 s** from entry. New audible evidence may restart a search; standing at the destination must not. Medium risk: previously endless searches will end even at rank 0. |

**Implementation note:** preserve the landed hiding damage guard. Do not claim scalar quietness supplies distance falloff; `_detect_ambient` is still a scalar test within the current target-acquisition architecture. Leave `NoisePropagation` available for planned systems; do not delete it.

**Bot impact:** expected easier disengagement, not easier damage output. The ordinary runner has no `unlock_skill` call; skill-dependent benefit is not covered by historical wins. The unskilled timer correction still changes AI scheduling.

**Acceptance criteria**
- [ ] At each legal rank, emitted radius and locomotion scalar use the same reduction once; overload/weather remain separate. Running at max rank is still audible under the default threshold.
- [ ] Search entered by hearing, hiding/lost pursuit, detect-area fallback or flee expiry uses the same rank-aware duration. With no new evidence, arrival does not refresh it; new evidence and actual sight still reacquire.
- [ ] Save/load and New Game preserve/reset ranks as intended; existing hidden-player damage protection remains intact. Compare unskilled and skilled pursuit traces before claiming success.

## P2 — Add two bounded stealth choices, not combat replacements

**Riskiest assumption:** a larger tree is affordable in a first run; `scripts/systems/xp_manager.gd:7-8,67-73` disproves affordable full-tree parity, so the proposal prioritizes useful first ranks rather than a promise to max the branch.

New entries belong inside `SKILL_TREES.stealth.skills`; both are **absent** from `scripts/systems/skill_tree_manager.gd:139-159` today. Reuse the dynamic button loop (`scripts/ui/skill_tree_tab.gd:28-35`), existing states/ranges and live rank getters; no new stealth meter, resource or scene.

| File / key | Old → new (source of current behavior) | Rationale / risk | Expected bot impact |
|---|---|---|---|
| `skill_tree_manager.gd`, `stealth.low_profile` | absent → `{cost: 2, max_level: 2, effect_per_level: 0.10, requires: [silent_steps]}` | Expensive avoidance choice rather than damage. `requires` means an unlocked prerequisite, not a maxed one (`:184-196`). Medium risk: sight/hearing interactions. | Neutral unbought; fewer acquisitions when tested with ranks. |
| `scripts/enemies/base_monster.gd`, `_can_see_player` effective ranges | no skill multiplier, **1.0→1.0/0.9/0.8** by rank; current main/peripheral checks `:493-509` | Apply to both main and peripheral ranges only when acquiring from IDLE/PATROL/INVESTIGATE, player is STEALTH/CROUCH and flashlight is off; exclude `boss`. Do not shrink DetectArea, change angles/LOS, clear CHASE, or suppress hearing. | Avoidance only; no bypass of the boss/light gate. |
| Worked `low_profile` example | Hunter sight **10→9→8 m**, from `scripts/enemies/hunter_3d.gd:20` | Derived from preceding row, not a global replacement of roster values. Maximum rank is not invisibility. | Needs a skilled, flashlight-off scenario; not measured. |
| `skill_tree_manager.gd`, `stealth.quiet_pace` | absent → `{cost: 1, max_level: 2, effect_per_level: 0.10, requires: [silent_steps]}` | Low-cost traversal alternative to a damage purchase. Low–medium risk: route timing. | Neutral unbought; faster stealth traversal if bot explicitly uses it. |
| `scripts/player/player_3d.gd`, `_speed_for(State.STEALTH)` | base **0.9→0.9/0.99/1.08 m/s**, `data/balance/player_stats.tres:7`, consumer `player_3d.gd:658-666` | Multiply the STEALTH base by `1+0.10L` before existing status/weight modifiers. Do not mutate the shared resource or stack on save-load. Retain walk **1.7**, run **3.0** (`player_stats.tres:5-6`); crouch is **1.7×0.4=0.68** unloaded (`player_3d.gd:87,532,664`). | Maximum remains below walking; no sprint/chase-speed or weapon buff. |

**Branch arithmetic:** existing stealth **2 skills / 7 SP→4 / 13 SP**: `3×1 + 2×2 + 2×2 + 2×1`. Combat remains **5 / 21**, survival **5 / 13**, utility **4 / 13** (`scripts/systems/skill_tree_manager.gd:7-132,139-159`). This meets `docs/GAME_AUDIT.md:125-133` without equating stealth damage to combat damage.

**Affordability, derived not playtested:** cumulative XP for 4 SP is **812**, for the existing 7-SP tree **3,216**, and for the proposed 13-SP tree **38,719**, using the integer threshold formula at `xp_manager.gd:67-73`. A practical 4-SP package is `silent_steps` rank 1 + `quiet_pace` rank 1 + `low_profile` rank 1. District restoration alone supplies **11×100=1,100 XP** (`xp_manager.gd:40-41`; spine `tools/qa_sim/balance_sim.py:28-30`), enough for this package by run end absent other spending. Do not change XP growth to make every branch maxable. Combat spending remains an opportunity cost.

**Localization handoff:** add `SKILL_LOW_PROFILE_NAME/DESC` (“Low Profile”; “While sneaking or crouching with the flashlight off, reduce enemy sight ranges by 10% per rank. Does not affect the Architect or an active chase.”) and `SKILL_QUIET_PACE_NAME/DESC` (“Quiet Pace”; “Move 10% faster per rank while sneaking. Does not affect walking, running or crouching.”) to `data/i18n/*.json` through the locale owner. These percentages derive from the rows above.

**Acceptance criteria**
- [ ] Tree count/cost arithmetic matches the table; P1 is implemented first. Existing costs, combat output and XP growth remain unchanged.
- [ ] Acquisition tests cover main/peripheral sight, occlusion, noise, flashlight on/off, crouch/stealth/run, hiding, ongoing chase and boss exclusion. No purchased skill is mandatory for a district or finale gate.
- [ ] Rank-zero behavior is unchanged; speed applies once and only to STEALTH. New Game/save-load and old saves without the keys work; localization/keyboard/controller selection works across shipped locales.
- [ ] The low-budget package can be selected with earned SP; report its avoided detections and completion separately from the unmodified bot. Do not label the branch maxable in one run without a measured XP ledger.

## P3 — Make activation and starting NG+ distinct

**Riskiest assumption:** “active NG+” means a fresh run has started; the actual call chain proves otherwise, and a global NG+ file also means Continue must not be advertised as restoring the old difficulty.

**Verified flow, correcting the audit's caller attribution:** `scripts/ui/ui_manager.gd:10,24,271-272` maps WIN to `win_screen.gd`; its “One More Run” button opens the existing NG+ screen (`scripts/ui/win_screen.gd:56-64,90-92`). `scripts/ui/new_game_plus_ui.gd:90-96` activates and refreshes **without** routing to the menu; Back currently only closes the overlay. Victory's menu button calls `GameManager.return_to_menu()` (`win_screen.gd:78-82`). The audit's `scripts/ui/victory_screen.gd:44-46` does implement activate→menu, but no scene/script reference wires that file into the shipped route. Do not edit that unused surface or invent a missing victory scene.

The post-fix reset remains real: `scripts/ui/main_menu.gd:34-39` separates Continue/load from Play/`Routes.start_game()`. `scripts/core/routes.gd:39-44` calls `GameManager.start_new_game()`; `scripts/core/game_manager.gd:101-109` distinguishes reset from load. `scripts/core/save_system.gd:325-366` resets run progress but intentionally retains NG+. NG+ persists separately in `scripts/systems/new_game_plus.gd:186-215`; there is no pending-run marker.

**Decision:** preserve the live NG+ setup/modifier screen, then make **victory → NG+ setup → activate → main menu → New Game** explicit. No automatic reset and no new save-state machine. Use Keeper-like restrained, practical language in explanatory text; keep action labels literal. Voice reference: `content/world/characters.json:6-16,97-105`. Do not reveal the radio speaker's identity in copy.

| Target / key | Current copy or behavior + source | Exact proposed English source copy / behavior |
|---|---|---|
| `scripts/ui/win_screen.gd`, `_more_btn`; new `NGP_SETUP_ACTION` | `BTN_ONE_MORE_RUN` = “One More Run” (`:63,91`; `data/i18n/en.json:1083`) | **“Set up New Game+”**. Keep opening the existing NG+ screen; this button does not activate or reset. |
| `scripts/ui/new_game_plus_ui.gd`, ActivateButton; new `NGP_ACTIVATE_ACTION` | scene literal “Activate New Game+” (`scenes/ui/new_game_plus.tscn:37-39`); handler `new_game_plus_ui.gd:90-93` | **“Activate NG+%d”**, formatted with the next allowed level. Check success; disable further activation for this screen visit after success. Keep modifiers available, then use the menu action below. |
| NG+ explanatory label; new `NGP_ACTIVATE_HELP` | absent (`new_game_plus_ui.gd:23-39`) | **“The grid can be walked again. Activate NG+ to raise the difficulty setting. Then continue to the main menu and choose New Game. Continue only loads saved progress.”** |
| NG+ BackButton / activation feedback | “Back” only closes this overlay (`new_game_plus.tscn:41-43`; `new_game_plus_ui.gd:95-96`); “New Game+ activated! Difficulty increased.” (`en.json:289`) | Before activation: **“Return to ending”** on this victory entry, retaining close. After activation: **“Continue to main menu”**, calling the existing `GameManager.return_to_menu()` path. Feedback: **“NG+%d is active. Choose your modifier, or continue to the main menu to start again.”** Use a local, reset-on-open activation latch, not a persisted pending-run flag. |
| NG+ CurrentLevel label; new `NGP_SETTING_LABEL` | describes “Current Run” from the global level (`new_game_plus_ui.gd:24-27`; `new_game_plus.tscn:26-27`) | **“NG+ setting: %s”**, formatting the existing localized base/NG+ label. Activation is a setting change, not proof a new run started. |
| `scripts/ui/main_menu.gd`, Play; new `NGP_NEW_GAME_ACTION` | `menu_play` = “Play” (`:9-16,207-214`; `en.json:700`) | At active NG+: **“New Game (NG+%d)”**. At base: **“New Game”**. Keep the existing start route. |
| Main-menu status; new `NGP_MENU_STATUS` | absent (`main_menu.gd:9-16`) | **“NG+%d active. A new circuit waits. New Game starts from the suburbs; Continue loads your saved progress.”** Show whenever the getter is positive, including after application restart. Do not say “pending”. |
| Main-menu Continue; new `NGP_CONTINUE_SAVED` | “Continue” (`en.json:673`; `main_menu.gd:131-139`) | **“Continue saved progress”** when NG+ is active. Retain save-existence visibility and load route; do not disable normal NG+ continuation. |
| Main-menu New Game confirmation; new `NGP_NEW_GAME_CONFIRM` | no confirmation on Play (`main_menu.gd:39`) | **“Start again at NG+%d? District progress, inventory, coins, purchased shop items and skills will reset. The new run will replace this save when saved. NG+ settings stay active.”** Buttons: **“Start new run”** / **“Keep saved progress”**. Reuse a native `ConfirmationDialog`; cancellation must not reset anything. |
| NG+ screen at cap; new `NGP_AT_LIMIT` | activation is disabled at cap (`new_game_plus_ui.gd:38`) | **“Highest NG+ reached”** (disabled activation); helper **“The grid holds no harder circuit. Start New Game to replay this NG+ level.”** Offer **“Continue to main menu”** at cap too; retain access to modifier choices. |

**Target files:** `scripts/ui/win_screen.gd`, `scripts/ui/new_game_plus_ui.gd`, `scripts/ui/main_menu.gd`; `scenes/ui/new_game_plus.tscn` and `scenes/ui/main_menu.tscn` for explanatory labels if needed; `data/i18n/*.json` via locale owner. Apply action text during language refresh and cached-screen reopening, not only initial build. The local activation latch is cleared on a new setup visit; labels after an application restart derive from the persisted NG+ level. If setup is entered outside victory, retain a context-appropriate **“Back”** before activation rather than promising an ending screen.

Confirmation stays in the menu click handler: **do not put a dialog in `Routes.start_game()`**, which the autoplay runner calls directly (`scripts/tools/_qa_autoplay_runner.gd:98-112`). `GameManager.return_to_menu()` already closes blocking screens and unpauses (`scripts/core/game_manager.gd:147-157`); reuse it, rather than leaving the win overlay behind on a scene swap.

**Knobs retained, not advertised from stale JSON:** cap **3→3**, per-level XP **+0.25→+0.25**, enemy damage **+0.15→+0.15**, enemy HP **+0.20→+0.20**, player damage and loot **+0.10→+0.10**, from `scripts/systems/new_game_plus.gd:15-20,119-147`. `data/ng_plus_config.json:2-3` instead says enemy 1.5 / XP 1.2; repository search finds no runtime loader for that filename. At NG+1 the live base getter values are **1.25 XP / 1.15 enemy damage / 1.20 enemy HP / 1.10 player damage / 1.10 loot**. Modifier multipliers compose separately (`new_game_plus.gd:82-98,132-147`; `content/ngp_modifiers.json:15,27,51-52,63-64,76`). No new balance numbers are proposed.

**Risk / bot impact:** low mechanical risk if labels stay separate from routing; high if reset/activation is duplicated. “Skills carry over” would be false (`save_system.gd:342-343`). “Continue the previous difficulty” would also be unsafe. The bot bypasses menu copy, so it cannot validate comprehension.

**Acceptance criteria**
- [ ] Victory → setup → successful activation → explicit menu action → confirmed New Game starts in suburbs at the displayed level. Cancel leaves run data intact; Continue loads progress without reset or another activation.
- [ ] Base, active NG+, cap, no-save, saved-progress, restart and language-change states display truthful copy. The live setup, victory entry and menu cannot present contradictory instructions; no double-press level increment within the activation visit.
- [ ] NG+ level/modifiers persist through the intended reset; no promise that global NG+ settings are tied to a save slot. Test the existing death-screen and direct bot start routes unchanged.
- [ ] All new strings are localized; narrow/mobile/RTL layouts retain action labels and reset warning. Owner-language review remains separate from static key parity.

## P4 — Pause procedural audio with gameplay

**Riskiest assumption:** stopping `_process` also stops all signal-triggered and awaited sound work; it does not, so explicit pause gates must accompany the process-mode decision.

**Decision: pause, not keep this node's ambient playing.** `proc_audio.gd` combines an ambient generator, timed moans, footsteps and flashlight clicks. Sibling ambient/music systems already continue; retaining another procedural bed does not justify making action sounds process during pause. This is intentional source-specific behavior, not a global silence policy.

| Target | Current + source | Proposed | Reason / risk / bot impact |
|---|---|---|---|
| `scripts/audio/proc_audio.gd`, `_ready` | implicit inherited process mode; no assignment (`:25-61`) | Explicit `PROCESS_MODE_PAUSABLE`, with a comment that the entire procedural layer follows gameplay | Smallest unambiguous policy. Low balance risk; no stat/AI effect. |
| Same, event handlers and generator continuations | flashlight handler can start a tween/click (`:64-95`); generators await a frame (`:113-126,144-158`); timers run in `:179-200` | Cache flashlight state without sound when paused; guard sound entry and post-await buffer writes; discard paused one-shots, do not queue them for resume. Pause gameplay-duration timers with `create_timer(..., false)` where relevant; cleanup may still run silently | Signals and suspended coroutines are not a pause boundary. Risk: a stale click or step after resume, or a generator freed mid-pause. |
| Hum/movement tuning | hum **65 Hz**, amplitude **0.08**, quiet **0.03** (`:4-10`); step intervals **0.5/0.8/0.25 s** walk/stealth/run (`:188-197`) | **Retain all values**; resume scheduling from current movement, without accumulated catch-up steps | This is a pause contract, not a loudness or pacing tune. Neutral to bot combat; listening validation still needed. |

`PROCESS_MODE_ALWAYS` exists in `scripts/systems/audio_manager.gd:24`, `music_manager.gd:162`, `streetlight_hum_pool.gd:29`. Grep does **not** establish automatic pause ducking there; do not repeat the audit's “duck-not-stop” suggestion as an implemented fact.

**Acceptance criteria**
- [ ] Pausing while walking, clicking or during a moan suspends this layer's playback/generation; injected state signals and resumed coroutines do not make audible action cues while paused.
- [ ] Resume produces no queued footstep burst or stale click; ambient resumes without generator underrun/clicks, and already-finished one-shots do not replay. Disabled-procedural-audio behavior remains unchanged.
- [ ] Existing music/ambient siblings and menu UI sounds remain governed by their own policies; no global bus mute, new duck value, time-scale effect or input leak is introduced.

## P5 — Make purchased battery capacity real; audit supply without fictional refills

**Riskiest assumption:** the per-district simulator's full starting charge represents actual transitions; source confirms full charge on player creation, not a guaranteed refill on every district visit, so report both continuous-player and respawn cases.

| Target / key | Current + source | Proposed | Reason / risk / expected bot impact |
|---|---|---|---|
| `scripts/player/player_3d.gd`, drain/use/refill clamps and battery HUD denominator | hard cap/denominator **100** in `:716-718,793-799`; exported capacity **100** (`:14`); skill adds **25/rank**, max **2**, cost **1** (`scripts/systems/skill_tree_manager.gd:79-85,233-234`) | Literal **100→effective battery_max** everywhere these paths clamp/normalize. Base remains **100**; skill-only rank 1/2 capacity **125/150** | Stops silently deleting paid capacity. Medium risk: purchase/load order; base unskilled bot should be unchanged, skilled endurance should improve. |
| Same, `apply_flashlight_upgrades` and skill consumer | upgrade assignment `100×(1+bat_bonus)` overwrites skill capacity (`:1083-1092`) | Use one idempotent composition: **`100×(1+bat_bonus)+25×battery_capacity_level`**, replacing last-writer-wins/increment replay in the battery skill path | Existing bonuses **0.2…1.0** (`scripts/systems/flashlight_upgrade_manager.gd:39-44`) stay unchanged. Combined assigned ceiling **200 overwritten / 250 order-dependent→250 consistently** (current use/drain still clamps usable charge to 100). Capacity purchase changes the ceiling, not current charge; do not grant free refills. |
| Runtime drain / pickup / strobe | **100/450 units/s** (`player_3d.gd:96`), pickup **35** (`data/items/battery.tres:14`), strobe **5** (`player_3d.gd:828,838-842`) | **Retain**; report resource cost separately from flashlight duty cycle | Drain reduction or free cells would soften boss P2 without evidence. The bot explicitly consumes batteries below **20** (`scripts/tools/_qa_autoplay_runner.gd:419-427`); retain that behavior. |
| `tools/qa_sim/balance_sim.py`, `battery_economy` / shop fallback | full charge + **2** common batteries per district (`:82-100`); price-regex “shop coverage” (`:199-210`) | No runtime loot change. Model carried charge, themed loot, skill capacity, strobe usage and NG+; give the disconnected shop **0 reachable supply** until an actual wallet→purchase→inventory path is proven | Removes a false pass, not real resources. An engine-free estimate cannot prove spatial pickup reachability. |

**Derived supply/demand ledger — no upgrade, no strobe, no pickup waste:**

| Observation / source | Arithmetic | Interpretation |
|---|---|---|
| Full battery + common loot (`player_3d.gd:96`; `district_loot.gd:25`) | **450 + 2×157.5 = 765 s = 12.75 min** of light | Current simulator budget. It narrowly exceeds efficient PARTIAL demand. |
| Themed batteries (`scripts/world/district_loot.gd:40-50`) | suburbs/residential/park/school/gas_station each add **1**: **922.5 s = 15.375 min** if arriving full; other districts remain **765 s** | Guaranteed spawn list, not guaranteed collection. Do not apply the richer district budget to hospital/police/late districts. |
| Efficient duty-cycle model (`balance_sim.py:78-79,122-129`) | DARK **12×0.5=6 min**; PARTIAL **18×0.7=12.6 min** | PARTIAL common-only margin is **0.15 min = 9 s**, not robust headroom. |
| Same on-time stretched by first-run multiplier **1.8** (`balance_sim.py:228`) | DARK **10.8 min**; PARTIAL **22.68 min** | Sensitivity case, not measured behavior: common budget misses PARTIAL by **9.93 min**. Not all reading/menu time drains battery (`player_3d.gd:708-710`). |
| Continuous-player spine; count common + themed only | **22+5=27 pickups** across the **11** districts (`district_loot.gd:25,40-50`; `balance_sim.py:28-30`); **450+27×157.5=4,702.5 s = 78.375 min** | One initial charge, not eleven. Efficient DARK needs **66 min**, PARTIAL **138.6 min**. Excludes boss demand, secrets, RNG drops, waste and respawns. |
| `long_night.battery` **0.80** (`content/ngp_modifiers.json:15`; drain consumer `player_3d.gd:714-715`) | common budget **765×0.8=612 s = 10.2 min**; continuous total **62.7 min** | Already short of efficient DARK's **66 min** in that restricted ledger; explicitly test, do not claim an NG+ hardlock. |
| Strobe **5** units / use (`player_3d.gd:828`) | **22.5 s** of normal light per strobe; **18 s** in Long Night | Must be subtracted; historical bot win strategy uses strobe (`_qa_autoplay_runner.gd:283-291`). |
| Capacity skill only, no upgrade | effective full-charge time **450→562.5→675 s**, derived from retained drain and proposed **100/125/150** caps | Restoring the advertised cap adds **112.5 s/rank** when filled; it does not create pickup income. |

**Acceptance criteria**
- [ ] Base/skill/upgrade/combined capacity, purchase order, consume/refill/strobe, HUD and save-load agree on the same ceiling; no excess is clipped to the old cap and no purchase fills missing charge.
- [ ] Simulator reports efficient versus first-run sensitivity, common versus themed loot, continuous versus recreated player, no-purchase versus capacity purchase, and Long Night separately. No automatic full recharge per district without transition evidence.
- [ ] Required **2 cable / 2 fuse / 2 transistor** supply remains unchanged (`district_loot.gd:34-36`), against **1 each** gate demand (`scripts/world/power_switch.gd:23-26`): **100% margin**, above existing **20%** simulator floor (`balance_sim.py:151-158`). No mandatory key/part is put behind random loot, a secret or a shop.
- [ ] Preserve battery access and strobe consumption in the boss approach; rerun actual unskilled wins before treating the capacity correction as harmless. Do not “fix” the ledger by reducing the test's demand assumptions.

## P6 — Coin and secret pacing: establish reachable faucets before changing prices

**Riskiest assumption:** all rewards described as coins enter the spending wallet; tracing finds separate paths and non-paying signals, so count only proven `CoinWallet` income.

**Proposal:** add a source-driven coin/secret ledger to the existing balance simulator; retain economy values. This implements the audit's missing faucet/sink check without a speculative global price cut.

| Current value + source | Proposed value / accounting | Rationale / risk / expected bot impact |
|---|---|---|
| Secret **50**, FULL district **200**, achievement **100** coins (`scripts/economy/rewards_manager.gd:2-22`) | **50→50 / 200→200 / 100→100**; count distinct eligible events | No evidence for inflation. `scripts/world/power_grid.gd:49-63` pays at FULL, not every stage. Static-ledger change only; no bot resource delta. |
| Catalog prices **1,500 / 2,000 / 2,500 / 4,000 sticker**, `data/shop/*.tres:9`; bundle discount **30%** (`bundle_starter.tres:10`) | Retain. Compare payable **1,500**, **2,000**, **2,500**, bundle **2,800** via `scripts/economy/shop_item.gd:13-14` | A two-item purchase need not cost the two most expensive items. Count bundle components without charging or rewarding duplicates twice; no current-bot effect. |
| Repeatable kill “coins” **5–15** (`scripts/enemies/base_monster.gd:651-659`) | Expected spendable repeatable kill income **0**, not mean **10**, until wallet credit exists | `EventBus.coins_changed` consumers are HUD labels (`scripts/ui/coin_hud.gd:6`, `scripts/ui/screens.gd:934`), not `CoinWallet.add`. Medium forecasting risk if mistaken for income. Do not add grinding to compensate. |
| Secret content **26**, across **11** districts; stage histogram **2/9/10/5** at DARK/PARTIAL/STREETS/FULL (`content/secrets.json:13-419`, parsed) | Retain counts/gates; optional income, not guaranteed critical-path funding | Only suburbs' DARK secret is available initially; the other DARK secret is in park (`:13-19,77-83`). Five FULL secrets may require post-restoration exploration. Bot does not intentionally seek them. |
| Suburbs secret reward **2 batteries** (`content/secrets.json:19`); Park coin item **60** (`:99`) | Retain; count the batteries only in discovery scenarios, and **do not count the 60-item reward as wallet currency** without a conversion consumer | `scripts/world/secret.gd:55-60` calls `InventoryManager.try_add`, separately emitting the **50**-coin secret event. Inventory acceptance can fail (`scripts/inventory/inventory_manager.gd:53-74`), so spawned rewards are not guaranteed usable supply. |
| Flashlight upgrade sink **100,250,500,1000,2000** per branch (`scripts/systems/flashlight_upgrade_manager.gd:31-36,85-98`) | Retain, but include it as competing `CoinWallet` spending | **3,850/branch; 19,250** for all five is derived, not a first-run target. Ignoring this sink overstates catalog affordability. |

**Derived NG0 ledgers (no quest/puzzle income, no prior spending):**
- Districts: **11×200=2,200**. All secrets: **26×50=1,300**. Combined **3,500** buys brightness **1,500** + slots **2,000**, with **0** repeatable grind. This is an all-secret route, not the bot's route.
- Fresh achievement profile: the restoration path triggers first-light + any-FULL + all-FULL + district-specific achievements: **1+1+1+11=14**, or **1,400** coins (`scripts/systems/achievements_manager.gd:152-162,292-309`; idempotent payout `:213-224`). Thus a fresh no-secret completion has **3,600** before optional spending and covers the same pair with **100** left. Unlocks are profile-persistent (`:165-188`); do **not** credit them again in a repeat run.
- Total registered achievement ceiling is **31×100=3,100** (`achievements_manager.gd:5-163`), giving **6,600** with all districts/secrets. This is a catalog upper bound, **not** proof all achievements can be earned in one run. Use the smaller event-traced ledger above for acceptance.
- Repeat profile, no secrets: **2,200**, a **1,300** gap to that pair. Report the gap rather than assume kill income. Optional quests/puzzles use real wallet calls (`scripts/core/quest_manager.gd:123`, `scripts/world/puzzle_system.gd:73`) but require a separate reachable-quest trace before inclusion.
- No new grind tolerance is needed: compare the existing audit's “at least 2 catalog items” requirement (`docs/GAME_AUDIT.md:140-146`) against **0 repeatable-grind income**. Sprint's rewards factor **1.5** is retained (`content/ngp_modifiers.json:63`; `rewards_manager.gd:9-10`); Ghost's achievements toggle (`ngp_modifiers.json:76`) requires a separate event-path check because automatic `_check_unlock` reaches `_unlock` without the public `unlock` guard (`achievements_manager.gd:213-235,332-339`). Do not grant phantom income or claim the toggle is fully verified.

**Secret/session evidence:** historical medians are first hint **9.95 s**, first discovery **113.6 s among only 5/10 finding runs**, and first FULL district **17.45 s** (`docs/KNOWN_ISSUES.md:270-280`). The target there is **≤480 s** to early onboarding, not a required delay. Keep that target; do not slow hints to fill a session. The runner explicitly follows parts/switches instead of secrets (`scripts/tools/_qa_autoplay_runner.gd:64-67`). These accelerated, pre-speed-fix traces cannot calibrate human session length.

**Acceptance criteria**
- [ ] The simulator exposes fresh-profile, repeat-profile, no-secret and all-secret ledgers; verifies the stated two-item purchasing examples, and reports competing spending rather than silently assuming all balances are disposable.
- [ ] Only wallet-crediting events count as coins; repeat district stages, repeat secrets, persistent achievements, bundle ownership and NG+ modifiers cannot be double-counted. Secret item rewards are distinct from coin events.
- [ ] State that base prices/rewards/gates are retained. Report unmet repeat-profile budgets as coverage/design findings, not permission to add kill grind or reduce guaranteed repair supplies.
- [ ] Keep secret hint/discovery telemetry separate and include missed discoveries, not just successful-case medians. No requirement to find optional secrets is added to a bot-win gate.

## P7 — Separate duration estimates from a pacing change

**Riskiest assumption:** PARTIAL's overrun is measured level pacing; `tools/qa_sim/balance_sim.py:118-129,220-248` identifies manually chosen model inputs, not measured durations, so a runtime trim is unjustified.

| Target / key | Current + source | Proposed | Reason / risk / expected bot impact |
|---|---|---|---|
| `docs/PRODUCTION_BIBLE.md`, duration scope | no explicit style-specific duration section (`:9-27`); audit calls out general **3–6 h** (`docs/GAME_AUDIT.md:147-152`) | Add: **“Target: 3–6 hours for a first DARK-oriented playthrough. The current model estimates 4.905 hours for DARK and 6.885 hours for thorough PARTIAL play. PARTIAL is a longer optional exploration style; neither estimate is a measured completion time or a per-session requirement.”** | Choose the audit's documentation option, not a fake reduction of world traversal. Risk: target scope needs owner approval and must agree with any external duration claims. Neutral to bot. |
| `balance_sim.py`, model inputs | DARK **12 min/district**, PARTIAL **18**, boss **15**, transition/menu **1.5/district**, first-run multiplier **1.8** (`:122-129,228`) | **Retain**; label assumptions and scope the final PASS text (`:256-257`) to DARK | Reporting change only. No new session target, game timer or district cut is proposed. |
| District gates / stage pressure | sequential prerequisites (`scripts/world/power_grid.gd:32-45`), cable/fuse/transistor stages (`power_switch.gd:23-26`), target enemies **6/5/4/3** by stage (`scripts/enemies/enemy_pool.gd:11,89-101`) | **Retain** all | Restoration should reduce pressure. These are target counts, not proof of observed live population. PARTIAL is a playstyle estimate; progression still requires FULL. |

**Derived check:** DARK `(11×12+15+11×1.5)×1.8/60 = 4.905 h`; PARTIAL `(11×18+15+11×1.5)×1.8/60 = 6.885 h`, **0.885 h / 53.1 min** above the upper target. The audit's suggested **15%** PARTIAL district-input trim would give **5.994 h**, almost exactly the limit; that arithmetic is **not evidence** the game became shorter. First-run district-plus-transition estimates are **24.3 min DARK / 35.1 min PARTIAL**, excluding the finale; these are possible stopping-point estimates, not a newly mandated session length. Inputs and sources are the preceding table.

**Acceptance criteria**
- [ ] Bible and simulator distinguish DARK's target, PARTIAL's estimate, efficient/first-run arithmetic, session versus full-run length, and measured versus assumed values. No marketing or completion-time guarantee is inferred.
- [ ] Final simulator PASS does not imply both styles are inside the target or that spatial winnability was simulated. Retain the PARTIAL overrun as a visible finding.
- [ ] Keep runtime movement, district stage requirements, content and enemy counts unchanged. Calibrate future tuning with post-speed-fix human district/reading/death/reload time, not the historical accelerated bot medians.

## P8 — Boss P1: retain timing; make the warning observable

**Riskiest assumption:** a callback delayed by the warning constant is perceptually fair; source confirms a delay but exposes a missing mesh cue, so timing fairness remains conditional on presentation and runtime verification.

### Timing verification and decision

| Current value + source | Proposed value | Static reasoning | Risk / expected bot impact |
|---|---|---|---|
| `WARN_DURATION` **0.4 s**, `scripts/enemies/monster_telegraph.gd:6,21-26`; boss uses `warn(_throw_energy_ball)` at `scripts/enemies/boss_3d.gd:86-93` | **0.4→0.4 s** | Real deferred spawn, unlike the pre-fix same-frame projectile. No evidence here justifies a shorter or longer wind-up. | Low if retained; runtime cue loss is a separate risk. No numerical bot change proposed. |
| P1 cooldown **2.0 s**, light ×**1.5** (`boss_3d.gd:27,94-98`) | **2.0/3.0→2.0/3.0 s** | Cooldown begins at warning scheduling, not projectile spawn; with a 0.4-second warning the nominal post-spawn remainder is **1.6/2.6 s**. Base timer decrements at `base_monster.gd:254`. | Preserve cadence; don't accidentally add warning duration to the cooldown. |
| Teleport interval **6 s**, distance **6–12 m** (`boss_3d.gd:11,82-85,147`) | **Retain** | Interval is only decremented on eligible P1 ticks because the attack/stun checks return first (`:76-83`); it is **not proven to be a six-second wall-clock interval**. | No teleport-frequency tuning from the constant alone. |
| Projectile speed **14 m/s**, radius **0.35 m**, damage **20** (`boss_3d.gd:8,261-272`); player radius **0.3 m** (`scenes/player/player_3d.tscn:7-9`) | **Retain** | At a stationary 6–12 m center separation: center-flight time **0.429–0.857 s**, cue-to-center **0.829–1.257 s**. Collision-radius-adjusted approximation: **0.782–1.211 s** (`0.4+(distance−0.65)/14`). Not a guaranteed reaction window. | Projectile aims at callback time (`boss_3d.gd:132-141`), so wind-up is preparation, not a locked-target dodge window. |
| Phase boundaries **0.66 / 0.33 HP ratio**, P2 summon **3 s / cap 3**, P3 beam **4 s / 25 damage** (`boss_3d.gd:9-12,46-56,113-115`) | **Retain** | P2's dark invulnerability (`:216-217`) and P3 pressure are outside evidence for a P1 timing tune. | Changing these invalidates old fight traces; no change proposed. |

**Geometry caveat, derived:** combined radii require roughly **0.65 m** lateral displacement. At unloaded walk **1.7 m/s**, ideal clearance takes **0.382 s**; run **3.0** takes **0.217 s**; stealth **0.9** takes **0.722 s** (`data/balance/player_stats.tres:5-7`). At the nearest teleport, collision-adjusted post-launch flight is about **0.382 s**. Walking has essentially no idealized post-launch reaction margin; advance preparation/running matters. Weight, acceleration, arena walls, camera direction and closing distance make actual outcomes different. This supports verifying the cue, **not** calling stealth-speed dodging guaranteed or declaring the boss unfair from a stationary calculation. Later shots may be fired closer than teleport distance.

### Implementable presentation repair (not a timing tune)

`MonsterTelegraph._ready()` searches only direct mesh children (`monster_telegraph.gd:14-19`). The boss scene has none (`scenes/enemies/boss_architect_3d.tscn:12-28`); base code adds the telegraph before building `VisualRoot/BodyMesh` (`base_monster.gd:137-164`), and boss silhouette is added after `super._ready()` (`boss_3d.gd:25-34`). Thus the current lookup can retain null. Even with a mesh, `_flash` targets `MeshInstance3D.modulate` (`monster_telegraph.gd:31-36`), not a valid Node3D color property. This is a static presentation defect, not an engine-observed error in this pass.

**Proposed target:** resolve an existing mesh at warning time after visuals exist, use a per-instance material/appropriate spatial visual instead of `modulate`, and show a steady non-strobing warning for the **same 0.4 s**. Current repeated flash segments **0.08+0.12+0.08+0.12 s→one steady 0.4-second gameplay cue**, sourced from `monster_telegraph.gd:33-36`. Keep warning audio at `:38-47`; do not change its **12 m** distance without audibility evidence. Under `reduce_flash`, retain a nonflashing shape/material cue, not audio alone. Treat this as gameplay information, not decorative flash; no new hit-stop or shake. Respect existing GAMEFEEL caps **≤80 ms / ≤4 px-equivalent** unchanged (`docs/GAMEFEEL_SPEC.md:3,23-28,42-46`).

**Risk / bot impact:** medium implementation risk from material sharing or cancelling an unrelated warning. The bot acts on movement/attack/strobe inputs, not this visual, so cue-only repair should not change its policy. Do not move damage to cue onset. Pending warning callbacks need tests through pause, death, stun and phase transition; `_throw_energy_ball` currently checks target existence, not all those states (`boss_3d.gd:132-141`). Treat observed post-stun/post-death launches as cancellation defects before changing duration. The audit's melee-during-wind-up cheese remains a **playtest hypothesis** (`docs/GAME_AUDIT.md:116-117`).

**Acceptance criteria**
- [ ] A visible, non-strobing warning is actually present before P1 projectile creation, including immediately after teleport, at near/far separation and with reduced-flash settings; muted-audio play retains actionable information. No invalid-property tween or shared-material cross-enemy flash.
- [ ] Trace cue onset, callback/spawn, impact and subsequent cue: retained duration/cadence match the table in gameplay time. Test pause/resume, death, stun and phase changes; do not allow damage from an invalidated attack.
- [ ] Human near/far and close-approach playtests after the movement-speed fix assess preparation, camera visibility, melee pressure and battery/strobe options. Only evidence of unavoidable damage after an observable cue authorizes a separate numerical timing proposal.
- [ ] Run the unmodified-balance bot on the current build before/after a cue-only repair. Distinguish boss attack stalls, early navigation failures and ordinary losses; never compensate for bot pathfinding by reducing boss HP/damage.

## Shared bot-evidence and QA disposition

**Current audit makes no new winnability claim.** The latest cited historical sample is **6 wins / 10 runs**, with a boss stall and spine-navigation failures (`docs/KNOWN_ISSUES.md:171-201`). The existing release criterion is **at least 1 win / 3 runs** (`docs/RELEASE_READINESS_REPORT.md:100-104`); retain it, do not reinterpret it as an all-seed guarantee. The wrapper is stricter: it exits successfully only when all requested seeds win (`tools/qa_sim/autoplay_bot:4,44-45`). Report both the release criterion and wrapper exit truthfully. Engine RNG makes seeds imperfectly reproducible (`docs/KNOWN_ISSUES.md:168-169`).

| Evidence category | Preserved / needs renewal | Required interpretation |
|---|---|---|
| This documentation-only patch | Runtime/data byte-identical to source revision | Cannot itself break gameplay; does not refresh historical wins. |
| P1/P2/P5 implemented | **New runtime evidence required** | Search behavior, acquired skills and resource ceilings change; skill-zero controls and affordable skilled cases must be distinguished. |
| P3/P4/P8 implemented | Flow/pause/cue regression checks required | Bot alone cannot validate menu comprehension, audio or visual fairness. P3 must preserve direct `Routes.start_game()`; P8 must preserve damage timing. |
| P6/P7 implemented | Static/reporting checks sufficient for their own scope | Their improved estimates still do not certify a playable route. |
| Unsafe implementations explicitly rejected | Evidence-breaking | Mandatory stealth purchase, randomizing required parts, cutting battery/strobe supply, shrinking the boss warning, increasing damage to counter stealth, or changing movement to fit a spreadsheet would invalidate the evidence and require a new balance review. |

Future engine owner rerun (not executed here): `QA_SEEDS="1 2 3" bash tools/qa_sim/autoplay_bot`, followed by the historically used `QA_SEEDS="1 2 3 4 5 6 7 8 9 10" bash tools/qa_sim/autoplay_bot`. Record current-build unmodified baseline first; retain logs and loss categories. Do not fabricate paired determinism or demand an exact reproduction of the old 6/10 ratio.

## Audit acceptance and verification record

Requirements re-read before delivery: one owned document; exactly eight proposals; current/source/proposed/reason/risk/bot impact for numerical recommendations; stealth additions/costs; exact Keeper-voice NG+ copy and targets; explicit pause policy; session/resource outliers; no unsupported boss timing tune; per-proposal acceptance criteria; commit/push/ref proof and artifact publication.

**Engine-free runs in this pass:**

| Check | Result | Limit |
|---|---|---|
| `bash tools/check.sh --static` | PASS, 12 checks | No engine execution. |
| `python3 tools/flow_check.py` | PASS, 53 checks | Structural flow, not playability. |
| `python3 tools/scene_node_check.py` | PASS, 95 script/scene pairs | Does not validate the runtime telegraph mesh lookup. |
| `python3 tools/qa_sim/balance_sim.py` | PASS; DARK ~4.9 h, PARTIAL ~6.9 h; branches 5/21, 5/13, 4/13, 2/7 | Existing simulator passes despite the modelling gaps documented in P5/P6. No claim it exercises the proposals. |
| Document structure/target validation | PASS after correcting the initially assumed, nonexistent victory scene target | Eight proposals, assumptions and acceptance sections; live UI route re-traced. |
| Inline standard-library JSON/arithmetic inspection | 26 secrets; stage counts 2/9/10/5; battery and SP arithmetic reproduced | Read-only, no extra repository artifact. |

Historical full-engine result is **20/26**, not an all-green RC (`docs/RUN_STATE.md:12-31`). It is not rerun here. A passing documentation patch must not conceal pre-existing runtime/environment findings.

**Self-review (three lines):**
1. Scope is one new Markdown file; all eight proposals are recommendations and runtime acceptance remains unchecked.
2. Numerical recommendations trace to current consumers; contradictory audit assumptions are corrected above, and estimates are not labelled measurements.
3. Current-build boss fairness, sensory behavior and bot wins remain owner-run gates; no failing implementation is being committed.

Delivery uses commit subject prefix `docs(design):`, pushes only `arena/01a0bdfa-igra`, and compares local HEAD with `git ls-remote origin refs/heads/arena/01a0bdfa-igra`. The final delivery message supplies the resulting hash proof; this document cannot self-embed its own commit hash. Publish this file in the artifact viewer.
