# Design critique — gaps against the TZ

Companion to `docs/TZ_COMPLIANCE_AUDIT.md`. Every id below is a GAP in that matrix. The quote and the file:line live there. This file is the feel, and the smallest change that would honor the TZ.

Frozen canon is `docs/GDD.md`. `docs/STYLE_GUIDE.md` saying "the art wins" does not amend it. `docs/GAMEFEEL_SPEC.md` and `docs/VISUAL_PASS.md` are not the TZ.

## Canon the shipped code contradicts

These are not taste. The player can see or hear them.

1. **Night is not the night in the bible.** TZ: permanent night, DARK ambient 0.03 / moon 0.12, STREETS 0.11 / 0.25, FULL 0.16 / 0.40. Live `world_env_setup.gd` uses 0.12 / 0.09, 0.20 / 0.14, 0.30 / 0.20, and its own comment says pitch-black was thrown out because the frame was unreadable. The canon numbers still sit in `district_grading.gd` and never reach the environment. Feel: a dim blue evening, not a city where the flashlight is the only way to see a silhouette. The "lights came on" reward is a small lift (0.12 → 0.30), not the jump the TZ wrote (0.03 → 0.16) against a black field.

2. **The flashlight is not brass.** Scene light is a wide, hot, white-gold spot (35°, 16 m, energy 24, color `1.0, 0.82, 0.48`), shadow off. TZ is a short brass cone (`#c9a24a`, 45°, 8 m, energy 2). Feel: a work lamp, not the one object the logline hangs on. The 45° / 8 m write exists, and only runs after an upgrade dictionary is non-empty, so a new game never sees it.

3. **Palette bans are broken in combat juice.** Boss emission is magenta (`1, 0.3, 1`). The TZ bans neon and acid. A magenta boss in a brass-and-ember game reads as a different title. `wow_director.gd` still names `Color.WHITE` on an explosion beat.

4. **The district order on the box is not the order of the locks.** The preload list matches the TZ chain. The `powered_by` graph does not. Park opens from suburbs, so the player can light the park while the houses are still dark. Police does not wait for the gas station. Warehouses do not wait for the police. Feel: eleven districts, not one road. The Act I "go inward" beat leaks.

5. **Fight numbers and the bestiary are different games.** Jab/Cross/Slam deal 14/21/35 instead of 8/12/20. There is no Shadow at 30 HP. Sniper's id holds Watcher's stats. A designer tuning "three jabs to drop a Shadow" cannot, because that creature is not in the roster the spawner aliases. Difficulty is whatever the alias map happens to spawn.

6. **Keeper is three people in Japanese, and two registers in Russian.** See the spot-audit in the compliance doc. EN `groundskeeper` became JA `管理人` (the Keeper) and stayed RU `смотритель`. The radio call is `вы` on the character card and `ты` in the broadcast. Feel: the voice that is supposed to be one man on one frequency is a committee.

7. **Pacing of the ending.** TZ says the grid completing *is* the win, and also requires the Architect. The code picked the boss and documented the skip. Until the owner amends one sentence, the finale is an unauthorized extra act. That is an owner call (G28), not a stealth redesign.

## Gameplay

**G01.** Intent: eyes at 1.7 m, the body unseen. Current: that is what `fps_mode` does, under the wrong scene name, with a third-person distance still exported on the same camera (`distance = 5.0`). Feel is FPS until something toggles `fps_mode` off. Minimal: delete or stop shipping `player_3d` as the named canon camera, and drop the unused TPS distance from the FPS scene so a one-line flag cannot pull the camera back.

**G02.** Intent: a 0.1 run bob, specifically not more, because of motion sickness. Current: no bob. Feel: skating. Minimal: one sine on the FPS camera, amplitude capped at 0.1, off when `reduce_ui_motion` / a future shake toggle is on. Do not add a trauma system for this.

**G03.** Intent: 80° rest, a short +5° on sprint so speed is felt in the edges, not in a zoom. Current: 80° holds; sprint does not touch FOV. Feel: run is only faster feet. Minimal: +5° for the sprint state, returned on release. Do not reuse `wow_director`'s FOV dip; that one subtracts.

**G04.** Intent: look at a thing within 3 m, get a prompt. Current: a downward ground ray. Interaction is whatever `interactor.gd` collects, not a 3 m look-ray. Feel: prompts can fire for things you are not looking at, or not fire for things you are. Minimal: one camera ray, length 3.

**G06.** Intent: sprint is 1.6× walk, loud enough that stealth players feel the trade. Current: 300/170 = 1.76×, and the noise side of the same sentence is only partly there (S01). Feel: slightly too fast, and the speed is not priced in noise the way the TZ pairs them. Minimal: set `run_speed` to `walk_speed * 1.6` in `player_stats.tres`. One number.

**G07.** Intent: crouch is slow, quiet (×0.3), half as visible, and the capsule shortens to 1.2 m so you fit under things. Current: speed matches; the noise and visibility constants are dead; the capsule stays 1.8 m. Feel: a slower walk with the same silhouette. You do not hide by posture. Minimal: multiply the live `noise_level` and visibility by those constants, and shrink the capsule height while crouched. Do not add a new stealth state.

**G08 / G09 / G10.** Intent: a short brass cone you have to aim, draining 1% every 2 seconds, a battery worth a quarter charge, flicker under 20%. Current: a floodlight that barely drains (1% / 4.5 s), a battery worth 35%, flicker threshold 30% in the unused stats resource. Feel: light is free and wide, so darkness stops being a puzzle. That undoes the logline. Minimal: write the TZ base onto the SpotLight at `_ready` (45°, 8 m, `#c9a24a`, energy 2, shadow 1024 on desktop), set drain to `0.5` percent per second, set the item to +25, and flicker only under 20% until Stability L5 (G12b; the stats resource flickers at 30% and nothing clears it). Do not wait for the upgrade function. Mobile may still drop shadows; the TZ allows that.

**G13.** Intent: three hits to matter, Slam is the payoff, a lit face or a back is the bonus. Timings already match. Current: each hit is ~1.75× the bible, so the combo deletes the early roster the bible thought would take a string. Feel: melee is a delete key. Minimal: put 8/12/20 back in `COMBO_DATA`. Leave the +25% / ×1.5 bonuses; those already match.

**G15.** Intent: a human-width hit, active only in the active frames. Current: the box is about twice as wide and almost three times as deep. Feel: you hit things you have not reached. Minimal: size the box to `0.6 × 0.4 × 1.2` and keep it enabled only in the active phase (that gate already exists).

**G16.** Intent: death puts you at the last lamp you earned, half health, battery where you left it. The lamp is the checkpoint because light is the safe path. Current: you stand up where you fell. Feel: death is a time loss, not a retreat to light. Minimal: store the last activated streetlight position and spawn there. The 50% HP heal can stay.

**G17.** Intent: hardcore is one life, and the save is gone, so the toggle is a real threat. Current: a checkbox that nothing reads. Feel: a lie in the settings. Minimal: on death, if the setting is on, delete the slot and do not offer retry. One branch in the death path.

**G18 / G19.** Intent: eleven named bodies with the table's HP, senses, and light reactions, plus the Architect. Current: an alias layer renames the cast, and Shadow is missing. Feel: the bestiary and the thing in the alley are not the same animal. Light-as-weapon (Shadow dies in the cone) cannot be true if Shadow is not spawned. Minimal: one id per TZ row, stats copied from the table, aliases deleted. Do not add a twelfth creature to "cover" the mismatch.

**G20.** Intent: three phases at 70% and 30%, light slows him, dark hides him, the finisher is combo-3 plus strobe. Current: the 30% line is 33%, and he glows magenta. Feel: a different boss wearing the right comment. Minimal: compare against `0.30`, and set emission to ember `#b4452f` or brass, not magenta. Phase behavior that already matches (dark invisibility, shadow adds) should be left alone.

**G21.** Intent: five blueprints, each found in a named district, each changing the flashlight. Current: a survival-crafting bench (molotov, lockpick, firework) and district notes that admit the blueprint ids do not exist. Feel: the workbench is a different game's inventory. The strobe you can fire (G12) was not built where the TZ says you build it. Minimal: replace `RECIPES` with the five §9 rows, using item ids that already exist (`battery`, `cable`, `fuse`, `transformer`). Do not add molotovs to "keep the content." §9 and §20 disagree on the strobe ingredients (transformer vs 5 scrap). Owner picks; until then ship the §9 row, because the header says this document wins and §9 is the recipe table.

**G22.** Intent: three manual slots and an autosave the player can see, under `user://`. Current: the API exists and the UI that shows it is archived. Feel: saving is a rumor. Minimal: point the existing slot screen at `save_slot()` / `load_slot()`. Path name `user://save.tres` vs `tls_savegame.save` is a rename; JSON is allowed by the same sentence. Do not rewrite the format.

**G24.** Intent: stepping into D10 (substation) is the point you cannot walk the story back. Current: nothing marks it. Feel: Act III is a district with a harder lock, not a commitment. Minimal: one flag set on entering `substation`, after which earlier-district toggles cannot drop the grid below STREETS. Do not add a cutscene.

**G25.** Intent: six slots, two of them weapons, plus battery, medkit, grenade, special, keys 1–6. Current: six material shortcuts. Feel: the hotbar is a shopping list, not a combat belt. Minimal: change `_SLOT_ITEMS` to the TZ loadout and keep the 1–6 keys. Drag-from-inventory can stay if it already writes those slots.

**G26.** Intent: a 200-photo collection with achievements at 50/100/200, so looking is a long goal. Current: an album of whatever was saved, and a `photos_10` achievement. Feel: a folder, not a collection. Minimal: cap and count toward 200, and point the three achievement ids at 50/100/200. Do not generate 200 placeholder photos to fake the count.

**G27.** Intent: the left half of the glass is the look stick. Current: a 35% zone. Feel: look and move fight over the same thumb, or look is a small corner. Minimal: set the look region to `0.5` of screen width. Dodge-on-double-tap can stay; it already matches §2.2.

**G30–G34.** Intent: five endings with different prices. Light matches (all districts, all documents). Hope is supposed to be the thin-archive ending (<50% documents); shipped code gives Hope to anyone missing a single page, so a near-complete file and an empty file feel the same. Survivor ("only D11") never happens to a living player. Truth collapses audio, photos, and the bunker into "documents found + station full", so the secret ending is just Light with the station up, not a harder hunt. Minimal: compare document ratio to 0.5 for Hope; return Survivor when only `power_station` is FULL and the player finishes; count audio logs, photos, and a real bunker flag separately before Truth.

**G28 / D04.** Intent, letter: full grid calls `trigger_win()`. Intent, other sentences: the Architect is the Act III fight. The code chose the boss and said so. Feel, if you honor only the letter: the boss never happens and the ending is a menu. Feel, as shipped: a finale the TZ's win line does not authorize. Minimal change that does not pick a side: stop. Owner amends §4.3 to "all FULL starts the finale; `trigger_win()` fires when the Architect dies" or deletes the boss from the win path. Do not silently keep the comment as canon.

## Stealth

**S01.** Intent: run is heard at 8 m, a hit at 5, a dodge at 3, a heavy pack adds 30%. Run radius and the pack penalty match. Hits and dodges are silent. Feel: you are loud when you run and invisible when you swing, which is the opposite of a horror stealth price. Minimal: emit 5 m on the attack active frame and 3 m on dodge. Do not rebuild `NoisePropagation`.

**S02.** Intent: the cone is a spotlight that also gives you away; darkness is 3 m of presence; walls are zero; running adds 20%. Current: those four numbers are not in the detection math. Feel: light is a weapon (when the enemy script remembers) and not a risk. Minimal: add the four multipliers where the monster already reads player visibility. The crouch ×0.5 constant (G07) should be the same variable.

**S03.** Intent: the screen edge pulses ember when you are loud. No number. Current: the vignette flashes when you are hurt. Feel: you learn damage, not exposure. Minimal: drive the existing vignette from `noise_level`, ember `#b4452f`, and stop using it as the only damage tell — or split the two colors. Do not add a noise bar; the TZ forbids a number, and Appendix V's bar is a later `[M1]` tag, not this sentence.

**S04.** Intent: closets, bushes, trunks, dark corners; inside you are unseen; the hunter searches 10 s inside 5 m. Current: locker, dumpster, car, crate, and a 2 m enter radius. Feel: cover is furniture, not the dark the game is about. A bush and a dark corner are the fantasy; a crate is a prop. Minimal: add bush and dark-corner types to the existing script, and a 10 s / 5 m search on the monster that already has a lost-target state. Do not make a second hiding system.

## NG+

**N01.** The TZ claims NG+ is done and never says what it is. Shipped modifiers (hearing, night length, hint suppression) change feel without a bible. A shorter night cycle fighting a permanent-night game is the dangerous one: if `DayNight` ever binds, NG+ invents daytime. Minimal: owner writes the NG+ rules, or the checkbox comes off. Until then, do not add modifiers, and do not let `get_night_cycle_multiplier()` touch the sky.

## Districts

**D02.** Covered under canon point 4. Minimal: set `powered_by` to the previous id in the TZ chain, one parent each, except where the TZ's own `powered_by` sentence is the only rule — it isn't; the chain is also a sentence. A strict chain is the smaller change. Industrial's two parents can stay only if the owner says the chain is flavor. Default: one parent, the previous district.

**D03 / V01.** Intent: black, then lamps, and the difference is the reward. Current: three shades of readable blue-grey, and the file says that was on purpose. Feel: you always see the street. Restoring power is a grade shift, not a rescue. Minimal: put 0.03 / 0.12, 0.11 / 0.25, 0.16 / 0.40 on `world_env_setup.gd`, which is the live writer. Keep a floor only if a playtest proves 0.03 is a black frame with no silhouettes — that amendment belongs in the TZ, not in a comment. Do not "fix" `district_grading.gd`; it is not in the frame. `DayNight` should not be wired to this environment. Wiring it would add a day, which the TZ forbids.

## Economy

**E03 / T02.** Intent: an optional coin top-up, or a painful skip, once an hour, faked on PC. Current: +100 with no −100, every 15 minutes. Feel: ads are a faucet, not a choice. That is the pay-to-win shape the previous sentence bans, even though the coins themselves are allowed. Minimal: add the −100 skip, set cooldown to 3600 s, and on desktop show the same dialog without a real SDK. Do not raise the +100.

**E05.** Intent: district 1 is poor (0–200) and district 11 is rich (8000+), so the flashlight tree (19 250, which *does* match) is an endgame purchase, not a midgame one. Current: no static curve enforces the endpoints. Feel, if shops pay out early: the tree is bought before the dark matters. Minimal: cap district-1 caches at 200 and check the D11 cache floor against 8000 before calling the economy done. Do not retune the upgrade prices; those match.

Hunger stays out. The dead `inventory_system.gd` hunger/thirst effects must not be instanced. Wiring that panel would break E02.

## Audio

**A01.** Intent: one music bus, and SFX split so footsteps, combat, UI, and the room can be ducked separately. Current: UI and Ambient sit beside SFX. Feel: a UI click and a footstep share a fader, or the room never ducks under a sting because Ambient is not the Environment child. Minimal: reparent UI under SFX and add Footsteps, Combat, Environment as SFX children. Move district beds onto Environment. Do not add a third music bus.

**A02.** Intent: 2 s crossfade, five layers, threat follows investigate then chase. The five files are wired. 2.2 s is a small lie, not a different score. Feel: almost right, a little slow. Minimal: `FADE_TIME = 2.0`.

**A03.** Intent: the ground tells you what you are walking on, six materials, three speeds. Current: one step sound, no material. Feel: every street is the same floor, so the districts do not sound like different rooms. That flattens the chain D01 got right in data. Minimal: map the existing step files (`step_asphalt`, `step_concrete`, `step_wood`, `step_metal`, `step_puddle`, `step_glass` — named in the TZ's own nomenclature) off the downward ray. Three speed pitches, not three new sample sets, if the files are one-speed.

**A04.** Intent: music under 100M, SFX under 50M, so the Android package is a phone game. Music is inside the cap (38M). Ambience (47M) plus sfx plus one-shots is over 50M. Feel is not the issue; install size is. `_pre_norm` is already excluded. Minimal: cut or re-encode ambience until non-music exported audio is ≤ 50M. Do not count `_pre_norm` as a ship failure; the export filter already drops it.

## Visual

**V02.** Intent: ember for danger, brass for light, no neon, no pure white. Current: the boss is magenta, which reads as a power-up from another genre. Feel: the one fight that should be the city's wound looks like a VFX demo. Minimal: recolor that emission to ember. Delete the `Color.WHITE` token in the explosion beat even if its alpha is 0, so the next person does not turn it up.

**V03.** Intent: Bebas Neue Bold for titles, so the UI is condensed and poster-like, not a default label. Current: Bebas Regular. Feel: titles are lighter and rounder than the brass-stamp the style asks for. Minimal: point the theme's title font at a Bold file. If Bold is not on disk, that is an asset add of one OFL file, not a new type system. Roboto Condensed and Share Tech Mono are already right. Leave Rajdhani unwired.

**V05.** Intent: the moon throws a 2048 shadow so silhouette edges are the navigation. Current: shadows on, atlas 1024. Feel: softer, cheaper moon, less readable edges in the dark the TZ wants. Minimal: set `directional_shadow/size` to 2048 on the desktop feature, and keep 1024 only if a mobile tier explicitly drops it. The TZ allows mobile without flashlight shadows; it does not allow a 1024 moon as the only setting.

## i18n

**I02.** Do not delete keys to hit 198. The game grew. The owner amends the census. A player never sees that number.

Keeper defects (locale + key) are listed in the compliance audit. Design note, not a new system: pick one JA name for the Keeper and use it in `WORLD_CHAR_KEEPER_TITLE`, `FINAL_NIGHT_DESC`, `NGP_KEEPERS_PACT_NAME`, and `DAILY_PLAY_20_FLAVOR`. `管理人` is a building superintendent. `守護者` is a fantasy guardian. Neither is "the man who logged the lamps." RU `Хранитель` is the one to translate from, not EN `groundskeeper`. The radio call should be one address (RU `ты` in both the card and the broadcast, matching the tape). EN `If you're replaying this` should become a diegetic "if you are hearing this," which RU already did.

## Accessibility

**C03.** Intent: auto-aim is a real assist, not a label. Current: the toggle emits and nothing aims. Feel: a broken promise in the accessibility tab, which is worse than a missing toggle. Minimal: one aim-assist read of that setting on the hitscan weapon, or remove the toggle until it does. Do not leave a dead checkbox.

**C04.** Intent: the crawler stops being a spider. The TZ names the replacement: blind dogs. Current: the mesh hides and an alt mesh shows, if the node exists. Feel: the creature vanishes or swaps to whatever mesh someone parented, and the bestiary still says crawler. Minimal: when the setting is on, swap the display name to the localized "слепые собаки" / "blind dogs" and force the dog mesh. Hiding the mesh with no alt is not the mode.

**C06.** Intent: four tiers that actually move fog, particles (50–150%), shadows, and resolution. Current: four index bags that set shadow/texture/effects/fps/resolution and do not mention fog density or particle percent. Feel: "Low" may not be the TZ's Low. Minimal: add `fog` and `particles` fields to `GRAPHICS_TIERS` and apply them in `world_env_setup.gd` / the particle owners. Do not add a fifth tier.

## Store

**T01.** The APK line is owner work: keystore, device, debug off. No design change makes a signed package appear. Do not fake a cert.

**T02.** Same change as E03.

## Perf / size

**P01 / P02.** Intent: a phone can hold D1 under 200 draw calls and D11 under 350, under 8 dynamic lights, under 500 particles, under 800 MB RAM. Current: no gate fails the build when that is exceeded, and this pass did not measure a frame. Feel risk: the live environment adds a moon, a player glow, and a flashlight on top of streetlights, and nothing stops an eighth dynamic light. Minimal: `LightLimiter` (already an autoload) should hard-cap dynamic lights at 8, and a headless count of draw calls is the check, not another preset. Do not claim the budget is met because it was not measured.

## What not to do

- Do not wire `DayNight` to the play environment to "use the autoload." That invents a day.
- Do not wire `district_grading.gd` and `world_env_setup.gd` both. Two writers is how 0.03 and 0.12 got to coexist.
- Do not instance `inventory_panel.tscn` to "finish inventory." It reintroduces hunger.
- Do not add NG+ knobs. The TZ has no rules to comply with.
- Do not treat `docs/STYLE_GUIDE.md` "art wins" as permission to keep the 0.12 ambient. The TZ wins.
- Do not cut i18n keys to 198.

## Riskiest assumption, checked

The night the player sees might have been the canon 0.03 in `district_grading.gd`. It is not. That script's environment path is unset. The frame is `world_env_setup.gd`. Any fix aimed at the grading file will not change the picture.
