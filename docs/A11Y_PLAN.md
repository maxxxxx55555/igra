# Accessibility plan (Session 23)

Nine features, each a Settings row (or a dialog) with a named reader. `python tools/qa_sim/a11y_check.py --mutations` holds the wiring: it reads the
Settings screen, the readers, the 13 locale files and the defaults, and then removes each one of them, in memory, one at a time, and demands that the
feature fails (116 removals of the 9 features, all caught). `CLOSEOUT_ONLY=s23` (scripts/tools/rc16/a11y_checks.gd, checks A11Y1 to A11Y8) shows each
feature working in the running game.

| # | Feature | Settings (Accessibility tab unless said) | What it does | Readers |
|---|---|---|---|---|
| A1 | Subtitles | Subtitles, Subtitle Size (S/M/L: 18, 24, 32 px), Subtitle Background (0, 50, 100 %), Subtitle Color (white, yellow, cyan) | The Keeper's lines (a caption of the Keeper's log, an examined note, a broadcast) are drawn in a bar above the quick slots, in the size, color and backing the player picked. White is bone `#d8d2c4`, yellow `#e6cf6e`, cyan `#7fc4d9`: lifted from the palette, never pure white. | `scripts/ui/subtitle_manager.gd` (overlay of UIManager), `EventBus.voice_line`, `EventBus.examine_text`, `toast_requested` of the type caption |
| A2 | Control remapping | Controls tab, Key Bindings | A dialog lists 14 actions; a click waits for the next key (Escape cancels); a key another action holds swaps places; Reset to Default puts back what project.godot says. The choices are the setting `keybinds` (action to physical keycode) and are applied again at every load. Pause stays on Escape. | `scripts/systems/input_remap.gd`, `scripts/ui/remap_panel.gd`, `SettingsManager.from_dict` |
| A3 | Difficulty presets | Game tab, Difficulty (also the Difficulty screen) | Monster health 70 / 100 / 130 %, monster damage 75 / 100 / 125 %, the player takes damage at 1/1.5 on Easy (50 % more health), Easy puts one more of each repair part on the street, Hard makes no revive offer. Normal is the game as tuned: the bot plays it. | `SettingsManager.DIFFICULTY_PRESETS`, `base_monster.gd`, `player_3d.gd` (`take_damage`), `district_loot.gd` (`_spawn_spare_parts`), `ad_service.gd` |
| A4 | Motion comfort | Motion Comfort | No screen shake, no FOV punch of the wow moments, no sprint blur. Together with the older Reduce Screen Shake, Reduce Flash, Reduce Time Effects and Reduce UI Motion. | `screen_shake.gd`, `wow_director.gd`, `post_process_overlay.gd`, `rain_lens.gd` |
| A5 | High contrast | High Contrast | The existing environment adjustment. The dyslexia-friendly font is an owner row: no font file ships (`assets/fonts` holds the four canon families), the toggle stays out of the screen until a licensed file is added and `SettingsManager._apply_dyslexia_font` loads it. | `settings_manager.gd` |
| A6 | Cognitive clarity | Clear Objectives | The objective list, the status rows and the touch controls do not fade: every contextual item of the HUD stays at full alpha. The tutorial already comes back after a death (a new run starts its step again) and shows one hint at a time in the current language. | `scripts/ui/hud_fade.gd` |
| A7 | One-handed mode | One-Handed Mode | On touch: the action buttons stand beside the joystick on the left (all eight within the left half of the screen, clear of the joystick at Button Size 1.0 and 1.5), Sprint latches on a press and lets go on the next, the double tap of the joystick has twice the time. | `scripts/ui/hud_3d.gd`, `virtual_joystick.gd`, `input_service.gd` |
| A8 | Edge highlight | Edge Highlight | Every interactable thing and pickup within 9 m gets a bright rim (a material overlay, so the object's own materials stay). | `scripts/effects/edge_highlight.gd`, child of the Interactor |
| A9 | Sound cues | Sound Cues | A bracketed line for the sounds the game makes (something noticed you, a monster strikes, a roar, a whisper nobody spoke, the light stutters, the flashlight dies, the grid comes back) and a flash at the screen edge for the loud ones; Reduce Flash keeps the caption and holds the flash. | `subtitle_manager.gd` |

## Decisions

- The game has no voiced dialogue (the Voice bus is empty: radio voice lines are owner row 19 of `docs/ASSET_SHOPPING_LIST.md`), so subtitles caption the
  Keeper's text lines and Sound Cues caption the sounds. The radio screen is not reachable in the shipped game (`ScreenFlowManager` is off); it says its
  transcript through `voice_line` for when it is.
- Remapping touches only the keyboard event of an action. A few strings name a default key ("WASD - move", "Press F", "Tab - inventory"): they keep the
  default letter after a remap (`docs/KNOWN_ISSUES.md`).
- Easy, Normal and Hard stay a Settings row of the Game tab and the Difficulty screen; the new numbers (30 % health) are in `DIFFICULTY_PRESETS` and in the
  13 descriptions `DIFF_EASY_DESC` and `DIFF_HARD_DESC`.
- The Accessibility and Controls tabs are scroll lists now: the rows outgrow the 580 px panel in a long language.
