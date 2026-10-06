extends Node
## rc15 play-through (the closeout's R0): the real game, played as a player through injected input events - mouse clicks
## pushed into the viewport, keys parsed through Input - with a frame saved and a state assertion at every step. One
## process per mode (PT_MODE), run by tools/qa_sim/playthrough on a fresh profile:
##   A  boot, difficulty, onboarding, controls, first monster, death, inventory, shop, upgrades, map travel, battery,
##      the four graphics tiers, the 13 languages
##   V  the bot plays the whole game with a frame at each milestone, then the victory screen, New Game+ and Save and quit
##   B  relaunch, Continue, the daily card, achievements, hardcore
##   S  the screens the others do not open: the eight Codex tabs one by one, the HUD's log and help buttons, the workbench, the credits
## A line "[pt] PASS|FAIL <id> <what> frame=<file>" per step; setup that is not input (items, coins, a teleport next to a
## monster) is named in the line. The frames are read by eye afterwards; each saved frame is hashed against the previous
## one, because a windowed run can hand back a stale frame when nothing animates (tools/qa_sim/gui_explore_runner.gd).

const OUT := "res://docs/stills/playthrough/"
const STATE_FILE := "res://.qa_logs/pt_state.json"
const WAIT_BOOT := 90.0
const WAIT_SCENE := 40.0
const CLICK_GAP := 0.12
const MOUSE_SENS := 0.003

var _mode: String = ""
var _t0: int = 0
var _steps: PackedStringArray = []
var _fails: int = 0
var _prev_hash: int = 0
var _player: Node3D = null
var _crosshair: StringName = &"default"
var _won: bool = false
var _spawn_pos: Vector3 = Vector3.ZERO
var _last_line_ms: int = 0
var _finished: bool = false
## A step that raises an engine error ends its coroutine silently; the watchdog turns that into a failed run.
const STALL_SEC := 150.0
const STALL_SEC_BOT := 420.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_mode = OS.get_environment("PT_MODE")
	_t0 = Time.get_ticks_msec()
	if DisplayServer.get_name() == "headless" or _mode == "":
		print("[pt] needs a window and PT_MODE (A, V or B): nothing to do")
		get_tree().quit(0)
		return
	print("[pt] mode=%s adapter=%s method=%s" % [_mode, RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_method()])
	AdService.enabled = false
	EventBus.crosshair_state_changed.connect(func(state: StringName) -> void: _crosshair = state)
	var mute := Timer.new()
	mute.wait_time = 1.5
	mute.autostart = true
	mute.timeout.connect(func() -> void:
		AudioServer.set_bus_mute(0, true)
		var limit := STALL_SEC_BOT if _mode == "V" else STALL_SEC
		if float(Time.get_ticks_msec() - _last_line_ms) / 1000.0 > limit:
			_step("STALL", false, "no step for %.0f s: a step raised an engine error and stopped (see the log)" % limit)
			_finish())
	add_child(mute)
	_last_line_ms = Time.get_ticks_msec()
	call_deferred("_run")

func _run() -> void:
	match _mode:
		"A":
			await _mode_a()
		"V":
			await _mode_v()
		"B":
			await _mode_b()
		"S":
			await _mode_s()
		_:
			_step("PT", false, "unknown PT_MODE '%s'" % _mode)
	_finish()

# ── reporting ────────────────────────────────────────────────────────────────
func _say(line: String) -> void:
	print(line)
	_steps.append(line)
	_last_line_ms = Time.get_ticks_msec()

func _step(id: String, ok: bool, what: String, frame: String = "") -> void:
	if not ok:
		_fails += 1
	_say("[pt] %s %s %s%s" % ["PASS" if ok else "FAIL", id, what, ("  frame=" + frame) if frame != "" else ""])

func _finish() -> void:
	if _finished:
		return
	_finished = true
	var path := ProjectSettings.globalize_path("res://.qa_logs/playthrough_%s.txt" % _mode)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		for line in _steps:
			f.store_line(line)
		f.close()
	print("[pt] DONE mode=%s steps=%d fails=%d time=%.0fs" % [_mode, _steps.size(), _fails, float(Time.get_ticks_msec() - _t0) / 1000.0])
	get_tree().quit(1 if _fails > 0 else 0)

## A frame is kept at 1280 px wide in JPEG: a full-size PNG of this grainy night is 2 to 8 MB, 40 of them would double the repo.
const FRAME_WIDTH := 1280
const FRAME_QUALITY := 0.86

## Saves the frame the player sees. A frame identical to the previous saved one is retried (a windowed run can return a
## stale image when nothing animates) and, if it stays identical, flagged in the returned name.
func _shot(name: String) -> String:
	var abs_dir := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(abs_dir)
	var same := false
	for attempt in 3:
		for n in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_tree().root.get_texture().get_image()
		var h := hash(img.get_data())
		same = h == _prev_hash
		if not same or attempt == 2:
			var width := mini(img.get_width(), FRAME_WIDTH)
			img.resize(width, int(float(img.get_height()) * width / img.get_width()), Image.INTERPOLATE_LANCZOS)
			img.save_jpg(abs_dir.path_join(name + ".jpg"), FRAME_QUALITY)
			_prev_hash = h
			break
		await get_tree().create_timer(0.4).timeout
	return name + ".jpg" + (" (identical to the previous frame)" if same else "")

# ── waiting ──────────────────────────────────────────────────────────────────
func _scene() -> Node:
	return get_tree().current_scene

func _wait_until(pred: Callable, timeout_sec: float) -> bool:
	var t := 0.0
	while t < timeout_sec:
		if pred.call():
			return true
		await get_tree().create_timer(0.2).timeout
		t += 0.2
	return pred.call()

func _wait_scene(path: String, timeout_sec: float) -> bool:
	return await _wait_until(func() -> bool:
		var s := get_tree().current_scene
		return s != null and s.scene_file_path == path, timeout_sec)

func _wait_playing() -> bool:
	var ok := await _wait_until(func() -> bool:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return GameManager.is_playing() and _player != null and is_instance_valid(_player), 60.0)
	if ok:
		await get_tree().create_timer(2.0).timeout
	return ok

# ── input ────────────────────────────────────────────────────────────────────
## A left click at the middle of a control, pushed into the viewport like the OS would: motion first (hover), then press
## and release. A click that another control would swallow is reported, not sent - that is what a player would see.
func _click(c: Control) -> String:
	if c == null or not is_instance_valid(c):
		return "missing"
	if not c.is_visible_in_tree():
		return "hidden"
	var vp := get_viewport()
	var pos := c.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	vp.push_input(move, true)
	await get_tree().process_frame
	var hovered := vp.gui_get_hovered_control()
	if hovered != null and hovered != c and not c.is_ancestor_of(hovered):
		return "blocked by %s (the click point holds: %s)" % [hovered.get_path(), _stack_at(pos)]
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		vp.push_input(ev, true)
		await get_tree().create_timer(CLICK_GAP).timeout
	return "ok"

func _layer_of(node: Node) -> String:
	var p := node.get_parent()
	while p != null:
		if p is CanvasLayer:
			return str((p as CanvasLayer).layer)
		p = p.get_parent()
	return "0"

## Every visible control that takes the mouse at a point, with the alpha it is drawn at: what a click there would meet.
func _stack_at(pos: Vector2) -> String:
	var parts: PackedStringArray = []
	for n in get_tree().root.find_children("*", "Control", true, false):
		var control := n as Control
		if control.is_visible_in_tree() and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.get_global_rect().has_point(pos):
			var alpha := 1.0
			var node: Node = control
			while node != null:
				if node is CanvasItem:
					alpha *= (node as CanvasItem).modulate.a * (node as CanvasItem).self_modulate.a
				node = node.get_parent()
			parts.append("%s rect=%s alpha=%.2f layer=%s" % [control.get_path(), control.get_global_rect(), alpha, _layer_of(control)])
	return " | ".join(parts)

## The control the pointer would be over at a point (a motion event first), as a path: what a player is looking at there.
func _top_at(pos: Vector2) -> String:
	var move := InputEventMouseMotion.new()
	move.position = pos
	move.global_position = pos
	get_viewport().push_input(move, true)
	await get_tree().process_frame
	var c := get_viewport().gui_get_hovered_control()
	return str(c.get_path()) if c != null else ""

func _center() -> Vector2:
	return get_viewport().get_visible_rect().size * 0.5

func _key_event(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)

func _tap(code: Key, hold: float = 0.1) -> void:
	_key_event(code, true)
	await get_tree().create_timer(hold).timeout
	_key_event(code, false)
	await get_tree().create_timer(CLICK_GAP).timeout

func _hold(codes: Array, seconds: float) -> void:
	for code in codes:
		_key_event(code, true)
	await get_tree().create_timer(seconds).timeout
	for code in codes:
		_key_event(code, false)
	await get_tree().process_frame

func _mouse_look(relative: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.relative = relative
	ev.position = get_viewport().get_visible_rect().size * 0.5
	Input.parse_input_event(ev)
	await get_tree().process_frame

func _attack_click() -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = get_viewport().get_visible_rect().size * 0.5
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		Input.parse_input_event(ev)
		await get_tree().create_timer(0.08).timeout

# ── finding things ───────────────────────────────────────────────────────────
func _buttons(root: Node) -> Array[Button]:
	var out: Array[Button] = []
	for n in root.find_children("*", "Button", true, false):
		out.append(n as Button)
	return out

func _button_with(root: Node, text: String) -> Button:
	for b in _buttons(root):
		if b.text == text and b.is_visible_in_tree():
			return b
	return null

func _ui(id: StringName) -> Control:
	return UIManager._get_screen(id)

func _ui_open(id: StringName) -> bool:
	var screen := _ui(id)
	return screen != null and screen.visible

func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)

func _state() -> Dictionary:
	var inv := {}
	for slot in InventoryManager.slots:
		if slot != null:
			inv[String(slot["item_id"])] = int(inv.get(String(slot["item_id"]), 0)) + int(slot["count"])
	var stages := {}
	for district in PowerGrid.all_districts():
		stages[String(district.id)] = district.stage
	return {"district": String(DistrictManager.current_district), "coins": CoinWallet.get_coins(), "level": XpManager.get_level(),
		"ng": NewGamePlus.get_current_ng_plus(), "inventory": inv, "stages": stages, "kills": ProgressTracker.kills,
		"docs": ProgressTracker.count_docs(), "photos": SaveSystem.get_photo_count(), "deaths": ProgressTracker.deaths}

## The menu a player clicks: UIManager keeps its own main-menu screen on a CanvasLayer above the scene's menu, so the
## buttons that take the click are the screen's whenever it is visible.
func _menu_vbox() -> Node:
	var screen: Control = UIManager._cache.get(&"main_menu", null)
	if screen != null and screen.visible:
		return screen.get_node_or_null("VBox")
	var s := _scene()
	return s.get_node_or_null("VBox") if s != null else null

func _go_menu() -> bool:
	Routes.goto(Routes.MENU)
	var ok := await _wait_scene(Routes.MENU, WAIT_SCENE)
	await get_tree().create_timer(0.8).timeout
	return ok

func _pause_open() -> bool:
	await _tap(KEY_ESCAPE)
	return await _wait_until(func() -> bool: return _ui_open(&"pause"), 3.0)

func _pause_resume() -> void:
	var resume := _button_with(_ui(&"pause"), LocalizationManager.t("resume"))
	await _click(resume)
	await _wait_until(func() -> bool: return not _ui_open(&"pause") and GameManager.is_playing(), 3.0)

# ── mode A: a fresh profile, the menus and the controls ──────────────────────
func _mode_a() -> void:
	if not await _a01_boot():
		return
	if not await _a02_start():
		return
	await _a03_onboarding()
	await _a04_controls()
	await _a04_ghosts()
	if OS.get_environment("PT_STOP") == "A04g":
		return
	await _a05_monster()
	if OS.get_environment("PT_STOP") == "A05":
		return
	await _a05_death()
	await _a06_inventory()
	await _a06_shop()
	await _a07_map()
	if OS.get_environment("PT_STOP") == "A07":
		return
	await _a08_battery()
	await _a09_skills()
	await _a12_tiers()
	await _a13_languages()
	await _a15_back_to_menu()

func _a01_boot() -> bool:
	var t0 := Time.get_ticks_msec()
	Routes.goto(Routes.BOOT)
	await get_tree().create_timer(1.5).timeout
	var boot_top := await _top_at(_center())
	_step("A01a", boot_top != "" and not boot_top.contains("main_menu"), "the launch shows the loading screen, not a menu (top control %s)" % boot_top, await _shot("A01_boot_loading"))
	var reached := await _wait_scene(Routes.MENU, WAIT_BOOT)
	var secs := float(Time.get_ticks_msec() - t0) / 1000.0
	await get_tree().create_timer(1.0).timeout
	var vb: Node = _menu_vbox()
	var has_continue := vb != null and vb.get_node_or_null("Continue") != null
	_step("A01", reached and GameManager.is_menu() and not has_continue,
		"boot reaches the main menu in %.1f s, no Continue on a fresh profile (language %s)" % [secs, LocalizationManager.current_lang], await _shot("A01_menu"))
	return reached

func _a02_start() -> bool:
	var vb: Node = _menu_vbox()
	var res := await _click(vb.get_node("Difficulty") as Button)
	var in_screen := await _wait_scene(Routes.DIFFICULTY, WAIT_SCENE)
	await get_tree().create_timer(0.6).timeout
	var described := true
	for pick in ["Easy", "Normal", "Hard"]:
		var label := _scene().get_node_or_null("Panel/%sDesc" % pick) as Label
		described = described and label != null and label.text != ""
	var top := await _top_at(_center())
	_step("A02", res == "ok" and in_screen and described and top.begins_with("/root/Difficulty"),
		"the Difficulty button opens the screen on top, with a description under each pick (click: %s, top control %s)" % [res, top], await _shot("A02_difficulty"))
	var normal := _scene().get_node_or_null("Panel/Normal") as Button
	if normal == null:
		return false
	res = await _click(normal)
	var back_in_menu := await _wait_scene(Routes.MENU, WAIT_SCENE)
	await get_tree().create_timer(1.0).timeout
	_step("A02b", res == "ok" and back_in_menu and int(SettingsManager.get_setting("difficulty", -1)) == 1 and not GameManager.is_playing(),
		"Normal sets the difficulty and returns to the menu: a pick starts nothing (click: %s)" % res, await _shot("A02_difficulty_picked"))
	var res_play := await _click(_menu_vbox().get_node("Play") as Button)
	var started := await _wait_playing()
	if started:
		_spawn_pos = _player.global_position
	_step("A02c", res_play == "ok" and started, "Play starts the game and the player spawns (click: %s)" % res_play, await _shot("A02_game_start"))
	return started

func _a03_onboarding() -> void:
	var overlay := _scene().get_node_or_null("OnboardingOverlay")
	var showing: bool = overlay != null and bool(overlay.get("_showing"))
	_step("A03", showing, "the onboarding card opens on the first start of a fresh profile", await _shot("A03_onboarding_1"))
	if overlay == null or not showing:
		return
	var p0 := _player.global_position
	await _hold([KEY_W], 1.0)
	var walked := _flat(_player.global_position - p0).length()
	_say("[pt] note A03 the player walked %.1f m in 1 s of W while the card covers the screen" % walked)
	var clicks := 0
	while bool(overlay.get("_showing")) and clicks < 10:
		var next := overlay.find_child("NextBtn", true, false) as Button
		var index := int(overlay.get("_index"))
		if index == 3 or index == 6:
			_say("[pt] note A03 card %d frame=%s" % [index + 1, await _shot("A03_onboarding_%d" % (index + 1))])
		if await _click(next) != "ok":
			break
		clicks += 1
	_step("A03b", not bool(overlay.get("_showing")) and SaveSystem.is_onboard_done() and clicks == 7,
		"Next seven times closes the card and the profile remembers it (%d clicks)" % clicks, await _shot("A03_onboarding_done"))

## The pale translucent squares that came and went in the lower right of the world frames (the flashlight's dust: a
## billboard that ignored the particle scale, so each speck was an 8 cm square by the hand). Eight frames of the standing
## player: the lower-right corner may not be brighter than the clearest of them by more than GHOST_LEVEL (0 to 255 after
## averaging the corner down). Measured: the defect 4 to 8 above the clearest in 2 to 4 of 8 frames; the same scene with the
## fix 1.9 and without any dust 1.5 to 2.4 over 24 frames (`docs/artifacts/rc15/ghost_sweep_*.txt`).
const GHOST_FRAMES := 8
const GHOST_LEVEL := 3.5

func _corner_level() -> float:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_tree().root.get_texture().get_image()
	var corner := img.get_region(Rect2i(int(img.get_width() * 0.7), int(img.get_height() * 0.82), int(img.get_width() * 0.3), int(img.get_height() * 0.18)))
	corner.resize(16, 6, Image.INTERPOLATE_BILINEAR)
	var sum := 0.0
	for y in 6:
		for x in 16:
			sum += corner.get_pixel(x, y).get_luminance()
	return sum / 96.0 * 255.0

func _a04_ghosts() -> void:
	_key_event(KEY_W, true)
	await get_tree().create_timer(1.2).timeout
	_key_event(KEY_W, false)
	await get_tree().create_timer(0.4).timeout
	var ghosts := 0
	var levels: Array[float] = []
	var hurt := 0.0
	for attempt in 4:
		# a hit makes the screen edges flash ember, which is no ghost: that window is measured again
		var damage0 := ProgressTracker.damage_taken
		levels.clear()
		for i in GHOST_FRAMES:
			levels.append(await _corner_level())
			await get_tree().create_timer(0.2).timeout
		hurt = ProgressTracker.damage_taken - damage0
		if hurt == 0.0:
			break
		await get_tree().create_timer(3.0).timeout
	ghosts = 0
	for level in levels:
		ghosts += 1 if level - levels.min() > GHOST_LEVEL else 0
	_step("A04h", ghosts == 0 and hurt == 0.0, "no pale square comes and goes in the lower-right corner (%d of %d frames brighter than the clearest by more than %.1f; corner %.1f to %.1f; hurt in the window %.0f by %s)" % [ghosts, GHOST_FRAMES, GHOST_LEVEL, levels.min(), levels.max(), hurt, ProgressTracker.last_hit_by], await _shot("A04_corner"))

func _a04_controls() -> void:
	_playing_or_fail()
	_step("A04", Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED, "the mouse is captured while playing (mode %d)" % Input.get_mouse_mode())
	var yaw0 := _player.rotation.y
	await _mouse_look(Vector2(200.0, 0.0))
	var turned := wrapf(_player.rotation.y - yaw0, -PI, PI)
	_step("A04a", absf(turned + 200.0 * MOUSE_SENS) < 0.05, "a 200 px mouse move turns the view %.2f rad (expected %.2f)" % [turned, -200.0 * MOUSE_SENS])
	await _mouse_look(Vector2(-200.0, 0.0))
	var lit_before := bool(_player.get("flashlight_enabled"))
	await _tap(KEY_F)
	var lit_after := bool(_player.get("flashlight_enabled"))
	await get_tree().create_timer(0.3).timeout
	_step("A04b", lit_before != lit_after, "F toggles the flashlight (%s -> %s)" % [lit_before, lit_after], await _shot("A04_flashlight_off" if not lit_after else "A04_flashlight_on"))
	if not lit_after:
		await _tap(KEY_F)
	var stamina_before := float(_player.get("stamina"))
	var p0 := _player.global_position
	_key_event(KEY_W, true)
	await get_tree().create_timer(2.0).timeout
	var walked := _flat(_player.global_position - p0).length()
	var shot_walk := await _shot("A04_walk")
	var stamina_walk := float(_player.get("stamina"))
	_key_event(KEY_W, false)
	await get_tree().create_timer(0.3).timeout
	_step("A04c", walked / 2.0 >= 2.0 and walked / 2.0 <= 4.0, "W walks %.1f m in 2 s (%.1f m/s, a person walks 1.4 to 3.5)" % [walked, walked / 2.0], shot_walk)
	_step("A04c2", stamina_walk >= stamina_before - 2.0, "starting to walk costs no stamina (%.0f -> %.0f): one press is not a dodge" % [stamina_before, stamina_walk])
	await get_tree().create_timer(1.0).timeout
	var stamina0 := float(_player.get("stamina"))
	p0 = _player.global_position
	_key_event(KEY_SHIFT, true)
	_key_event(KEY_W, true)
	await get_tree().create_timer(1.5).timeout
	var run_state := int(_player.get("current_state"))
	var stamina1 := float(_player.get("stamina"))
	var shot_run := await _shot("A04_run")
	_key_event(KEY_W, false)
	_key_event(KEY_SHIFT, false)
	var ran := _flat(_player.global_position - p0).length()
	_step("A04d", ran / 1.5 >= 3.8 and ran / 1.5 <= 6.0 and stamina1 < stamina0 and run_state == 2, "Shift+W runs %.1f m in 1.5 s (%.1f m/s), stamina %.0f -> %.0f, state %d" % [ran, ran / 1.5, stamina0, stamina1, run_state], shot_run)
	await get_tree().create_timer(1.0).timeout
	var jumps0 := ProgressTracker.jumps
	var y0 := _player.global_position.y
	_key_event(KEY_SPACE, true)
	await get_tree().create_timer(0.25).timeout
	var rose := _player.global_position.y - y0
	_key_event(KEY_SPACE, false)
	_step("A04e", rose > 0.2 and ProgressTracker.jumps == jumps0 + 1, "Space jumps %.2f m and counts" % rose)
	await get_tree().create_timer(1.0).timeout
	var stamina2 := float(_player.get("stamina"))
	p0 = _player.global_position
	_key_event(KEY_W, true)
	await get_tree().create_timer(0.08).timeout
	_key_event(KEY_W, false)
	await get_tree().create_timer(0.1).timeout
	_key_event(KEY_W, true)
	await get_tree().create_timer(0.25).timeout
	var stamina3 := float(_player.get("stamina"))
	var dashed := _flat(_player.global_position - p0).length()
	_key_event(KEY_W, false)
	await get_tree().create_timer(0.6).timeout
	_step("A04g", stamina3 < stamina2 and dashed > 2.5, "a double tap of W dashes %.1f m in 0.4 s (a walk covers 1.2) and costs stamina (%.0f -> %.0f, part of it regained meanwhile)" % [dashed, stamina2, stamina3])
	var capsule := (_player.get_node("CollisionShape3D") as CollisionShape3D).shape as CapsuleShape3D
	_key_event(KEY_CTRL, true)
	_key_event(KEY_W, true)
	await get_tree().create_timer(1.2).timeout
	var crouch_height := capsule.height
	var crouch_state := int(_player.get("current_state"))
	var shot_crouch := await _shot("A04_crouch")
	_key_event(KEY_W, false)
	_key_event(KEY_CTRL, false)
	await get_tree().create_timer(0.8).timeout
	_step("A04f", is_equal_approx(crouch_height, 1.2) and crouch_state == 4 and is_equal_approx(capsule.height, 1.6),
		"holding Ctrl crouches (capsule %.1f m, state %d) and releasing stands up (%.1f m)" % [crouch_height, crouch_state, capsule.height], shot_crouch)
	_player.global_position = _spawn_pos
	_player.velocity = Vector3.ZERO
	await get_tree().create_timer(0.5).timeout

func _playing_or_fail() -> void:
	if not GameManager.is_playing():
		GameManager.resume_game()

func _face(target: Vector3) -> void:
	var to := _flat(target - _player.global_position)
	_player.rotation.y = atan2(-to.x, -to.z)

## A crawler is placed 5 m ahead, turned to face the player. The nearest monster of the street would not do: a shadow dies
## in the flashlight without a swing (the first version of this step passed that way while no swing ever landed).
func _a05_monster() -> void:
	var m := (load("res://scenes/enemies/crawler_3d.tscn") as PackedScene).instantiate() as Node3D
	_scene().add_child(m)
	var ahead := -_player.global_transform.basis.z
	m.global_position = _player.global_position + _flat(ahead).normalized() * 5.0
	m.rotation.y = atan2(ahead.x, ahead.z)
	m.set("player_ref", _player)
	_face(m.global_position)
	await get_tree().create_timer(0.6).timeout
	var hp0 := float(m.get("hp"))
	var seen := await _shot("A05_monster_sight")
	_say("[pt] note A05 setup: a %s spawned 5 m ahead, turned to face the player; crosshair state '%s'" % [m.get("monster_id"), _crosshair])
	var hp_taken := ProgressTracker.damage_taken
	var t := 0.0
	var hit_frame := ""
	var start := _player.global_position
	var gap := 0.0
	while t < 25.0 and is_instance_valid(m) and int(m.get("ai_state")) != 7:
		_face(m.global_position)
		gap = _flat(m.global_position - _player.global_position).length()
		if gap > 2.2:
			_key_event(KEY_W, true)
		else:
			_key_event(KEY_W, false)
		await _attack_click()
		await get_tree().create_timer(0.45).timeout
		t += 0.6
		if is_instance_valid(m) and float(m.get("hp")) < hp0 and hit_frame == "":
			hit_frame = await _shot("A05_monster_hit")
		if float(_player.get("hp")) <= 20.0:
			break
	_key_event(KEY_W, false)
	var hp1 := float(m.get("hp")) if is_instance_valid(m) else 0.0
	var where := "last gap %.1f m, walked %.1f m" % [gap, _flat(_player.global_position - start).length()]
	_step("A05", hp1 < hp0, "injected left clicks hurt the monster (hp %.0f -> %.0f in %.1f s; the player took %.0f; %s)" % [hp0, hp1, t, ProgressTracker.damage_taken - hp_taken, where], hit_frame if hit_frame != "" else seen)
	if is_instance_valid(m) and int(m.get("ai_state")) == 7:
		_say("[pt] note A05 the monster died; frame=%s" % await _shot("A05_monster_dead"))
	elif is_instance_valid(m):
		m.queue_free()
	_player.set("hp", float(_player.stats.max_hp))

func _a05_death() -> void:
	var deaths0 := ProgressTracker.deaths
	SaveSystem.save_all()
	_say("[pt] note A05 setup: the profile is saved first (the autosave a first repair writes); with no save at all a retry is a new game")
	_player.set("hp", 5.0)
	_player.set("_damage_grace_timer", 0.0)
	_player.call("take_damage", 12.0)
	await get_tree().create_timer(0.5).timeout
	var fall := await _shot("A05_death_fall")
	var reached := await _wait_until(func() -> bool: return _ui_open(&"death"), 8.0)
	await get_tree().create_timer(0.8).timeout
	var death := _ui(&"death")
	var texts: Array[String] = []
	if death != null:
		for l in death.find_children("*", "Label", true, false):
			texts.append((l as Label).text)
	var need := ["DEATH_TIME", "DEATH_DISTRICTS", "DEATH_DOCS"]
	var shown := 0
	for key in need:
		var prefix := LocalizationManager.t(key).split("%")[0].strip_edges()
		for line in texts:
			if prefix != "" and line.contains(prefix):
				shown += 1
				break
	_step("A05b", reached and ProgressTracker.deaths == deaths0 + 1 and shown == need.size(), "HP 0 ends in the death screen with cause, time, districts and documents, one death counted (%s; deaths %d -> %d)" % [" | ".join(texts), deaths0, ProgressTracker.deaths], await _shot("A05_death_screen"))
	var retry: Button = null
	var names: PackedStringArray = []
	if death != null:
		retry = _button_with(death, LocalizationManager.t("retry"))
		for b in _buttons(death):
			names.append("%s(%s)" % [b.text, b.is_visible_in_tree()])
	var old_player := get_tree().get_first_node_in_group("player")
	var battery_at_death := float(_player.get("battery"))
	var res := await _click(retry)
	var back := await _wait_until(func() -> bool: return GameManager.is_playing() and get_tree().get_first_node_in_group("player") != null and get_tree().get_first_node_in_group("player") != old_player, 40.0)
	_player = get_tree().get_first_node_in_group("player") as Node3D
	var samples: PackedStringArray = []
	for n in 8:
		samples.append("%.0f/%.0f" % [float(_player.get("hp")), float(_player.get("battery"))])
		await get_tree().create_timer(0.25).timeout
	_say("[pt] note A05c new player: a different node from the dead one: %s; hp/battery each 0.25 s: %s; battery at death %.0f; pending respawn %s" % [_player != old_player, " ".join(samples), battery_at_death, GameManager.get("_respawn_battery")])
	var hp_ratio: float = float(samples[0].split("/")[0]) / float(_player.stats.max_hp)
	_step("A05c", res == "ok" and back and hp_ratio >= 0.45 and hp_ratio <= 0.55, "Retry respawns the player at HP %.0f%% (click: %s; buttons %s)" % [hp_ratio * 100.0, res, ", ".join(names)], await _shot("A05_respawn"))

func _a06_inventory() -> void:
	InventoryManager.try_add(&"battery", 2)
	InventoryManager.try_add(&"medkit", 1)
	_player.set("battery", 20.0)
	await _tap(KEY_TAB)
	var open := await _wait_until(func() -> bool: return _ui_open(&"inventory"), 3.0)
	await get_tree().create_timer(0.5).timeout
	_say("[pt] note A06 setup: two batteries and a medkit added to the pack")
	var inv := _ui(&"inventory")
	_step("A06", open, "Tab opens the inventory screen", await _shot("A06_inventory"))
	if not open:
		return
	var slot := -1
	for i in InventoryManager.slots.size():
		if InventoryManager.slots[i] != null and InventoryManager.slots[i]["item_id"] == &"battery":
			slot = i
	var cell_index := 0
	for i in slot:
		if InventoryManager.slots[i] != null:
			cell_index += 1
	var cell := inv._grid.get_child(cell_index) as Button
	var res := await _click(cell)
	await get_tree().create_timer(0.3).timeout
	var shot_select := await _shot("A06_inventory_selected")
	var use := _button_with(inv, LocalizationManager.t("INV_USE"))
	var count0 := InventoryManager.count_of(&"battery")
	var res_use := await _click(use)
	await get_tree().create_timer(0.4).timeout
	_step("A06b", res == "ok" and res_use == "ok" and InventoryManager.count_of(&"battery") == count0 - 1 and float(_player.get("battery")) > 20.0,
		"select the battery, press Use: one battery spent, the light recharged to %.0f%% (clicks: %s / %s)" % [float(_player.get("battery")), res, res_use], shot_select)
	await _tap(KEY_TAB)
	await get_tree().create_timer(0.4).timeout
	_step("A06c", not _ui_open(&"inventory") and GameManager.is_playing(), "Tab closes it and the game runs on")

func _a06_shop() -> void:
	CoinWallet.add(3000)
	_say("[pt] note A06 setup: 3000 coins added (the cheapest shop item costs 1000)")
	var opened := await _pause_open()
	_step("A06d", opened, "Esc opens the pause menu", await _shot("A06_pause"))
	var pause := _ui(&"pause")
	var res := await _click(_button_with(pause, LocalizationManager.t("SHOP_COINS")))
	await get_tree().create_timer(0.7).timeout
	var screens := _scene().get_node("Screens")
	var in_shop: bool = String(screens.get("_active_screen")) == "Shop"
	var coins0 := CoinWallet.get_coins()
	var buy := _button_with(screens, LocalizationManager.t("SCR_KUPIT"))
	var stock := 0
	for b in _buttons(screens):
		stock += int(b.text == LocalizationManager.t("SCR_KUPIT") and b.is_visible_in_tree())
	var grid := screens.find_child("ShopGrid", true, false) as Control
	_step("A06e0", stock > 0, "the shop lists something to buy (%d items; grid %s, %d cards, visible %s)" % [stock, grid.get_global_rect() if grid != null else "none", grid.get_child_count() if grid != null else 0, grid.is_visible_in_tree() if grid != null else false])
	var shot_shop := await _shot("A06_shop")
	var res_buy := await _click(buy)
	await get_tree().create_timer(0.5).timeout
	_step("A06e", res == "ok" and in_shop and res_buy == "ok" and CoinWallet.get_coins() < coins0 and buy.disabled,
		"Pause > Shop opens the card; Buy takes %d coins, grants the item and marks the card '%s' (clicks: %s / %s)" % [coins0 - CoinWallet.get_coins(), buy.text, res, res_buy], await _shot("A06_shop_bought"))
	_say("[pt] note A06 the card before the purchase: frame=%s" % shot_shop)
	await _click(_button_with(screens, LocalizationManager.t("SCR_ZAKRYT")))
	await get_tree().create_timer(0.4).timeout
	var res_up := await _click(_button_with(pause, LocalizationManager.t("CRAFT_UPGRADE")))
	await get_tree().create_timer(0.7).timeout
	var in_up: bool = String(screens.get("_active_screen")) == "FlashlightUpgrade"
	var levels0 := _upgrade_levels()
	var coins1 := CoinWallet.get_coins()
	var shot_up := await _shot("A06_upgrades")
	var cost_button: Button = null
	for b in _buttons(screens):
		if b.is_visible_in_tree() and b.text.is_valid_int():
			cost_button = b
			break
	var res_cost := await _click(cost_button)
	await get_tree().create_timer(0.6).timeout
	_step("A06f", res_up == "ok" and in_up and res_cost == "ok" and _upgrade_levels() == levels0 + 1 and CoinWallet.get_coins() < coins1,
		"Pause > Upgrades opens the five branches; a cost button buys one level (%d -> %d, clicks: %s / %s)" % [levels0, _upgrade_levels(), res_up, res_cost], shot_up)
	await _click(_button_with(screens, LocalizationManager.t("SCR_ZAKRYT")))
	await get_tree().create_timer(0.3).timeout
	await _pause_resume()
	_step("A06g", GameManager.is_playing() and not _ui_open(&"pause"), "Resume returns to the game")

func _upgrade_levels() -> int:
	var total := 0
	for b in FlashlightUpgradeManager.get_all_data():
		total += int(b["level"])
	return total

func _a07_map() -> void:
	await _tap(KEY_K)
	var open := await _wait_until(func() -> bool: return _ui_open(&"city_map"), 3.0)
	await get_tree().create_timer(0.6).timeout
	var map := _ui(&"city_map")
	var disabled := 0
	var enabled := 0
	if open:
		for b in _buttons(map):
			if b.custom_minimum_size == map.get_script().get_script_constant_map()["ACTION_SIZE"]:
				if b.disabled:
					disabled += 1
				else:
					enabled += 1
	_step("A07", open and disabled == 11 and enabled == 0, "K opens the city map; on a fresh profile every row is the street you stand on or locked (%d disabled, %d travel)" % [disabled, enabled], await _shot("A07_map_fresh"))
	var list: ScrollContainer = null
	if open:
		list = map.find_children("*", "ScrollContainer", true, false)[0] as ScrollContainer
	var bar := list.get_v_scroll_bar() if list != null else null
	var hbar := list.get_h_scroll_bar() if list != null else null
	_step("A07c", bar != null and bar.visible and bar.size.x >= 8.0 and bar.max_value > bar.page and not hbar.visible,
		"the map's list is longer than its window and shows a scroll bar (%s px wide, %.0f of %.0f), with no horizontal bar (rows fit: %s)" % [bar.size.x if bar != null else 0, bar.page if bar != null else 0, bar.max_value if bar != null else 0, str(hbar != null and not hbar.visible)])
	if list != null:
		list.scroll_vertical = int(bar.max_value)
		await get_tree().process_frame
		_say("[pt] note A07 the list scrolled to its end, frame=%s" % await _shot("A07_map_scrolled"))
		list.scroll_vertical = 0
	await _tap(KEY_K)
	await get_tree().create_timer(0.4).timeout
	for id in [&"suburbs"]:
		PowerGrid.advance_district(id, DistrictData.Stage.FULL)
	_say("[pt] note A07 setup: the Suburbs set to FULL so that Residential opens")
	await _tap(KEY_K)
	await _wait_until(func() -> bool: return _ui_open(&"city_map"), 3.0)
	await get_tree().create_timer(0.5).timeout
	map = _ui(&"city_map")
	var travel: Button = null
	for b in _buttons(map):
		if b.text == LocalizationManager.t("MAP_TRAVEL") and not b.disabled and b.is_visible_in_tree():
			travel = b
			break
	var res := await _click(travel)
	var arrived := await _wait_until(func() -> bool: return String(DistrictManager.current_district) == "residential", 30.0)
	await get_tree().create_timer(3.0).timeout
	_player = get_tree().get_first_node_in_group("player") as Node3D
	var ghosts: PackedStringArray = []
	for b in _buttons(get_tree().root):
		if b.is_visible_in_tree() and not _ui_open(&"city_map") and b.text.begins_with(LocalizationManager.t("MAP_LOCKED_BY").split("%")[0].strip_edges()):
			ghosts.append(str(b.get_path()))
	_step("A07b", res == "ok" and arrived and GameManager.is_playing() and ghosts.is_empty(), "Travel on the open row moves the player to %s and leaves no map rows on screen (click: %s; stray: %s)" % [DistrictManager.current_district, res, ", ".join(ghosts)], await _shot("A07_travel_residential"))

func _a08_battery() -> void:
	if not bool(_player.get("flashlight_enabled")):
		await _tap(KEY_F)
	_player.call("consume_battery", float(_player.get("battery")) - 18.0)
	await get_tree().create_timer(1.6).timeout
	var hud := _scene().get_node("HUD")
	_step("A08", String(hud.notice.text) == LocalizationManager.t("HUD_HINT_BATTERY") or hud._hints_shown.has("battery"), "a light at 18%% shows the battery hint ('%s')" % hud.notice.text, await _shot("A08_battery_low"))
	_player.call("consume_battery", float(_player.get("battery")))
	await get_tree().create_timer(1.4).timeout
	var went_out := not bool(_player.get("flashlight_enabled")) and bool(_player.get("_light_died"))
	_step("A08b", went_out, "at 0%% the light goes out and stays out until a battery (enabled %s, died %s)" % [_player.get("flashlight_enabled"), _player.get("_light_died")], await _shot("A08_battery_0"))
	_player.call("consume_battery", -90.0)
	await get_tree().create_timer(0.5).timeout

func _a09_skills() -> void:
	await _tap(KEY_T)
	var open := await _wait_until(func() -> bool: return _ui_open(&"skill_tree"), 3.0)
	await get_tree().create_timer(0.6).timeout
	var tree := _ui(&"skill_tree")
	var tabs := tree.find_children("*", "TabContainer", true, false) if tree != null else []
	_step("A09", open and tabs.size() > 0, "T opens the skill tree with its branches (%d tab group)" % tabs.size(), await _shot("A09_skill_tree"))
	await _tap(KEY_T)
	await get_tree().create_timer(0.4).timeout
	_step("A09b", not _ui_open(&"skill_tree") and GameManager.is_playing(), "T closes it and the game runs on")

func _open_settings() -> Control:
	if not await _pause_open():
		return null
	await _click(_button_with(_ui(&"pause"), LocalizationManager.t("settings")))
	await _wait_until(func() -> bool: return _ui_open(&"settings"), 3.0)
	await get_tree().create_timer(0.5).timeout
	return _ui(&"settings")

func _close_settings() -> void:
	var settings := _ui(&"settings")
	var back: Button = null
	if settings != null:
		back = _button_with(settings, LocalizationManager.t("Back"))
	await _click(back)
	await get_tree().create_timer(0.4).timeout
	if _ui_open(&"settings"):
		UIManager.close(&"settings")
	await _pause_resume()

func _option_with_items(root: Node, count: int) -> OptionButton:
	for n in root.find_children("*", "OptionButton", true, false):
		if (n as OptionButton).item_count == count:
			return n as OptionButton
	return null

func _a12_tiers() -> void:
	var names := ["Low", "Medium", "High", "Ultra"]
	for tier in [0, 1, 2, 3, 2]:
		var settings := await _open_settings()
		if settings == null:
			_step("A12", false, "the settings screen did not open from the pause menu")
			return
		var tabs := settings.find_children("*", "TabContainer", true, false)[0] as TabContainer
		tabs.current_tab = 2
		await get_tree().create_timer(0.3).timeout
		var drop := _option_with_items(tabs, 4)
		if tier == 0:
			var res := await _click(drop)
			_say("[pt] note A12 the tier dropdown opens by a real click: %s frame=%s" % [res, await _shot("A12_dropdown_open")])
			if drop != null and drop.get_popup().visible:
				drop.get_popup().hide()
		drop.select(tier)
		drop.item_selected.emit(tier)
		await get_tree().create_timer(0.3).timeout
		await _close_settings()
		await get_tree().create_timer(1.6).timeout
		var calls := int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		var applied: bool = int(SettingsManager.get_setting("graphics_tier", -1)) == tier
		_step("A12.%d" % tier, applied and GameManager.is_playing(), "graphics tier %s applies live (draw calls %d, %.0f fps)" % [names[tier], calls, Engine.get_frames_per_second()], await _shot("A12_tier_%d_%s" % [tier, names[tier].to_lower()]))

func _a13_languages() -> void:
	var settings := await _open_settings()
	if settings == null:
		_step("A13", false, "the settings screen did not open")
		return
	var codes: Array = LocalizationManager.SUPPORTED
	(settings.find_children("*", "TabContainer", true, false)[0] as TabContainer).current_tab = 0
	await get_tree().create_timer(0.3).timeout
	for i in codes.size():
		var drop := _option_with_items(_ui(&"settings"), codes.size())
		if drop == null:
			_step("A13.%s" % codes[i], false, "the language dropdown is gone after the previous switch")
			continue
		drop.select(i)
		drop.item_selected.emit(i)
		await get_tree().create_timer(0.7).timeout
		var clipped := _clipped_controls(_ui(&"settings"))
		_step("A13.%s" % codes[i], LocalizationManager.current_lang == codes[i] and clipped == 0,
			"language %s: the settings screen reads in it, %d control(s) run past the window" % [codes[i], clipped], await _shot("A13_lang_%s" % codes[i]))
	var en := codes.find("en")
	var drop := _option_with_items(_ui(&"settings"), codes.size())
	if drop != null and en >= 0:
		drop.select(en)
		drop.item_selected.emit(en)
		await get_tree().create_timer(0.5).timeout
	await _close_settings()

## Visible text controls whose rectangle leaves the window.
func _clipped_controls(root: Node) -> int:
	var win := get_viewport().get_visible_rect().grow(2.0)
	var n := 0
	for c in root.find_children("*", "Control", true, false):
		var control := c as Control
		if control.is_visible_in_tree() and (control is Label or control is Button or control is CheckBox) and not win.encloses(control.get_global_rect()):
			if String(control.get("text")) != "":
				n += 1
	return n

# ── mode V: the bot plays, frames at the milestones, then victory, New Game+ and Save and quit ──
func _mode_v() -> void:
	if not await _go_menu():
		_step("V00", false, "the menu was not reached")
		return
	_step("V00", true, "menu reached", await _shot("V00_menu"))
	var marks := {"repair": false, "monster": false, "hit": false, "boss": false, "map": false}
	EventBus.district_stage_changed.connect(func(id: StringName, stage: int) -> void:
		if id == &"suburbs" and stage >= 1 and not marks["repair"]:
			marks["repair"] = true
			_milestone("V04", "the first repair lights the Suburbs (stage %d)" % stage, "V04_first_repair", 1.0))
	EventBus.player_detected.connect(func(id: StringName) -> void:
		if not marks["monster"]:
			marks["monster"] = true
			_milestone("V05", "the first monster notices the player (%s)" % id, "V05_first_monster", 0.4))
	EventBus.player_damaged.connect(func(amount: float) -> void:
		if not marks["hit"]:
			marks["hit"] = true
			_milestone("V05b", "the first hit lands on the player (%.0f)" % amount, "V05_first_hit", 0.2))
	EventBus.boss_spawned.connect(func() -> void:
		marks["boss"] = true
		_milestone("V09", "the Architect appears", "V09_boss_spawn", 1.5))
	EventBus.boss_phase_changed.connect(func(phase: int) -> void:
		_milestone("V09.%d" % phase, "the Architect enters phase %d" % phase, "V09_boss_phase_%d" % phase, 0.8))
	EventBus.game_won.connect(func() -> void: _won = true)
	var map_watch := Timer.new()
	map_watch.wait_time = 0.5
	map_watch.autostart = true
	map_watch.timeout.connect(func() -> void:
		if not marks["map"] and _ui_open(&"city_map"):
			marks["map"] = true
			_milestone("V07", "the bot opens the city map to travel", "V07_map_travel", 0.2))
	add_child(map_watch)
	var progress := Timer.new()
	progress.wait_time = 30.0
	progress.autostart = true
	progress.timeout.connect(func() -> void:
		var full := 0
		for district in PowerGrid.all_districts():
			full += int(district.stage >= DistrictData.Stage.FULL)
		var seconds := int(float(Time.get_ticks_msec() - _t0) / 1000.0)
		_say("[pt] note V the bot is in %s, %d of %d districts FULL, %d s in; frame=%s" % [DistrictManager.current_district, full, PowerGrid.all_districts().size(), seconds, await _shot("V_t%04d" % seconds)]))
	add_child(progress)
	OS.set_environment("QA_NO_QUIT", "1")
	var bot := Node.new()
	bot.set_script(load("res://scripts/tools/_qa_autoplay_runner.gd"))
	get_tree().root.add_child(bot)
	var finished := await _wait_until(func() -> bool: return _won or bot.get("_done") == true, 900.0)
	map_watch.stop()
	progress.stop()
	_step("V08", _won, "the bot reaches the win ending (%s)" % ("won" if _won else "no win in 900 s"))
	if not _won:
		return
	await _wait_until(func() -> bool: return _ui_open(&"win"), 20.0)
	await get_tree().create_timer(2.0).timeout
	var victory_open := GameManager.is_win()
	_step("V10", finished and victory_open, "the victory screen follows the win (state win: %s)" % victory_open, await _shot("V10_victory"))
	await _v11_new_game_plus()

func _milestone(id: String, what: String, frame: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	_step(id, true, what, await _shot(frame))

func _v11_new_game_plus() -> void:
	var win := _victory_screen()
	var setup: Button = null
	if win != null:
		setup = _button_with(win, LocalizationManager.t("NGP_SETUP_ACTION"))
	var res := await _click(setup)
	await get_tree().create_timer(0.8).timeout
	var ngp := _ui(&"new_game_plus")
	_step("V11", res == "ok" and ngp != null and ngp.visible, "the victory screen offers New Game+ setup (click: %s)" % res, await _shot("V11_ngp_screen"))
	if ngp == null:
		return
	var level0 := NewGamePlus.get_current_ng_plus()
	var res_act := await _click(ngp.activate_button)
	await get_tree().create_timer(0.6).timeout
	_step("V11b", res_act == "ok" and NewGamePlus.get_current_ng_plus() == level0 + 1, "Activate raises New Game+ to %d (click: %s)" % [NewGamePlus.get_current_ng_plus(), res_act], await _shot("V11_ngp_activated"))
	var picked := ""
	for b in _buttons(ngp):
		if b.is_visible_in_tree() and not b.disabled and b != ngp.activate_button and b != ngp.back_button and b.text.contains(" — "):
			picked = b.text
			await _click(b)
			break
	await get_tree().create_timer(0.5).timeout
	_step("V11c", picked != "" and NewGamePlus.get_active_modifiers().size() == 1, "one modifier can be taken for the new level ('%s')" % picked.left(40), await _shot("V11_ngp_modifier"))
	await _click(ngp.back_button)
	var in_menu := await _wait_until(func() -> bool: return _menu_vbox() != null, 20.0)
	await get_tree().create_timer(1.0).timeout
	var vb: Node = _menu_vbox()
	var play := vb.get_node("Play") as Button if vb != null else null
	_step("V11d", in_menu and play.text == LocalizationManager.tf("NGP_NEW_GAME_ACTION", [NewGamePlus.get_current_ng_plus()]), "the menu says Play is New Game+ %d ('%s')" % [NewGamePlus.get_current_ng_plus(), play.text], await _shot("V11_menu_ngp"))
	var res_play := await _click(play)
	await get_tree().create_timer(0.6).timeout
	var dialog: ConfirmationDialog = null
	for n in get_tree().root.find_children("*", "ConfirmationDialog", true, false):
		if (n as ConfirmationDialog).visible:
			dialog = n as ConfirmationDialog
	var shot_confirm := await _shot("V11_confirm")
	var res_ok := "no dialog"
	if dialog != null:
		res_ok = _press_dialog_ok(dialog)
	var started := await _wait_playing()
	_step("V11e", res_play == "ok" and res_ok == "ok" and started and NewGamePlus.get_current_ng_plus() == level0 + 1,
		"Play asks before it erases the save, and starts New Game+ %d (clicks: %s / %s)" % [NewGamePlus.get_current_ng_plus(), res_play, res_ok], shot_confirm)
	await get_tree().create_timer(2.0).timeout
	var strong := 0
	var weak := 0
	for m in get_tree().get_nodes_in_group("monsters"):
		var entry: Dictionary = m.get("roster_entry") if m.get("roster_entry") != null else {}
		if entry.has("hp"):
			if is_equal_approx(float(m.get("max_hp")), float(entry["hp"]) * NewGamePlus.get_enemy_hp_multiplier()):
				strong += 1
			else:
				weak += 1
	_step("V11f", strong > 0 and weak == 0, "New Game+ monsters carry the scaled health (%d scaled, %d not)" % [strong, weak], await _shot("V11_ng_run"))
	await _v14_save_quit()

## A ConfirmationDialog is an embedded window: the viewport's hit test cannot see into it, so its button is pressed by
## its signal and the dialog's presence and text are read from the frame.
func _press_dialog_ok(dialog: ConfirmationDialog) -> String:
	dialog.get_ok_button().pressed.emit()
	dialog.hide()
	return "ok"

func _victory_screen() -> Control:
	var s := _ui(&"win")
	return s if s != null and s.visible else null

func _v14_save_quit() -> void:
	var opened := await _pause_open()
	var pause := _ui(&"pause")
	var quit: Button = null
	if pause != null:
		quit = _button_with(pause, LocalizationManager.t("PAUSE_SAVE_QUIT"))
	_step("V14", opened and quit != null, "Esc offers Save and quit", await _shot("V14_pause"))
	var state := _state()
	state["pos"] = [_player.global_position.x, _player.global_position.y, _player.global_position.z]
	var f := FileAccess.open(ProjectSettings.globalize_path(STATE_FILE), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(state))
		f.close()
	_say("[pt] note V14 state before quitting: %s" % JSON.stringify(state))
	var path := ProjectSettings.globalize_path("res://.qa_logs/playthrough_V.txt")
	var out := FileAccess.open(path, FileAccess.WRITE)
	if out != null:
		for line in _steps:
			out.store_line(line)
		out.store_line("[pt] DONE mode=V steps=%d fails=%d (Save and quit pressed next)" % [_steps.size(), _fails])
		out.close()
	await _click(quit)
	await get_tree().create_timer(3.0).timeout
	_step("V14b", false, "the process is still running 3 s after Save and quit")

# ── mode B: the relaunch ─────────────────────────────────────────────────────
func _mode_b() -> void:
	if not await _b01_menu():
		return
	await _b02_continue()
	await _b04_daily()
	await _b05_achievements()
	await _b03_hardcore()

func _b01_menu() -> bool:
	Routes.goto(Routes.BOOT)
	var reached := await _wait_scene(Routes.MENU, WAIT_BOOT)
	await get_tree().create_timer(1.0).timeout
	var vb: Node = _menu_vbox()
	var cont: Button = null
	if vb != null:
		cont = vb.get_node_or_null("Continue") as Button
	_step("B01", reached and cont != null, "a relaunch shows Continue and the New Game+ status ('%s')" % [cont.text if cont != null else "no Continue"], await _shot("B01_menu"))
	return reached and cont != null

func _b02_continue() -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path(STATE_FILE), FileAccess.READ)
	var want: Dictionary = JSON.parse_string(f.get_as_text()) if f != null else {}
	var vb: Node = _menu_vbox()
	var res := await _click(vb.get_node("Continue") as Button)
	var started := await _wait_playing()
	var early := _state()
	await get_tree().create_timer(3.0).timeout
	var got: Dictionary = JSON.parse_string(JSON.stringify(_state()))
	_say("[pt] note B02 the run as loaded (2 s in): coins %s, kills %s; 3 s later: coins %s, kills %s" % [early["coins"], early["kills"], got["coins"], got["kills"]])
	var diffs: Array[String] = []
	# the game runs for the 3 s before the comparison: a roaming monster killed by the light earns a kill and its coins, so
	# what only grows may grow; a Continue that loses any of it is the failure
	var may_grow := ["coins", "kills", "docs", "photos"]
	for key in ["district", "coins", "level", "ng", "inventory", "stages", "kills", "docs", "photos"]:
		if not want.has(key):
			continue
		var lost: bool = float(got[key]) < float(want[key]) if key in may_grow else JSON.stringify(want[key]) != JSON.stringify(got[key])
		if lost:
			diffs.append("%s %s -> %s" % [key, JSON.stringify(want[key]).left(60), JSON.stringify(got[key]).left(60)])
	var moved := 0.0
	if want.has("pos"):
		moved = Vector3(float(want["pos"][0]), float(want["pos"][1]), float(want["pos"][2])).distance_to(_player.global_position)
	_step("B02", res == "ok" and started and diffs.is_empty() and not want.is_empty(),
		"Continue restores the saved run (click: %s; differences: %s; start %.1f m from where it was saved)" % [res, ", ".join(diffs) if not diffs.is_empty() else "none", moved], await _shot("B02_continued"))

func _b04_daily() -> void:
	if not await _go_menu():
		return
	var vb: Node = _menu_vbox()
	var card: Node = vb.get_node_or_null("DailyCard")
	var body: Label = null
	var streak: Label = null
	if card != null:
		body = card.get_node("Body") as Label
		streak = card.get_node("Streak") as Label
	_step("B04", card != null and body != null and body.text != "" and streak.text.contains("(x"),
		"the menu shows the daily challenge and the streak with its multiplier ('%s' / '%s')" % [body.text if body != null else "", streak.text if streak != null else ""], await _shot("B04_daily_card"))
	var today: Dictionary = DailyChallengeManager.get_today()
	var coins0 := CoinWallet.get_coins()
	var done_before := DailyChallengeManager.is_completed_today()
	if not done_before:
		DailyChallengeManager._tick(String(today.get("type", "kill_enemies")), int(today.get("target", 1)))
		_say("[pt] note B04 setup: today's challenge (%s x%d) completed through the manager" % [today.get("type", ""), int(today.get("target", 0))])
	await _go_menu()
	vb = _menu_vbox()
	body = vb.get_node("DailyCard/Body") as Label
	var paid := done_before or CoinWallet.get_coins() > coins0
	_step("B04b", DailyChallengeManager.is_completed_today() and paid and body.text.contains(LocalizationManager.t("DAILY_COMPLETED_LABEL")),
		"the finished challenge paid coins (%d -> %d, already done by the run: %s) and the card says Completed" % [coins0, CoinWallet.get_coins(), done_before], await _shot("B04_daily_done"))

func _b05_achievements() -> void:
	var cont: Button = _menu_vbox().get_node_or_null("Continue") as Button
	await _click(cont)
	if not await _wait_playing():
		_step("B05", false, "Continue did not return to the game")
		return
	var opened := await _pause_open()
	await _click(_button_with(_ui(&"pause"), LocalizationManager.t("CODEX_TITLE")))
	await get_tree().create_timer(0.8).timeout
	var codex := _ui(&"codex")
	var tab: Button = null
	if codex != null:
		tab = _button_with(codex, LocalizationManager.t("ACHIEVEMENTS_TITLE"))
	var res := await _click(tab)
	await get_tree().create_timer(0.8).timeout
	var unlocked := 0
	for a in AchievementManager.get_all():
		unlocked += int(bool(a["unlocked"]))
	_step("B05", opened and res == "ok" and codex != null and codex.visible, "Pause > Codex > Achievements opens the list (click: %s, %d unlocked)" % [res, unlocked], await _shot("B05_achievements"))
	await _click(_button_with(codex, LocalizationManager.t("STATS_TITLE")))
	await get_tree().create_timer(0.6).timeout
	_say("[pt] note B05 statistics tab frame=%s" % await _shot("B05_stats"))
	UIManager.close_all_blocking()
	GameManager.resume_game()

func _b03_hardcore() -> void:
	if not await _go_menu():
		_step("B03", false, "the menu did not come back")
		return
	var opened := await _click(_menu_vbox().get_node("Settings") as Button)
	await _wait_scene(Routes.SETTINGS, WAIT_SCENE)
	await get_tree().create_timer(0.8).timeout
	var settings := _scene()
	var hardcore: CheckBox = null
	for row in settings.find_children("*", "HBoxContainer", true, false):
		var kids := row.get_children()
		if kids.size() == 2 and kids[0] is Label and (kids[0] as Label).text == LocalizationManager.t("Hardcore Mode") and kids[1] is CheckBox:
			hardcore = kids[1] as CheckBox
	var res := await _click(hardcore)
	await get_tree().create_timer(0.4).timeout
	_step("B03", opened == "ok" and res == "ok" and bool(SettingsManager.get_setting("hardcore", false)), "the main menu's Settings has a Hardcore box that turns it on (clicks: %s / %s)" % [opened, res], await _shot("B03_hardcore_on"))
	await _click(_button_with(settings, LocalizationManager.t("Back")))
	await _wait_scene(Routes.MENU, WAIT_SCENE)
	await get_tree().create_timer(0.8).timeout
	await _click(_menu_vbox().get_node("Play") as Button)
	await get_tree().create_timer(0.6).timeout
	var dialog: ConfirmationDialog = null
	for n in get_tree().root.find_children("*", "ConfirmationDialog", true, false):
		if (n as ConfirmationDialog).visible:
			dialog = n as ConfirmationDialog
	_say("[pt] note B03 after Play: dialog %s, top control %s, frame=%s" % [dialog.dialog_text.left(60) if dialog != null else "none", await _top_at(_center()), await _shot("B03_play_click")])
	if dialog != null:
		_press_dialog_ok(dialog)
	var started := await _wait_playing()
	_step("B03b", started and GameManager.run_hardcore, "Play starts a run with Hardcore on (started %s, the run's hardcore %s, state %s)" % [started, GameManager.run_hardcore, GameManager.current_state])
	if not started:
		return
	_player.set("hp", 5.0)
	_player.set("_damage_grace_timer", 0.0)
	_player.set("_iframes", 0.0)
	_player.call("take_damage", 12.0)
	await get_tree().create_timer(3.0).timeout
	_step("B03c", not SaveSystem.has_save(), "dying on hardcore deletes the save (has_save: %s)" % SaveSystem.has_save(), await _shot("B03_hardcore_death"))
	SettingsManager.set_setting("hardcore", false)

## From the pause menu back to the main menu: one menu on screen, and Continue offered because a save exists.
# ── mode S: the screens the other modes do not open ──────────────────────────
## The visible texts that still hold a format specifier (\"Repair panel (needs: %s)\" as the label of a key): a string that
## was meant for tf() and reached a label raw.
func _raw_placeholders(root: Node) -> PackedStringArray:
	var found: PackedStringArray = []
	var specifier := RegEx.create_from_string("(?<!%)%[0-9.]*[sdif]")
	for n in root.find_children("*", "Control", true, false):
		var text := ""
		if n is Label:
			text = (n as Label).text
		elif n is Button:
			text = (n as Button).text
		if text != "" and (n as Control).is_visible_in_tree() and specifier.search(text) != null:
			found.append(text)
	return found

## Visible texts with a run of four Latin letters in a Russian UI: a string that skipped the translation (the credits' four
## lines were English in every language). Names, key caps and technical suffixes are left out.
const LATIN_OK := ["THE LAST STREETLIGHT", "TLS Team", "NG+", "FPS", "fps", "VSync", "Escape", "Shift", "Ctrl", "Space", "Tab", "720p", "1080p", "1440p", "Easy", "Normal", "Hard"]

func _latin_texts(root: Node) -> PackedStringArray:
	var found: PackedStringArray = []
	var latin := RegEx.create_from_string("[A-Za-z]{4,}")
	for n in root.find_children("*", "Control", true, false):
		var text := ""
		if n is Label:
			text = (n as Label).text
		elif n is Button:
			text = (n as Button).text
		if text == "" or not (n as Control).is_visible_in_tree() or latin.search(text) == null:
			continue
		var scrubbed := text
		for ok in LATIN_OK:
			scrubbed = scrubbed.replace(ok, "")
		if latin.search(scrubbed) != null:
			found.append(text)
	return found

## A list that scrolls must have a window of at least a third of the screen: a list cut to 7 of 31 rows by a 330 px window
## in a 600 px page is the defect the first run of this mode found.
const S_MIN_LIST_SHARE := 0.35

func _mode_s() -> void:
	if not await _a01_boot():
		return
	if not await _a02_start():
		return
	await _a03_onboarding()
	await _s_codex()
	await _s_hud_buttons()
	await _s_workbench()
	await _s_credits()

func _s_codex() -> void:
	UIManager.open(&"codex")
	await _wait_until(func() -> bool: return _ui_open(&"codex"), 3.0)
	await get_tree().create_timer(0.6).timeout
	var codex := _ui(&"codex")
	var viewport := get_viewport().get_visible_rect().size
	var tabs: Array = codex.get("_buttons")
	var specs: Array = (codex.get_script() as Script).get_script_constant_map()["TABS"]
	for i in tabs.size():
		var res := await _click(tabs[i] as Button)
		await get_tree().create_timer(0.7).timeout
		var worst := 1.0
		var seen := 0
		for sc in codex.find_children("*", "ScrollContainer", true, false):
			var scroll := sc as ScrollContainer
			if not scroll.is_visible_in_tree() or scroll.get_child_count() == 0:
				continue
			seen += 1
			if (scroll.get_child(0) as Control).size.y > scroll.size.y + 1.0:
				worst = minf(worst, scroll.size.y / viewport.y)
		var id := String(specs[i]["id"])
		var raw := _raw_placeholders(codex)
		var latin := _latin_texts(codex)
		if not latin.is_empty():
			_say("[pt] note S_codex_%s Latin text in a Russian UI: %s" % [String(specs[i]["id"]), " | ".join(latin).left(400)])
		_step("S_codex_" + id, res == "ok" and String(codex.call("current_tab")) == id and worst >= S_MIN_LIST_SHARE and raw.is_empty(),
			"the Codex tab %s opens by a click; its lists that scroll have a window of %.0f%% of the screen at least (%d lists); raw format specifiers on screen: %s" % [id, worst * 100.0, seen, ", ".join(raw) if not raw.is_empty() else "none"], await _shot("S_codex_" + id))
	UIManager.close_all_blocking()
	GameManager.resume_game()
	await get_tree().create_timer(0.5).timeout

func _s_hud_buttons() -> void:
	for text in [LocalizationManager.t("HUD_LOG_TOGGLE"), "?"]:
		var button: Button = null
		for b in _buttons(get_tree().root):
			if b.text == text and b.is_visible_in_tree():
				button = b
		var res := await _click(button)
		await get_tree().create_timer(0.7).timeout
		_step("S_hud_" + ("log" if text != "?" else "help"), res == "ok", "the HUD button '%s' answers a click (%s)" % [text, res], await _shot("S_hud_" + ("log" if text != "?" else "help")))
		if text == "?":
			UIManager.close_all_blocking()
			GameManager.resume_game()
		else:
			await _click(button)
		await get_tree().create_timer(0.4).timeout

func _s_workbench() -> void:
	UIManager.open(&"workbench")
	var open := await _wait_until(func() -> bool: return _ui_open(&"workbench"), 3.0)
	await get_tree().create_timer(0.7).timeout
	var latin := _latin_texts(_ui(&"workbench"))
	if not latin.is_empty():
		_say("[pt] note S_workbench Latin text in a Russian UI: %s" % " | ".join(latin).left(400))
	_step("S_workbench", open, "the workbench screen opens", await _shot("S_workbench"))
	UIManager.close_all_blocking()
	GameManager.resume_game()
	await get_tree().create_timer(0.4).timeout

func _s_credits() -> void:
	if not await _go_menu():
		_step("S_credits", false, "the menu did not come back")
		return
	var res := await _click(_menu_vbox().get_node("Credits") as Button)
	var reached := await _wait_scene(Routes.CREDITS, WAIT_SCENE)
	await get_tree().create_timer(1.0).timeout
	var latin := _latin_texts(_scene())
	_step("S_credits", res == "ok" and reached and latin.is_empty(), "the main menu's Credits opens the credits, all in the language of the UI (click: %s; Latin text: %s)" % [res, " | ".join(latin) if not latin.is_empty() else "none"], await _shot("S_credits"))

func _a15_back_to_menu() -> void:
	SaveSystem.save_all()
	var opened := await _pause_open()
	await _click(_button_with(_ui(&"pause"), LocalizationManager.t("back_menu")))
	var reached := await _wait_until(func() -> bool: return GameManager.is_menu() and _menu_vbox() != null, 15.0)
	await get_tree().create_timer(1.2).timeout
	var vb: Node = _menu_vbox()
	var cont: Node = vb.get_node_or_null("Continue") if vb != null else null
	var menus := 0
	for n in get_tree().root.find_children("*", "Control", true, false):
		if n.is_visible_in_tree() and n.get_script() != null and String(n.get_script().resource_path).ends_with("scripts/ui/main_menu.gd"):
			menus += 1
	_step("A15", opened and reached and cont != null and menus == 1, "Main menu from the pause menu: one menu (%d), Continue offered (%s)" % [menus, cont != null], await _shot("A15_menu_after_play"))
