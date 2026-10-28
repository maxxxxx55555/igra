# Known issues

## OPEN (2026-10-28, Session 36): runtime acceptance of the source pass of 2026-10-28, and what it leaves

Closed with an engine (head `76529eaa`; the rows are the Session 36 block of `docs/RUN_STATE.md`): the source pass runs. Compile and arity read 0, the closeout reads 625 of 625 (its first run read six failures, all in the checks and not in the game), the autoplay bot won 3 of 3 seeds on Normal and 3 of 3 on Hard with no softlock, `qa_guard_e2e`, the audio truth gate, the density frames (55 per setting), AF3 on the 8 store frames and the static gates pass; the signed Android bundle (version code 7) passes `aab_check` and the Windows build starts with no script error.

- **Perf is not settled on this laptop.** The High tier gate (p95 at most 33 ms) read 33.65 and 33.21 ms in one run of `a5664feb` and 21.37 and 21.12 ms in the next, with another program's Godot runs on the same CPU; the A/B of the art pass (before, with, before, with) passed both sides in its first round and failed both in its second, so nothing is attributable to the art. Draw calls are 104 to 115 against 200 and video memory 191 MiB against 512. Nobody has measured a phone.
- **The ten-minute soak ends slower than it starts** (p95 18.06 to 32.32 ms, 215 frames over 50 ms; static memory +6.55 MiB, 160 objects, 25 nodes, 0 orphans). The machine was shared, so a hot laptop and a slow leak both fit: read it again on a cold, quiet one before calling it a leak.
- **The bundle was never booted** and the new menu, shop and HUD layout were never seen on a phone; the engine's runs are desktop and GL Compatibility.
- **The twelve music tracks have no verified commercial rights** (`docs/ASSET_LICENSES.md`, `RELEASE_CHECKLIST.md` section 10: owner step 1).
- **The checks of the source pass have no mutation rows** (the five that Session 36 fixed and the new ones were run green, never made to fail on purpose).
- **The surfaces are photographs, the things on them are not**: the road, the sidewalk and the prop surfaces are CC0 scans (Poly Haven) and the trees are bare limbs, but the monsters, the buildings and the props are still primitives. Real models and animation are the next art step and need an artist or a CC0 kit (Kenney, Quaternius) and a licence row each.
- **35 ObjectDB instances are still freed only at the exit of a bot run** (benign, as before).

## Source pass 2026-10-28; runtime acceptance done in Session 36

The dated records below are historical. Current fixes and exact runtime
regressions are in `RELEASE_COMPLETION_20261028.md`. Loop seams are now a
mandatory static gate, all four recipe one-shots exist in the pinned PR,
and the current locale set is six. This pass fixes the early First Light
grant, Truth eligibility, milestone/daily persistence, quick-wheel bindings
and modal pause, initial HUD values and quality-switch district grading.
New menu/shop/HUD art and layout still need fresh Godot captures.
Fresh full-engine and bot results, AF3 and the signing were done in Session
36 (the section above); physical-device checks, rights and store actions
remain pending. Earlier dated PASS records do not certify this source
revision, the Session 36 records do.

## OPEN (2026-10-21, Session 28, closed out by Session 29): what the masterpiece pass finished and what it left

Closed by Session 28 (every one with a gate and a mutation that bites, `docs/artifacts/rc16/proofs/s28_*`): the attack telegraphs (TEL1-TEL7, `tools/qa_sim/telegraph_audit.py`); the hit cap of `12 x damage_cap x NG+`, the Watcher's reach of 6 m, the first spawn point, the respawn battery floor, the park that opens with the Shadow, the ammo that doubles from the gas station and the wake of the heavy kinds within 10 m (DIF1-DIF3, ESC1, RET1, WAKE1, BAT0); the security extension (SPD1, VIT1, ECO1, NGB1, DLY4, DLY5, ACH2, SAV2, CFG1, OVL1, SAVE1, PICK1, LANG1, EX3, EX4, EX10, HC1); the hunted-level stem mixing (MUS5, MUS6); the story props (STORY1, STORY2); the window and lamp detail (V1A, V1B: the cream pyramids were a render-order bug, fixed by a render priority, a transparency sort and a distance fade); the burst scale (BURST1); the ending title contrast (ENDC1); DAILY-28 and CURVE-28.

- **Left red at launch 13** (`s28_f1_3cb2ad7.out`): the perf gate (power_station p95 34.72 ms, suburbs 29.11, against 33: the `process_ms` of 30 to 43 ms that the pass read as script time is `Performance.TIME_PROCESS`, the whole frame with its waiting, so Session 29 measures the script time per script, `scripts/tools/_script_profile_runner.gd`); `af3_frame_check` (the release frames are stale by design until one re-shoot after the art pass); the closeout group of rc15 (its timeout was 200 s and the 565 checks take 199 s: `3ca44bb` gave it 700 s, which is the number of checks and not a slow check); one mutation of the S26 run (set 2, `SOV8 failed without a mutation`: a collision with SOV4's mutation); 66 to 112 ObjectDB instances and 12 `ShapedTextDataAdvanced` RIDs leaked at the exit of a bot run.
- **`3ca44bb` was never run by an engine** when the pass stopped (Session 29 R1 ran it: compile 0, 565 closeout checks, no cream pixel in the flashlight-on frames).
- **The brightness of the lower half of a frame drifts by 4 to 9 % between frames at constant light** (a driver effect whose cause Session 28 did not find: the positional shadows of 48 lamps and the limit of eight lights on a mesh are the two candidates; F19 of the v10 queue tests the second after the pickup lights are gone).
- **No export, no verifier round and no tag happened**: the bundle is still version code 4, 127,147,642 bytes; the launch budget stood at 13 of 14, 0 of 2 exports and 0 verifier rounds.

## OPEN (2026-10-17, Session 27): what the v9.1.0-store pass left

Closed by this pass (the block of Session 26 below still lists them): the cream slab and the halo (SLAB-27, HALO-27), the mutation of DAILY3 (it bites: `docs/artifacts/rc16/s27_mutations.txt`), the 17 scripts kept on a citation (KEPT-27), the two daily templates and `data/ng_plus_config.json` (DAILY-27, NGCFG-27), the notice and prompt labels (HUD-27), the perf gate's red reads (PERF-27).

- **The commercial rights of the 12 generated music tracks are not verified** (MUSIC-27, `docs/ASSET_LICENSES.md` "Session 27 M1"): Google's Terms say Google claims no ownership of what a user creates with its services and say nothing on commercial use of Gemini-app music. Owner step 1 of `RELEASE_CHECKLIST.md` section 10; the synthesized beds, the old menu theme and the single boss theme are the way back (`docs/store/HUMAN_CHECKLIST.md`).
- **The music and the new shaders were not heard or run on a phone.** The bundle was read in the zip and the game on the desktop (launches 9 to 11); the weathering, signs, grass, fog and stencil shaders are plain spatial and canvas shaders of the GL Compatibility renderer, and nobody has seen them on a mobile GPU (UNVERIFIABLE-HERE, owner step 4).
- **Seed 1 of the autoplay bot can run out of the Architect's 240 s** (BOT-27): launch 11 won 2 of 3. The fight is the slowest part of the run (27 to 240 s over 31 won runs); the deadline is the bot's, not the game's.
- **Loop wraps are not gated.** Every looped music and bed file has a wrap step of at most 0.037 of full scale now (`python tools/qa_sim/music_post.py --seams`, `docs/artifacts/rc16/proofs/s27_f2_seams_after.out`); eleven files had steps of 0.05 to 0.53 and got 10 ms edge fades (SEAM-27). No gate reads a seam (`tools/qa_sim/audio_loudness.py` and the audio truth gate read levels): measure the next generated or re-cut loop by hand.
- **The police and the hospital are the most saturated districts** (the facade band's saturation 0.46 and 0.45 against 0.27 to 0.34 elsewhere, `store/SCREENSHOT_RECIPES.md` section 6): the hue of the district (GLOW-27); a flatter palette is one constant, `GLOW_HUE` in `scripts/world/skyline.gd`.
- **The first view of a district shows the burst of the pickup's sparkles over the subject** in the density and store runs: the frames are picked around it (`store/SCREENSHOT_RECIPES.md` section 6); no game code changed for it.
- **Four music targets of the recipe are not made** (the district-restored sting, the death cue and two UI ticks: `docs/GEMINI_HANDOFF.md` 2.3): one-shots of 0.06 to 8 s that the Music skill cannot place; the game skips an absent file without a word.

## OPEN (2026-10-16, Session 26): what the v9.0.0-universe pass left

- **The windowed audio gate's Music peak is bimodal and its cause is not isolated** (CORRECTION_LOG 114 and 276, `docs/UNVERIFIABLE_HERE.md` U8). Of 24 windowed readings on record (`docs/artifacts/rc16/proofs/s26_audio_readings.out`) 10 are over the -1.5 dB ceiling (+0.5 to +1.9 dB) and 14 under it (-9.3 to -12.4 dB), all in the same context (BATTLE, a monster 4.6 m away), two of the high ones at this head. The layout now ends the Music bus in a hard limiter at -2 dB (`default_bus_layout.tres`; check `AUD6`; the gate read -2.0 dB afterwards), so the Music bus is held (no other bus carries a limiter); why the level jumps 12 dB between runs of one code tree is unknown (a trace needs a gate that prints each Music player and its volume at the peak sample). Whether the unlimited music was audible as clipping stays the owner's listening row (`RELEASE_CHECKLIST.md` section 9, item 3).
- **The editor rewrites `default_bus_layout.tres` during an export** (`--export-release` as well as `--editor`, the entry of Session 19 below): the Master block, the default `room_size` and the resource's own `uid` (`audiobuses00` to `udiobuses00`) change. Run `git diff default_bus_layout.tres` after every export and `git checkout -- default_bus_layout.tres`; the bundle is built from the loaded resource, so it holds the limiter either way. An idle Gradle daemon can also keep the export process alive after the bundle is written (as in Session 23's export, `docs/RELEASE_ARTIFACTS.md`): stop it (`android/build/gradlew.bat --stop`, or `java.exe` by hand as this pass did) and the export exits with 0.
- **A static pass does not see an undeclared identifier** (CORRECTION_LOG 275): `tools/lint_changed.py` and the 62 static gates of that commit passed a script that the engine's compile gate then rejected. After a `.gd` edit, only the compile gate (inside `bash tools/check.sh --all`, or `res://scenes/tools/compile_gate_scene.tscn` alone) says the project still loads.
- **Three unlocks the achievement catalog does not list** (`district_one`, `shadow_slayer`, `secret_hunter`, granted by `ProgressTracker`; `docs/ACHIEVEMENT_REACHABILITY.md`): the player hears the fanfare and gets 100 coins each for nothing the achievements screen shows. Make them real (3 names, 3 descriptions, 13 locales, 3 medals) or remove them (300 coins). Two margins: `ach_17` needs 200 of 203 photos, `ach_08` 39 of a 40 kg pack.
- **Two daily templates are never offered** (`streets_12`, `streets_16`: a run lights at most 11 districts; CORRECTION_LOG 266). The selector walks past them, so a day gets the next template; the listing's "60 daily challenges" is the authored count, 58 are offered. Their flavor lines are in 13 locales and the content file is hashed in `data/integrity_manifest.json`.
- **The cream slab and the brass halo** (`docs/FINAL_POLISH_PLAN.md` D2 and D3): the flashlight's `light_energy = 24.0` saturates the lit road (6 % of the combat frame at 240 or more on all channels) and also feeds `LightGrid`, so a dimmer flashlight is a stealth-balance decision; the landmark halo is flat brass behind a hard-edged silhouette by design. Not changed.
- **The mutation of DAILY3 has not bitten in the engine** (CORRECTION_LOG 280). The check passes on the fixed code (launch 10: 485 checks, 0 fails); its mutation sat in a set with DAILY2's and read ok (`docs/artifacts/rc16/proofs/s26_last_09dfb04.out`). It is in set 1 now, with ACHRUN2; `python tools/qa_sim/s26_mutations.py run --tag s27` is the run that shows it, and `docs/artifacts/rc16/proofs/s26_daily_model.out` (a python model of the day line, calibrated on the combination the engine read) stands in until then.
- **The HUD's prompt and notice labels** (`PromptLabel`, `NoticeLabel`) are plain labels like the toast that was outlined; they were not measured over a lit road.
- **Kept on a citation, not on use** (`docs/CLEANUP_MANIFEST.md`): 17 scripts nothing reaches (props, cutscenes, weapon mods, the save-slot UI, haptics, the PanelCard adoption) and 26 functions nothing calls (LAN, ads, integrity, accessibility, weapons, the VisualStyle helper, hiding spots); ten `EventBus` signals are declared and never emitted or read (two of them, `coin_changed` and `lives_changed`, lost their only emitters, `emit_coin` and `emit_lives`, which no script called and the sweep deleted; `coin_changed` alone is named as a hook point, by `docs/GEMINI_INTEGRATION_REPORT.md:70`). `ftue_generator.gd` is deleted; `behavior_node.gd` and `weight_bar.gd` joined `_QUARANTINE/`; eleven documents nothing names moved to `docs/_archive/` (`docs/_archive/PROVENANCE.md`, `git mv` puts one back).
- **`data/ng_plus_config.json`** is read by no script and ships (`docs/NGPLUS_TABLE.md`): delete it with the integrity manifest regenerated, or wire it.
- **The perf gate** reads green at this head (D1 152 draw calls at 17.48 ms p95, D11 142 at 19.05 ms) after a red reading at Session 23; one green does not settle it, and the phone is the number that matters.

## OPEN (2026-10-16, Session 25): what the Gemini-integration pass left

- **The Gemini artifacts are not in the repository** (`docs/GEMINI_INTEGRATION_REPORT.md`): 7 of the 9 files the directive names are on no ref and in no commit. The owner's action: push them to a `gemini/<name>` branch or a pull request of `maxxxxx55555/igra`, or say that the Jules proposal is the intended specification.
- **19 more achievements (31 shipped; GDD section 21 asks 15+)** are not implemented: the only proposal (`docs/jules/ACHIEVEMENT_TRIGGER_SPEC.md`, now in the bundle named under Parallel branches below and on `refs/pull/20/head`) fails its own hook check (13 of 19 EventBus signals do not exist, 5 rows need new emission points, `ach_37` is out of reach within one run). A feature-sized wave: spec-kit, per `CLAUDE.md`.
- **Tags below 8.0.0 are gone from origin** (`v1.0-final`, `v7.*`; the table of commits is in `docs/CLEANUP_LOG.md`); `.clinerules/zone.md` and three documents still name `v7.0.0-rc1` (`c5292c8`).

## OPEN (2026-10-15, Session 24): what the v8.1.0-premium pass left

- **Parallel branches** (`docs/ABSORB_PLAN.md`, `docs/CLEANUP_LOG.md`): 3 remain on origin: `claude/keen-cori-0sc9uo` and `claude/serene-sagan-wynb3r` (two documents of them are in `main`) and `gh-pages` (the privacy page). The ten `arena/*` and `jules/*` branches were deleted on 2026-10-16 under the owner's directive of Session 25, with a bundle that restores them in `..\_BACKUPS\2026-10-16_00-45\`; the heads of pull requests 18 and 20 also stay on origin as `refs/pull/N/head`.
- **Quarantine** (`docs/CLEANUP_LEDGER.md` 12.3): three scripts that a planning document still names (`death_sequence.gd`, `onboarding.gd`, `city_decorator.gd`) and two wav masters whose bed the trailer plan names stay in `_QUARANTINE/` and `assets/audio/ambience/wav_src/`; the 17 UNCERTAIN files of the quarantine root (16 at `HEAD`) are the owner's, and the audit now lists `ftue_generator.gd` as AUTO-DELETABLE too, a candidate of the next batch. The 25 sha256 duplicate groups (18.7 MB) were not examined file by file.
- **Generator run** (`docs/GEMINI_HANDOFF.md`): 16 of the 19 recipe tracks are not on disk (one replaces the menu's `abandoned_hallways.mp3`), and the 11 lit beds are synthesized loops; the seven cards have licence rows (`docs/ASSET_LICENSES.md` 482 to 485), only their raws were not kept. The game runs without any of them.
- **LOD, occlusion culling, texture streaming**: unchanged, with the reasons of Session 23 (the table of the section "Session 23: deferred by design and owner rows" below).
- **Next export** (each is an edit of a runtime path, so it waits for one): the comments of `scripts/ui/weapon_compare_ui.gd` at lines 85 and 132 still name the purged `icons/weapons` set (the live set is `renders_v2/weapons`), and the `exclude_filter` of `export_presets.cfg` keeps `assets/textures/icons/ach_*` and `assets/textures/icons/weapons/*`, which match no tracked file now.
- **History rewrite (K-1)** and the rotation of the two credentials of `docs/CLEANUP_LEDGER.md` section 8: the owner's, as before.

## OPEN (2026-10-11, Session 19; rated in Session 20: 168, 178, 179 and 180 are closed; triaged in Session 21: 169, 172 and 174 are closed, 170, 171, 173 and 177 are the owner's, CORRECTION_LOG 198): findings of the v8.0.0 release validation that stay open, for the owner to rate

The pass fixed three P0 (CORRECTION_LOG 165 to 167) and left these. None is a softlock or a crash: the full loop (`docs/artifacts/rc16/proofs/s19_loop_14fc1b3.out`, 3 seeds, 12 processes, 427 steps, 0 failed) did not meet them as failures, and the exploit run (`docs/artifacts/rc16/proofs/s19_exploit_post_afb76e9.out`, `DONE checks=8 fails=0`) holds the guards. Each row has its mechanism, its file and line and its owner action in `docs/CORRECTION_LOG.md`. Session 20 (the final window pass) closed 168, 178, 179 and 180 with a fix and its AF2 pair and rated the other seven (CORRECTION_LOG 194 and 195); none of the four fixes is in `build/tls.aab`, which was built from `e241597`.

- B5 (CLOSED in Session 22, CORRECTION_LOG 205, `126912d`): a craft at the workbench lost its materials when a quest reward was pending and the pack was full, because the payout of 169 ran inside the craft's own inventory changes. The payout hook is connected deferred (`scripts/core/quest_manager.gd:28`), so a craft's remove and add finish first; check CRF1 (`scripts/tools/rc16/ship_checks.gd`) fails on the old runtime and passes now (`docs/artifacts/rc16/s22b_af2_both_ways.txt`). The patch of Session 21, `docs/artifacts/rc16/s21_b5_fix.patch`, was never applied: the one-line connect is the smaller fix.
- Session 22 (the HUD pass) leaves four things that are not defects a player meets: (1) the touch layout and the contextual rows are read on a desktop that emulates touch (`docs/UNVERIFIABLE_HERE.md` U13: reach, size, legibility and the hold times need a phone); (2) `scripts/ui/hud_3d.gd` is about 1,900 lines (the style rule is 300): the pass put its new logic in `scripts/ui/hud_fade.gd` and did not split the file; (3) the perf probe counts 82 of the suburbs' 142 draw calls in `Main3D/HUD` (budget 200, met); (4) the HUD principles that were not built are listed in CORRECTION_LOG 206.
- Session 22, verifier round 1 (CORRECTION_LOG 208 and 209; report `docs/artifacts/rc16/proofs/s22_verifier_round1.md`): B10 (the joystick faded the first-run calibration dialog) and B11 (the side buttons did not grow with Button Size) are CLOSED with checks HUDP10 and HUDP11 and their AF2 pair, and the wrong frame size in two store documents is corrected. Left open, none a defect a player meets in a normal run: (1) on a first run the objective list first shows at the first refresh that finds a quest (an objective change or a language change), not at the very start of play: the start hook in `scripts/ui/quest_tracker_hud.gd` needs a list that is already visible, and the comment at line 31 of that file says "and when play starts"; one `_refresh()` call in the hook and an export close it; (2) the frames of `docs/stills/shipping/hud/after1/` fail AF3 F4 against HEAD by design (the record of batch 1, superseded by batch 2); (3) the strings `tip4` and `tutorial_map` of the 13 locale files say M for the map and the key is K; no script, scene or tool reads them, and the help screen reads the live binding; (4) the labels of the 72 px Sprint and Stealth buttons in the 13 languages (the longest, pt_BR "FURTIVIDADE"), the calibration dialog and Button Size 1.5 are not measured on a phone (`docs/UNVERIFIABLE_HERE.md` U13); (5) the Interact button flashes to full for 0.15 s when its prompt goes away (cosmetic, `_pulse_interact_button`).
- 168 (CLOSED in Session 20, `6f6d643`): a save written while no player is in the tree holds no position, so a load takes the district's spawn.
- 169 (CLOSED in Session 21, `85fece8`): a quest reward that does not fit a full pack is paid when the pack has room, and salvage on a full pack keeps the item.
- 170 (ACCEPTED, CORRECTION_LOG 198), the daily challenge can be claimed twice by deleting `user://tls_daily.json` (needs file access on the device; a cross-check would close only the Continue path).
- 171 (ACCEPTED, CORRECTION_LOG 198), Export Save, then a Hardcore death, then Import brings the dead run back (the closing fix is a hardcore flag in the signed save: a save-format change for 1.1).
- 172 (CLOSED in Session 21, `adf0f6b`): Pause > Restart goes back to the last save, as Continue does, and leaves the game playing.
- 173, the LAN calls take any peer (co-op only, latent, the owner's: two peers are needed to verify a sender check); 174 (CLOSED in Session 21, `107db81`): `InventoryManager.remove` counts before it takes.
- 177, the rewarded-ad revive button lives on a death screen nothing loads; ads are off in this build, so no player sees it.
- 178 (CLOSED in Session 20, `6f6d643`): the Hardcore death screen shows the run it ends: the state changes before the wipe.
- 179 (CLOSED in Session 20, `6f6d643`): the daily streak belongs to the profile: a New Game keeps it, Reset progress clears it.
- 180 (CLOSED in Session 20, `6f6d643`): the tutorial hint follows a language switch.
- 182 (fixed) leaves one decision: the 5 images of `assets/store/endings/` stay in the bundle, planned art of the ending screens that no script loads yet.

Owner: rate 168 to 180 for 1.0 or the next pass; 177 before an ad SDK key is set; for 182, wire the endings art or exclude it.

## OPEN (2026-10-11, rc17): on the desktop the title change moved the `user://` folder

`config/name` is "Last Streetlight" since the merge `0cabe8b` (`project.godot:13`), and a desktop build keeps `user://` in `%APPDATA%\Godot\app_userdata\[project_name]`, so it now reads `...\Last Streetlight` instead of `...\The Last Streetlight` (CORRECTION_LOG 150). On a phone `user://` is the app's own storage, so the Android build is not affected, and 1.0 has no earlier players. The QA runs of this pass wrote files into the new folder (the guard restores only the files it snapshotted, and it found none). Owner: before a desktop play test, rename the new folder or copy the old one over it; if a desktop build ships later, `application/config/use_custom_user_dir` with `custom_user_dir_name` would fix the folder name.

## CLOSED (2026-10-21, v10 E6, by removal): the eight Screens cards that drew their content outside the card in Arabic; Arabic left the game and no supported language reads right to left

Measured with `CLOSEOUT_ONLY=rtl` (`rtl_screens_note` in `scripts/tools/rc16/finish_checks.gd`, headless, `docs/artifacts/rc16/proofs/r0_rtl_screens_b82bfef.out`): rebuilt in Arabic, Saves 3 of 3, Bestiary 1 of 1, FlashlightUpgrade 28 of 28, ControlsTouch 12 of 12, Weather 4 of 4, Radio 1 of 1, PowerGrid 23 of 35 and Events 4 of 4 direct children of the content stand outside the card. Loading, PhotoMode, PuzzleCables, StoryScene and FinalNight start flows of their own and were not measured. Cause: the one the shop had (closed below): their builders in `scripts/ui/screens.gd` size and place each Control before it has a parent, and a Control placed without a parent under a right-to-left language is mirrored against a zero-width parent. The builders are as at rc16: `git diff v8.0.0-rc16 HEAD -- scripts/ui/screens.gd` changes only `_populate_shop`. The fix is the shop's, per builder (attach first, then size and place), with a check like SHOP2 per card; it is not done in this pass, which allowed one fix attempt, on the shop (owner directive of 2026-10-11, R0). Owner: decide whether Arabic ships with these eight cards as they are, or the next pass fixes their builders; the measurement re-runs with `CLOSEOUT_ONLY=rtl bash tools/qa_sim/closeout_check 300`.

## CLOSED (2026-10-11, rc17 R0): the shop in Arabic drew its content outside the panel

In Arabic the coin header, the scroll area and the six item cards of the shop stand about one panel width to the right of the panel, which stays empty (frame `docs/stills/rc16_f1/A06_shop_ar_after_74f710b_20261008T091603Z.png`, read once). Found by reading that frame. SHOP1 passes in Arabic because it checks each Buy button against its own card and the grid, not the grid against the panel.
Cause, as far as launches 21 to 23 show: the shop and the other Screens cards set `.position` on Controls that have no parent yet; under the right-to-left layout of Arabic that offset lands one parent width away (a Buy button at the card's x plus 322.5 px with an Arabic card, minus 187.5 px with a left-to-right card; derived from the printed rects, which the check grows by its 0.5 px tolerance, so the card's own x is the printed 1725.333 plus 0.5: `docs/artifacts/rc16/proofs/f1_post2_3840ac9.out`, `docs/artifacts/rc16/proofs/f1_post3_7bc23c6.out`). The cards of the shop are containers now (below), so each Buy button stays inside its card; `header.position = Vector2(0, 0)` (`scripts/ui/screens.gd:958`) and `scroll.position = Vector2(0, SHOP_TOP)` (`scripts/ui/screens.gd:973`) still use absolute positions, and so do the other Screens cards; eight of them were measured in Arabic since (the OPEN entry above), Loading, PhotoMode, PuzzleCables, StoryScene and FinalNight were not.
Fixed: `_populate_shop` attaches the coin header and the scroll area to the panel's content before it sizes and places them (`scripts/ui/screens.gd:939`, `scripts/ui/screens.gd:954`). The closeout check SHOP2 (the card encloses the header and the scroll area, 13 languages x 3 text sizes) fails on the shop code of `03fd367` in Arabic at the three sizes (`docs/artifacts/rc16/proofs/r0_af2_pre_b82bfef.out`: the header at x 1433.3 against the content's 913.3, one content width of 520 px to the right) and passes on the fix (`docs/artifacts/rc16/proofs/r0_af2_post_b82bfef.out`: 39 cases, none outside); headless, CORRECTION_LOG 147.

## CLOSED (2026-10-08, RC16 FINISH F1): two defects of rc15 found by the S8 frame read

- **The skill tree Close button was English in 12 locales.** It is the scene literal `Close` that `_refresh` never set. `_refresh` sets it now (`close_button.text = LocalizationManager.t("BTN_CLOSE")`, `scripts/ui/skill_tree_ui.gd:46`; the key exists in all 13 locale files). Check CLOSE1 (`scripts/tools/rc16/finish_checks.gd`, closeout rc16 group): on the unfixed code it failed in the 12 other languages (`docs/artifacts/rc16/proofs/f1_pre_b7aee72.out`), on the fixed code it passes in all 13, at the first open and after a live switch (`docs/artifacts/rc16/proofs/l24_f1_f3_74f710b.out` and its attached log); frame `docs/stills/rc16_f1/A09_skill_tree_after_74f710b_20261008T091545Z.png` (Russian) shows "Закрыть" under the tabs. The `hardcoded_text_gate` still scans scripts only, so a scene literal that no script overwrites stays invisible to it; every `text = "..."` literal under `scenes/` is listed in `docs/artifacts/rc16/proofs/f1_scene_literals.out` (86 lines in 22 scenes) and reading the list found no other untranslated literal that a player can reach (a reading, not a logged check: daily_events, photo_album, new_game_plus and the HUD set theirs in script; save_slots, achievement_screen, lobby, menu and game_over have no shipped entry point; `Routes.LOADING` has no caller).
- **The shop Buy buttons overlapped the next row and the last row was cut.** The button asked for 20 px, a Button cannot be smaller than its theme minimum (40 px, 43 px in Arabic), and the card was 80 px. A shop card is a PanelContainer with a VBoxContainer now (`var card_item := PanelContainer.new()`, `scripts/ui/screens.gd:970`), so its height follows its content and each Buy button stays inside it. Check SHOP1: on the unfixed code it failed in every case listed (`docs/artifacts/rc16/proofs/f1_pre_b7aee72.out`), on the fixed code it passes in 39 of 39 cases (13 languages x 3 text sizes; the three text sizes give one geometry, CORRECTION_LOG 112). Frame `docs/stills/rc16_f1/A06_shop_after_74f710b_20261008T091547Z.png` (Russian): the buttons lie inside their cards and the next row starts below them; the fourth row is reachable by scrolling. The Arabic frame shows the older defect above.

## CLOSED (2026-09-30, rc14 sign-off): Russian text reached every other locale

Key parity passed the i18n gates while text that never goes through the dictionary did not (CORRECTION_LOG 55).
Found by reading a frame, then by scanning the bot logs and the scene files for Cyrillic:

- District names in the power switch label and toasts, the district lock hints and the city map; item names in the
  switch prompts, the generator prompt and the quick wheel; shop item names and notices; monster descriptions in the
  encyclopedia (six newer monsters were English only); 7 component items had no key at all.
- 33 legacy documents (title and body) in the catalog were raw Russian: world pickups, the pickup toast and the journal.
- The main scene showed the Russian word for Loading on every launch.

All routed through the dictionary (93 new keys, 1407 per locale). Guards: `hardcoded_text_gate` (a `display_name`
read outside `name_for()`, a resource without its name key, a catalog entry with raw text), `ui_layout_check` (18 screens
and 18 live scenes opened in English must show no Cyrillic), suite P5c and P5d. Each fails on the old tree.

**Still open (honest):** `data/documents.json`, `data/dialogs.json`, `data/dialogs/*.json` and `data/lore/lore.json` hold
Russian or transliterated text that no runtime code reads (legacy data, CERT_CONTENTDEPTH); item `description` fields
are read nowhere; `scenes/ui/game_over.tscn` and `pause_menu.tscn` keep Russian placeholders but only the scene smoke
loads them. The translations of the 33 documents and the 27 name keys are written by this pass, not by a native
speaker: a native read (NATIVE_QA_FINDINGS) would still help.

## CLOSED (2026-09-30, rc14 sign-off): the boss-phase and spine "bot stalls" were game bugs, not skill gates

Two standing entries of this file (the boss-phase stall, 9 of 13 bot seeds, and the X21 spine stall) were
filed as bot-harness limits. Both were real game defects, found by tracing stalled runs instead of tuning the bot:

- **Melee swing spent on the wrong body** (`scripts/player/player_3d.gd` `_on_attack_hit`, X30). The attack
  `Area3D` is a child of the player's body, so it reports the player itself and any wall or prop before the
  enemy; the first body marked the swing spent. A boss-only bot trace showed `body=1` (the player) entering before
  `BossArchitect` on hundreds of swings, each one wasted and each one damaging the player. Fixed: the swing is
  spent only by another body that can take damage. `game_test_3d` asserts both cases (mutation-tested).
  The boss collider holds a player 2.6-2.8 m out; the bot's swing gate was 2.6 m and is now 3.4 m (bot side).
- **Loot hovering over the void** (`scripts/world/district_loot.gd`, X37/X21). The 3x3 street grid has floor only
  on its streets; loot was scattered over a 6-22 m disk. A ray down from every pickup, document and secret found
  2-4 floating ones in 10 of 11 districts, repair parts included, so a real player could not collect them either.
  Positions now snap onto the nearest street band; `loot_floor_check_scene` (11 districts) is a blocking gate.
- **Pickup reach shorter than the approach** (`scenes/pickups/item_pickup_3d.tscn`). The contact sphere reached
  1.0 m from the player body while an approach stops at about 1.4 m; radius 0.7 -> 1.1 m.
- **Full pack** (bot side): a required part is refused while the pack is 12/12; the bot now drops junk.

Result: 13-seed bot 3/13 -> 13/13 WIN, 11/11 districts FULL on every seed, 0 watchdog stalls. The bot is
nondeterministic between runs, so this is evidence, not proof; the sign-off records the stalls of every run.
Also fixed in the same pass (found by frames, `docs/stills/beauty/`): lamp heads glowing in every power stage,
star panorama drawn as blocky diamonds, roads in a void, trees and benches in the roadway, ash drawn white,
a dead brute still slamming, the HUD opacity setting raising the hit marker to the screen centre.
Found reading the final frames: the menu title drew a blank line between its words on CRLF checkouts (Windows autocrlf, the
AAB included; a multi-line string in a scene file), fixed and gated in `ui_layout_check`.

**Still open (honest), rc14 text, superseded in rc15:** the 1.34 M primitives per frame fell to 39.7K-50.2K (PF4) and the deferred GDD rows G21, G25, G26, S02, S04-hide and C03 were built (`docs/TZ_COMPLIANCE.md`, CORRECTION_LOG 96); the open list is the rc15 residual table in `docs/ORDER_PASS_REPORT.md`.

## DIAGNOSED (2026-09-21, P8): the "прогон 3D-сцены" gate's real failure point, captured for the first time

Named as a pre-existing stall across v7 through v7.3.2's reports, always as an opaque 90s
timeout with no diagnostic — because `tools/check.sh`'s own shell-level `run_gate` timeout
(90s) was **shorter** than the test scene's own internal `HARD_TIMEOUT_SEC` (150s,
`scripts/tools/_game_test_3d.gd:25`), so the shell always killed the process before the
scene's own graceful-timeout handler (which reports exactly which phase it's stuck on) ever
got to run. Bumped the gate's shell timeout to 170s (`tools/check.sh`) and ran it directly —
the scene's own diagnostic fired clean: **`[FAIL] hard timeout at phase 7 — stalled, not
completed`**, with `boss spawned` / `boss energy ball spawned: 0` / `boss minion cap 3: 14 ->
4` all failing first, plus `SCRIPT ERROR: Cannot call method 'get' on a null value.` at
`_game_test_3d.gd:138/142/160/162`. This is `_game_test_3d.gd`'s own **synthetic phase-7 boss
test harness** never getting a boss reference to test against — not the real game: the real
`autoplay_bot`, on this same current codebase, reaches and fights the boss fine (2/3 real wins
this pass alone, boss HP tracked dropping normally in the logs). The gap is in the test
scene's own boss-spawn setup for that one phase, not shipped gameplay.

**Not fixed this pass** — this was the sanctioned "timeout-tune, attempt once" per this pass's
own directive; actually fixing `_game_test_3d.gd`'s phase-7 boss setup is a second, separate
task (read how phases 1-6 set up their test subjects vs. phase 7, find why the boss reference
is null there specifically) that a future session should pick up now that the real failure
point is finally visible instead of a bare timeout. The `tools/check.sh` timeout bump (90s ->
170s) is a real, permanent fix in itself — every future run of this gate gets an actual
diagnostic instead of an opaque kill, regardless of whether phase 7 itself ever gets fixed.

**CLOSED (2026-09-22, R3 CHALLENGE-01)**: the follow-up task above is done. Root cause was
never "the boss reference is null" in isolation — it was 3 layers deep: phase 4's puzzle-solve
call targeted a puzzle ID already trimmed from `puzzle_system.gd`'s data as dead data, so it
never advanced district stage, so the boss's real spawn gate (11 districts FULL) never fired;
the test also never spawned the boss itself, having always relied on that gate; and once spawned,
the synthetic damage amounts didn't account for the boss's real 25% armor + 50% bullet
resistance, so the P1->P2 phase transition never crossed threshold either. All 3 fixed in
`scripts/tools/_game_test_3d.gd`; phase 7 now passes all 9 of its own checks, zero crashes,
verified across multiple consecutive runs. Full trace in `docs/RUN_STATE.md`. New, separate
finding surfaced by this fix (phase 8's death screen doesn't display when boot is bypassed) is
tracked as `docs/FUNCTION_MATRIX.md` X22, not part of this closure.

## CRITICAL, NEW, NOT FIXED (2026-09-21): 3D world renders as severe magenta/pink corruption in windowed mode

First time this project has ever had a real windowed Godot binary + the ability to actually
look at a captured frame (P0/P4 of a v7.5 pass) — and the very first real 3D gameplay
screenshots taken (`res://scenes/tools/capture_stills_scene.tscn`, real playthrough via the
autoplay bot, not a synthetic probe) show the entire 3D world rendering as severe magenta/pink
visual noise: jagged horizontal scanline-like streaks across the ground plane, hundreds of
scattered magenta/purple particle-like dots, and at least one object rendering as concentric
magenta/purple rings. The HUD (health/stamina/battery bars, radar, all text) renders perfectly
clean and readable on top of it — this is a 3D-world-rendering-only problem, not a whole-engine
or UI-layer problem. GPU: `ATI Technologies Inc. — AMD Radeon(TM) Graphics` (integrated),
renderer: `gl_compatibility` (`project.godot:273-274`, used for both desktop and mobile presets).

**Ruled out already**: not an import-cache issue (ran a full `--headless --import` immediately
before capturing, zero texture-load errors in the capture log); not shader compile failures
(grepped the full log for `shader`/`compil`/`unsupported`/`fallback`, zero hits); not
SSR/SSIL/SSAO/volumetric fog (all four are Forward+/Mobile-only features not supported by
`gl_compatibility` — disabled all four in a scratch edit of
`assets/env/night_environment_desktop.tres` and re-captured; corruption was **unchanged**,
edit reverted, never committed).

**Not established, genuinely unknown**: whether this is the game actually rendering wrong on
this hardware/driver/renderer combination (which would mean real players on similar low-end/
integrated GPUs — exactly the target Android min-spec per `docs/release_checklist.md` — could
see the same thing), or an artifact specific to the `get_tree().root.get_texture().get_image()`
viewport-readback capture method used by `capture_stills.gd` (a driver-level framebuffer-readback
bug is a known class of issue on some integrated-GPU OpenGL drivers, and would explain corrupted
*captures* while the actually-displayed frame is fine). No way to tell which from inside this
session — nobody watched the live window while this ran, only the saved PNGs.

**Evidence**: `docs/stills/03_district_suburbs.png` and `04_district_residential.png` from this
pass's capture runs (not committed to git — multi-MB PNGs, not this repo's convention for
`KNOWN_ISSUES.md` evidence — left on disk locally, `docs/stills/` is untracked-but-not-gitignored
so `git status` will show them until cleaned up or committed).

**Next session must do, before anything else visual**: have a human actually look at the live
game window (not a captured PNG) during a `--windowed` run on this same machine, to settle
capture-artifact vs. real-rendering-bug. This blocks P4's full W2-W10 material-assignment work
and P7's store screenshots for this pass — assigning new materials or capturing store shots on
top of an unconfirmed-cause rendering corruption risks wasted or actively misleading work.

## NEW, NOT FIXED (2026-09-21): City Map "Travel" to `park` produced `player.global_position = (inf, inf, inf)`, new softlock

Found in the same windowed capture run as the magenta-corruption finding above (real autoplay
bot driving real gameplay, not a synthetic probe) — **not the already-fixed residential
nudge-duration softlock** (different district, different mechanism, and the fix for that one is
verified 3/3 clean in 3 separate headless re-runs this same pass, so this is not a regression of
it). Sequence from the log: bot reaches `suburbs` FULL at t=13.9s, travels to `residential` via
the City Map's Travel button (`city_map.gd:_travel` → `DistrictManager.transition_to`), reaches
`residential` FULL at t=30.4s, travels to `park` the same way at t=31.5s — and from t=36.5s
onward every heartbeat shows `ppos=(inf, inf, inf)` until the 45s no-progress watchdog fires:
`SOFTLOCK: no progress for 45s — phase=spine district=park spine_i=2`.

**Not root-caused this pass** — time went to the (more severe-looking) rendering finding above.
Candidate starting points for whoever picks this up: `world_runtime.gd:_place_player()`'s
`SaveSystem.consume_pending_player_pos()` sentinel path (`Vector3.INF` is the real "no saved
position" sentinel value already used by design — worth checking whether `park.tscn` has a
`PlayerSpawn` node at all, and whether some other code path can end up *setting* the pending-pos
field to a bad value rather than just consuming the sentinel), and whether this is
windowed-mode-specific (3 separate all-headless 3-seed bot re-runs this same pass, on the exact
current codebase, produced zero occurrences of this — this is the first time `park` has been
reached via a **windowed** run with a live camera/viewport, and `_qa_autoplay_runner.gd`'s own
`_dir_to()` depends on `get_viewport().get_camera_3d()`). Two real leads, neither confirmed —
recorded here rather than guessed at.

## CORRECTION (2026-09-21, even later): the entry below is NOT fully resolved — much rarer, reproduced once more

Downgrading the "RESOLVED" claim below before it goes stale: while verifying an unrelated
change (P6, `data/shop/*.tres` price data, zero code path to movement/pickup logic) with a
fresh 3-seed run, seed3 hit **the exact same signature again** — `SOFTLOCK: no progress for
45s — phase=spine district=residential spine_i=1`, `tdist` oscillating at 1.4-1.5 for the full
stall window, same as originally documented. 2/3 seeds still won cleanly (meets the IRON
RULE's own ≥1-win bar for the price change, which is unrelated and not being reverted over
this), but this proves the nudge-duration fix (`b7213ac`, below) **reduced** the failure rate,
it did not **eliminate** the underlying mechanism: shortening the nudge window makes the
"lucky recovery" case much more likely (was demonstrated working, in-log, for the original
fix's own verification run) but a sufficiently unlucky RNG draw can still fail to land the
player inside the true 1.0m contact radius within 45s. Real state: **much rarer, not gone**.
Don't re-claim "RESOLVED" without a much larger sample (10+ seeds) showing zero recurrences,
and don't re-try the two already-rejected hypotheses (PICKUP_TOUCH tightening, bot-side
NavigationAgent3D) if picking this back up — both are still bad ideas, this new data doesn't
change that.

## PARTIALLY RESOLVED (2026-09-21, later): spine-phase softlock — root cause was nudge duration, not touch distance or speed (see correction above — reduced, not eliminated)

The two entries below (both 2026-09-21) each ruled out one wrong hypothesis without finding
the real cause. A third pass got there: `arena/01a0c324-igra`'s `docs/SPINE_SOFTLOCK_AUDIT.md`
proposed C1 (high-speed tunneling, 170 m/s skipping the pickup's Area3D) as the top candidate.
Checked against real telemetry before touching any code — temporary diagnostic prints in
`_qa_autoplay_runner.gd` and `item_pickup_3d.gd` (reverted after, never shipped) showed
**player velocity was 0.0** while stuck at the 1.27-1.32m touch threshold, dozens of
consecutive frames: no tunneling, the bot was simply idle, waiting for a collision that
needed it to be within the true 1.0m contact radius (0.7 pickup + 0.3 player), not the 1.4m
it stops at. C1 rejected on direct evidence.

What the same log then showed working: a stuck-nudge event fired, launched the player at
~117 m/s, and this time landed it at 0.31m (inside true contact) — the pickup registered.
So the nudge mechanism itself was fine at recovering *locally*; the actual bug was in its
blast radius. `player_3d.gd:544` normalizes the movement direction before applying speed
(`dir.normalized() * final_speed`) — the audit's proposed fix (shrink the nudge vector's
*length* to slow it down) would have done nothing, since magnitude never affected velocity
in this codebase. The only real lever was **time**: the nudge ran at full walk-speed for a
fixed 1.2s, which is exactly what produced the previously-logged 150-250m jumps that could
land the player outside the district's ~40m nav-mesh half-size entirely. Cut to 0.25s
(`b7213ac`) — bounds worst-case displacement to ~43m even from a max-radius (22m) scatter
start, while still covering far more distance than the sub-meter local obstacles a sidestep
actually needs to clear. 3-seed bot: **3/3 WINS, zero FAIL/SOFTLOCK lines in any log** — up
from the 2/3 boss-fix baseline, a net improvement, not just a recovery. QA-bot-only change,
no gameplay/balance file touched. See `docs/SPINE_SOFTLOCK_AUDIT.md` for the full candidate
ranking and `docs/IDEAL_GAP_REPORT.md` v7.3.2 for the writeup. Keeping both entries below for
the diagnostic trail — each correctly ruled out what it tested, even though neither found the
real cause on its own.

## RESOLVED (2026-09-21): boss-phase softlock — root cause was the Y-dip, not battery/light

The entry below (2026-09-20) correctly identified the Y-dip as the likely mechanism but
couldn't confirm it — no softlock had happened WITH the new telemetry yet. This pass got
that run: `boss_pos.y` sank from ~1 to −33 over ~90s during a real softlock (seed3,
`.qa_logs/autoplay_seed3.log` from a 2026-09-21 session), while the existing "keep near
player" rescue teleport (`base_monster.gd._boss_keep_near_player`) only checked full 3D
distance with a 1.5s grace period — a boss that had fallen 30+ units down still read as
"close" in 3D distance, so the rescue never fired in time. Fixed by checking vertical
separation independently, no grace period (`acddc80`). 3-seed bot: 2/3 wins with the boss
resolved both times (was 1/3 pre-fix). See `docs/IDEAL_GAP_REPORT.md` v7.3 for the full
writeup. Keeping the original entry below for the diagnostic trail, not deleting it.

**Correction, Session 23 (CORRECTION_LOG 237):** this was not the last boss softlock. At launch 22 seed 2 stalled when the boss's teleport-jump, which picks a random spot round the player, landed outside the perimeter wall of the district; the jump takes a spot with a clear ray from the boss now (`scripts/enemies/boss_3d.gd:151`) and BOSS1 holds it; the 3-seed bot won 3 of 3 at launch 23 (`docs/artifacts/rc16/proofs/s23_final_f2e628a.attach.autoplay_seed*.log`).

## New (2026-09-21): spine-phase softlock, residential — investigated, root cause NOT found, one hypothesis tried and rejected

A 2026-09-21 verification run (seed2) softlocked in the SPINE phase (not boss) at
`residential`, `spine_i=1`: `SOFTLOCK: no progress for 45s — phase=spine
district=residential spine_i=1`. Heartbeats show the bot oscillating at distance 1.4-1.5
from a `cable` pickup target for ~30s (never closing the gap), then the player's position
jumps ~150-250 units between two consecutive 5s heartbeats before the softlock fires with a
stale target.

**Hypothesis tried and REJECTED**: the bot's `PICKUP_TOUCH` constant (1.4,
`scripts/tools/_qa_autoplay_runner.gd`) is larger than the pickup's actual Area3D contact
radius (pickup Area3D radius 0.7 + player capsule radius 0.3 = 1.0m true overlap distance),
so the bot could plausibly stop at 1.4m — just outside real contact — and oscillate
indefinitely. Tightened `PICKUP_TOUCH` to 0.8 (below the 1.0m true radius) and re-ran the
full 3-seed verification: **result was 0/3 wins, with softlocks in three DIFFERENT
districts (gas_station, suburbs, school) — worse than the 2/3 baseline, not better.**
Reverted immediately (never committed). Whatever the touch-distance math predicts in
isolation, in practice a tighter `PICKUP_TOUCH` makes the bot's approach/pathing behavior
meaningfully worse across many districts, not just better at residential — the real
mechanism is not simply "the stop distance is too far from the collision radius." Do not
re-try this exact fix without new evidence (e.g., telemetry showing what specifically
blocks the approach at residential specifically, since the position jump afterward still
needs its own explanation — plausibly just the stuck-nudge fallback moving the character a
long way at the game's canonical, bot-verified-correct high speed, 170-300 "m/s" per
`data/balance/player_stats.tres`, once nudging engages for multiple 1.2s cycles — but this
wasn't confirmed either). Left open, not silently dropped. `.qa_logs/autoplay_seed2.log`
from the 2026-09-21 pass has the original trace, if still present when picked up next.

**Lead investigated and RULED OUT (not a hypothesis tried, a theory disproven before touching
code)**: `content/districts/residential/item_spawns.json`'s `residential_fix_puzzle_01` places
the district's first-needed `cable` in `zone: "z_boiler_room"`, the same zone as the
key-gated `transistor` ("behind the locked boiler-room door (key = residential_fix_key_01)"
per that file's own comment) — a plausible "bot walks toward a pickup that's behind a closed
door it can't open" explanation. Checked before attempting any fix:
`scripts/world/district_loot.gd`'s own comment (`_spawn_secrets`, ~line 177) says plainly
that 3D districts have **no named zone markers at all** — `zone` is authoring-only metadata
in the JSON, every fixed-spawn item (including the "locked" ones) is placed by the same
seeded random scatter as everything else, with zero physical door/lock gating anywhere in
`scripts/` (grepped for `z_boiler_room` / `locked_zones` / `zone_locked` / `key_gated`, zero
hits outside content JSON, and `residential.tscn` has no "door" node at all). The locked
boiler room is pure narrative flavor text with no code behind it — ruled out, not the cause.

**Second hypothesis tried and REJECTED (2026-09-21, later)**: the bot's `_dir_to()` steers in
a straight line at the target regardless of walls (`scripts/tools/_qa_autoplay_runner.gd`),
unlike monsters, which route via `NavigationAgent3D` (`base_monster.gd._move_to`) — plausible
that residential's denser courtyard/stairwell geometry defeats the 2s stuck-nudge fallback
where open districts don't. Added a `NavigationAgent3D` child to the bot's player node,
mirroring `base_monster.gd`'s exact idiom (including its off-navmesh straight-line fallback),
and routed `_dir_to()` through it. Full 3-seed verification: **0/3 wins — softlocks in
`park` (spine_i=2), `hospital` (spine_i=4), AND `suburbs` (spine_i=0, the tutorial district,
which had never failed before)** — worse than the 2/3 baseline and a regression into a
district that used to be solid. Reverted immediately (`git checkout --`, never committed).
Whatever navmesh-vs-pickup-position mismatch might explain this (items are placed by a
seeded scatter with no navmesh awareness per the ruled-out lead above — plausible some land
in spots the navmesh reaches only via a clamped nearest-point that isn't actually adjacent to
the real pickup) is not confirmed. **Do not retry this exact fix (bot-side NavigationAgent3D)
without new evidence.** Two hypotheses down; the residential softlock's actual mechanism is
still unknown. Left open.

## Boss-phase softlock is real but nondeterministic — battery/light-gate hypothesis disproven (2026-09-20)

RC finish pass observed the autoplay bot softlock in the boss phase (power_station,
`phase=boss`) twice independently, always AFTER restoring all 11/11 districts (spine
navigation and the P5 battery-capacity fix both proven fine both times — full district
timelines, no resource starvation). Formed a hypothesis: the boss's P2 phase requires the
flashlight to be lit on it to take damage (`boss_3d.gd`'s `_is_in_light()` gate); if the bot's
battery ran out with no items left to refill, the boss would go permanently invulnerable and
neither side could progress, matching the observed symptom (`boss_hp` frozen, `boss_dist`
stuck near attack range for 40+ seconds before the 45s no-progress SOFTLOCK fired).

**Disproven by a targeted diagnostic run**: added `battery=`/`fl_on=` to the bot's boss-phase
heartbeat log (`scripts/tools/_qa_autoplay_runner.gd`) and re-ran. `fl_on=true` for the entire
fight, `battery` never dropped below ~20 (the bot's own `_maintain_flashlight()` refill logic
kept it topped up), and `boss_hp` dropped steadily throughout — the run **won cleanly** in
303s. Also noted: `boss_pos.y` occasionally goes negative (e.g. `-31.0`, `-28.0`, `-17.0`)
mid-fight before recovering — a navigation/physics dip below the floor plane that usually
self-corrects but, in the two observed failures, may not have. This is the likely real
mechanism, not battery/light-gating, but is **unconfirmed** — would need a run that
softlocks WITH the new telemetry to nail down (neither of the two prior softlocks had it).
Matches this doc's own much older "boss stall" entries below (2026-09-14/15/16) — a
long-running, real, intermittent issue, not a regression from anything landed today.

**Not a regression**: this session's own bot-win evidence across today's runs: 1/3 (P5
verification), 1/1 (this diagnostic) — consistent with historical ~50-60% win rates recorded
elsewhere in this file, not a new failure mode.

## W2-W10 visual pass — deliberately not attempted this session (2026-09-17)

`docs/VISUAL_PASS.md` §8 has a fully-specified wiring plan (W1-W11) for the merged visual-pass
branch's delivered materials/shaders (`camera_attributes_night.tres`, `mat_lamp_flicker.tres`,
`mat_wet_asphalt.tres`, `contact_shadow.gdshader`, `vfx_rain.tscn`, etc.) — verified this session
that only **W1** (graphics-tier preset) is actually wired; W2-W10 are real files sitting unused,
confirmed via `grep -rln "<filename>"` finding zero consumers for each.

Not implemented, on purpose: two real blockers surfaced while investigating just W5 (wet ground).
First, the "live" ground-material code path is genuinely ambiguous — `district_grading.gd` looks
like the place to wire it (has a `_apply_ground` function, per-district floor texture logic) but
its own file comment says it's dead code today (`world_environment_path`/`district_root_path`
exports never set by its instantiator); the actual live ground rendering appears to be scene-file
authored, not script-driven, meaning a real fix needs opening and editing up to 11 district
`.tscn` files, not one script. Second — and the bigger reason — this session has no way to
visually verify a shader/material change (headless-only, confirmed in the STORE_KIT/stills entry
below), and `docs/SIZE_BUDGET.md`'s E2-E4 correction (same session) just proved this repo has
real, non-obvious traps around "is this actually wired or just delivered" that are easy to get
wrong confidently. Wiring 9 waves of 3D rendering/shader code blind, with no render to check
against, risked shipping something subtly broken with no way to catch it — worse than leaving it
honestly open. `docs/VISUAL_PASS.md` §8 already has the exact per-wave instructions; this is real,
scoped, dev-remaining work for a session (or a human) that can actually see the game render.

## Owner-only cleanup: `assets/_orphaned/` and `assets/audio/_pre_norm/` physical deletion (2026-09-17)

Both are already excluded from the shipped `.pck` via `export_presets.cfg` exclude_filter
(`11cbb4e`, 27.7% real measured cut — see `docs/SIZE_BUDGET.md`). Physical deletion from the repo
is a separate, smaller win (frees repo/checkout disk space, not build size) and is blocked in
automated sessions: the local tool-permission classifier refuses `git rm -r` as irreversible
destruction even though both are git-tracked and fully revertible. Owner-run, when convenient:

```
git rm -r assets/_orphaned assets/audio/_pre_norm
```

`assets/_orphaned/` was independently verified dead twice (a prior session's own orphan-scan,
documented in this file's own history/`docs/ERROR_LOG_FINAL.md`; re-confirmed this session via
the same 17-directory dynamic-loader narrowing in `docs/SIZE_BUDGET.md`). `assets/audio/_pre_norm/`
is documented "do NOT import" archive material in `docs/ASSET_HANDOFF.md`/`docs/REPORT_ASSETS.md`.
Also newly spotted this session, not yet investigated: a `res://_QUARANTINE/` directory exists
(seen in `compile_gate_scene.tscn`'s gate output, scenes under `_QUARANTINE/scenes/effects/`) —
another asset-quarantine location the size-budget pass didn't cover; worth folding into the next
size pass.

## Audio bitrate (E7 of `docs/SIZE_BUDGET.md`) — investigated, definitively no safe control exists (2026-09-17, confirmed in follow-up)

`assets/audio/{music,sfx,ambience,ui}` is not raw in the shipped build: every `.wav`'s own
`.import` file already sets `compress/mode=2` — **correction to this entry's first version**:
that's **Quite OK Audio (QOA)**, not Vorbis (Godot 4.7's WAV importer offers exactly 3
`compress/mode` values: `0` PCM, `1` IMA ADPCM, `2` QOA — verified against
`../refs/godot-docs/classes/class_resourceimporterwav.rst`, the authoritative property reference).
`downtown.wav` measured 1.06MB source → 214KB imported at this setting.

**Definitive answer**: `ResourceImporterWAV`'s full property list is `compress/mode`,
`edit/{loop_begin,loop_end,loop_mode,normalize,trim}`, `force/{8_bit,max_rate,max_rate_hz,mono}`
— confirmed exhaustive from the reference doc. There is no bitrate/quality float anywhere in it.
QOA (the current setting) has no tunable rate; the only way to get a real Vorbis-with-bitrate-cap
is external re-encoding to `.ogg` with a tool like ffmpeg and updating every `.wav` reference to
`.ogg` in code — a second lossy generation on top of QOA, changes tracked source files, and
touches every `load("...wav")` call site. Not attempted: the ask (E7, "music ≤96kbps / sfx
≤64kbps Vorbis") doesn't map onto what this importer can actually do, and forcing it through
external re-encoding is a meaningfully different, riskier task than the one line item implied.

## Stills / store screenshots — owner-run, not automatable in this environment (2026-09-17)

`tools/qa_sim/capture_stills.gd`'s own header already documents why:
`DisplayServer.get_name() == "headless"` → no compositor → no-op by design, confirmed unchanged
this session. The tool itself works; it just needs a real window. Owner-run command:

```
"C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64_console.exe" --path . --windowed res://scenes/tools/capture_stills_scene.tscn
```

Outputs 8 canonical shots to `docs/stills/`. The 8-shot STORE_KIT list in `docs/STORE_KIT.md` and
the before/after GAMEFEEL_SPEC stills both depend on this same owner-run windowed step.

## Visual pass merged, graphics-tier seam wired; two named "lanes" from this task's own brief don't exist (2026-09-16)

A follow-up task named three branch "lanes" to bridge by commit-subject prefix: `feat(visual):`,
`feat(qa): cert ledger`, `feat(accessibility):`. Checked for real against every ref on `origin`
(fetched fresh first) rather than trusted: only **one** exists —
`arena/01a0a4c3-igra`, `9c2263f feat(visual): AAA environment/material/UI pass with mobile
profiles`. No branch anywhere on `origin`, merged or not, has a `feat(qa): cert ledger` or
`feat(accessibility):` commit. Whoever gets a task referencing those two again: they are not on
this repo's remote as of this entry; don't spend time hunting for a fork that was never checked
either (this repo has no forks — `origin` is the only remote).

The one real lane was verified before merging, not just merged on the branch's own say-so: a
dry-run 3-way merge on a scratch branch first (a raw `git diff main..tip` looked alarming —
666 files, 29K deletions — because it diffs two divergent tips directly, not what a real merge
produces; the actual merge base was 21 commits back and the real merge was clean, 21 files,
+970/-14, zero conflicts, every file from this session's own prior work still present
afterward). Merged for real, static-gate verified, pushed (`1de306d`).

Its own `docs/VISUAL_PASS.md` (added by the merge) named one real gap: the Settings screen's
"Graphics Tier" dropdown already called `SettingsManager.set_graphics_tier()`, but nothing
downstream ever read `assets/config/visual_quality.tres`'s low/medium/high preset — the
dropdown changed shadow/texture/fps/resolution tiers but never touched the environment
(tonemap/glow/fog/SSAO). Wired that one seam in `world_env_setup.gd` (`77d11ac`): applies the
preset on boot and live on `EventBus.settings_changed`, in the doc's own stated order (preset
first, per-district LUT/postfx refine after, unchanged). Scoped to just this seam — the doc's
full W1-W10 spec (materials, particles, per-district light multipliers, UI transitions,
ThemeProvider parity) is real future work, most of it needing on-device visual verification this
session structurally cannot do (headless-only policy) and several of its own values are
explicitly flagged "blind-tuned, VERIFY ON DEVICE" by the branch that wrote them — not something
to wire blind in bulk without a way to see the result. A known pre-existing gap this pass did
*not* fix (flagged by the doc's own author, not new): `district_scene_factory` builds a second,
separate `WorldEnvironment` for procedural districts, so this seam's tier-apply may not reach
that one in every gameplay scene — needs unifying onto one `WorldEnvironment`, out of scope here.

Added a real headless-safe regression gate for two of this task's checklist items rather than
declaring them blocked: `settings_persist_probe_scene.tscn` proves (a) the tier switch reaches
the live `Environment` (glow_intensity 0.40→0.55, SSAO false→true measured across Low→High) and
(b) an accessibility setting (`high_contrast`, `text_size`) survives a real
`save_to_cfg()` → fresh `SettingsManager` → `load_from_cfg()` round trip — the same path a real
app restart uses, no window needed since both are pure state reads. Now gate #26 in
`tools/check.sh`, passing. **Still genuinely blocked**: 8 canonical screenshots in
`docs/stills/` — `tools/qa_sim/capture_stills.gd` exists and its headless no-op path is
verified, but actually producing PNGs needs a windowed run, which the standing headless-only
policy doesn't allow this session to do. `docs/stills/` has 0 files; not fabricated as done.

## Tried and reverted twice: routing the bot's spine navigation through a NavigationAgent3D (2026-09-16)

The persistent spine-phase softlocks (see the 10-seed table below) come from the bot's
straight-line-to-target movement having no real obstacle routing, only a sideways "nudge" when
fully stopped. Two separate attempts at a real fix, both reverted:

**Attempt 1 — unconditional routing.** Give the bot its own `NavigationAgent3D` (same navmesh
`base_monster.gd`'s enemies already path through) and route pickup/switch approach through
`get_next_path_position()` instead of a raw direct vector, for every tick. **Made it worse, not
better, on all three seeds re-tested** (8, 9, 10 — the ones that softlocked in the 10-seed
sample below): all three now failed at 0/11 or 1/11 districts (vs. 1/11, 3/11, 8/11 before) —
`0/3 seeds won, 3 softlock(s)`, every one earlier than its pre-fix failure point.

**Attempt 2 — escalation-only routing.** Suspecting attempt 1's problem was querying an async
`NavigationServer` path the same frame it was requested, tried a narrower version: only switch
to nav-agent routing after the bot's existing stuck/nudge cycle had already failed 3 times in a
row (several real seconds of settle time first), leaving normal movement untouched otherwise.
**This genuinely fixed what it targeted** — re-tested on seeds 8/9/10: all three now reached
11/11 districts (up from 1/11, 3/11, 8/11), one of them (seed 9) an outright win, with the
other two's only remaining failure moved to the already-known boss-phase attack-stall, not
navigation at all. But re-testing seeds 1-7 to check for side effects on previously-reliable
seeds **found a real regression there instead**: seed 1 (which had won every single time it
was run this session) softlocked in the spine for the first time, seed 3 (also always a win)
softlocked too, and seed 4 got worse (used to reach 11/11 and only stall in the boss fight, now
stalled at 1/11 in the spine). Net effect across the full 1-10 range: negative, not positive —
reverted.

Root cause not diagnosed for either attempt. Whoever tries this again should retest the full
seed 1-10 range (not just the seeds that were already failing) before trusting any fix — this
mechanism has now twice looked like an improvement on a narrow slice and turned out to be a net
regression on the fuller picture.

## Boss winnability — the bot wins for the first time this session (merged 2026-09-15)

This session's own six fixes (below) and a parallel arena-platform pass (`arena/01a09aec-igra`,
PR #17) both chased the same goal from the same starting point (`aea3743`) without knowing
about each other, and largely found *different* bugs. Merged together 2026-09-15. The arena
pass's own record claimed 2/3 seeds won on its branch alone (see the superseded entry below,
kept for the record) — that number was **not** carried forward as true for the merged code;
instead the bot was re-run for real on the actual merged tree, twice: a first 3-seed check
right after merging, then a full 10-seed sample for the onboarding-timing pass below (which
needed a bigger sample anyway). The two runs used the **same seeds with different outcomes**
(seed 2 softlocked in the first run, won in the second; seed 3 softlocked in the first run,
won in the second) — the bot is driven by real-time physics/input timing, not a pure seeded
RNG, so re-running the same seed is not perfectly reproducible. Treat both runs as independent
samples of the same underlying win rate, not as two measurements of one true per-seed result.

**10-seed sample** (the primary evidence — larger and run right after the 3-seed check, same
merged code, no balance changes in between), `QA_SEEDS="1 2 3 4 5 6 7 8 9 10" bash
tools/qa_sim/autoplay_bot`, 2026-09-15:

| Seed | Result | Notes |
|---|---|---|
| 1, 2, 3, 5, 6, 7 | **WIN** (6/10) | |
| 4 | SOFTLOCK | Reached boss (11/11 districts), same mid-fight attack-stall pattern as below |
| 8 | SOFTLOCK | Spine nav flake, `residential` spine_i=1, only 1/11 districts — an early, severe case |
| 9 | SOFTLOCK | Spine nav flake, `school` spine_i=3, 3/11 districts |
| 10 | SOFTLOCK | Spine nav flake, `industrial` spine_i=8, 8/11 districts |

**6/10 seeds won.** The earlier 3-seed check (below) independently produced 1/3 — both are
consistent with a real, non-trivial win rate now existing where there was none all session
until this merge, comfortably past the "≥1 of 3" bar and inside the task's own stated fairness
band ("1–2/3 bot wins" scaled to a 3-seed batch; a 10-seed batch naturally shows more
variance). No balance tuning was attempted beyond what arrived in the merge itself — per the
task's own instructions, tuning stops once seeds are winning, and re-tuning to chase a
specific ratio across differently-sized samples would just be curve-fitting noise.

**First 3-seed check** (immediately after merging, before the 10-seed sample above),
`QA_SEEDS="1 2 3" bash tools/qa_sim/autoplay_bot`:

| Seed | Result | Wall time | Districts | Boss HP removed | Notes |
|---|---|---|---|---|---|
| 1 | **WIN** | 274.7s | 11/11 | 100% (killed, 14.9→0/800 in the final hit) | 0 deaths. First real bot win recorded this session, after every prior attempt topped out around 28.5% damage |
| 2 | SOFTLOCK | — | 5/11 | never reached boss | Pre-existing spine-navigation flake (`gas_station`, spine_i=5) |
| 3 | SOFTLOCK | — | 11/11 | 78.4% (172.95/800) | Reached and fought the boss, dealt real damage, then got stuck circling at melee range without landing further hits for 45s straight |

**The remaining boss-phase gap** (seed 3 above, seed 4 in the 10-seed sample): a new,
boss-fight-specific bot-behavior symptom, not a physics bug — `boss_dist` stayed ~2-2.5 the
whole stall in both cases, so the bot was in range but its attack loop stopped connecting.
This is the same category already named below as one of two honest paths to close 0/3 (a
smarter bot combat loop), now partially closed by the merge — the bot no longer fails to
damage the boss at all, it occasionally stalls only after landing most of a kill's worth of
hits. **The remaining spine-navigation softlocks** (2 of 4 in the 3-seed check's own class,
3 of 4 in the 10-seed sample) are the same pre-existing, already-documented bot-navigation
flakiness — unrelated to this pass's changes, and in the 10-seed sample responsible for most
of the non-wins, not the boss fight itself.

**What the arena pass added, on top of this session's six fixes below** (all real, read from
its diff against `aea3743`, not copied from its own claims):
- `_boss_keep_near_player()` in `base_monster.gd`: if the boss and player drift past 10m for
  1.5s, teleport the boss back — a safety net for P2/P3, which (unlike P1) never had a
  reposition mechanic if the bot's pathing put it out of aggro range.
- Knockback on the boss damped to 15% of the applied impulse (`apply_knockback`), rather than
  the full impulse — prevents the boss being flung out of the arena on a landed hit.
- Residual velocity zeroed whenever any monster enters `State.ATTACK` (`_change_state`) — the
  same class of drift bug as this session's P1 fix, but for the generic state machine that
  P2/P3 (and all non-boss monsters) actually use.
- `_move_to()`'s stuck-on-no-path case (target off the nav mesh entirely) now walks straight
  toward the target past 1.5m instead of freezing forever — a real gap this session's fix
  didn't touch, since the floor-reset fix only covered the already-pathing case.
- The flashlight vulnerability gate (`_update_light_exposure`) dropped its cone-angle check —
  distance + flashlight-on is now the whole gate. The autoplay bot doesn't aim its view, so
  the angle check could never pass for it; a human player's flashlight still has to physically
  point at the target since the SpotLight3D itself is still cone-shaped and only lights what
  it's aimed at, so this doesn't hand a human an obviously-different fight, just removes a
  redundant server-side re-check.
- Player-side: single-hit damage capped at 12 (`take_damage`), a 0.8s "mercy" invulnerability
  window starting on any hit taken (independent of and stacked with this session's dodge/
  revive `_iframes`), and battery drain retuned. Melee hitbox gained a second, generous 2.7m
  sphere shape alongside the resized box, superseding this session's own smaller forward-
  offset fix for the same "hitbox too short" root cause.

## The merged texture-compression pass's "≥30% smaller APK" claim is unverified, and a spot check doesn't support it (2026-09-15)

`docs/TEXTURE_COMPRESSION_REPORT.md` (from `arena/texture-optimization`, merged this pass)
extends the real, measured 74-file pilot (`docs/artifacts/texture_compression_audit.md`) to
~465 more files, but its own text says every PSNR value past the original pilot is
**"est." (projected, not measured)**, and its "Overall APK build-size reduction of ≥30%" is
explicitly labeled **"Estimated"** — the report says outright its sandbox had no Godot binary
to measure with. That estimate should not be trusted at face value: the original pilot's own
*real* measurement found the opposite of the naive expectation for this project's flat,
palette-locked art — on-disk size **increased** slightly (8.99→9.69 MiB) even though VRAM
dropped ~4x, because fixed-rate block compression doesn't beat PNG's deflate on simple,
flat-color source images.

A quick real spot check this pass (`.godot/imported/*.ctex` size vs source PNG, several
categories) is consistent with that same pattern, more severely: `ui_v2` +1976%, `icons_v2`
+839%, `items` +357%, `tiles`+`surfaces` combined +43.7% (vs. the original pilot's own +7.8%
for the same two categories — the discrepancy itself suggests this spot-check method doesn't
cleanly reproduce the pilot's more careful measurement, most likely because the dev-time
`.ctex` cache carries Godot resource-wrapper overhead a real exported `.pck`/APK may not).
`badges` was the one category that came out smaller (-40%). **Net: the real evidence is mixed
and mostly points away from "≥30% smaller," not toward it** — the true number needs an actual
APK export + diff (blocked on the Android SDK this machine doesn't have,
`docs/OWNER_RELEASE_PACKET.md` §a) before anyone should rely on it. The VRAM-reduction case
(the pilot's *real* win, and the actual motivation — protecting low-end Android devices from
texture-memory pressure) is unaffected by any of this.

## Onboarding timing: already well inside the ≤8min target, no trigger tuning needed (2026-09-15)

Telemetry (`first_interactable_seen`, `first_secret_hinted`, `first_secret_found`,
`first_district_cleared`) was already wired into `scripts/tools/_qa_autoplay_runner.gd` from an
earlier pass; this pass ran the real 10-seed sample it was waiting on
(`QA_SEEDS="1 2 3 4 5 6 7 8 9 10" bash tools/qa_sim/autoplay_bot`, same run used for the
winnability table above):

| Metric | Median | Notes |
|---|---|---|
| First interactable seen | 5.1s | |
| First secret hinted | 9.95s | The game's own trigger — this is the metric "tune existing triggers" would actually move, and it's already ~48x under the 480s (8min) target |
| First secret found | 113.6s (**among the 5/10 seeds that found one at all**) | 5 of 10 seeds never found a secret in-run: `-1.0`. Not a trigger-timing problem — the bot doesn't seek secrets, it only stumbles onto one opportunistically while pathing to its real objective (an already-documented bot-behavior gap, see the winnability entry above and "Autoplay bot" below). Even the found-cases' median is 4x under target |
| First district cleared | 17.45s | |

**No trigger tuning was attempted** — every measured median is already far inside the ≤8min
target, so there was nothing to tune. The only honest gap is `first_secret_found`'s 50% miss
rate, and that's a bot-capability gap (it would need the bot taught to seek secrets, which is
out of scope for "tune existing triggers, no new popups"), not evidence the game's own hint
timing is slow.

## The autoplay bot still wins 0 of 3 seeds — but six real boss-fight bugs behind that number got fixed (2026-09-14)

`bash tools/qa_sim/autoplay_bot` still reports **`0/3 seeds won`**. Do not read that as "no
progress" — the fight underneath that number went from an instant, unwinnable spiral to a
stable, safe fight that deals real damage. Chasing the bot's winnability found and fixed six
genuine defects, none of them balance numbers:

1. **`revive_player()` had no grace window.** It dropped the player back at half HP standing
   next to the boss; the next ranged hit (every 2-3s) killed them again, in a loop that
   consumed the entire 240s fight without landing a single melee swing.
2. **Dodge invulnerability was completely broken.** `_iframes` counted down but `take_damage()`
   never checked it — dodging through an attack never actually avoided the hit, for any enemy,
   not just the boss. One guard (`player_3d.gd`) fixes both this and #1: `revive_player()` now
   calls the same `grant_iframes()` for a 2s grace period.
3. **The boss's documented weakness was unreachable by the only automated player.** GDD §6.2
   lists "стробоскоп" (the strobe) as the Architect's weakness, but strobe only ever fired from
   a raw `"strobe"` input action — nothing driving through `InputService` (the bot's only
   interface) could trigger it. Added `InputService.request_strobe()` alongside the existing
   `request_attack`/`request_dodge`/etc.
4. **P1 was immune to the stun the strobe applies.** P2 and P3 both check
   `ai_state == State.STUN` and pause; P1 never did, so a landed strobe froze the model in
   place while its ranged attacks kept firing on schedule anyway.
5. **A long P2 chase could send the boss falling through the floor, forever.** `_move_to()`
   added gravity to `velocity.y` every call and never reset it on landing — the standard
   `CharacterBody3D` gotcha. Harmless for a short chase, but P2's invisible pursuit can run
   long enough for it to accumulate past what floor collision arrests in one step. Measured:
   the boss's Y went from 1 to -166 over 25 seconds and never came back.
6. **The melee attack hitbox was never offset from the player's own origin**, so it only ever
   reached about 0.3m past the player's own body — short of a boss standing at the ~1.8m the
   combat AI naturally holds. Measured landed DPS was roughly a tenth of the combo system's
   theoretical output before this was fixed.

**What the fight looks like now:** stable position (no more drift or floor-fall), zero
deaths across every post-fix run, and real sustained damage — up to **28.5% of the boss's
800 HP dealt within the 240s window** in the best observed run. Still short of a kill, and
still not a win. Two more runs never even reached the boss phase, softlocking earlier in the
spine (`suburbs` at spine_i=0 in one run, `gas_station` at spine_i=5 in another) — this is
pre-existing bot-navigation flakiness, not a boss-fight regression: the bot's movement is a
naive direct-vector-to-target with no real pathfinding, and it has intermittently stalled in
different districts across many runs this session regardless of which code was under test.

**What would close the remaining gap:** the ceiling now is raw damage throughput, not
survival — the bot never dies anymore, it just runs out of clock. Two honest options, neither
attempted this pass: (a) teach the bot a better combat loop (sustained combo uptime, using the
strobe-stun window specifically to land free hits, maybe throwing a FIRE-type item the boss
resists far less than the BLUNT its combo deals), or (b) a real difficulty pass on the boss's
`armor`/`resistances` (`scripts/enemies/enemy_roster_data.gd` `&"beast"` entry — these are
implementation details, not specified by the GDD's own stat table, so they're a legitimate
tuning target). Don't just inflate combo damage numbers to force a bot win without a human
confirming the fight still feels fair — see item below on why a human playtest still matters
here.

**Consequence for release claims:** the project does **not** currently have an automated
winnability proof. The game is bot-verified playable, safely, up to and through a real boss
engagement, and no further. Any statement that a bot run proves the Truth ending, or proves
the game completable, remains unsupported. What changed today is that the remaining gap is
now demonstrably about combat throughput, not about the bot instantly breaking on contact
with the boss.

### Superseded record: the arena pass's own "2/3 seeds won" claim (`arena/01a09aec-igra`, 2026-09-13)

Kept verbatim for the record, **not verified against the merged code** (see the entry above
this one): `QA_SEEDS=3 bash tools/qa_sim/autoplay_bot` on that branch *alone* reportedly gave
**2/3 seeds won** (seed 1: WIN, boss fight ≈66s; seed 2: WIN, boss fight ≈63s; 0 deaths in
both; third seed softlocked in spine navigation, unrelated to the boss). That branch never
had this session's own six fixes underneath it, and this merge stacks both fix sets — the
combined result has not yet been measured for real. Its fix list (NG+ knobs wired end-to-end,
battery drain tuned to 100/450 per second, player durability changes, boss-side knockback/
velocity/pathing fixes) is folded into the bullet list in the entry above, restated from the
actual diff rather than from this claim.

## arena/card-unique-rescue delivered no card art — the 4-of-22 duplicate-photo defect is still open (2026-09-13)

**Status update (2026-09-14): RESOLVED — 11/11 districts have unique card
art, and the textures are shipped in-game.**
The seven new photographs (park, school, hospital, gas_station, police,
warehouses, substation) were generated from the `docs/CARD_ART_BRIEF.md` §4
prompts, graded through `scripts/regen_cards_v2.py` — **all 8 validation
checks PASS for all 7 districts** (per-image report summarized in the
`feat(art): generate + grade 7 unique district cards` commit message) — and
committed to `content/cards/` (1024×1536 masters) with 512² twins in
`content/cards/twins/`.
Then shipped: the seven duplicate-photo textures in
`assets/textures/cards/` were replaced with the new unique twins and the
matching `_locked_512` variants were regenerated deterministically
(`scripts/make_locked_cards.py`: per-pixel RGB affine OLS-fit on the 4
keeper pairs, flat accent×0.6 border, seeded grain 0.01 — two full runs are
byte-identical); `docs/artifacts/art-final/cards_contact_sheet.png` was
rebuilt by `scripts/make_card_contact_sheet.py`. No GDScript change was
needed — `scripts/ui/collection_ui.gd` already loads cards by name
(`res://assets/textures/cards/card_<district>[_locked]_512.png`).
Final audit of the shipped set (`scripts/audit_card_clusters.py --images`
on the 11 shipped unlocked cards): min cross aHash Hamming **13** (floor
8), MAD 20.5–27.7, k-means(k=11) → 11 singleton clusters. One frozen
remnant: the suburbs/residential **keeper** cards remain a near-twin pair
(aHash h=1, MAD 1.01 — both ship `hero_first_restore` per
`LEDGER_ARTFINAL.md` L4); closing it requires regenerating a keeper card,
which stays out of scope (keepers are frozen).
The pipeline and gate from the 2026-09-13 update stand as documented in
`docs/CARD_ART_BRIEF.md` (now with the saturation-rolloff and palette-lock
grade stages, §6) and still reject card-art commits/PRs with zero changes
under `content/cards/`.

The branch `arena/card-unique-rescue` (tip `b1d7830`) was commissioned to fix the known
defect where 4 of the 22 district collection cards share a base photo and do not depict
their own district. It was **rejected, not merged**, because it does not contain the fix it
certifies. Evidence, all reproducible:

- `git ls-tree -r main -- assets/textures/cards/` and the same command against the branch
  produce **byte-identical listings** — same 22 filenames, same 22 blob SHAs. Not one card
  image was changed. `git diff --name-status` lists only 4 paths, none under
  `assets/textures/cards/`.
- The branch's `docs/CERT_ARTFINAL.md` claims four named cards were regenerated with
  distinct scenes, claims the locked variants match spec, and asserts "Scene match: 22/22
  (100%) — independent verify-agent read". The blob hashes disprove all of it.
- It would also have been a **regression**: its `cards_contact_sheet.png` replaces the real
  1024×1536 contact sheet (the only artifact that makes the defect visible) with a single
  512×512 card image, and `cards_contact_sheet_48.png` is a lone 48×48 thumbnail rather
  than a 48px legibility sheet.
- `scripts/regen_cards.py` could not have produced the fix even if run: it reads
  `card_<d>_512.png` and writes the same path applying only a blue-channel multiply and
  `-auto-level` — a tint cannot change what a photograph depicts — and its locked path
  colorizes 100% to flat `#0c1016`, which would yield a solid near-black rectangle. It also
  hardcodes `cwd="/home/user/igra"`, so every subprocess call fails on this machine and the
  script exits 0 having done nothing.

**Status: RESOLVED 2026-09-14** (status update at the top of this entry —
11/11 districts ship unique card art, textures in `assets/textures/cards/`).
The two cautions below remain valid. Do not re-merge the rejected branch;
do not relocate `regen_cards.py` into `tools/` — it is broken and unreferenced.

**The defect is substantially worse than "4 of 22" as previously recorded.** A measured
visual audit (average-hash Hamming distance plus mean-absolute-difference on 32×32
greyscale, all 55 unlocked pairs) found the 11 unlocked district cards reduce to just
**4 distinct base photographs**:

| Cluster | Hamming | MAD |
|---|---|---|
| suburbs / residential / park | 0 | 1.06–2.93 |
| school / hospital / gas_station / police | 0–1 | 2.1–6.2 |
| warehouses / industrial | 0 | 1.07 |
| substation / power_station | 0 | 1.06 |

The nearest cross-cluster pair (hospital/industrial) jumps to Hamming 9 / MAD 16.1, so the
four clusters are a real separation and not a threshold artifact. Locked variants are clean —
each hashes against its own unlocked twin only, the difference being darkening rather than
structure. So **all 22 card files represent 4 photographs for 11 districts**, and 7 districts
need genuinely new photography. Previous entries describing this as "4 of 22 share a base
photo" understated it.

## The 155 formerly-English content strings are now translated in all 12 non-English locales (2026-09-13)

The secrets/daily/NG+/caption content wave left 155 keys holding English
placeholder text in ru, es, de, fr, it, pt_BR, tr, ja, ko, zh, zh_TW and ar
(52 `SECRET_*`, 60 `DAILY_*_FLAVOR`, 28 `CAPTION_*`, 14 `NGP_*`, `TUT_JOURNAL`).
They are now authored in every non-English locale in the established Keeper
voice, reusing the glossary of the existing `secret_found_`/`district_`/
`achievement_` strings. `NG_PLUS_LABEL` ("NG+ %d") deliberately stays identical
everywhere — "NG+" is universal. Parity is unaffected (1265 keys × 13 locales,
`i18n_audit` MISSING: 0), and the strings still identical to English are the
intentional cognates listed further down plus `NG_PLUS_LABEL`.

## Secret placement uses seeded scatter, not the authored zones (2026-09-13)

`content/secrets.json` gives every secret a `zone` (`"z_maple_row"`) and a prose
`location_hint` ("base of the third lamp pole, behind the trunk"). The 3D districts carry
**no named zone markers** — `zone` exists only as authoring vocabulary shared with
`content/districts/<id>/item_spawns.json`, and nothing in the scenes resolves those names to
positions. So `DistrictLoot._spawn_secrets()` places each secret by the same deterministic
seeded scatter used for all other loot, seeded per secret id so the spot is stable across
runs and across players in LAN, at a wider radius than ordinary loot.

Consequence: a secret is findable and stable, but it is not *where its text says it is*, so
the location_hint prose currently describes fiction rather than geometry. Closing this needs
named zone marker nodes in the district scenes that `_spawn_secrets` can look up by name.

## All 11 NG+ modifier knobs now wired (updated 2026-09-16)

`content/ngp_modifiers.json` defines 11 effect knobs. This entry previously claimed 4 were
live and named `loot` as one of them — that was wrong: `get_loot_chance_multiplier()` existed
but had zero call sites anywhere in `scripts/`, so picking `whisper` changed nothing at all.
Corrected count as of the 2026-09-14 pass: 7 of 11. The 2026-09-15 pass added three more
(10 of 11). This pass closes the last one:
- `battery` (flashlight drain, `player_3d.gd`), `hunter_hearing` (detection radius,
  `noise_propagation.gd`), `achievements` (no-ops `AchievementManager.unlock()`), `loot`
  (`base_monster.gd::_maybe_drop_loot()`), `lore` (secret-found XP grant, `xp_manager.gd`),
  `rewards` (all three coin payouts, `rewards_manager.gd`), `hints` (onboarding hint toggle,
  `onboarding.gd`) — all pre-existing as of 2026-09-14.
- `crawlers_ignore` — arrived wired from the `arena/01a09aec-igra` merge
  (`base_monster.gd::_can_see_player()`, Crawlers skip aggro entirely).
- `cycle` — wired 2026-09-15 into `day_night.gd`'s `day_duration_sec` (`call_deferred`, since
  `DayNight` initializes before `NewGamePlus` in the autoload order and would otherwise always
  read the neutral 1.0 default).
- `time_pressure` — wired 2026-09-15 into `daily_events_ui.gd`: gates whether the already-
  running event countdown actually displays a ticking clock (`00:00`→hidden without it), rather
  than gating the event/bonus mechanic itself, so non-NG+ play is unaffected either way.
- `extra_dark_districts` — wired this pass, but not where the modifier's own text implies.
  Its literal premise ("one extra district starts DARK") doesn't hold against the codebase:
  `PowerGrid.reset()` already sets **all 11 districts** to `Stage.DARK` on every new game, so
  there's no "starts lit" baseline to subtract from — inventing one would mean building a new
  mechanic nobody asked for. But the modifier is literally *named* "Blackout+", and the game
  already has a real blackout mechanic: `scripts/systems/random_events.gd` periodically fires
  one of four random events, one of which (`Ev.BLACKOUT`) darkens a random non-FULL district
  for 15s (`EventBus.district_blackout`, consumed by `streetlight.gd`'s city-map icon). Wired
  the knob into that instead: a blackout event now hits `1 + extra_dark_districts` districts
  instead of always exactly 1 — the real mechanic the modifier's name and "no mercy" framing
  actually point at, reusing existing infrastructure rather than adding new gameplay.

## district_grading.gd's Environment branch is dead code (found 2026-09-12, wiring LUTs)

While wiring the 2026-09-12 arena visual pass's 11 per-district color-correction LUTs into
`WorldEnvironment`, found that `scripts/world/district_grading.gd` (the script the LUT
README and `docs/VISUAL_AUDIO_SPEC.md` both name as the intended wiring point) never
actually runs its Environment-mutation branch (fog/sky/ambient/tonemap — `_apply()`'s
`if _env != null and _env.environment != null:` block). Its only instantiator,
`scripts/world/world_bootstrap.gd` `_wire()`, dynamically creates the `Grading` child node
per district but only sets `district_root_path`, never the `@export var
world_environment_path` the script needs to find its WorldEnvironment — so `_env` is always
`null` and the whole branch (per-district fog color, sky background, ambient tint,
FILMIC tonemap) has been a silent no-op since it was written. The only visible effect that
ever shipped from `district_grading.gd` is its separate `_apply_ground()` floor-tint call
(guarded by `_root`, not `_env` — that one does run).

**Why not fixed by wiring the missing NodePath:** a second, genuinely live system already
owns the same WorldEnvironment resource — `scripts/world_env_setup.gd` (attached to the
main scene root) sets ambient/fog/tonemap once in `_ready()` and re-drives
`ambient_light_color`/`ambient_light_energy`/moon/player-glow per **stage** (DARK/LIT/FULL)
on every `district_stage_changed`, using one fixed palette for the whole game, not a
per-district hue. Simply pointing `district_grading.gd` at the real WorldEnvironment would
make two systems fight over `ambient_light_color`/`fog_color`/`tonemap_mode` on every stage
change — a worse, flickering bug. Whether districts should carry their own fog/sky hue (not
just LUT grading + floor tint, which do work today) is a design call, not a wiring bug fix,
so it's left alone here.

**What was actually wired instead:** the 11 LUTs go into `world_env_setup.gd` — the real
live WorldEnvironment owner — as `Environment.adjustment_color_correction`, keyed by
`EventBus.district_entered` (`_apply_lut()`, filename = `lut_<district_id>.png`, no table
needed). This is genuinely live and does not conflict with the stage-based ambient system
(different Environment properties).

**If someone wants full per-district fog/sky/ambient later:** decide whether that should
override or blend with `world_env_setup.gd`'s stage palette, then either delete
`district_grading.gd`'s dead branch or wire `world_environment_path` to the real node and
make the two systems cooperate (e.g. `district_grading.gd` sets fog/sky/tonemap only,
`world_env_setup.gd` keeps owning ambient/moon/glow).

## Autoplay bot (FINAL HARDENING PASS, 2026-09-12) — ROOT CAUSE FOUND AND FIXED; boss fight remains a skill gate

`tools/qa_sim/autoplay_bot` + `scenes/tools/qa_autoplay_scene.tscn` drive
the game with **simulated inputs only** (joystick move, look/aim,
interact, attack, dodge, City-Map Travel, Save/Continue) while reading
real state.

**The actual root cause of every prior session's ~8s world-teardown,
finally traced:** `scenes/main_3d.tscn` embeds a `Splash` child
(`splash.tscn` / `scripts/splash.gd`) that, **unconditionally**, ~3
seconds after `main_3d.tscn` loads, fired `Routes.goto(Routes.BOOT)` —
destroying the entire game world and routing back through
`boot_loading.tscn` to the main menu. No guard existed anywhere. Confirmed
with a one-off diagnostic print: the redirect landed at **t=7.87s**,
matching the "~8s after New Game" figure every prior session's own
observations independently converged on, exactly. **This was never a
test-only artifact — a real player hits it too, identically, every single
new-game session past the ~8s mark.** It went uncaught for the same
reason `docs/HONEST_ASSESSMENT.md` names as this whole repo's headline
risk: no session, agent or human, had ever played past that point with
eyes on the result. Fixed (`84cd280`): ported the exact
`GameManager.is_playing()` guard the dead, never-wired sibling
`scripts/ui/splash.gd` already had into the file actually instanced.

**A second real bug found chasing the bot further once the world stopped
being destroyed:** the player has no recovery if it ends up below the
world (a hole in a district's procedurally-generated street geometry —
reproduced concretely in the school district). No `Y` floor, no fall
timeout, nothing — a fallen player free-falls forever. Fixed (`85af9f9`):
a time-based guard (3s continuous `is_on_floor()==false`) teleports back
to the last grounded position.

**A third real, severe, previously-shipped bug found investigating why
the bot's flashlight died mid-fight despite carrying batteries:** using
*any* consumable (medkit, battery) from *any* inventory UI
(`character_screen.gd`, `hud_3d.gd` quickbar, `inventory_ui.gd`,
`quick_wheel_ui.gd`) has always routed through
`InventoryManager.use_item()` → `EventBus.item_consumed`, but the only
listener that applied the actual heal/recharge effect lived on
`scripts/player/player.gd` — a legacy script **never instanced by
`player_3d.tscn`**, the real 3D player. Consuming a medkit or battery
silently removed it from inventory and did **nothing else, for every
player, in every build, until now.** Fixed (`85af9f9`): ported the exact
dispatch to the live script.

**Net result:** the bot went from **0/11 districts, dead at ~8s, every
single run** (the state every prior session documented) to **11/11
districts FULL in the clear majority of runs** — the district spine has
never cleared headlessly before this pass. Combat, revives, and the real
final-boss engagement (the Architect) are all reached and function with
genuine simulated input (no state injection).

**What's still not won:** the boss's P2 phase (`scripts/enemies/
boss_3d.gd`: "invisible in dark") requires the player's flashlight cone
actually on the boss (`base_monster.gd` `_is_in_flashlight`, a real
angle+distance test) — the bot never simulated look/aim input at all
before this pass (movement + action buttons only), so P2 was permanently
unwinnable regardless of the fixes above. Added `_face()` (aims via the
same `_apply_look` real mouse/touch look drives — simulated input, not a
warp) and `_maintain_flashlight()` (battery management) to the bot
(`8f5925e`), but a handful of runs after both fixes still didn't land a
win — the boss may kite/reposition in a way the bot's simple
approach-and-attack loop can't close on, which is now a bot-sophistication
gap, not a lifecycle bug. **Also newly visible now that the spine can be
reached at all:** roughly 1-in-3 runs still fail *early* (suburbs/
residential, before the fixed bug would even apply) with the same
SOFTLOCK signature — not investigated this pass (budget), plausibly
physics/navigation timing variance rather than a fixed bug, since retries
of the identical seed produce different failure points. Flagged for a
future pass, not the blocker this one targeted.

**Owner real-device/editor playtest remains the authoritative winnability
check** — tracked in `RELEASE_CHECKLIST.md` — but the headless evidence
bar just moved enormously: from "the world cannot survive 8 seconds" to
"the whole game is headlessly completable except the final boss fight."

## Verification policy: headless-only Godot ALLOWED since 2026-09-10 (GOLD MASTER)

The owner lifted the absolute NO-GODOT constraint to **headless-only**:
`godot --headless` non-interactive script/scene runs are now allowed and
required for verification. Still banned: `--windowed`, the editor GUI,
any visible window, window-opening probe scenes. The gate is
`tools/qa_sim/headless_suite` (engine gate scenes each with a per-gate
timeout + `scenes/tools/qa_headless_suite_scene.tscn`). The
`tools/qa_sim/*.py` static sims below stay valid and still run — they now
back up the headless suite rather than replace it. Logs: `.qa_logs/`
(untracked).

First headless run found and fixed 4 latent regressions that static
checks structurally cannot see (commit `f3bd1e3`): a `var`/`func` name
collision that killed the `WowDirector` autoload, `LOOT_SCRIPT.populate`
not dispatching through a `Script`-typed const (zero loot spawned in any
district), and two `:=` type-inference errors that cascaded compile
failures on a cold parse.

### `game_test_3d_scene` phase 1+ stalls intermittently under --headless

Its phase 0 (player / monsters / **pickups: 12** / fuel-item constant)
passes reliably and is also covered by `headless_suite` P2/P2b. Phases
1–8 (combat / inventory / battery / generator / boss / death) hang
intermittently in the phase-1 combat step (`take_damage` on a monster
inside `main_3d` — physics/nav timing under the dummy renderer); no
script error, `_process` just stops ticking. Pre-existing (the scene
predates this pass). Mitigated: a 150 s hard-timeout-as-FAIL + real exit
code (`quit(fails)`) added so it can never hang CI. Substitute coverage:
`headless_suite` P2b (combat damage in isolation — passes every run) +
`tools/flow_check.py` (combat/inventory/battery/death signal wiring).
Run the scene manually for the fuller smoke.

### `headless_suite` P6 soak ends at ~10 s (test-runner MENU race)

A gate scene that boots past `boot_loading.tscn` makes the splash/
bootstrap fallback and the natural scene load contend for the first
scene swap; the loser periodically fires `Routes.goto(BOOT)` /
`return_to_menu()`, so sustained gameplay started from a test scene
drops back to MENU after ~10 s. This is the **same** artifact the
PERMANENT gate `_boot_check_runner.gd` documents and tolerates. Real
players always boot through `boot_loading.tscn` and never hit it. P6
logs it and ends the soak clean (no fail), same stance as boot_check.
Net: the "10-minute soak" is capped at ~10 s of in-engine sustained
play; the rest of the soak intent is covered by the crash-safety static
sweep (`STATIC_AUDIT` #38–42, all 20 JSON/FileAccess sites) and the
`boot_check_scene` 60 s sustain.

## NO-GODOT verification substitutes (MEGA FINAL POLISH, 2026-09-10)

This pass ran under an absolute no-engine constraint. The engine-launching
gates were replaced with static equivalents, all committed under
`tools/qa_sim/`:

| Engine gate | Static substitute |
|---|---|
| `game_test_3d_scene` / compile smoke | `tools/check.sh --static` (10/10) + `flow_check.py` + `scene_node_check.py` + manual re-read of every edited function |
| endings reachability (would need a playthrough) | `tools/qa_sim/endings_sim.py` — walks the reachable state space from the district DAG |
| PARTIAL vs DARK visual diff | `tools/qa_sim/lighting_stage_sim.py` — tabulates the per-stage light/colour values |
| puzzle-economy reachability | `tools/qa_sim/puzzle_economy_sim.py` — resolves every id against real `start_puzzle()` callers |
| i18n text-overflow in-scene | `tools/qa_sim/overflow_check.py` — locale-length ratio × container width |
| accessibility toggles apply | `tools/qa_sim/a11y_check.py` — traces each setting key to a real effect |
| `perf_check_scene` draw calls | `tools/qa_sim/drawcall_estimate.py` — structural estimate + exact active-light before/after |

`perf_check_scene.tscn --windowed` still needs one owner run for the real
`RENDER_TOTAL_DRAW_CALLS_IN_FRAME` number (see the draw-calls entry).

## District `powered_by` graph branches; GDD §4.1's chain text is narrative order, not a literal dependency spec

`data/districts/*.tres` forms a branching, reconverging DAG (e.g.
`industrial` requires BOTH `warehouses` AND `police` at FULL), not the
single arrow-chain GDD §4.1 lists. `school` and `gas_station` are leaves
of this graph — nothing lists them as anyone's prerequisite. Verified
2026-09-08 (`docs/STATIC_AUDIT.md` #21): this predates any recent
session's work, and victory still requires all 11 districts at FULL
regardless of graph shape, so a leaf district isn't a completion bug,
just one that gates nothing downstream. Do not "fix" `powered_by` to
match a strict chain — the content team's `world_refs` reveal-gate
closures (`docs/CONTENT_PIPELINE_AUDIT.md` §3.4) are computed against
the real branching topology; forcing a linear chain would invalidate
them.

## `industrial_dark.ogg` is 33.994 s, not the shipped 36.000 s house contract — accepted as intentional

Every other district's dark ambience bed (10 of 11) plus all 3 shipped
lit beds (`suburbs`/`hospital`/`residential`) measure exactly 36.000 s
(Ogg granule 1,587,600 @ 44.1 kHz) — independently re-verified
2026-09-09 by parsing the Ogg container's final page granule directly
(no ffmpeg needed): `industrial_dark.ogg`'s last granule is 1,499,146,
giving 33.994 s exactly.

Accepted as **deliberate, not a defect**: `tools/gen_audio.py`'s
`DISTRICTS` canon sets industrial's theme to 85 bpm / 12 bars, and
12 bars × 4 beats ÷ 85 bpm × 60 = 33.882 s — within 112 ms of the
shipped 33.994 s (consistent with normal OGG frame-alignment padding
at encode time, not a random mis-render; 36 s at 85 bpm would be a
non-whole 12.75 bars, which the generator correctly declined to
produce). No code hardcodes the 36 s assumption anywhere
(`music_manager.gd`'s loop handling is duration-agnostic, driven by
the actual resource), so there is no functional risk either way. The
still-unfabricated `industrial_lit.ogg` (spec `docs/AUDIO_COVERAGE.md`
G2h) must match this bed's real length (33.994 s), not the generic
36 s, for `MusicManager`'s crossfade to land cleanly — already
specified correctly. Re-rendering the dark bed for contract uniformity
would be a valid alternative but is out of scope for this decision:
`assets/audio/**` is Arena's ownership zone, not code's, and NO-GODOT
mode's static-only verification is not a reason to fabricate binary
audio myself. Decision recorded in `PLAN.md`'s decisions log
(2026-09-09, PR #6).

## Two power_station audio one-shots are off the 30.000 s detail-bed class — not blocking

`power_station_generator_thrum.ogg` (28.749 s) and
`power_station_cooling_fan.ogg` (28.948 s) are shorter than the
30.000 s every other district's detail one-shots hold exactly —
independently re-verified 2026-09-09 by the same direct Ogg-granule
parsing used for the `industrial_dark.ogg` finding above. Both loop
(`loop = true` in `district_atmosphere.gd`) and no code reads or
assumes a detail-bed duration anywhere, so there is no functional
risk. Same reasoning as the industrial bed: `assets/audio/**` is
Arena's ownership zone, re-rendering (if wanted for consistency) is
the audio toolchain holder's call, not code's. Full reasoning:
`docs/STATIC_AUDIT.md` #32, Arena's `docs/CONTENT_PIPELINE_AUDIT.md`
finding F1.

## `WorldBible.is_revealed()` doesn't distinguish "district exists" from "district visited"

`scripts/world/world_bible.gd`'s `is_revealed(reveal)` checks
`DistrictManager.get_stage(district) >= min_stage`. Every district
defaults to stage `DARK` (0) whether or not the player has ever been
there, so a `min_stage: 0` reveal is trivially "revealed" for an
unvisited district — the check verifies stage progression, not
visitation. Not a live bug today: content authoring discipline
(`content/README.md`'s reachability rule, `docs/CONTENT_PIPELINE_AUDIT.md`
§3.4) is what actually keeps `world_refs` from leaking early across all
6 shipped district packs, not this primitive. Flagged so a future pack
or UI feature doesn't lean on `is_revealed()` alone for "has the player
been here" — it doesn't mean that. Found 2026-09-08 while reviewing
Arena's own `park_note_05` fix (`docs/STATIC_AUDIT.md` #24).

## `scripts/world/puzzle_base.gd` — dead fossil, wrong node type for this 3D game

Found in the 2026-09-08 static audit (`docs/STATIC_AUDIT.md` #16).
`extends Area2D`, calls `PowerGrid.toggle_district(district_id)` — the
only other live call site of `toggle_district()`/`toggle()` besides
`power_grid.gd` itself, and the mechanic GDD §4.3 still documents
("Переключатели `PowerSwitch` и пазлы: `toggle_district` = STREETS ↔
DARK"). Confirmed unreachable: `scenes/props/puzzle.tscn` (its only
scene) is never instanced anywhere. Even revived it would need `Area3D`/
`StaticBody3D` collision like `power_switch.gd`, not `Area2D`, to
receive any interaction in this project's 3D interact system. Same
treatment as the already-documented `streetlight.gd`/
`streetlight_spawner.gd` fossils below: not deleted (CLAUDE.md: never
delete a file unless proven dead *and* not a planned feature), flagged
so nobody assumes it's live.

## `godot --headless --editor --quit` corrupts `default_bus_layout.tres` on resave — never commit after running it

Needed once this pass to force a `global_script_class_cache.cfg` rebuild
(a brand-new `class_name` isn't visible to other scripts/gates until the
editor rescans the project — a plain `--headless --path . --quit` run
does NOT trigger this, only `--editor` does). Side effect: the editor
resaved `default_bus_layout.tres` on exit and silently corrupted it —
dropped the entire Master bus block, dropped `room_size` from the reverb
effect, and mangled the resource's own `uid` (`audiobuses00` →
`udiobuses00`). Caught only by manually diffing the file before
committing — no gate currently checks bus layout content, only that the
5 expected buses exist by name. **Always run `git diff
default_bus_layout.tres` (and ideally a full `git status`) after any
`--editor` invocation, before staging anything.** `git checkout --
default_bus_layout.tres` reverts it cleanly since flow_check's own bus
gate doesn't need the class cache and passes either way.

**2026-09-12 addendum:** confirmed `--import` triggers the identical
corruption, not just `--editor` — ran `godot --headless --path . --import
--quit` to materialize `.import` files for the arena visual/audio pass's
new assets (LUTs, screenshots, ogg beds), and got the exact same
Master-block/`room_size`/uid damage on `default_bus_layout.tres`. So the
rule is: **any** headless invocation that does a project-wide reimport or
class-cache rebuild (`--import`, `--editor`) is suspect, not just
`--editor` specifically. Reverted with the same `git checkout --` before
committing.

## `game_test_3d_scene.tscn` gate stalls silently after "phase1 combat: damage Shadow"

Pre-existing, not a regression — reproduced identically on a clean stash
of the working tree (before any 2026-09-08 RC-pass edits) and on `main`
with those edits applied. `--headless` hangs until killed (`timeout`
exit code 124); `--windowed` exits cleanly (code 0) but the test runner
never prints its `DONE`/`fails=` line past that point — no script error
in the log, just engine shutdown/leak noise. Combat/damage-on-Shadow is
unrelated to any RC-pass change (i18n, HUD, settings, document catalog).
Not investigated further this pass (would need `--verbose`/a debugger
attached to see what phase1's coroutine is actually waiting on); `tools/
check.sh`'s full (non `--static`) mode will hang here too — run the other
11 gate scenes individually (5 headless: compile/signal-arity/autoload-
api/i18n/asset; boot/perf need `--windowed`, same as the existing boot-
flow note below) until this is fixed.

## i18n: a few always-open-while-playing screens didn't retranslate on a live language switch

Screens toggled via `UIManager` (`.visible = true/false`) stay instantiated
for the whole session — they only rebuild their translated text if they
explicitly listen for it. `journal_ui.gd` and `hud_3d.gd` (HP/Stamina/
Battery/Noise/Visibility/Ammo/Radar/Sprint/Stealth captions) had no such
hook and went stale after Settings → Language until the scene reloaded —
fixed 2026-09-08 (both now reload their translated text on
`LocalizationManager.language_changed`). `city_map.gd` was already correct
(rebuilds on `visibility_changed`). `quest_journal.gd` and
`skill_tree_ui.gd`/`skill_button.gd` had the same gap (tab titles, skill
name/description/cost) — fixed 2026-09-08 Phase 4 pass, same shape of fix
(quest_journal rebuilds like `settings_screen.gd`; skill tree reuses its
existing `refresh()` chain). All screens now cover live language switch.

## i18n: 165 strings are identical to English on purpose — do not "fix" them

`tools/i18n_audit.py`'s `value == en[key]` check still flags ~165 strings
across the 11 non-en/non-ru locales. Every one was manually verified during
the 2026-09-08 autonomous i18n wave as a legitimate cognate/loanword (e.g.
"Auto", "Park", "Normal", "AUDIO", "Journal", "Radio", the "SS-N" codes,
" kg" as an SI unit) or a deliberate loanword choice ("Speedrunner",
"Endurance" kept in de/fr/it/pt_BR) — not an overlooked gap. Full
per-string breakdown and the commit list: `PLAN.md` §Б.4. Any *new* i18n
key added after this point must be translated immediately, not added to
this list.

## Draw calls: 234 measured vs GDD's <200 (D1) / <350 (D11) — D11 met, D1 not

**Update rc14 (2026-09-27): D1 met.** Every D1 figure below (370, 234, and the later 246/253) was
taken while ScreenShake pinned the FPS camera at (0, 1.7, 0) (CORRECTION_LOG 46). From the player's
real position D1 is 168-170 and D11 175-186 draw calls, both under budget (`docs/PERF_PASS.md` §0).
Primitives, 1.34 M per frame, stay far over the GDD's 50K.

**Update 2026-09-08 (autonomous wave)**: the root cause this entry used
to describe (unbatched per-streetlight Pole/Lamp `MeshInstance3D`) was
fixed in an intervening "FINAL PERFECTION P3" wave — `street_props.gd`
now batches every district's Pole and Lamp meshes into two shared
`MultiMeshInstance3D`, and each `streetlight_3d.tscn` instance sets
`mesh_visible=false` on its own redundant copies (kept for the
`Light3D`/`Hum`/`LightArea` nodes, which can't be MultiMesh'd and were
confirmed NOT the draw-call problem — see
`docs/SESSION_REPORT_FINAL_PERFECTION.md`). Re-measured via
`scenes/tools/perf_check_scene.tscn` (now a real gate, see below):
370 → **234** draw calls in the suburbs spawn district. `perf_check_scene`
gates hard on D11<350 (met); D1<200 is flagged in its output but not
hard-failed (see `scripts/tools/_perf_check_runner.gd`).

The remaining 234→200 gap (per `PLAN.md`'s own prior analysis, still
accurate): monster meshes (6, intentionally not MultiMesh-batched — they
need independent skeletal animation/materials per instance) and
pickupable items (12, individual — scattered per-instance, not currently
pooled). Further reduction needs either a design call (fewer items/
monsters live in the scene at once) or a deeper per-instance batching
technique for animated/pickup meshes — neither is a small tweak.
Documenting rather than guessing further, per this project's honesty
rule; see `docs/PRODUCTION_BIBLE.md` §7 and `PLAN.md` item 1.

**RC final pass (2026-09-10) — WON'T-FIX for RC ("D1 perf, code-side
only").** No draw-call reduction here is simultaneously code-only,
behavior-preserving, *and* verifiable without a Godot Visual Profiler
run (headless reports `draw_calls=0`). The shippable budget — D11 < 350,
the busiest district — is met (234) and hard-gated by
`perf_check_scene.tscn`. Candidates and why each is deferred, not done
blind: (a) MultiMesh-batching the 12 pickup / 6 monster meshes breaks
per-instance bob/rotate animation and individual removal — the same
regression class that broke streetlight reactivity when rushed once
already; (b) distance-culling far pickups changes visible behavior
(pop-in); (c) the single most promising code-side lever for a
Godot-enabled pass: **each `scenes/pickups/item_pickup_3d.tscn` carries
its own `OmniLight3D` glow** (12 live dynamic omni lights in D1) — the
box mesh is already self-lit via an emissive material, so the cast-glow
light is a readability nicety that could be swapped for a cheaper
`VisibleOnScreenNotifier3D`-gated shared light or dropped, but that is a
visual-quality call that needs a Profiler before/after, not a static
guess.

**Update 2026-09-10 (MEGA POLISH) — code-side reduction applied.**
`distance_fade_enabled` added to the streetlight `SpotLight`/`Glow`
(`begin 22 m`, culled at 30 m) and the pickup `GlowOmniLight3D`
(`begin 12 m`, culled at 16 m). Both lights have short reach (spot 12 m,
pickup omni 3.2 m), so nothing a player can see changes — only lights
whose lit effect is already off-screen get culled entirely ("not sent to
the shader at all", per the `Light3D` docs). `tools/qa_sim/drawcall_estimate.py`:
a representative D1 frame goes from **58 → 18 active real-time lights
(−69%)**. The residual structural draw calls (6 non-batchable monster
meshes, in-view pickups / interactables, HUD 2D) still put a firm `<200`
out of static reach — that needs a Profiler pass and, likely, a design
call on concurrent monster/pickup counts. Owner step: re-run
`scenes/tools/perf_check_scene.tscn --windowed` and read the new number.

## boot_check_scene.tscn can see a spurious PLAYING -> MENU during its
## sustain phase — test-harness artifact, not a real-game bug (tolerated,
## logged as WARN, does not fail the gate)

Found and extensively traced while building the P0.4 permanent gate.
Sequence: `_boot_check_runner.gd` runs under `get_tree().root` because
`boot_check_scene.tscn` is passed as a scene override (`godot ... res://
scenes/tools/boot_check_scene.tscn`), which is not how a real player ever
launches the game (they always boot through the real configured main
scene, `boot_loading.tscn`, directly). This unusual entry point puts
`_bootstrap.gd`'s autoload fallback (`if current_scene == null or
current_scene.name == "": Routes.goto(splash.tscn)`) in an ambiguous
position it never occupies for a real player, and something in that
window occasionally leaves a `splash.tscn` instance alive whose ~3s tween
fires `Routes.goto(BOOT)` a second time, later, during active gameplay —
`boot_loading.tscn`'s own natural ~3.3s countdown then calls
`Routes.to_menu()`, and `main_menu.gd`'s own defensive
`if not GameManager.is_menu(): return_to_menu()` forces the state change
the gate observes.

Traced with temporary stack-trace instrumentation on
`GameManager._change_state()` and `Routes.goto()` (removed after
diagnosis — see the corresponding commit) across ~8 runs. The exact
instantiation call for the orphaned `splash.tscn` node was never fully
pinned down (every `Routes.goto()` call is logged unconditionally, and no
`splash.tscn` target ever appeared in the trace despite `splash.gd`'s
callback firing later) — plausibly a buffering/ordering artifact of the
diagnostic prints themselves rather than the underlying scene-tree
mechanism, but conclusively NOT reachable through any code path a real
player's boot sequence uses (`boot_loading.tscn` is deterministically
`current_scene` from frame 1 in a real launch; `_bootstrap.gd`'s
fallback condition can only be true in a real launch if the engine
somehow fails to set up its own configured main scene, an unrelated and
already-legitimate safety net).

Given the repro requires a test-only entry point mismatch, the gate
treats a `PLAYING -> MENU` transition (without death) during its sustain
phase as a logged warning, not a failure — `scripts/tools/
_boot_check_runner.gd`'s sustain loop. If this same symptom is ever
reported from an actual player build (not a `boot_check_scene.tscn`
run), treat it as a new, real bug — this analysis assumes the gate's own
entry-point mismatch as the root cause and would not apply.

## Streetlights: three implementations existed, only one was live, none
## reacted to district power (fixed — see git log for the commit)

Found during TRUTH WAVE P1. Three separate streetlight scripts existed:

- `scripts/world/street_props.gd` (CityStreetProps) — live in all 11
  district scenes. Built flat emissive-decal "lamps" (a `SphereMesh` with
  an emissive material, no actual `Light3D` node) that were always on,
  never checked district power stage.
- `scripts/world/streetlight_spawner.gd` (StreetLightSpawner) — only
  placed in `main_3d.tscn`'s root, whose `street_builder_path` default
  (`^"StreetBuilder"`) never resolves there (the real `StreetBuilder`
  nodes only exist nested inside each district's runtime-built subtree).
  Confirmed **dead code**: `_ready()` returns immediately every time.
- `scripts/world/streetlight_3d.gd` + `scenes/props/streetlight_3d.tscn`
  — a complete, correct implementation: real pole mesh, `SpotLight3D` +
  `OmniLight3D` glow, hum audio that starts/stops with the light, a
  `light_zone` `Area3D` (stealth-visibility relevant), and a live
  `EventBus.district_stage_changed` connection matching GDD §11.1's
  "darkness -> restored power" reward exactly. **Never instantiated
  anywhere** — confirmed dead simply because nothing spawned it.

Net effect before the fix: the game's namesake mechanic (streetlights
turning on as districts are restored) did not exist in actual gameplay.
Every street was permanently "lit" with non-reactive decals regardless
of district power stage.

**Fix**: `street_props.gd` now instantiates `streetlight_3d.tscn` (reading
`district_id` from the sibling `StreetBuilder` node already present in
every district scene) instead of building the old decals. The old
behavior is preserved behind a project setting, disabled by default:

```ini
[world]
legacy_streetlights=false   ; true = old flat-decal poles, for comparison/rollback
```

`streetlight_spawner.gd` and `scenes/props/streetlight_3d.tscn`'s dev-only
probe references were left as-is — neither is deleted (CLAUDE.md: never
delete a file unless proven dead *and* not a planned feature; the spawner
in particular has real road-following placement math that could be
salvaged later if street_props.gd's simpler even-step placement isn't
good enough).

`scripts/world/streetlight.gd` (`extends PointLight2D`) is a leftover
fossil from an earlier prototype phase — inert in this 3D game (Light2D
nodes do not affect the 3D rendering pipeline at all). Not deleted for
the same reason; flagged here so nobody spends time trying to "fix" a
2D light node in a 3D scene.

## Confirmed dead code, not touched (fixing it would have zero player-facing effect)

- `scripts/ui/lobby_menu.gd` + `scenes/ui/lobby.tscn` — a LAN multiplayer
  lobby screen. Not registered in `UIManager`'s screen dict, no button
  anywhere opens it. Has the same raw-`tr()`-on-English-sentence bug as
  the skill tree did, left unfixed since nothing reaches this screen.
  **ARCHIVED (PLAN.md Stage 1, decided): keep unwired, do not delete.**
- `scripts/ui/save_slot_entry.gd` + `scripts/ui/save_slots_ui.gd` — a
  multi-slot save/load picker UI. Also not registered in `UIManager`, no
  reachable entry point (the real save/load path is `main_menu.gd`'s
  single "Continue" button -> `GameManager.continue_game()`, unrelated to
  this file). Same unfixed `tr()` bug for the same reason.
  **ARCHIVED (PLAN.md Stage 1, decided): keep unwired, do not delete.**
- Previously documented in `docs/VISUAL_AUDIT.md`: `city_decorator.gd`,
  `door.tscn`/`exploding_barrel.tscn`/old `pickups/*.tscn` (no material,
  never instantiated), `daily_events_ui.gd` (not in `UIManager`'s dict
  either — its hardcoded strings were still localized in the RC final
  pass so a future wiring doesn't reintroduce an i18n-rule violation).
- `scripts/ui/onboarding.gd` — a contextual first-time-hint system
  (WASD / flashlight / shadow / interact / inventory prompts on gameplay
  events), fully authored and i18n'd, but **not instanced anywhere** and
  not an autoload. Superseded by the two live systems: `tutorial_system.gd`
  (the FTUE) and `onboarding_overlay.gd` (the 4-panel first-launch
  overlay, wired in `main_3d.tscn`). Reviewed in the RC final pass —
  wiring a hint system in blind (NO-GODOT) is a feature-integration risk,
  not an RC polish; left for a Godot-enabled pass or an owner decision to
  archive it. `onboarding_overlay.gd` itself was reviewed clean (shows
  once per save profile, never blocks gameplay, i18n on all captions/
  buttons; only nit — it doesn't retranslate on a live language switch
  mid-overlay, negligible for a once-ever first-launch screen).

## Accessibility toggles — 5 of 7 were non-functional; fixed 2026-09-10 (MEGA POLISH)

The Settings → Accessibility tab shipped 7 toggles; a static trace
(`tools/qa_sim/a11y_check.py`) found only High Contrast half-worked:

- **Colorblind Mode** — `_apply_colorblind()` was an empty stub. Now a
  real full-screen `canvas_item` post shader (deuteranopia / protanopia /
  tritanopia channel-lift), mounted on a `CanvasLayer` from
  `settings_manager.gd`. Conservative constants — a colorblind playtester
  can tune the `*1.15 / 0.10 / 0.20` factors in the shader string.
- **Text Size** — iterated an `"ui_text"` group that nothing ever joins
  (and would have compounded). Now scales `get_tree().root.theme.default_font_size`
  from a captured base. **Partial by design**: screens that hard-override
  their own font size won't scale — full coverage needs each screen to
  honor a text-scale, out of scope for RC.
- **High Contrast** — `_apply_high_contrast()` worked, but the generic
  `_toggle` in the Settings screen only called `set_setting()`, never
  `set_high_contrast()`, so the checkbox did nothing. `set_setting()` now
  dispatches to the real applier for every accessibility key.
- **Arachnophobia Mode** — `enemy.is_instance_valid()` is a runtime error
  (`Node` has no such method) → the toggle *crashed*. Fixed to the global
  `is_instance_valid(enemy)`.
- **Auto-aim Assist** — `auto_aim` is read by nothing anywhere in the
  codebase. **Removed from the UI.** Re-add when an aim-assist code path
  exists (`player_3d` targeting).
- **Dyslexia Font** — loaded `res://assets/fonts/OpenDyslexic-Regular.ttf`,
  which is **not shipped**, and (again) iterated the empty `"ui_text"`
  group. **Removed from the UI**; `_apply_dyslexia_font()` guarded against
  the null load. Re-add once the OpenDyslexic `.ttf` is added to
  `assets/fonts/` — and gate it to Latin-script locales (it has no CJK /
  Arabic glyphs).
- **Reduce Screen Shake** — worked (added in the RC pass; read directly in
  `screen_shake.gd`).

Accessibility effects are now re-applied on config load
(`from_dict → call_deferred("apply_all_accessibility")`).

## Unmerged `arena/*` branches on origin — deliberately not merged (RC triage 2026-09-10)

Three `arena/*` branches remain on origin after the RC final pass. Only
one was merged; the other two are intentionally left alone.

- **`arena/01a08729-igra` — MERGED** (RC final pass, Phase B). Store kit
  (`store/**`), `docs/PROSE_CHANGES.md`, `docs/ASSET_LICENSES.md` +
  `AUDIO_COVERAGE.md` + `CONTENT_PIPELINE_AUDIT.md` §10, and a 2-word
  `centre→center` prose fix in `gas_station`/`police` `lore_notes.json`.
  In MERGE POLICY scope; see `PLAN.md` 2026-09-10 decisions-log entry.
- **`arena/019ffbd0-igra` — NOT merged.** 57 commits, merge-base ~60
  commits behind `main`. Its payload (the autopilot in-engine test suite
  plus a large stealth/doors/save/tutorial/finale fix batch) already
  landed on `main` through earlier integration — `tools/autopilot/`,
  `tools/flow_check.py`, `tools/orphan_check.py` are present and
  CLAUDE.md's "Already done" list enumerates the fixes. Merging now would
  replay stale history into conflicts for no gain. Kept on origin for
  archival only; safe to delete once someone confirms nothing unique is
  on it.
- **`arena/01a07b1c-igra` — NOT merged.** 9 commits implementing an
  FPS-weapons layer (`scripts/weapons/**`, `project.godot`, player/weapon
  `.tscn`, `data/items/ammo.tres`, `docs/IDEA_CONFORMANCE.md`). Outside
  the content/store/docs scope this project's self-merge protocol allows,
  and a separate feature track (GDD §18) rather than RC finishing work.
  Needs an explicit owner design decision before any of it goes near
  `main` — do not self-merge.

## Mobile texture compression — every texture ships Lossless (mode=0), not VRAM Compressed (P1/OWNER)

Checked this pass (PLAYABLE IDEAL, STEP 5 mobile perf): all 1230 `assets/**/*.import` files
sampled use `compress/mode=0` (Lossless) — none are VRAM Compressed. On Android this means
larger APK size and full RGBA8 GPU memory per texture instead of ETC2/ASTC block compression
(typically 4-6x less VRAM). `export_presets.cfg`'s Android preset now has
`texture_format/etc2_astc=true` (added this pass — inert today since nothing is VRAM-compressed
yet, but correct and ready for the migration below).

**2026-09-12 re-measured (RELEASE CONVERGENCE STEP 7):** fresh count finds
738 texture `.import` files (not 1230 — likely a different glob/snapshot;
both counts agree on the finding: 100% Lossless, 0% VRAM Compressed),
41.2 MiB total on disk. Full byte breakdown, a scoped/prioritized pilot
(`tiles`+`surfaces` = 65% of `assets/textures/`, lowest banding risk),
and an honest APK-size-vs-VRAM-memory impact estimate in
`docs/artifacts/apk_size_report.md`. Same decision as below still holds —
not fixed this pass either, for the same reason (needs a windowed banding
check this session structurally cannot run).

**2026-09-12 EXECUTED (FINAL HARDENING PASS, BLOCKER 2):** the pilot
above was actually run and PSNR-verified — 74 files (`tiles`, `surfaces`,
3 of 4 `environment`) converted to `compress/mode=2` +
`compress/high_quality=true`, every one individually confirmed ≥40dB
against its Lossless original (45.64-52.37 dB actual range;
`high_quality=true` was required — default quality failed the bar
entirely at 34-37 dB). `enemies` textures failed even at high quality
(28-36 dB) and stayed Lossless. Full method, per-file numbers, and
category-by-category reasoning: `docs/artifacts/
texture_compression_audit.md`. Committed via a scoped `.gitignore`
exception for exactly these 74 `.import` files (normally never
committed in this project) so the setting survives a clean checkout.
**Real measured result, not an estimate:** on-disk size for these 74
files went **up** 8.99→9.69 MiB (this game's flat art already compresses
well under Lossless PNG) while VRAM/runtime footprint went **down**
38.75→9.69 MiB, a real ~4x reduction — confirming the VRAM-memory case
was always the substantial one, not APK download size. The windowed
banding check remains the one owner-only step before this specific
change should be trusted in production
(`docs/artifacts/known_owner_only_items.md`).

**Why not fixed here:** re-importing ~1230 textures to VRAM Compressed is a bulk `.import`
edit outside a headless session's safe reach for two reasons: (1) `assets/textures/**` is
Arena's/OpenCode's ownership zone, not reassigned for a project-wide pipeline change (only
this pass's 12 new mobile-art files were reassigned); (2) VRAM block compression can introduce
visible banding on this game's palette-locked, deliberately-flat-gradient art (STYLE_GUIDE
explicitly bans banding) — verifying that needs a windowed visual diff, which NO-GODOT
headless-only policy forbids.

**Owner remediation:** in the Godot editor, select `assets/textures/**` (environment/prop
surfaces are the highest-value targets — UI glyphs and the STYLE_GUIDE-locked flat art may be
better left Lossless for crispness) → Import dock → Compress Mode → **VRAM Compressed** →
Reimport, then a visual spot-check for banding on a few district loading screens before
shipping. `texture_format/etc2_astc=true` is already set for when this lands.

## GDD achievement count is stale — code ships 31, GDD/store copy says 20

Found 2026-09-12 (RELEASE CONVERGENCE, arena store-pass cert). `docs/GDD.md` §21 and its
supplement §S17 list exactly `ach_01`–`ach_20` (20 achievements), and `store/listing.md`
correctly ships "20" per the repo's GDD-wins-on-conflict rule. But
`scripts/systems/achievements_manager.gd` has shipped **31** since the GOLD MASTER v5 hooks
pass (2026-09-11) added 11 per-district achievements (`ach_district_<id>`) that were never
back-ported into the GDD. The GDD is the stale side, not the store copy.

**Why not fixed here:** updating GDD §21 to list 11 new achievement entries (name/description/
trigger per district) is a content-canon write, not a bugfix, and risks scope creep into a
docs-consolidation pass. Deferred to a dedicated content pass.

**Remediation:** add the 11 `ach_district_<id>` entries to GDD §21/§S17 (name = the existing
`DISTRICT_NAME_<ID>` i18n key, description = the shared `ACH_DISTRICT_FULL_DESC` key already
in code), then re-run `tools/gen_store_listing_locales.py` with the polished bullets ported in
first (`docs/CERT_STORE.md` §8.2 warns regenerating without doing so reverts the 2026-09-11
benefit-led polish) so store copy can honestly say 31.

## Touch feel (BLOCKER 3, FINAL HARDENING PASS) — code-level timing proven headlessly; real-device feel is not, and cannot be

`touch_probe_scene.tscn` now asserts concrete timing budgets, not just
that a signal fires eventually: joystick touch-down updates
`InputService` the same call (measured, not assumed — CPU time between
the injected event and the state change, comfortably under one frame at
60fps); the knob's press-scale animates over 80-120ms of *simulated game
time* (driven by an explicit fixed 60fps delta rather than real engine
frames — `--headless` has no vsync/frame cap, so wall-clock time for N
frames does not equal N/60s of game time on a nearly-empty test scene,
which is what the first version of this test got wrong before it was
fixed to drive `_process()` directly); the haptic call and the
interact-button proximity pulse both fire the same call as their
triggering signal.

**What this proves:** the code paths that are SUPPOSED to feel responsive
have no accidental extra latency, no deferred call, no wrong animation
rate baked in — `virtual_joystick.gd`'s press-scale rate was actually
wrong before this pass (6.0/s → ~167ms, outside the 80-120ms spec; fixed
to 10.0/s → ~100ms) and this is the test that caught it.

**What this cannot prove, and no headless session ever will:** whether a
real thumb on real glass, with real touch-sampling latency, a real
haptic motor's actual felt intensity, and real screen-to-finger parallax,
actually *feels* good. `Input.vibrate_handheld()`'s ms argument is a
request to the OS; its physical strength/timing on any specific device is
outside Godot's (or this session's) control entirely. This is the same
category of gap `docs/HONEST_ASSESSMENT.md` already names as the
project's headline risk — a real device playtest is the only way to close
it, tracked in `RELEASE_CHECKLIST.md`.

**Also new this pass:** a "Touch Tuning" preset (Comfort/Default/
Responsive — Settings → Controls) is a one-tap shortcut over the
sensitivity/deadzone/haptics sliders that already existed, not a new
mechanic; and a one-time "Touch Calibration" overlay (drag, tap, feel the
haptic) shown on a touch device's first HUD load
(`scripts/ui/touch_calibration_overlay.gd`), gated the same way every
other touch-only setup in `hud_3d.gd` already is
(`has_touch_ui()` + a persisted `touch_calibration_done` flag).

## District collection cards: 4 of 22 share a base photo, don't depict their own district (2026-09-13, art-final merge)

**Status (2026-09-14): RESOLVED.** 11/11 districts now ship unique
photography; the seven shared-photo textures above were replaced in
`assets/textures/cards/` (unlocked + regenerated `_locked_512`), see the
status update in the "arena/card-unique-rescue" entry at the top of this
file. Only the frozen suburbs/residential keeper pair (h=1) remains.

`arena/art-final`'s new `assets/textures/cards/card_<district>_512.png` art
(wired live this pass into `scripts/ui/collection_ui.gd`) is genuinely
new, correctly dimensioned (512×512, PSNR/purity clean per
`docs/CERT_ARTFINAL.md`), and each file is a distinct PNG (different
SHA-256) — but `docs/LEDGER_ARTFINAL.md` line 90 documents, by design,
that 4 source photos are shared across all 11 districts: `hero_grid_
cascade` for power_station/substation, `hero_first_restore` for suburbs/
residential/park, `hero_reactor_room` for industrial/warehouses, and
`still_first_light` for **everything else** — school, hospital,
gas_station, and police all key off the same streetlight photo,
differentiated only by per-district color grading (same "twins stay
twins" precedent already accepted for the LUTs), not by depicting the
district. This means `docs/CERT_ARTFINAL.md`'s own per-card "Mood"
column ("gas station pumps wet concrete ember glow", "school corridor
chalk dust flickering", "police desk badge radio blue cold", "hospital
hallway cold teal gurney") describes a scene that isn't actually in the
image for those 4 districts — a real content-accuracy gap in the
delivered art, found by an S-assets verification subagent during the
FINAL CONSOLIDATION merge, not a wiring bug and not something code can
fix. Not blocking (the card still renders, still shows *a* moody night
scene, and the district name/accent-color/progress-bar below it are
correct) — flagged here for whoever holds the art pipeline next: 4 of
22 cards would benefit from a bespoke re-render matching their own
scene description.

## arena/texture-optimization edge-case defects (2026-09-13)

Hunted across the five mandated focus areas (save/load across district
transitions, NG+ restart, locale switch mid-run, audio bus reconnection,
concurrent signal emissions). Five new defects found; three fixed in
this branch (✅), two left as KNOWN_ISSUES (⚠️) because they need an
owner-level decision or art/content change, not a code patch.

### ✅ Defect 1 (FIXED): `audio_atmosphere.gd` district pitch table used wrong ids
**Area:** audio + district transitions
**Repro:** Start a run, walk into any district (hospital/police/gas_station/
warehouses/substation/power_station). The procedural ambient drone in
`audio_atmosphere.gd` is supposed to shift per district (+/-25 Hz) but
the `_district_pitch_offset()` match table used legacy names
(`"suburb"`, `"policestation"`, `"gasstation"`, `"warehouse"`,
`"powerplant"`) that never match the canonical district ids
(`suburbs/police/gas_station/warehouses/power_station`). Every district
fell through to the `return 0.0` default so the same 55 Hz drone played
everywhere.
**Fix:** Renamed the table's keys to the real StringNames used
everywhere else in the project. Verified against DistrictManager.DISTRICTS.

### ✅ Defect 2 (FIXED): Slot saves didn't persist current district / onboarding / daily streak
**Area:** save/load across district transitions
**Repro:** Walk into hospital, open the (archived) save-slots UI, save to
slot 1, return to menu, load slot 1. `save_slot()` wrote `wallet`,
`power`, `player_pos`, etc. but omitted `district`, `onboard_done`,
`daily_streak`, `last_daily_time` — the exact same class of bug that
TRUTH WAVE P0.2 fixed on the main save. Loading the slot always returned
the player to `suburbs` regardless of where they saved, reset the daily
streak, and could re-show the onboarding overlay that should only appear
once.
**Fix:** `save_slot()` now writes `district`, `onboard_done`,
`daily_streak`, `last_daily_time` (matching `_save()`); `load_slot()`
restores `DistrictManager.current_district` and `_onboard_done` the same
way `load_all()` does.

### ✅ Defect 3 (FIXED): Weather name doesn't refresh on mid-run locale switch
**Area:** locale switch mid-run
**Repro:** Start a run during a non-CLEAR weather (wait ~45 s for RAIN/
FOG/STORM/WIND), open Settings → Language, pick a different language,
close settings. The `weather_changed` signal carries a localized
`weather_name` string; until the next random weather tick (up to 45 s
later) any UI showing the current weather name kept the previous
language. Latent today (no listener reads the name in the current HUD)
but a real trap for future consumers and a violation of the "all
dynamic strings refresh on language_changed" invariant every other
system holds.
**Fix:** `weather_system.gd` connects to
`LocalizationManager.language_changed` (deferred, to handle autoload
order) and re-emits the current weather with the freshly translated
name.

### ✅ Defect 4 (FIXED): `streetlight_hum_pool` never set an audio bus, never looped the hum, never reconnected to SFX
**Area:** audio bus reconnection
**Repro:** Boot a fresh profile, walk to a lit street (post-restore
suburbs). The 8-slot `AudioStreamPlayer3D` pool in
`streetlight_hum_pool.gd` routed to the default `"Master"` bus (bypassing
SFX volume sliders) because `p.bus` was never set. More importantly, the
hum stream's `.import` loop flag is not committed to git (same pattern
called out in `audio_manager._force_loop()` / `music_manager._force_loop()`),
so on a fresh checkout the WAV imported with `loop_mode=DISABLED` and
each pool slot fell silent after ~0.6 s once the one-shot WAV ended,
producing a continuous pop/churn on the REASSIGN_INTERVAL cadence. Also,
if SettingsManager created the `SFX` bus deferred after our `_ready()`
ran, we never migrated slots off Master.
**Fix:** Pool slots now set `bus = "SFX"` (with Master fallback),
`_force_loop()` the hum stream at startup, and `_reassign()` lazily
reconnects every slot to SFX the moment the bus appears.

### ⚠️ Defect 5 (known, not fixed): `DistrictTrigger.one_shot` can prevent district_entered from (re)firing on respawn after death
**Area:** save/load + concurrent signals
**Repro:** Die and revive inside a district trigger Zone (rare: trigger
Zones are the invisible boxes at district borders, but a death while
backpedalling across a border can leave the player's body inside the
neighboring trigger). Revive keeps the same district scene loaded;
`_fired = true` from the original entry stays `true` because
`district_trigger.gd` only resets it on `_ready` (new scene instantiation),
not on revive. Walking back across the trigger and re-entering the same
neighbor district would not emit `district_entered` again. Low hit-rate
in practice (deaths inside border triggers are uncommon) and fixing it
correctly needs a design call on whether revive should re-fire
`district_entered` at all (would restart the save-on-entry autosave,
refresh ambience twice, etc.) — flagging here rather than making a
call that could re-introduce the double-transition crashes `world_
runtime.gd`'s `_loading` guard exists to prevent.

### ✅ Drive-by fix caught during the hunt: `music_manager.gd` double-subscribed to game_won / game_started
`_ready()` connected `EventBus.game_won` twice (once for `set_mood(VICTORY)`,
once for `_play_wow_cue("ending")`) and `game_started` twice (once for
`set_mood(AMBIENT)`, once to reset `_first_light_cue_done`). Godot still
invokes each callback, so both effects did happen, but the double
subscription was a latent concurrent-signal footgun (a future listener
added to one of those lambdas would fire twice per event). Consolidated
into two `_on_game_started` / `_on_game_won` methods that do both.

## Session 23: key letters in hint strings (OPEN, small)
After a remap (Settings > Controls > Key Bindings) a few strings keep the default letter: `tutorial_move` ("WASD - move"), `TUT_FIND_FLASHLIGHT` ("Press F ..."), `HINT_INVENTORY` ("Tab ..."), `WORKBENCH_CLOSE` ("Close (E)"), `INV_HINTS`. The interact prompt reads the real binding (`scripts/ui/hud_3d.gd`, `_interact_key_hint`); these do not. The fix is a `%s` in the 13 strings and `LocalizationManager.tf` with `InputRemap.key_text(InputRemap.key_of(action))` at the five call sites.

## Session 23: deferred by design and owner rows (OPEN)

| What | Why it is not built | What would build it |
|---|---|---|
| LOD swap at 20, 50 and 100 m | Every mesh of the districts is a primitive or a MultiMesh of blocks; there is no lower detail to swap to. | New meshes with LODs (an art task), then `visibility_range_*` on the instances. |
| Occlusion culling | The player walks inside the skyline ring of blocks, so a baked occluder set would hide nothing the camera sees, and the culling is on the CPU. | A district with real buildings the player passes behind. |
| Texture streaming | The Compatibility renderer has none; the textures are mipmapped and VRAM-compressed, and a district holds 70 MiB of them (`docs/PERF_PASS.md`). | A move to the Mobile renderer. |
| God-rays through windows | The Compatibility renderer has no volumetric fog. The dust motes in the lamp beams (`scripts/effects/dust_motes.gd`) are the cheap form. | The Mobile renderer, or a billboard shaft scene as an art task. |
| Dyslexia-friendly font | No such font is in the repository and a download is not allowed here. | The owner adds a licensed font file and the Settings row. |
| Aim down sights; spread that grows with movement; a reload animation | No weapon is drawn in the view (a weapon scene is a node with a muzzle marker and a script). The first two change the accuracy of the bot. | A design decision, a weapon model, and the IRON RULE run of the 3-seed bot. |
| A monster that loses the player behind a wall inside its detect area | It still paths to the real position of the player; a memory of the last seen point inside the area changes every encounter (`docs/AI_STEALTH.md`). | A second memory in the chase state, with the bot after it. |
| AES-256-GCM saves; PCK encryption; the app-signature check; R8 | `docs/SECURITY_HARDENING.md` gives each reason (no GCM in `AESContext`; custom export templates; a Java plugin; nothing secret to hide). | The owner's decisions listed there. |
| The two keys of the game (`SaveSystem._HMAC_KEY`, `SecurityLog.KEY`) are in the scripts | An offline game has nowhere else to keep them; anyone who unpacks the bundle reads them. | A server that signs, which the game does not have. |

## Session 23: store copy and data that the audits listed (OPEN, owner)

| What | Where | What would close it |
|---|---|---|
| The store copy says "zero loading screens" (all 13 locales): there is none between districts, and a loading scene plays once when a new game starts (`scripts/core/routes.gd`, `LOADING`) | `store/listing.md` | The owner keeps it (it is true of the city) or asks a translator for "no loading screens between districts" in 13 languages; a digit was the only thing this session changed in the translations. |
| `data/ng_plus_config.json` is read by no script (its numbers live as constants in `new_game_plus.gd`); it ships and is in the integrity manifest | `docs/NGPLUS_TABLE.md` | Delete it in a cleanup with the manifest regenerated, or wire it; listed, not deleted (it is data a planned audit named). |
| The 11 lit beds are synthesized loops (`docs/CERT_AUDIO.md`); a composed bed is better | `docs/MUSIC_BRIEF.md` | The owner generates or licenses beds from the briefs and replaces the files of the same name. |
| The loudness of the shipped audio is under the directive's targets for music (median -18.0 against -14) and SFX (-15.0 against -10), and at the canon for ambience (-18.2 against -18); every true peak is at or under -1.0 dBFS | `docs/AUDIO_LOUDNESS_TABLE.md` | Re-mastering the files, not a bus gain (a gain would clip the peaks); the canon numbers (`docs/PRODUCTION_BIBLE.md` section 3) were kept, see `docs/AUDIO_CONSISTENCY.md`. |

## Session 23: what the soak, the stress run, the bot and the ablations left (OPEN)

| What | Where | What would close it |
|---|---|---|
| 120 monsters at once run at 7.8 frames a second; 16 and 32 hold 60 (the cap is 8 a district) and a knee lies between 32 and 120 that was not located | `docs/STRESS_TEST.md` | Run `tools/qa_sim/soak stress <hash> 1 300 64`, and look at the fan-out of the group alert, a noise event every monster hears (`scripts/enemies/base_monster.gd:830`), before a design lifts the cap. |
| The HUD draws 73 calls and costs 2.3 to 4.1 ms of the 19 ms GPU frame on the dev iGPU; the overlay's chromatic aberration (a copy of the frame, 0.5 to 1.0 px by district) costs 1.8 ms at High and its grain and vignette 0.5 each | `docs/PERF_PASS.md` | Merge the grain and the vignette into one pass, draw the aberration on a hit only below Ultra, fewer HUD labels. Not changed: the look is the shipped canon (the windowed gate of launch 24 still reads a p95 over its budget: the next row, CORRECTION_LOG 248). |
| The windowed perf gate reads RED at the final head: a p95 frame time of 35.00 ms at the suburbs spawn and 38.63 ms in the power station against its 33 ms (the median of three 300-frame reads at the High tier, 2x MSAA, vsync on, the quality manager off, full HD); 150 and 140 draw calls (under 200 and 350) and 125.0 MiB of video memory (under 512) pass. The GPU mean is 19.1 to 20.4 ms and 22.6 to 23.2 ms where Session 22 read 15.4 and 16.4 ms; the same machine at 1280 x 720 (the probe and the soak) reads a p95 of 16.67 ms in the probe and 18.4 ms at the median minute of the soak. The budget of 33.0 ms is below the 33.33 ms of a steady 30 FPS frame, and the gate keeps vsync on and prints neither its window size nor its vsync state | `docs/PERF_PASS.md` section 0b, CORRECTION_LOG 248 | Owner decision O-1: ship High as it is (the quality manager and dynamic resolution step a phone down) or lighten it after the phone's numbers (U1, U21). For the gate itself: print the window size and the vsync state, and read the p95 against a budget that follows the cap (as the two governors' limits do). A runtime change after the frames of launch 24 stales them (AF3 F4). |
| The whole-frame primitives at D1 read 51,733 at the final head, over the GDD's 50K per district (PF4); the district's own node counts 48,514 of them, the HUD 1,657 and the rest the other nodes of the frame (the breakdown line lists them) (`docs/artifacts/rc16/proofs/s23_last_a4acbb5.attach.gate_perf_l24.log:4-5`); the rc16 tree read 43,263 to 44,205, Session 22 47,281, and D11 reads 48,463 now. The probe's reads at other poses are 56,337 to 57,611 | `docs/ACCEPTANCE_CHECKLIST.md` PF4, `docs/PERF_PASS.md` section 0b | Decide what the budget counts (the district's meshes, as the GDD says, or the whole frame); if the whole frame, fewer scattered pieces in the dressing of the suburbs, with the gate's draw calls read after it. Not changed: the look is the shipped canon and DENS1 holds its minimum. |
| From the 54th minute of the 120-minute soak of launch 19 every frame sat on one 30 Hz interval while the processor was nearly idle; the probable cause is the quality manager's ratchet (CORRECTION_LOG 241, fixed), the log of that soak carries no tier so it is a reading. The 120-minute soak of launch 24 (tier 2 and the 60 FPS cap printed, the manager off) did not show it: 114 of 120 minutes at 55 frames a second or more, the median minute 58.0 | `docs/LONG_SESSION_TEST.md` section 5, `docs/THERMAL_TEST.md` section 4 | The reading is not proved: a soak with the manager ON on a loaded machine (the runner switches it off now) prints the tier it ends on, and a second machine with the display's refresh rate and the power plan written down settles the rest (U22). |
| One freeze of 0.13 to 0.15 s at every district change (one to three frames over 50 ms), because a district is built whole on the main thread | `docs/STREAMING_TEST.md` | Owner row ST-1: build the props in batches, a few a frame. |
| The power station's visit shows 10 to 11 frames over 50 ms in some probes (the cold visit of launch 23: 11 hitches and 454 ms over the budget; the perf visit of the fix chain: 10 and 592 ms) and 1 to 2 in the others (launches 18 and 24, the cold visits of the fix chain); the cause is not traced (CORRECTION_LOG 256) | `docs/STREAMING_TEST.md` | Run `tools/qa_sim/rc16_probe after <hash>` three times in a row on a quiet machine and read which pass has it; then trace the first frames after the switch (which resource the renderer builds in that district). |
| The cost of what the lighting fix adds at a dark-to-FULL entry (the moon's shadow switching on, `scripts/world_env_setup.gd:141`) and the lighting by eye: no run enters a stage 3 district from a stage 0 one (the stream probe, the perf gate and ENV1 stay at stage 0) (round 3, CORRECTION_LOG 258) | `docs/STREAMING_TEST.md`, `docs/PERF_PASS.md` section 0b | A windowed probe that travels from a dark district into a FULL one and logs the frame time and the ambient, the moon and the glow after the entry. |
| ENV1 emits `district_entered` for the district the world already holds, so it cannot tell `_apply_stage_of(id)` from a variant that reads `DistrictManager.current_district`, and it reads the ambient only, not the moon or the glow (`scripts/tools/rc16/perf23_checks.gd:169-182`); the code as written is right (round 3 read it) | `scripts/world_env_setup.gd:179` | A check that emits `district_entered` for another district with the pointer unchanged and reads the moon and the glow too, with its AF2 pair (an engine run). |
| Continue, respawn and the map's Travel are lit by the stage of the district at once: read in code by two rounds (each route ends in a `district_entered` that `scripts/world_env_setup.gd:98` receives), no run logs the ambient one frame after them | the lighting section of this file (CLOSED by the fix chain) | One windowed run per route, with the state line of the density runner. |
| The district's colour grade (the LUT) is switched off 0.5 s after each `WorldEnvironment` that enters the tree and each tier change by `SettingsManager._apply_high_contrast` (`scripts/systems/settings_manager.gd:441-450`, the timers at `:535` and `:548`), so it is off after 0.5 s in the first district of a session, and a tier change rewrites the district's bloom with the tier's until the next entry (BEAUTY_RC16 X5; round 3) | `docs/BEAUTY_RC16.md` | The patch of the X5 row: keep the grade on unless high contrast asks for the flat one, and apply the district's bloom again after a tier change; its frames decide the look. |
| The history of the repository is about 979 MiB on disk (975.8 MiB reachable: `docs/artifacts/rc16/proofs/s23_repo_size_l25.out`; it was 874 MB on the cleanup day and stills and proofs came after), not the directive's 500 | `docs/CLEANUP_LEDGER.md` section 9 | Owner row K-1: the owner's approval of a history rewrite and a force push. |
| 1,656 lines of the scripts hold Russian text, 1,469 of them comments | `docs/TZ_DECISIONS.md`, LANG-23 | Owner row L-1: say so if the sweep is wanted; it becomes one commit a folder. |
| The boss's other ways out of the district (a knockback through the thin wall, a spawn at the wall) are not tried; only its jump is held (BOSS1) | `scripts/enemies/boss_3d.gd:151` | A recovery rule: a boss with no path to the player for ten seconds jumps to a clear spot, with the 3-seed bot after it. |
| Trailer Mode and Photo Mode hide the film grain and the vignette multiply of the HUD with the HUD, because that pass is a child of the HUD layer (`scripts/ui/hud_3d.gd:347`, `_setup_grain_overlay`); their frames, among them the store frames of this pass, are darker and cleaner than play, whose overlay (`scripts/post_process_overlay.gd`) keeps its own grain and vignette. The HUD's pass is also a second grain and a second vignette over the overlay's, and it reads the screen (0.8 ms in the ablation) | `docs/PERF_PASS.md`, `store/SCREENSHOT_RECIPES.md` | Move the pass out of the HUD layer or drop it and raise the overlay's grain to the same visible amount, with the frames read before and after; a look decision, not made blind. |

## CLOSED in Session 23 by launch 24 (2026-10-14, ledger row 117, `s23_last_a4acbb5`; the sub-check run is row 119)

- **The play-through's pale-square step (A04h)**: it passed (0 of 8 frames brighter than the clearest by more than 3.5, the corner 19.0 to 19.9: `docs/artifacts/rc16/proofs/s23_last_a4acbb5.attach.playthrough_A.txt`); the play-through A read 67 steps and 0 failed (54 PASS lines, 13 notes), the S 23 and 0 (19 and 4).
- **BOSS1, POOL1, FOG1, FOLIAGE1, DENS1 and the mutation rows that read NOT RUN at launch 23**: the s23 closeout read 65 checks and 0 fails (`docs/artifacts/rc16/proofs/s23_last_a4acbb5.attach.closeout_s23_l24.log`), and the 40 mutation rows each made their own check fail with nothing failing without a mutation (`s23_last_a4acbb5.out:121`).
- **The English store frames** (dim, every one at the DARK stage): CORRECTION_LOG 249; the eight kept frames read in launch 24 and its sub-check run pass `store_frames_check.py` (0 faults); `store/SCREENSHOT_RECIPES.md` section 6.
- **The visual truth gate failing on the frames a run leaves in `docs/stills/final`**: CORRECTION_LOG 250.

## CLOSED (Session 23, launch 24): the quality manager could not raise a tier it had lowered, and saved the one it applied
`scripts/systems/quality_manager.gd` (T17) lowers the graphics tier after 5 s under 30 FPS. Low and Medium cap the frame rate at 30, where the 45 FPS it needed to raise the tier never comes, so it stayed down for the session; a machine that held the cap read 29.x and was taken on down to Low; and the tier it had applied was saved with the settings (half a second later, `scripts/systems/settings_manager.gd`, `_on_any_setting_changed`) and read back as the player's own choice, so one dip lowered a device's quality and capped its frame rate at 30 for good (CORRECTION_LOG 241). Fixed with limits that follow the cap, a doubling wait after each drop and the player's tier kept under `graphics_ceiling`; QM1 to QM4 hold it: they ran in an engine in launch 24 (`docs/artifacts/rc16/proofs/s23_last_a4acbb5.attach.closeout_s23_l24.log`, all `ok`) and their four mutation rows each bite (40 of 40). Not tested: the read of `graphics_ceiling` at the next start (it needs a second process), and the manager on a real phone (U23).

## CLOSED in the second bundle (Session 23, export 2, row 121): the first signed bundle of the pass packed the integrity guard without the two files it preloads
The export filter left out `scripts/security/*` (since `855a278`, when the folder held only the attack simulator) while `scripts/systems/integrity_guard.gd`, an autoload, preloads two files of it: in the bundle of `1414899` the guard could not load, which would have switched off the whole security layer of Session 23 on a phone and broken `local_leaderboard.gd` (CORRECTION_LOG 242). Found by listing the zip after the export; fixed in the filter and held by the static gate `export_refs_check`; the second export carries them: 4 entries under `scripts/security` next to the guard's 2 (`docs/artifacts/rc16/proofs/s23_aab_entries_ebc1acc.out`), `refs` ok (`s23_aab_check_ebc1acc.out`). Not tested: a boot of the exported game (no device).

## CLOSED in the second bundle (Session 23, export 2, row 121): the skill icons were in no bundle
The export filter `assets/textures/icons/*.png` was meant for the 12 legacy achievement icons in the root of that folder; the `*` of a filter matches `/`, so it also left out the 15 icons of `icons/skills/` that the skill tree loads, in every bundle since 2026-09-17 (CORRECTION_LOG 243). The pattern is `assets/textures/icons/ach_*` now and the static gate `export_refs_check` reads format-string paths too. The second bundle packs the 15 (`.png.import` under `icons/skills`, `docs/artifacts/rc16/proofs/s23_aab_entries_ebc1acc.out`) and `refs` is ok. Not seen in a frame: no screenshot of this pass shows the skill tree of an exported build.

## CLOSED in an engine and in the second bundle (Session 23, launch 24, export 2): the three defects of the verifier's round (CORRECTION_LOG 244 to 246)
(1) `scripts/systems/dynamic_resolution.gd` judged the frame rate by an absolute 30 and 45 FPS, so under the 30 FPS cap of Low and Medium it counted 29.x as a dip and could not return to the full scale; its limits follow the cap now, a drop within 30 s of a return doubles the wait for the next and a later one starts it over (PERF4 to PERF7). (2) `ui_ending_sting.ogg` and `ui_streak_milestone_sting.ogg` had been deleted as unwired while `uisfx.gd` plays them through a built path: the dark and survivor endings and the streak milestone were silent in v8.0.0-shipping; the two CC0 files are back and `export_refs_check.py` reads `play_ui` names as files; nobody has heard them in an engine (the listening of U3 covers them). (3) `WowDirector.hit_stop` could put an old time scale back over a cinematic's 1.0 and leave the game at half speed; it gives back the scale only if it is still its own dip (JUICE5). PERF4 to PERF7 and JUICE5 ran in an engine in launch 24 (all `ok`, each with a biting mutation row); the two stings are in the second bundle (4 entries with their imports, `docs/artifacts/rc16/proofs/s23_aab_entries_ebc1acc.out`); nobody has heard them.

## CLOSED in Session 23 by the fix chain (2026-10-15, ledger row 120, `s23_fixenv_0752c9b`): a district entered kept the lighting of the one left, for up to 45 s
`scripts/world_env_setup.gd` applied a stage's ambient, moon and player glow on the first five frames, on a stage change of the current district, on the shadows setting and on the weather's 45 s tick, and not when a district was entered: a travel or a step over a boundary kept the light of the district left (from a FULL district into a dark one the moon stayed at 0.40 with its shadow and the glow at 0.7, and the other way round the dark values) until the next tick, in `v8.0.0-shipping` too (CORRECTION_LOG 252; found by the second verifier). `_apply_stage_of` (`scripts/world_env_setup.gd:179`) is connected to `district_entered` now and check ENV1 reads the ambient after the signal; its mutation row, the 41st, takes the connect out and fails it. Evidence (`docs/artifacts/rc16/proofs/s23_fixenv_0752c9b.out:105-110, 326`; `s23_ambient_states_l25.out`): the 41 mutations each fail their own check with nothing failing without one, the clean s23 group reads 66 checks and 0 fails, the stage 0 views of the pair run read the ambient 0.030 in 22 of 22 (2 of 22 before), the 3-seed bot won 3 of 3. Not measured: the cost of the one change that is new at a dark-to-FULL entry, the moon's shadow switching on (the stream probe enters every district at stage 0, where the handler writes the same dark values), and the lighting by eye on a phone. The windowed perf, audio and soak gates were not read again: they read `a4acbb5`, and the head differs from it by this handler and the version code (`docs/PERF_PASS.md` section 0b).

## Session 28: what the masterpiece pass left (OPEN)

| What | Where | What would close it |
|---|---|---|
| The pavement changes between two frames at constant light: the mean brightness of the lower half of a view moved 4 percent (street view) and 9 percent (skyline view) between consecutive frames while the energy of the nearest lamp and of the moon stood still (`docs/artifacts/rc16/proofs/s28_v1d_e539016.attach.s28_v1d_series.log`); the null pair of launch 6 differs in 5 to 13 percent of its cells | `docs/CORRECTION_LOG.md` row 297 | Owner row O-S28-1: shoot one view twice on a phone and watch the pavement at rest. The candidates are the positional shadows of 48 lamps and the limit of eight lights on a mesh in the Compatibility renderer; no run of this pass tells them apart. |
| The lamps of STREETS and of FULL have the same energy in play: the stage's energy is set by `_update_light` (`scripts/world/streetlight_3d.gd:84`) and overwritten on every frame by `_process` (`scripts/world/streetlight_3d.gd:51`) with the flicker's value, 1.7 on average, so the stages differ in range and attenuation only | `scripts/world/streetlight_3d.gd` | A decision and eleven frames: set the flicker's mean from the stage's energy and grade every district again. Left as shipped: the districts were graded in this state. |
| The steam of the manholes is drawn at the 1 m of its quad (`scripts/world/manhole.gd:77`), where it asks for 0.45 to 0.9 m | `docs/VFX_BUDGET.md` | Set `billboard_keep_scale` on its material and read one frame of a manhole at night; near what it asks for, so left. |
| Five scripts are over 300 lines and were before the pass: `scripts/world/district_dressing.gd` (400), `scripts/enemies/boss_3d.gd` (400), `scripts/systems/music_manager.gd` (564), `scripts/systems/settings_manager.gd` (669) and `scripts/core/save_system.gd` (721) | `docs/RUN_STATE.md` (the skill log of Session 28) | A split of each; those of an autoload move the compile order (`DistrictSceneFactory`, rc16), so each one is a launch of its own. |
| The music variants `_b` and `_c` of the eight district beds are not made: the beds turn over from another point of the same file (`docs/TZ_DECISIONS.md`, BED-28), and their rights stay unverifiable here | `docs/MUSIC_RECIPE.md`, B1 to B8 | Owner step: the eight prompts, the take, `tools/qa_sim/music_post.py` and the rights row. |
| Hard was measured, not played: it costs the bot more health, lives and time than Normal, and nobody has felt it | `docs/DIFFICULTY_INTENT.md` section 3 | Owner row D-1: a human at Hard through the gas station and the Architect. |
| Nothing of this pass ran on a phone, and the strings it added (the story lines of the scenes, the ending and daily notices) are machine translations in 13 locales | `docs/RESUME_NOTE.md` | Owner rows: one run on a device of the minimum tier, and a native reading of the new strings. |

## Session 30 / land pass (2026-10-22): stray branches, dispositioned (X0)

- **origin/oc/visual-w10 (627f489, 3 commits from 3ca44bb) — NOT MERGED.** Its scripts/world_env_setup.gd hunk (+43/-2) repeats the W2 camera attributes and the W10 moon shadow bias that pv10 already carries and verified ( 6882ac, 3b97aa7), and its _wire_visual_materials is an alternative W5 wiring whose consumers already exist in pv10 (scripts/world/street_wetness.gd, scripts/world/lamp_head.gd, scripts/world/street_props.gd). Its 11 before/after frames stay reference only. No merge commit from it exists on land/v10.0.0.
- **origin/dsh/work (3ca44bb) — empty and unused**, left as-is; no merge from it.
- **origin/pass/v1.0.0-ship (c7911c1) — superseded** by pass/v10.0.0-ship; left alone, not merged.
- Landing goes through a PR into protected main (PR required, enforce_admins, no force-push, no deletions). The protection is not weakened and the gh api -X DELETE .../protection form is not run.

## Session 30 (v10.0.0-LAND): what is genuinely still open

- **`check.sh --all` is 87 pass / 5 fail at `a7713ef`** and NOT green here: `proofs_audit_sim` needs a full-history clone (this one is shallow; 159 closure rows cannot resolve their commits, and the S27 frame set was re-shot by E10), and `timing_equiv` reports the mean frame time margin (the 15 equivalence keys themselves read ok). The other three of the five were fixed on the landing branch.
- **The verifier's one read-only round and the 600 s soak were not run in this pass** (no subagent context here, and the round budget went to the export, the battery and the bot).
- **DOD22 is a FINDING, not a task**: its row says the bot floor is 3/3 at Hard, the pass head reads 3/3 Normal and 2/3 Hard with 0 softlocks; `PROMPT_v10.0.0-LAND` §7's own condition is >=1 win each.
- **`v10.0.0` is not tagged** because §7 is not fully met; the work is landed by PR #22 instead.
- **Owner-only rows unchanged**: keystore/Play Console upload, a phone run of the minimum tier, native reading of the transcreated strings, the music licence, the AppLovin key. `docs/store/HUMAN_CHECKLIST.md` is the list.

## Session 30 (v10.0.0-LAND): the verifier round (one read-only pass) — GAME-AFFECTING 1 > fixed 0, META 4

The verifier ran in its own context on `1aa13bb` (report in the round log). Findings and disposal:

- **GAME-AFFECTING (1) — FIXED in this branch:** `scenes/ui/settings_screen.tscn:1-12` is now the bare root Control its script builds from; before the fix the scene carried six `[connection]` rows (at its then-lines 112-117) to `_on_sfx/_on_music/_on_sens/_on_fs/_on_lang/_on_back`, none of which exists in `scripts/ui/settings_screen.gd` (the screen went procedural in a later pass and the legacy static panel stayed in the scene). The engine wrote a connect ERROR on every open of the main-menu Settings screen and left six dead, focusable controls behind the built UI. Fixed by making the scene the bare root Control its script builds from (the pattern of `difficulty_screen.tscn`); the new static gate `tools/qa_sim/tscn_connections_check.py` (wired into `tools/check.sh`) fails on the pre-fix scene with exactly the six rows and passes after (172 scenes, 0 findings).
- **META (4), recorded, not rewritten (they are Session-25 certification documents; R1 keeps doc edits in the seven allowed files):** `docs/CERT_STORESYNC.md` claims 13 locales (the build ships 6: `localization_manager.gd` SUPPORTED=6), "30 daily challenges" (the loader reads `content/daily_challenges.json`, 60 templates), and two paths that no longer exist (`data/ng_plus_config.json` -> `content/ngp_modifiers.json`, `data/economy/shop_catalog.json` -> `data/shop/*.tres`); `docs/release_checklist.md` said version code 3 (annotated at the top with the current code 5 and the fresh bundle).
- Verifier PASS lines (its raw evidence): res:// refs 0 real misses; autoload API 0; input actions 32 all defined; i18n 426+555 keys all present in en.json, 6 locales x 1566 keys; export filter packs every runtime path (2437 entries); integrity manifest 37/37 hash-match; 180 scenes wired except the six above; sampled store claims (11 districts, 5 endings, 31 achievements, 6 languages, 88 lore, 4 skill branches, 11 playable enemies) all reproduce.
- UNVERIFIED (as the verifier says): boot/save of the exported AAB itself — no device and no engine launch in that round.

## Session 30 final: the tag decision and the two tool-drift blockers

- **Why `v10.0.0` is not tagged.** The pass's DoD (PROMPT §7 item 11) needs `bash tools/check.sh --all` exit 0. It reads **92 pass / 1 fail** on this machine, the one fail is `timing_equiv`: this Godot 4.7 launcher no longer sets the process delta of `--fixed-fps` (delta_mean 0.02304 for a 30 fps request; re-tested on AC, argument order and `--delta-smoothing` do not change it; the probe's 15 equivalence keys all pass). R6 forbids tuning a gate to pass, so the tag is withheld and the pass is PARTIAL.
- The second blocker is the mutation run: 105 of 107 mutations BITE, and the verdict FAIL bad=5 is tool drift (two rows name mutations no longer in the tree: `SECV2B`, `SECV9L`; two subset baselines read SECV2/SECV9/GROUND1 as failed inside their group while the full closeout is 611/0). A tool-fix pass, not a game fix.
- Third: `coverage_matrix` 51/60 with 9 log-matching misses (FOV kick, salvage, exploding barrels, radio, hiding types locker/dumpster/bush/dark_corner, truth ending) - each needs a waiver with a reason or one run log.
- **What is already landed and green in `main`:** closeout 611/0; signed AAB 66.7 MiB code 5 with `aab_check`/`release_export_check` PASS; bot Hard 3/3 WIN 0 softlocks and Normal 2/3 recorded; perf 3 tiers (battery and AC); audio truth gate x2; soak 600 s flat; proofs_audit_sim 309/309; af3 8/8; af2 analyzed 5/5 BITES; the verifier's one game-affecting finding found and fixed with the new `tscn_connections_check` gate.
- **Owner decision (one of two, either unblocks the tag):** (a) accept the engine-semantics note and authorize `v10.0.0` on the current landed main, or (b) authorize the compat patch of `timing_equiv`/`s26_mutations` (gate semantics change) and have a later pass rerun them and tag.

## Session 30 (v10.0.0-TAG, machine 2): what the second host could not verify, and what it settled

- **Settled.** The qa_guard_e2e SIGILL is the abort path of QaLaunchGuard itself (`qa_launch_guard.gd:88`, `OS.crash()`): rc=132 on the two abort steps and rc=0 on the four lifecycle steps, identical at `3ca44bb`, `d9932fe3` and the session head - a host red, not a regression; the compensation gates (qa_guard_check, attack_sim, tscn_connections) are green. F19 brightness drift is closed: static-region 1.27-1.49% between frames 3 s apart (was 4-9%). N037 is fixed (`apply_dot`, DOT1/DOT2).
- **Open on this host (owner rows).** `proofs_audit_sim` needs the session-29 machine's `.qa_logs/proofs/` (untracked, not in git); `branch_absorb_sim` needs the four stray origin branches deleted by an owner push; a release-signed AAB needs `.signing/` restored on this machine (the shipped `build/tls.aab` of `07ec9ee` is debug-signed); `af3_frame_check` reads 8 frames older than the settings_screen change (stale, fail identically on the pristine land head); exit leaks at bot exit are 35-37 anonymous RefCounted with refcount 0 - engine-owned by the teardown evidence, the same class the land head recorded at 25.

## OPEN (2026-10-28, arena release agent): art pass 2 repainted the wired 2D art

Repainted in the premium-noir painterly canon of `docs/ART_PASS_2.md`, zero game code changed: the menu hero, the loading/death/stats/journal backdrops, the city map and grid panel, 11 district cards plus 11 locked variants derived by the repo's own measured affine. Static gates green on a fresh clone (battery, flow, scene-node, af5, consistency); evidence `.qa_logs/evidence/artpass2_static.out`.
- **Store frames and AF3 (closed in Session 37)**: the eight frames were re-shot at `04a3f8f1` after an import and AF3 reads 8 frames, 0 fail; the menu was read on the desktop and stays legible. Still open: the menu on the target phone.
- **The primitives stand**: monsters, buildings and props are unchanged; the CC0-kit route of the Session 36 row above is still the next art step and still needs an engine and eyes.
- **Music rights verified as far as an agent can**: `docs/MUSIC_RIGHTS_MEMO.md` (2026-10-28) — Google claims no ownership of Gemini-generated content, but Google APIs ToS 5(e)'s distribution restriction is unresolved for generated music (no official clarification exists); decisions A/B/C are listed for the owner, whose call it stays.
