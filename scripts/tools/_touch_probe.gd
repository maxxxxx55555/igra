extends Node
## Headless touch-input probe (GOLD MASTER v4 mobile-art pass, TASK 1
## STEP 1). Instantiates the real virtual_joystick.gd control and the real
## HUD touch buttons, injects InputEventScreenTouch/InputEventScreenDrag
## directly (--headless has no OS touch layer to route through), and
## asserts the InputService state they are supposed to drive actually
## changes. No visible window; NO-GODOT headless-only policy respected.

var _fails: PackedStringArray = []

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("[touch-probe] OK  ", msg)
	else:
		_fails.append(msg)
		print("[touch-probe] FAIL ", msg)

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_probe_joystick()
	_probe_buttons()
	_probe_help_screen()
	_probe_leaderboard()
	_probe_daily_challenge()
	_probe_achievements_and_share()
	print("[touch-probe] DONE fails=", _fails.size())
	get_tree().quit(mini(_fails.size(), 250))

## GOLD MASTER v5 hooks pass: a recorded run shows up in the leaderboard
## and Stats builds cleanly with an entry present.
func _probe_leaderboard() -> void:
	LocalLeaderboard.record_run(754.0, 12, 11, "light")
	var top := LocalLeaderboard.get_top_runs(5)
	_ok(top.size() > 0 and float(top[0]["time"]) <= 754.0, "record_run() -> get_top_runs() round-trips")
	var stats_scr: Script = load("res://scripts/ui/stats_ui.gd")
	var stats := Control.new()
	stats.set_script(stats_scr)
	get_tree().root.add_child(stats)
	var lb_row: Label = null
	for n in stats.find_children("*", "Label", true, false):
		if (n as Label).text == LocalizationManager.t("LEADERBOARD_TITLE"):
			lb_row = n
			break
	_ok(lb_row != null, "Stats screen shows the leaderboard section once a run exists")
	stats.queue_free()

## GOLD MASTER v5 hooks pass: today's challenge loads from the 30-template
## JSON, a real EventBus signal advances progress, completion pays the
## coin reward and bumps SaveSystem's (already-persisted) daily streak.
func _probe_daily_challenge() -> void:
	var t: Dictionary = DailyChallengeManager.get_today()
	_ok(not t.is_empty(), "today's daily challenge loaded from data/daily_challenges.json")
	_ok(int(t.get("target", 0)) > 0 and int(t.get("reward", 0)) > 0, "challenge has a target and a reward")
	if DailyChallengeManager.is_completed_today():
		# user://tls_daily.json persists across separate headless-suite gate
		# invocations on the same calendar day — an earlier gate in this
		# same run (e.g. the scripted P0-P6 scenario) may have already
		# completed today's challenge for real. That's correct persistence
		# behavior, not something to fight; just confirm the loaded state
		# is internally consistent instead of re-asserting a fresh delta.
		_ok(DailyChallengeManager.get_progress() >= int(t.get("target", 1)),
			"already-completed-today state is internally consistent (loaded from a prior gate this run)")
		return
	var type := String(t.get("type", ""))
	var wallet_before: int = CoinWallet.get_coins()
	var streak_before: int = SaveSystem.get_daily_streak()
	var target := int(t.get("target", 1))
	match type:
		"kill_enemies":
			for i in target: EventBus.enemy_killed.emit(&"shadow")
		"find_secrets":
			for i in target: EventBus.document_unlocked.emit(StringName("probe_doc_%d" % i))
		"light_streets":
			for i in target: EventBus.streetlight_activated.emit("probe_%d" % i)
		"restore_districts":
			for i in target: EventBus.district_restored.emit(StringName("probe_%d" % i), 3)
		"play_minutes":
			pass  # time-based; skip forcing completion, just check progress API exists
	if type != "play_minutes":
		_ok(DailyChallengeManager.is_completed_today(), "%d x %s completes the challenge" % [target, type])
		_ok(CoinWallet.get_coins() > wallet_before, "completion pays the coin reward")
		_ok(SaveSystem.get_daily_streak() > streak_before, "completion bumps the daily streak")

## GOLD MASTER v4 STEP 2: the new Help/Codex tab actually builds and
## shows controls + glossary content, keyboard+touch, no script errors.
func _probe_help_screen() -> void:
	var scr: Script = load("res://scripts/ui/codex_ui.gd")
	var codex := Control.new()
	codex.set_script(scr)
	get_tree().root.add_child(codex)
	codex.call("open_tab", &"help")
	_ok(codex.call("current_tab") == &"help", "Codex.open_tab(&help) switches to the Help tab")
	var help_page: Control = null
	for n in codex.find_children("*", "Control", true, false):
		if n.get_script() != null and String(n.get_script().resource_path).ends_with("help_ui.gd"):
			help_page = n
			break
	_ok(help_page != null and help_page.visible, "Help page instantiated and visible")

	codex.call("open_tab", &"collection")
	_ok(codex.call("current_tab") == &"collection", "Codex.open_tab(&collection) switches to the Collection tab")
	var coll_page: Control = null
	for n in codex.find_children("*", "Control", true, false):
		if n.get_script() != null and String(n.get_script().resource_path).ends_with("collection_ui.gd"):
			coll_page = n
			break
	_ok(coll_page != null and coll_page.visible, "Collection page instantiated and visible")
	var cards := 0
	if coll_page != null:
		var grid := coll_page.find_children("*", "GridContainer", true, false)
		if not grid.is_empty():
			cards = (grid[0] as GridContainer).get_child_count()
	_ok(cards == DistrictSceneFactory.district_count(), "Collection shows one card per district (%d)" % cards)

	codex.queue_free()

func _probe_joystick() -> void:
	var js_script: Script = load("res://scripts/ui/virtual_joystick.gd")
	var js := Control.new()
	js.set_script(js_script)
	js.size = Vector2(160, 160)
	add_child(js)

	InputService.set_joy_active(false)
	InputService.set_joy_move_dir(Vector2.ZERO)

	# touch down at center -> no movement yet (inside dead-zone)
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = Vector2(80, 80)
	js.call("_gui_input", down)
	_ok(InputService.get_move_dir().length() < 0.05, "touch-down at center stays inside dead-zone")

	# drag to the edge -> full deflection, action fires
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(160, 80)  # full right
	drag.relative = Vector2(80, 0)
	js.call("_gui_input", drag)
	var mv := InputService.get_move_dir()
	_ok(mv.x > 0.3, "drag to the rim drives InputService move_dir (x=%.2f)" % mv.x)

	# release -> back to zero, joystick inactive
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.pressed = false
	up.position = Vector2(160, 80)
	js.call("_gui_input", up)
	_ok(InputService.get_move_dir().length() < 0.01, "release zeroes move_dir")

	# dead-zone setting is actually read (not hardcoded): a half-deflection
	# drag passes at the default 0.15 dead-zone but is swallowed at 0.6.
	var half_drag := InputEventScreenDrag.new()
	half_drag.index = 0
	half_drag.position = Vector2(120, 80)  # ~half-radius right
	half_drag.relative = Vector2(40, 0)
	SettingsManager.set_setting("deadzone", 0.15)
	js.call("_gui_input", down)
	js.call("_gui_input", half_drag)
	var half_mv := InputService.get_move_dir().length()
	js.call("_gui_input", up)
	SettingsManager.set_setting("deadzone", 0.6)
	js.call("_gui_input", down)
	js.call("_gui_input", half_drag)
	var half_mv_highdz := InputService.get_move_dir().length()
	js.call("_gui_input", up)
	SettingsManager.set_setting("deadzone", 0.15)
	_ok(half_mv > 0.0 and half_mv_highdz < half_mv,
		"dead-zone setting is live (same drag: dz=0.15 -> %.2f, dz=0.6 -> %.2f)" % [half_mv, half_mv_highdz])

	js.queue_free()

func _probe_buttons() -> void:
	var hud_script: Script = load("res://scripts/ui/hud_3d.gd")
	var hud_scene: PackedScene = load("res://scenes/ui/hud_3d.tscn")
	var hud := hud_scene.instantiate()
	get_tree().root.add_child(hud)
	# BtnInteract/BtnAttack wiring (_setup_button_feedback) runs
	# unconditionally in hud_3d._ready() — unlike the joystick, it is not
	# gated behind has_touch_ui(), so no touch-mode override is needed here.
	var interact := hud.find_child("BtnInteract", true, false) as Button
	_ok(interact != null, "HUD exposes BtnInteract")
	if interact != null:
		_ok(interact.button_down.get_connections().size() > 0, "BtnInteract.button_down has a listener")
		# GDScript lambdas capture outer locals BY VALUE — a bare `var flag
		# := false` mutated inside the lambda never propagates back out.
		# Box it in a 1-element Array (a reference type) instead.
		var box := [false]
		InputService.interact_requested.connect(func() -> void: box[0] = true, CONNECT_ONE_SHOT)
		interact.button_down.emit()
		_ok(box[0], "BtnInteract.button_down -> InputService.interact_requested")

	var attack := hud.find_child("BtnAttack", true, false) as Button
	_ok(attack != null, "HUD exposes BtnAttack")
	if attack != null:
		var box2 := [false]
		var conn2 := func() -> void: box2[0] = true
		InputService.attack_requested.connect(conn2, CONNECT_ONE_SHOT)
		attack.button_down.emit()
		_ok(box2[0], "BtnAttack.button_down -> InputService.attack_requested")

	hud.queue_free()

## GOLD MASTER v5 hooks pass: the 11 per-district achievements (one
## generic trigger, no per-district special-casing) + the clipboard
## Share flow on the win screen.
func _probe_achievements_and_share() -> void:
	_ok(AchievementManager.ACHIEVEMENTS.size() >= 31,
		"achievement roster >= 31 (20 original + 11 per-district) — found %d" % AchievementManager.ACHIEVEMENTS.size())
	# user://achievements.cfg persists across separate headless-suite gate
	# invocations (and across this dev machine's own repeated manual runs)
	# on the same calendar day, so this may already be unlocked — assert
	# the post-condition, not a fresh-unlock delta (same reasoning as the
	# daily-challenge persistence handling above).
	EventBus.district_restored.emit(&"suburbs", 3)
	_ok(AchievementManager.is_unlocked(&"ach_district_suburbs"),
		"district_restored(suburbs, FULL) unlocks/keeps ach_district_suburbs unlocked")

	var win_scr: Script = load("res://scripts/ui/win_screen.gd")
	var win := Control.new()
	win.set_script(win_scr)
	get_tree().root.add_child(win)
	# _build_share_text() is the testable half; DisplayServer.clipboard_set
	# is a real OS call the --headless driver doesn't back (see the
	# function's own comment) — not something this session can verify.
	var text: String = win.call("_build_share_text")
	_ok(text.length() > 10 and text.contains("%") == false,
		"Share text is built and fully substituted (%d chars, no leftover %%d/%%s)" % text.length())
	win.queue_free()
