extends "res://scripts/tools/_playthrough_runner.gd"
## v8.0.0 release validation (Session 19): the whole loop of one profile, as four processes of tools/qa_sim/playthrough L
## (QA_SEED picks the autoplay bot's tie-breaks; a fresh profile per seed):
##   L0  fresh boot, Normal, Play, the onboarding, the bot wins, New Game+ 1 set up and started, Save and quit
##   L1  relaunch, Continue, the bot wins New Game+ 1, New Game+ 2 set up and started, Save and quit
##   L2  the same for New Game+ 2, then every settings tab and the 13 languages in New Game+ 3, Save and quit
##   L3  relaunch, Continue, the daily card, achievements, Hardcore on, Play, the bot plays that run to the win or its one death
## In every run the bot is held once for a shop purchase and an upgrade (at SHOP_AT_COINS earned coins) and once for a skill
## (at the first skill point). Every frame is timed; one over HITCH_MS is listed with the state it fell in, the frames this
## runner saves left out. Raw frames go to .qa_logs/loop_frames/ (stamped into docs/stills/v800_loop/ afterwards).

const HITCH_MS := 100.0
const SHOP_AT_COINS := 3000
const MONSTER_CLEAR_M := 20.0
const CYCLE_WAIT_SEC := 960.0

var _seed: int = 1
var _bot: Node = null
var _busy: bool = false
var _shopped: bool = false
var _skilled: bool = false
var _hc_dead: bool = false
var _note_ms: int = 0
var _in_shot: bool = false
var _quiet_until_us: int = 0
var _last_us: int = 0
var _travel_us: int = 0
var _frames: int = 0
var _in_play: int = 0
var _hitches: Array[Dictionary] = []

func _ready() -> void:
	_seed = maxi(1, int(OS.get_environment("QA_SEED")))
	_out = "res://.qa_logs/loop_frames/"
	EventBus.game_won.connect(func() -> void: _won = true)
	EventBus.district_entered.connect(func(_id: StringName) -> void: _travel_us = Time.get_ticks_usec())
	EventBus.boss_spawned.connect(func() -> void:
		_milestone("BOSS", "the Architect appears (New Game+ %d)" % NewGamePlus.get_current_ng_plus(), "boss_spawn", 1.5))
	EventBus.game_over.connect(_on_game_over)
	super()

func _run() -> void:
	match _mode:
		"L0":
			if await _a01_boot() and await _a02_start():
				await _a03_onboarding()
				await _cycle_then_next()
		"L1", "L2":
			if await _b01_menu():
				await _b02_continue()
				await _cycle_then_next()
		"L3":
			if await _b01_menu():
				await _b02_continue()
				await _b04_daily()
				await _b05_achievements()
				if await _b03_hardcore_start():
					await _play_cycle()
				SettingsManager.set_setting("hardcore", false)
		_:
			_step("PT", false, "unknown PT_MODE '%s'" % _mode)
	_hitch_note()
	_finish()

## The bot plays this run; after the win New Game+ goes one level up and starts, then (L2) the settings, and Save and quit.
func _cycle_then_next() -> void:
	if not await _play_cycle():
		return
	await _v11_new_game_plus()
	if _mode == "L2":
		await _settings_tabs()
		await _a13_languages()
		await _pause_after_languages()
	_hitch_note()
	await _v14_save_quit()

func _shot(name: String) -> String:
	_in_shot = true
	var file: String = await super._shot("s%d_%s_%s" % [_seed, _mode, name])
	_in_shot = false
	_quiet_until_us = Time.get_ticks_usec() + 300000
	return file

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _last_us > 0 and not _in_shot and now > _quiet_until_us:
		_frames += 1
		var ms := float(now - _last_us) / 1000.0
		if ms > HITCH_MS:
			var travel := now - _travel_us < 3000000
			var scene := _scene()
			_in_play += int(GameManager.is_playing() and not travel)
			_hitches.append({"ms": ms, "text": "%.0f ms at %.0f s (state %d, %s, %s%s)" % [ms, float(Time.get_ticks_msec() - _t0) / 1000.0,
				GameManager.current_state, scene.name if scene != null else "no scene", DistrictManager.current_district, ", district change" if travel else ""]})
	_last_us = now

func _hitch_note() -> void:
	var worst := _hitches.duplicate()
	worst.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["ms"]) > float(b["ms"]))
	var lines: PackedStringArray = []
	for h: Dictionary in worst.slice(0, 8):
		lines.append(String(h["text"]))
	_say("[pt] note HITCH frames=%d over_%.0fms=%d in_play=%d longest: %s" % [_frames, HITCH_MS, _hitches.size(), _in_play, " | ".join(lines)])

## The autoplay bot plays the run in progress (QA_ATTACH: it starts nothing). True on the win; a hardcore death stops the bot
## before its revive, which is the ad path (GameManager.revive_player), not one a hardcore player has.
func _play_cycle() -> bool:
	var level := NewGamePlus.get_current_ng_plus()
	var hardcore := GameManager.run_hardcore
	_say("[pt] note C%d the bot takes the run (seed %d, New Game+ %d, hardcore %s, coins %d)" % [level, _seed, level, hardcore, CoinWallet.get_coins()])
	OS.set_environment("QA_NO_QUIT", "1")
	OS.set_environment("QA_ATTACH", "1")
	_bot = Node.new()
	_bot.set_script(load("res://scripts/tools/_qa_autoplay_runner.gd"))
	get_tree().root.add_child(_bot)
	var errands := Timer.new()
	errands.wait_time = 5.0
	errands.autostart = true
	errands.timeout.connect(_errands)
	add_child(errands)
	var t0 := Time.get_ticks_msec()
	await _wait_until(func() -> bool: return _won or _hc_dead or bool(_bot.get("_done")), CYCLE_WAIT_SEC)
	errands.stop()
	var secs := float(Time.get_ticks_msec() - t0) / 1000.0
	if _hc_dead:
		await get_tree().create_timer(2.5).timeout
		var offered: PackedStringArray = []
		for b: Button in _buttons(get_tree().root):
			if b.is_visible_in_tree():
				offered.append(b.text)
		_step("C%d.hc" % level, not SaveSystem.has_save() and GameManager.is_dead(), "the hardcore run's one death ends it after %.0f s in %s: has_save %s, the death screen offers %s" % [secs, DistrictManager.current_district, SaveSystem.has_save(), offered], await _shot("hardcore_death"))
		_bot.call("_finish")
	elif _won:
		await _wait_until(func() -> bool: return _ui_open(&"win"), 20.0)
		await get_tree().create_timer(2.0).timeout
	var full := 0
	for district: DistrictData in PowerGrid.all_districts():
		full += int(district.stage >= DistrictData.Stage.FULL)
	var fails: PackedStringArray = _bot.get("_fails")
	_step("C%d" % level, _won or (_hc_dead and fails.is_empty()), "New Game+ %d%s: %s after %.0f s; %d of 11 districts FULL, deaths %d (revived in place by the bot), nudges %d, coins earned %d, shop %s, skill %s; bot fails: %s" % [
		level, " hardcore" if hardcore else "", "WIN" if _won else ("its one death" if _hc_dead else "NO WIN"), secs, full, int(_bot.get("_deaths")), int(_bot.get("_nudge_count")),
		int(_bot.get("_coins_earned")), _shopped, _skilled, " | ".join(fails) if not fails.is_empty() else "none"], await _shot("cycle_end"))
	return _won

func _on_game_over() -> void:
	if GameManager.run_hardcore and _bot != null and not _hc_dead:
		_hc_dead = true
		_bot.set_process(false)

func _hold_bot(hold: bool) -> void:
	InputService.set_joy_move_dir(Vector2.ZERO)
	_bot.set_process(not hold)
	if not hold:
		_bot.set("_score_t", _bot.call("_now"))
		_bot.set("_stuck_sec", 0.0)

## Every 5 s: a progress line every 30 s, and the shop and skill errands when the run is quiet (no monster near, in the spine).
func _errands() -> void:
	if Time.get_ticks_msec() >= _note_ms:
		_note_ms = Time.get_ticks_msec() + 30000
		_say("[pt] note C%d the bot is in %s, phase %s, coins %d, skill points %d, %.0f fps" % [NewGamePlus.get_current_ng_plus(), DistrictManager.current_district,
			_bot.get("_phase"), CoinWallet.get_coins(), SkillTreeManager.get_skill_points(), Engine.get_frames_per_second()])
	var scene := _scene()
	if _busy or bool(_bot.get("_done")) or String(_bot.get("_phase")) != "spine" or not GameManager.is_playing() or scene == null or not scene.has_node("Screens") or _monster_near():
		return
	if not _shopped and CoinWallet.get_coins() >= SHOP_AT_COINS:
		_busy = true
		_hold_bot(true)
		await _a06_shop(0)
		_shopped = true
		_hold_bot(false)
		_busy = false
	elif not _skilled and SkillTreeManager.get_skill_points() > 0:
		_busy = true
		_hold_bot(true)
		await _skill_errand()
		_skilled = true
		_hold_bot(false)
		_busy = false

func _monster_near() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return true
	for m: Node in get_tree().get_nodes_in_group("monsters"):
		if m is Node3D and is_instance_valid(m) and (m as Node3D).global_position.distance_to(player.global_position) < MONSTER_CLEAR_M:
			return true
	return false

func _skill_errand() -> void:
	var points := SkillTreeManager.get_skill_points()
	await _tap(KEY_T)
	var open := await _wait_until(func() -> bool: return _ui_open(&"skill_tree"), 3.0)
	await get_tree().create_timer(0.6).timeout
	var pick: Button = null
	if open:
		for tabs: Node in _ui(&"skill_tree").find_children("*", "TabContainer", true, false):
			for i: int in (tabs as TabContainer).get_tab_count():
				if pick == null:
					await _click_tab(tabs as TabContainer, i)
					pick = _unlockable(_ui(&"skill_tree"))
	var id: StringName = pick.get("_skill_id") if pick != null else &""
	var res := await _click(pick)
	await get_tree().create_timer(0.5).timeout
	_step("SKILL", open and res == "ok" and SkillTreeManager.get_skill_level(id) == 1 and SkillTreeManager.get_skill_points() < points,
		"T opens the skill tree; a click on an open skill (%s) spends its points (%d -> %d, click: %s)" % [id, points, SkillTreeManager.get_skill_points(), res], await _shot("skill_unlocked"))
	await _tap(KEY_T)
	await _wait_until(func() -> bool: return not _ui_open(&"skill_tree"), 3.0)

func _unlockable(root: Node) -> Button:
	for b: Button in _buttons(root):
		if b is SkillButton and b.is_visible_in_tree() and not b.disabled and SkillTreeManager.get_skill_level(b.get("_skill_id")) == 0:
			return b
	return null

## A click on a tab's title, the way a player switches tabs.
func _click_tab(tabs: TabContainer, index: int) -> String:
	var bar := tabs.get_tab_bar()
	if not bar.is_visible_in_tree():
		return "hidden"
	var pos := bar.get_global_rect().position + bar.get_tab_rect(index).get_center()
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	get_viewport().push_input(move, true)
	await get_tree().process_frame
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		get_viewport().push_input(ev, true)
		await get_tree().create_timer(CLICK_GAP).timeout
	return "ok" if tabs.current_tab == index else "the tab did not switch"

## The HUD's Pause button (the phone's pause) pauses; then Settings, each tab by a click: no text control off the window (a scrolled
## list may run past it) and no raw specifier.
func _settings_tabs() -> void:
	var res := await _click(_scene().get_node_or_null("HUD/BtnPause") as Button)
	var opened := await _wait_until(func() -> bool: return _ui_open(&"pause"), 3.0)
	_step("PAUSE3", res == "ok" and opened and get_tree().paused and GameManager.current_state == GameManager.GameState.PAUSED,
		"the HUD's Pause button pauses the game (click: %s, tree paused %s, state %d)" % [res, get_tree().paused, GameManager.current_state], await _shot("hud_pause"))
	await _click(_button_with(_ui(&"pause"), LocalizationManager.t("settings")))
	await _wait_until(func() -> bool: return _ui_open(&"settings"), 3.0)
	await get_tree().create_timer(0.5).timeout
	var settings := _ui(&"settings")
	if settings == null or not settings.visible:
		_step("SET", false, "the settings screen did not open from the pause menu")
		return
	var tabs := settings.find_children("*", "TabContainer", true, false)[0] as TabContainer
	for i: int in tabs.get_tab_count():
		var res := await _click_tab(tabs, i)
		await get_tree().create_timer(0.4).timeout
		var page := tabs.get_current_tab_control()
		var raw := _raw_placeholders(page)
		var off := _off_window(page)
		_step("SET.%d" % i, res == "ok" and off == 0 and raw.is_empty(), "settings tab %d (%s) opens by a click: %d text control(s) off the window, raw specifiers: %s" % [
			i, tabs.get_tab_title(i), off, ", ".join(raw) if not raw.is_empty() else "none"], await _shot("settings_tab_%d" % i))
	await _close_settings()

## After the language switches of A13 the pause menu still shows (it came back invisible on v8.0.0).
func _pause_after_languages() -> void:
	var opened := await _pause_open()
	await get_tree().create_timer(0.6).timeout
	var panel := _ui(&"pause").get_node_or_null("Panel") as Control
	_step("PAUSE2", opened and panel != null and panel.modulate.a > 0.99, "after the language switches the pause menu shows (panel alpha %.2f)" % (
		panel.modulate.a if panel != null else -1.0), await _shot("pause_after_languages"))
	await _pause_resume()

func _off_window(root: Node) -> int:
	var win := get_viewport().get_visible_rect().grow(2.0)
	var n := 0
	for c: Node in root.find_children("*", "Control", true, false):
		var control := c as Control
		if control.is_visible_in_tree() and (control is Label or control is Button or control is CheckBox) and String(control.get("text")) != "" \
				and not win.encloses(control.get_global_rect()) and not _in_scroll(control):
			n += 1
	return n

func _in_scroll(node: Node) -> bool:
	var p := node.get_parent()
	while p != null:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false
