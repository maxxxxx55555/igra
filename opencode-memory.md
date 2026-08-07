# Project Memory — THE_LAST_STREETLIGHT (Godot 4.7)

## Objective
- Continue pushing The Last Streetlight (Godot 4.7) toward 10/10 by fixing runtime bugs, wiring missing features, and raising per-parameter scores each turn; exclusions: visual polish, music composition, APK build.
- User instruction flow: "доделай щас еще, добей везде баллы" → "делай чтобы средний балл сильно увеличивался с каждым запросом, перепроверяй себя, работай на 100%" → "доделай" + timeout JSON request.
- User's per-turn rule: always end with what remains + progress made; keep raising ratings each turn.
- User asked to print/change a network timeout config in JSON → no such file exists anywhere in `TLS_Build` (no JSON contains `timeout`/`network`/`connection`); needs user to provide file path. STILL UNRESOLVED — ask user.

## Important Details
- Project: `C:\Users\Maxsim\Desktop\TLS_Build\THE_LAST_STREETLIGHT`; binary: `C:\Users\Maxsim\Desktop\TLS_Build\godot_extracted\Godot_v4.7-stable_win64.exe`
- Runtime smoke test (catches what --check-only misses): `cmd /c "<binary>" --headless --path . res://<scene>.tscn --quit-after 120` (workdir = project root); filter `^ERROR:|SCRIPT ERROR|Failed to`
- PowerShell quirks: `$i` in loops, `;` separators (NOT `&&`/`&`); `foreach ($s in @(...))` works; cmd /c stderr lines become ErrorRecord objects → must `.ToString()` before matching; `\t` is LITERAL in PS strings (no escapes) — never write GDScript via PS string replacements, use [write] tool; grep/Select-String console output gets truncated — redirect to file in `C:\Users\Maxsim\AppData\Local\Temp\opencode\`
- **CRITICAL .tscn rule**: `parent="X"` paths must be FULL paths from scene root (`parent="MarginContainer/VBoxContainer"`); single-segment parent only valid for DIRECT children of root. Broken relative parents silently detach nodes (they get `Parent#Name` auto-rename) with NO error, then script @onready paths fail
- **CRITICAL .tscn rule 2**: `add_theme_font_size_override(...)`/`add_theme_color_override(...)` method calls in .tscn silently drop SUBSEQUENT nodes in Godot 4.7 parser — use `theme_override_font_sizes/font_size = N` / `theme_override_colors/font_color = Color(...)` properties instead (verified on save_slots.tscn)
- **CRITICAL .tscn rule 3**: `script = "res://path.gd"` as bare string fails to attach (difficulty_screen bug) — always `script = ExtResource("id")`
- **CRITICAL .gd rule**: NEVER override native methods (set_owner, show, disconnect, _pick...) — "Warning treated as error" compile failure. Rename to custom (set_shooter, _show_ui, shutdown)
- GDScript parse errors: `LevelManager`/`EconomyManager`/`ScreenRouter`/`SaveManager`/`IapBridge`/`ThemeProvider`/`AssetRegistry`/`FlashlightStats`/`InventoryStats`/`DistrictData`/`MonsterData`/`ShopItem`/`ItemData` etc. = LEGACY names not existing as autoloads/class_name → replace with real ones or get_node_or_null
- **CRITICAL probe gotcha**: `ResourceLoader.load()` of a script with parse error returns NON-null (prints SCRIPT ERROR + backtrace, but returns a GDScript resource) — a null-check probe reports failures=0 despite broken scripts. Reliable check = run probe and grep full engine output for `^SCRIPT ERROR` lines, or `--check-only --script res://x.gd` per file; `if not script.can_instantiate()` also catches it
- Legacy broken patterns found & eliminated: `script = "res://path.gd"` string attachments (dialogue_box/quest_tracker/tutorial_hint scenes were silently script-less), `var x := dict[key]` Variant inference = "Warning treated as error" (puzzle_cables: add explicit types `: Vector2`/`: String`/`: Dictionary`/`: Array`)
- Godot 4 API diffs from Godot 3: NO `Vector3.get_euler()` (use `look_at`), NO `CSGCapsule3D` class (use `CSGMesh3D`+`CapsuleMesh` sub_resource), `get_euler`/`set_owner` overrides fail
- `resources still in use at exit` ERROR during smoke = harmless headless quit noise (audio/music preloads), NOT a load failure
- After deleting .gd files with class_name: MUST run `--headless --editor --path . --quit` once to rebuild `global_script_class_cache.cfg` before smoke tests, else "Could not find script for class X" errors
- Current rating: ~9.4/10 (was 9.3/10). Table: stability/load 10, economy/saves 8, UI integration 10, gameplay depth 8, visuals 5, audio 6, mobile optimization 7, content 7.5, i18n 10, code quality 9.5
- **This session**: deleted 4 more dead files (shop_manager.gd, 2× achievement_manager duplicates, secret_pickup.gd, secret_manager.gd, 2× tutorial_manager duplicates, PauseMenu.tscn, pause_menu.tscn, scenes/ui/pause_menu.gd). Fixed: photo_mode.gd path in screens.gd, SaveManager→SaveSystem in pause_menu/game_over, ScreenRouter→UIManager in hud_3d, ScreenRouter→GameManager in splash, EventBus contract (13 missing signals added), achievement_manager JSON+serialize/from_dict, i18n TranslationServer integration, ACHIEVEMENTS_TITLE added. Final: 274/274 scripts, 119/119 scenes, 65/65 EventBus signals, 148/148 i18n keys × 13 langs, 97/97 tr() covered, main_3d 15s runtime 0 errors
- **EventBus contract check**: all 65 signals declared in event_bus.gd; 62 used; added 13 missing this turn (ammo_changed, enemy_died, enemy_encountered, enemy_hp_updated, enemy_spawned, interaction_done, player_damaged, zone_reached, final_night_started, health_changed, purchase_done, quest_completed, radar_marker_added); deleted broken unused scripts/systems/shop_manager.gd (emitted player_money into health_changed — bug, 0 refs)
- 13 i18n languages NOT removed; mobile rendering settings in project.godot ([rendering]: scaling_3d/scale 0.8, FSR, MSAA 2x, directional shadow 1024, LOD 0.75, anisotropic 1)

## Work State
### Completed (this session)
- **Dead code purge**: deleted shop_manager.gd (0 refs, bug: emitted money into health_changed), 2× achievement_manager.gd duplicates (non-autoload, 0 refs), secret_pickup.gd + secret_manager.gd (0 refs), 2× tutorial_manager.gd duplicates (not autoloaded, 0 refs), PauseMenu.tscn + pause_menu.tscn + scenes/ui/pause_menu.gd (0 scene refs)
- **Bug fixes**: screens.gd photo_mode.gd path (ui→systems), pause_menu.gd SaveManager→SaveSystem + ScreenRouter→UIManager, game_over.gd SaveManager→SaveSystem, hud_3d.gd ScreenRouter→UIManager, splash.gd ScreenRouter→GameManager.return_to_menu()
- **EventBus contract**: added 13 missing signals (ammo_changed, enemy_died, enemy_encountered, enemy_hp_updated, enemy_spawned, interaction_done, player_damaged, zone_reached, final_night_started, health_changed, purchase_done, quest_completed, radar_marker_added)
- **AchievementManager**: rewrote core/achievement_manager.gd — now loads achievements.json, has serialize()/from_dict(), 14 JSON achievements + persistence
- **i18n**: TranslationServer integration in localization_manager.gd (tr() resolves real translations), ACHIEVEMENTS_TITLE added to all 13 JSONs (148 keys × 13 langs)
- **Final state**: 274/274 scripts parse-clean, 119/119 scenes load-clean, 65/65 EventBus signals declared/used, 148/148 i18n keys valid, 97/97 tr() keys covered, main_3d 15s runtime 0 errors
  - `scenes/ui/new_game_plus.tscn`: relative `parent="VBoxContainer"` → full `parent="MarginContainer/VBoxContainer"` (5 nodes)
  - `scenes/ui/skill_button.tscn`: `parent="HBoxContainer"` → `parent="VBoxContainer/HBoxContainer"` (CostLabel/LevelLabel); `scripts/ui/skill_tree_tab.gd`: `SkillButton.new()` → `preload("res://scenes/ui/skill_button.tscn").instantiate()`, add_child before setup; `scripts/ui/skill_tree_ui.gd`: same for SkillTreeTab scene instantiate
  - `scenes/ui/lobby.tscn`: add_theme_* → theme_override_* (3 spots); `scripts/ui/lobby_menu.gd`: fixed @onready paths ($VBoxContainer/HBoxContainer/HostButton, /RefreshButton)
  - `scenes/ui/difficulty_screen.tscn`: `script = "res://..."` string → `ExtResource("1_diff")` (script wasn't attaching → `Control::_pick` callable errors)
  - DELETED duplicate `scripts/network/network_manager.gd` (old class_name NetworkManager conflicted with autoload `scripts/multiplayer/network_manager.gd`; docs/A10_multiplayer_decision.md already demanded deletion) → lobby now parses clean
  - `scripts/weapons/weapon_base.gd`: `set_owner()` → `set_shooter()` (native override), `direction.get_euler()` → `bullet.look_at(from_pos + direction)`; `scripts/weapons/weapon_manager.gd`: callers updated → weapon_pistol/rifle/shotgun scenes load
  - `scenes/enemies/enemy_model.tscn`: CSGCapsule3D (doesn't exist in Godot 4) → CSGMesh3D + CapsuleMesh sub_resource
  - `scripts/levels/checkpoint.gd`: `if LevelManager:` → `get_node_or_null("/root/LevelManager")`; rewrote with tabs (mixed-indent parse error)
  - `scenes/ui/game_over.gd` + `scenes/ui/victory.gd`: `func show()` → `func _show_ui()` (CanvasLayer.show native override warning-as-error)
- Parent-path validator: `C:\Users\Maxsim\AppData\Local\Temp\opencode\check_parents.ps1` (scans all scenes, flags relative parent paths; run with `&` from project root) — only 2 real issues found, both fixed
- All add_theme_* in real scenes converted (only tests/*.tscn throwaways still have them)
- **DEAD-CODE PURGE (this turn): deleted 35 broken+unused .gd + 3 dead .tscn (+ .uid files)** — all verified: 0 scene refs, 0 preload/load refs, 0 uid refs (all 121 [ext_resource] entries carry path= so filename grep is complete), 0 .tres (none exist), no class_name collisions: shop_menu, hub_screen, first_launch, monetization/iap_manager, systems/level_manager, systems/screen_router, ui/save_slots (+ shop_menu.tscn), content/encounter_tracker, content/secret_manager, core/pool_manager, enemies/{boss_enemy,cover_ai,enemy_runner,enemy_tank}, levels/{doorway,power_puzzle}, managers/{level_manager,quest_manager}, multiplayer/multiplayer_player, npc/npc_base, screen_router, stealth/stealth_controller, systems/{challenge_manager,dialog_manager,district_manager,document_placer,skill_tree,vfx_manager}, tests/test_runner, tools/generate_placeholder_textures, ui/pause_full, root item_pickup, ui/{dialogue_box,quest_tracker,tutorial_hint} (+ their 3 dead scenes with string-script attachments), quests/quest_manager
- **FIXED `scripts/ui/puzzle_cables.gd`** (dynamically loaded by screens.gd:1531): 7 Variant-inference warnings-as-errors → explicit types (`lv: Dictionary`, `ck: Array`, `tpos: Vector2`, `sgrid: Variant`, `spos: Vector2`, `cn: String`, `mp: Vector2`)
- Global legacy-name grep now clean: only remaining identifier-class usage is `IapBridge` (properly defined in scripts/economy/iap_bridge.gd, used by shop_service.gd) — no ScreenRouter/ShopManager/ParticleManager/NoiseSystem/SubtitleManager/DistrictManager/WeatherManager/SaveSlotManager/DialogueManager/TutorialManager/TransitionManager/EconomyManager/ObjectPool references left
- **FINAL STATE: 281/281 scripts parse-clean (0 SCRIPT ERROR), 121/121 scenes load clean** (probe_all_scripts.gd + full scene smoke after `--editor` cache rebuild)
- `tests/` cleaned: `probe_all_scripts.gd` (regression) + `validate_i18n.gd` (13-lang JSON validator via Godot JSON.parse_string); deleted probes 1-9, probe_csg, scan_resources, scan_scripts, g1-6/t*/v*/save_slots_copy scenes, tr_probe, coverage_probe
- **I18N COMPLETE**: `data/i18n/*.json` = 51 legacy + 96 new + 1 last-minute = **148 keys × 13 langs**, all valid (Godot parse), **97/97 tr()/extra keys covered, 0 missing**
  - `localization_manager.gd`: now syncs each loaded lang into TranslationServer (`_sync_translation_server()`: remove old Translation, add new with all messages, set_locale) → `tr()` in scripts resolves real translations (verified: ru/en/ar probes return translated strings, NOT raw keys)
  - PS5.1 ConvertFrom-Json is CASE-INSENSITIVE on duplicate keys → rejects `language`/`Language` collision; Godot JSON.parse_string is case-sensitive = valid. ALWAYS validate i18n via Godot, never PS
  - merge_i18n.ps1 quirks: cut at `"Already unlocked"` marker, TrimEnd trailing comma, add comma after last old key before inserting new block

### Active
- Nothing blocked on my side. JSON timeout request waiting on user file path.

### Blocked
- 3D model assets absent (`assets/models/enemies|weapons|player/` empty) → `image.png` import error; needs user-supplied GLB
- APK build, visual polish, music composition — excluded by user
- Headless smoke tests only verify load/parse, NOT gameplay input

## Next Move
1. Ask user for JSON timeout file path (unresolved request)
2. Next quality lever: enemy AI behavior audit (base_monster/fast_zombie/shadow_3d runtime paths — wave spawn, damage flow), save/load round-trip test (SaveSystem: save → load → verify fields)
3. Keep probe_all_scripts.gd as regression gate after every change batch
4. Re-provide 10-point rating table + "what remains + progress made" each turn (user rule)

## Relevant Files
- `scenes/ui/{save_slots,new_game_plus,skill_tree_ui,lobby,difficulty_screen,skill_button}.tscn` + matching scripts: ALL LOAD CLEAN
- `scripts/multiplayer/network_manager.gd`: THE only network_manager (autoload): create_server/join_server/shutdown/is_host/server_created/connection_failed/public_ip
- `scripts/weapons/weapon_base.gd`: set_shooter(), look_at-based bullet spawn; weapon scenes load clean
- Autoloads (project.godot): EventBus, GameManager, SaveSystem, InputService, ItemDatabase, InventoryManager, PowerGrid, Encyclopedia, CoinWallet, ShopService, UpgradeSystem, RewardsManager, UIManager, WeatherSystem, SettingsManager, RandomEvents, ProgressTracker, AudioManager, AchievementManager, LocalizationManager, QuestManager, LANDiscovery, SkillTreeManager, XpManager, NewGamePlus — NO LevelManager/ScreenRouter/SaveManager/EconomyManager (legacy names must map: SaveManager→SaveSystem, EconomyManager→CoinWallet, ScreenRouter→UIManager/screens.gd own router, LevelManager→get_node_or_null("/root/LevelManager"))
- `scripts/ui/screens.gd`: own router `show_screen("Name")`/`hide_all()`, SCREEN_LIST has 26 screens incl "Saves"/"Shop"/"Settings"
- `scripts/economy/coin_wallet.gd`: add/try_spend/get_coins/to_dict/from_dict
- `scripts/core/save_system.gd`: get_slot_info/save_slot/load_slot/delete_slot/set_checkpoint
- `scripts/i18n/localization_manager.gd`: `_sync_translation_server()` syncs JSON → TranslationServer; tr() resolves; 19 legacy t() keys + 97 tr() keys all covered
- `tests/validate_i18n.gd`: Godot-based 13-lang JSON validator (PS ConvertFrom-Json unreliable: case-insensitive dup detection)
- Validator: `C:\Users\Maxsim\AppData\Local\Temp\opencode\check_parents.ps1`
