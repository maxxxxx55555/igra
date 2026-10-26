# The first five minutes (Session 23, PX1)

What a player who has never opened the game meets, read from the code and from the bot's first minute. A person's own timing needs a person, and is the one owner row
here (F-1); everything else below is a fact of the sources or of the logs.

## 1. The path, step by step

1. **Menu to game, two taps.** "Play" with no save goes straight in, no confirmation: the dialog of `_on_play_pressed` (`scripts/ui/main_menu.gd:229`) appears only when a save would be lost.
   It calls `Routes.start_game` (`scripts/core/routes.gd:39`), which resets the profile (`GameManager.start_new_game`, `scripts/core/game_manager.gd:129`) and opens the loading screen.
   The difficulty presets (Easy, Normal, Hard) are one button of the same menu (`LABELS`, `scripts/ui/main_menu.gd:16`); a new player is on Normal (`scripts/systems/settings_manager.gd:73`) and does not have to choose.
2. **The onboarding, once per profile, skip-able.** Seven cards with art (`PANELS`, `scripts/ui/onboarding_overlay.gd:9`), each with NEXT and SKIP (`skip.pressed.connect(_finish)`, line 97), shown
   once per save profile (`is_onboard_done`, line 41), never blocking after the dismissal, and closing by itself when the first district reaches the lit streets (`AUTO_HIDE_STAGE`, line 23).
3. **The tutorial: one hint at a time, a Skip button on every hint.** Eleven steps (`STEPS`, `scripts/ui/tutorial_system.gd:6`): "wake up" is timed (5 s, line 12), then the light, a move,
   a pickup, the generator, crouch, dodge, attack, the inventory and the journal each wait for the action they name, and "complete" closes it (5 s, line 87). The light step is skipped when the light already burns
   (`scripts/ui/tutorial_system.gd:223`); the Skip button ends the whole tutorial (`_skip_btn.pressed.connect(_skip_tutorial)`, line 164; `_skip_tutorial`, line 313); the hint follows a language
   switch (line 112; check TUTL1, `scripts/tools/rc16/window_checks.gd:75`) and the tutorial comes back after a death (`docs/A11Y_PLAN.md:15`, row A6).
   So the first five minutes are **skip-able at two layers** (the cards, the hints) and tutorial-free for a player who skips both.
4. **The first district.** Suburbs at DARK holds six monsters, shadows and crawlers (strength 3.8, the lowest of the game: `docs/DIFFICULTY_CURVE.md`), the player has no gun
   (the pistol lies in the second district, `WEAPON_FINDS`, `scripts/world/district_loot.gd:389`) and no ammo, and the shadows that come die to the flashlight in about a second
   (`light_vulnerable`, 25 damage a second against 30 hit points: `data/monsters/monster_shadow.tres:16-19`) and flee a lit district. The first lesson is the game's: the light is the weapon.

## 2. The time (the bot's, then a person's)

The bot, three seeds (`docs/PACING_AUDIT.md`): first secret hint at 11.2 to 11.7 s, the first interactable at 24.4 to 24.9 s, the first district lit at 26.5 to 27.0 s of game time
(`onboarding` line, `scripts/tools/_qa_autoplay_runner.gd:783`). That is a floor: the bot reads nothing. A person adds the cards (seven taps, or one on SKIP), the hints (each waits for its
action) and the walking; the model of `tools/qa_sim/balance_sim.py` puts a first play at 12 to 18 minutes a district before its multiplier, so a first district is a stretch of minutes
and the first five minutes end inside it, with the first power restored or about to be.

## 3. What was checked and what was not

| Claim | Evidence |
|---|---|
| a fresh profile reaches the first frame of play without a prompt | the bot's New Game stable line at 6.8 s, three seeds; the boot gate (`scenes/tools/boot_check_scene.tscn`) |
| the cards and the hints are skip-able | the code above; the play-through mode A walks the onboarding (`tools/qa_sim/playthrough`) |
| the hint is in the language of the screen | TUTL1 |
| a person finds the first power in five minutes | **not measured** (F-1) |

## 4. Owner rows

- **F-1** the first five minutes of a person who has not seen the game. Executable action: install the signed AAB on a phone, hand it to someone, say nothing, and write down the minute
  they first move, the minute they first restore a power, and the first word they ask about. A first district longer than 10 minutes or a question about the light means the cards and the
  first hints need another pass (`scenes/ui/tutorial.tscn`, `scripts/ui/onboarding_overlay.gd`).
- **F-2** the text size of the cards on a phone (U-1 of `docs/UI_CONSISTENCY.md`).
