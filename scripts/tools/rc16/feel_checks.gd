extends RefCounted
## Session 23 (docs/WEAPON_FEEL.md, docs/MOVEMENT_FEEL.md, docs/POLISH.md): the feel of the game at run time: hit-stop, the camera, the walk, the bursts of a find, the
## feedback of the UI and the tutorial's hints. Wired into _closeout_check_runner.gd as `await Rc23Feel.run(self)`; CLOSEOUT_ONLY=s23 runs it with the others.

const FAR := Vector3(500.0, 0.0, 500.0)
const ONBOARDING := preload("res://scripts/ui/onboarding_overlay.gd")
const REFERENCE_DISTANCE_M: float = 5.0  # the shake is measured on a point this far ahead of the camera
const FRAME_HEIGHT_PX: float = 1080.0
const NARROWEST_FOV_DEG: float = 48.0  # the interior view of camera_follow_3d.gd

static func run(r: Node) -> void:
	r._playing()
	UIManager.close_all_blocking()
	await _hit_stop(r)
	await _melee_stops_time(r)
	await _shake_px(r)
	_camera(r)
	_breath(r)
	_bursts(r)
	_weapons(r)
	await _walk_eases(r)
	await _ui_feedback(r)
	await _screens_ease(r)
	await _tutorial(r)
	r._playing()

## JUICE1: a hit-stop freezes time (a quarter speed) for 80 ms at most of real time, gives back the time scale it found (a run at 2x comes back to 2x),
## and does nothing with Reduce Time Effects.
static func _hit_stop(r: Node) -> void:
	var scale0: float = Engine.time_scale
	SettingsManager.set_setting("reduce_time_fx", false)
	Engine.time_scale = 2.0
	var started: int = Time.get_ticks_msec()
	WowDirector.hit_stop(80.0)
	var dipped: float = Engine.time_scale
	while not is_equal_approx(Engine.time_scale, 2.0) and Time.get_ticks_msec() - started < 400:
		await r.get_tree().process_frame
	var elapsed: int = Time.get_ticks_msec() - started
	var back: float = Engine.time_scale
	SettingsManager.set_setting("reduce_time_fx", true)
	WowDirector.hit_stop(80.0)
	var gated: bool = is_equal_approx(Engine.time_scale, 2.0)
	SettingsManager.set_setting("reduce_time_fx", false)
	Engine.time_scale = scale0
	r._ok(is_equal_approx(dipped, 0.5) and elapsed >= 30 and elapsed <= 140 and is_equal_approx(back, 2.0) and gated, "JUICE1 hit-stop: a run at 2x dips to %.2fx, is back at %.1fx after %d ms of real time (80 ms asked), and does nothing with Reduce Time Effects (%s)" % [dipped, back, elapsed, gated])

## JUICE2: a melee hit that lands stops time for 50 ms (80 ms for the last hit of a combo).
static func _melee_stops_time(r: Node) -> void:
	var player: Node3D = r._player
	var monster: Node3D = r._monster("crawler_3d", FAR)
	var phase0: Variant = player.get("_attack_phase")
	var stops: Array[float] = []
	for finisher: bool in [false, true]:
		player.set("_attack_phase", "active")
		player.set("_hit_registered", false)
		player.set("_attack_idx", 0)
		player.set("_chain_landed", finisher)
		monster.set("hp", 1000.0)
		monster.set("ai_state", BaseMonster.State.IDLE)
		player.call("_on_attack_hit", monster)
		stops.append(Engine.time_scale)
		await r.get_tree().create_timer(0.3).timeout
	player.set("_attack_phase", phase0)
	player.set("_chain_landed", false)
	monster.queue_free()
	r._ok(is_equal_approx(stops[0], 0.25) and is_equal_approx(stops[1], 0.25) and is_equal_approx(Engine.time_scale, 1.0), "JUICE2 melee hit-stop: time slows to %.2fx on a landed hit and %.2fx on a combo's last hit, and is back at %.1fx 0.3 s later" % [stops[0], stops[1], Engine.time_scale])

## JUICE3: the shake is in proportion to the trauma; at full trauma a point 5 m ahead moves 4 px or less of a 1080p frame in the narrowest view the camera uses (an interior's), and a damage
## hit (0.3) still moves it by half a pixel or more.
static func _shake_px(r: Node) -> void:
	var shake: Node = r._main.get_node("ScreenShake")
	var camera: Camera3D = r.get_viewport().get_camera_3d()
	SettingsManager.set_setting("reduce_screen_shake", false)
	SettingsManager.set_setting("reduce_camera_motion", false)
	var worst: Array[float] = [0.0, 0.0]
	for k in 2:
		for i in 16:
			shake.set("_trauma", [1.0, 0.3][k])
			await r.get_tree().process_frame
			worst[k] = maxf(worst[k], maxf(absf(camera.h_offset), absf(camera.v_offset)))
	shake.set("_trauma", 0.0)
	await r.get_tree().process_frame
	var per_m: float = FRAME_HEIGHT_PX / (2.0 * REFERENCE_DISTANCE_M * tan(deg_to_rad(NARROWEST_FOV_DEG) * 0.5))
	var px: float = worst[0] * per_m
	var px_hit: float = worst[1] * per_m
	var intensity: float = float(shake.get("shake_intensity"))
	r._ok(px <= 4.0 and worst[0] > 0.3 * intensity and worst[0] <= intensity + 0.0001 and px_hit >= 0.5, "JUICE3 screen shake: the camera moves %.4f m at most (limit %.3f m), %.2f px of 1080p at %.0f m with a %.0f degree view (limit 4 px), a damage hit %.2f px (least 0.5)" % [worst[0], intensity, px, REFERENCE_DISTANCE_M, NARROWEST_FOV_DEG, px_hit])

## JUICE4: the first-person camera opens the view 5 degrees in a sprint and 2 degrees in a landing, dips the eye in a landing from the air (not from a hop), and does
## none of it with Motion Comfort.
static func _camera(r: Node) -> void:
	var follow: Node = r._main.get_node("Camera3D")  # the main scene's camera carries camera_follow_3d.gd
	var running0: Variant = follow.get("_running")
	var kick0: Variant = follow.get("_land_kick")
	follow.set("_running", false)
	follow.set("_land_kick", 0.0)
	SettingsManager.set_setting("reduce_camera_motion", false)
	SettingsManager.set_setting("reduce_ui_motion", false)
	var base: float = float(follow.call("fov_target"))
	follow.set("_running", true)
	var sprint: float = float(follow.call("fov_target")) - base
	follow.set("_running", false)
	follow.set("_land_kick", 1.0)
	var landing: float = float(follow.call("fov_target")) - base
	SettingsManager.set_setting("reduce_camera_motion", true)
	var comfort: float = float(follow.call("fov_target")) - base
	SettingsManager.set_setting("reduce_camera_motion", false)
	follow.set("_land_kick", 0.0)
	follow.set("_was_grounded", false)
	follow.set("_air_sec", 0.5)
	follow.call("_track_landing", 0.016)
	var kicked: float = float(follow.get("_land_kick"))
	follow.set("_land_kick", 0.0)
	follow.set("_was_grounded", false)
	follow.set("_air_sec", 0.1)
	follow.call("_track_landing", 0.016)
	var hop: float = float(follow.get("_land_kick"))
	follow.set("_running", running0)
	follow.set("_land_kick", kick0)
	follow.set("_air_sec", 0.0)
	follow.set("_was_grounded", true)
	r._ok(is_equal_approx(sprint, 5.0) and is_equal_approx(landing, 2.0) and is_equal_approx(comfort, 0.0) and kicked > 0.85 and hop == 0.0, "JUICE4 camera: sprint punch %.1f degrees, landing punch %.1f, with Motion Comfort %.1f; a landing after 0.5 s in the air kicks %.2f, after 0.1 s %.2f" % [sprint, landing, comfort, kicked, hop])

## POL3: at rest the eye breathes (a few millimetres over one breath of about 4 s) and holds still with Motion Comfort.
static func _breath(r: Node) -> void:
	var follow := r._main.get_node("Camera3D") as Camera3D
	var running0: Variant = follow.get("_running")
	var kick0: Variant = follow.get("_land_kick")
	follow.set("_running", false)
	follow.set("_land_kick", 0.0)
	var spans: Array[float] = []
	for calm: bool in [false, true]:
		SettingsManager.set_setting("reduce_camera_motion", calm)
		var low: float = INF
		var high: float = -INF
		for i in 40:
			follow.call("_tick_fps", 0.1)
			low = minf(low, follow.global_position.y)
			high = maxf(high, follow.global_position.y)
		spans.append(high - low)
	SettingsManager.set_setting("reduce_camera_motion", false)
	follow.set("_running", running0)
	follow.set("_land_kick", kick0)
	r._ok(spans[0] >= 0.006 and spans[0] <= 0.01 and spans[1] < 0.0005, "POL3 idle breath: the eye moves %.4f m over a breath (0.006 to 0.01) and %.4f m with Motion Comfort" % [spans[0], spans[1]])

## JUICE5: a find and a finished daily throw their bursts (wired to the signals; none at Effects Low; one burst of each, played again).
static func _bursts(r: Node) -> void:
	var wired: Array[bool] = []
	for signal_ref: Signal in [EventBus.secret_found, EventBus.quest_completed]:
		var found: bool = false
		for connection: Dictionary in signal_ref.get_connections():
			if (connection["callable"] as Callable).get_object() == WowDirector:
				found = true
		wired.append(found)
	var daily: Node = r.get_node("/root/DailyChallengeManager")
	var daily_wired: bool = false
	for connection: Dictionary in Signal(daily, &"completed").get_connections():
		if (connection["callable"] as Callable).get_object() == WowDirector:
			daily_wired = true
	var bursts: Dictionary = WowDirector.get("_bursts")
	bursts.clear()
	SettingsManager.set_setting("effects", 0)
	WowDirector.burst(WowDirector.SPARKLE)
	var none_low: bool = bursts.is_empty()
	SettingsManager.set_setting("effects", 2)
	WowDirector.burst(WowDirector.SPARKLE)
	WowDirector.burst(WowDirector.CONFETTI)
	var made: bool = bursts.size() == 2
	var sparkle: VFXBurst = bursts[WowDirector.SPARKLE] as VFXBurst
	WowDirector.burst(WowDirector.SPARKLE)
	var again: bool = bursts.size() == 2 and bursts[WowDirector.SPARKLE] == sparkle
	r._ok(wired == [true, true] and daily_wired and none_low and made and again and sparkle.amount == 24, "JUICE5 bursts: wired to a find %s and a quest %s and the daily %s, none at Effects Low (%s), two made (%s) and played again (%s)" % [wired[0], wired[1], daily_wired, none_low, made, again])

## WEAPON1: each weapon has its own kick (the shotgun's is the largest, the rifle's the smallest), a shot kicks the view and it settles, Motion Comfort keeps it still;
## a reload with rounds left takes 0.8 of the time of a reload from empty.
static func _weapons(r: Node) -> void:
	var follow: Node = r._main.get_node("Camera3D")
	var recoils: Dictionary = {}
	for weapon_name: String in ["pistol", "rifle", "shotgun"]:
		var weapon := load("res://scenes/weapons/weapon_%s.tscn" % weapon_name).instantiate() as WeaponBase
		r.add_child(weapon)  # each weapon sets its numbers in its own _ready
		recoils[weapon_name] = weapon.recoil
		if weapon_name == "pistol":
			weapon.current_ammo = 5
			weapon.try_reload()
			var tactical: float = weapon._reload_duration
			weapon._reloading = false
			weapon.current_ammo = 0
			weapon.try_reload()
			var empty: float = weapon._reload_duration
			recoils["tactical"] = tactical / empty
		weapon.queue_free()
	SettingsManager.set_setting("reduce_camera_motion", false)
	SettingsManager.set_setting("reduce_ui_motion", false)
	follow.set("_recoil", Vector2.ZERO)
	follow.call("kick", float(recoils["shotgun"]))
	var kicked: Vector2 = follow.get("_recoil")
	for i in 30:
		follow.call("_tick_fps", 0.016)
	var settled: Vector2 = follow.get("_recoil")
	SettingsManager.set_setting("reduce_camera_motion", true)
	follow.set("_recoil", Vector2.ZERO)
	follow.call("kick", 1.0)
	var calm: Vector2 = follow.get("_recoil")
	SettingsManager.set_setting("reduce_camera_motion", false)
	follow.set("_recoil", Vector2.ZERO)
	r._ok(float(recoils["shotgun"]) > float(recoils["pistol"]) and float(recoils["pistol"]) > float(recoils["rifle"]) and kicked.x > 0.03 and settled.length() < 0.2 * kicked.length() and calm == Vector2.ZERO and is_equal_approx(float(recoils["tactical"]), 0.8), "WEAPON1 weapon feel: recoil shotgun %.2f, pistol %.2f, rifle %.2f; a shotgun shot kicks the view %.3f rad and half a second later it is at %.3f; none with Motion Comfort (%s); a tactical reload takes %.2f of an empty one" % [recoils["shotgun"], recoils["pistol"], recoils["rifle"], kicked.x, settled.length(), calm == Vector2.ZERO, recoils["tactical"]])

## MOVE1: the walk takes about 0.12 s to its speed and does not stop in a frame (it keeps over a third after one frame, and is under 5 % ten frames later).
static func _walk_eases(r: Node) -> void:
	var player: CharacterBody3D = r._player
	player.set("gameplay_active", true)
	player.global_position = Vector3(-8.0, 1.0, -8.0)
	player.rotation.y = 0.0
	await r.get_tree().create_timer(0.6).timeout
	InputService.set_joy_active(true)
	InputService.set_joy_move_dir(Vector2(0.0, -1.0))
	await r.get_tree().physics_frame
	await r.get_tree().physics_frame  # the first step that sees the stick
	var first: float = _planar(player)
	for i in 10:
		await r.get_tree().physics_frame
	var quick: float = _planar(player)
	for i in 20:
		await r.get_tree().physics_frame
	var full: float = _planar(player)
	InputService.set_joy_active(false)
	InputService.set_joy_move_dir(Vector2.ZERO)
	await r.get_tree().physics_frame
	await r.get_tree().physics_frame  # the first step that sees the stick let go
	var kept: float = _planar(player)
	for i in 9:
		await r.get_tree().physics_frame
	var rest: float = _planar(player)
	r._ok(full > 1.0 and first < 0.6 * full and quick >= 0.9 * full and kept > 0.3 * full and rest < 0.05 * full, "MOVE1 the walk eases: %.2f m/s after one step, %.2f after twelve, %.2f at full speed; after letting go %.2f after one step and %.2f after ten" % [first, quick, full, kept, rest])

static func _planar(body: CharacterBody3D) -> float:
	return Vector2(body.velocity.x, body.velocity.z).length()

## POL1: every button answers a press (0.95, back in 0.1 s) and a hover (ThemeSetup's swell and UISFX's tick), a toggle and a tab change click, the HUD's controls and a button a screen
## already wired are left alone, and Reduce UI Motion keeps the scale still.
static func _ui_feedback(r: Node) -> void:
	var holder := Control.new()
	r.add_child(holder)
	var button := Button.new()
	button.text = "Press"
	button.size = Vector2(120.0, 40.0)
	holder.add_child(button)
	var check := CheckBox.new()
	holder.add_child(check)
	var tabs := TabContainer.new()
	tabs.add_child(Control.new())
	tabs.add_child(Control.new())
	holder.add_child(tabs)
	var hud_row := Control.new()
	hud_row.add_to_group("hud")
	var hud_button := Button.new()
	hud_row.add_child(hud_button)
	holder.add_child(hud_row)
	var own := Button.new()
	own.pressed.connect(UISFX.click)
	holder.add_child(own)
	for i in 3:
		await r.get_tree().process_frame
	SettingsManager.set_setting("reduce_ui_motion", false)
	var wired: bool = button.pressed.is_connected(UISFX.click) and check.pressed.is_connected(UISFX.click) and tabs.tab_changed.get_connections().size() >= 1
	var left: bool = not hud_button.has_meta(&"ui_feel") and own.pressed.get_connections().size() == 1
	button.pressed.emit()
	var pressed: float = button.scale.x
	await r.get_tree().create_timer(0.25).timeout
	var settled: bool = absf(button.scale.x - 1.0) < 0.01
	button.mouse_entered.emit()
	await r.get_tree().create_timer(0.2).timeout
	var grown: float = button.scale.x  # ThemeSetup's swell
	button.mouse_exited.emit()
	await r.get_tree().create_timer(0.2).timeout
	var shrunk: bool = absf(button.scale.x - 1.0) < 0.005
	SettingsManager.set_setting("reduce_ui_motion", true)
	button.pressed.emit()
	button.mouse_entered.emit()
	await r.get_tree().create_timer(0.2).timeout
	var still: bool = is_equal_approx(button.scale.x, 1.0)
	SettingsManager.set_setting("reduce_ui_motion", false)
	holder.queue_free()
	r._ok(wired and left and is_equal_approx(pressed, 0.95) and settled and absf(grown - ThemeSetup.HOVER_SCALE.x) < 0.005 and button.mouse_entered.is_connected(UISFX.hover) and shrunk and still, "POL1 ui feedback: button, check box and tabs wired (%s), the HUD's button and a screen's own click left alone (%s), press %.2f then back (%s), hover %.3f (ThemeSetup's swell) with the tick wired, then back (%s), still with Reduce UI Motion (%s)" % [wired, left, pressed, settled, grown, shrunk, still])

## POL2: a screen built from a script slides in (0.3 s) and fades out (0.15 s): after a close it is closed for the logic at once and still on screen, then hidden with
## its alpha back; opened again while it fades it stays; with Reduce UI Motion it hides at once.
static func _screens_ease(r: Node) -> void:
	SettingsManager.set_setting("reduce_ui_motion", false)
	UIManager.close_all_blocking()
	await r.get_tree().process_frame
	UIManager.open(&"stats")
	var screen: Control = UIManager.get("_cache").get(&"codex", null)
	await r.get_tree().create_timer(0.05).timeout
	var sliding: bool = screen != null and screen.visible and screen.modulate.a < 0.99
	await r.get_tree().create_timer(0.4).timeout
	var shown: bool = screen.modulate.a > 0.99
	UIManager.close(&"codex")
	var closed_for_logic: bool = not UIManager.call("_is_open", &"codex")
	var still_drawn: bool = screen.visible
	await r.get_tree().create_timer(0.3).timeout
	var hidden: bool = not screen.visible and screen.modulate.a > 0.99
	UIManager.open(&"codex")
	await r.get_tree().create_timer(0.4).timeout
	UIManager.close(&"codex")
	await r.get_tree().create_timer(0.05).timeout
	UIManager.open(&"codex")  # opened again while it fades
	await r.get_tree().create_timer(0.5).timeout
	var stayed: bool = screen.visible and screen.modulate.a > 0.99
	SettingsManager.set_setting("reduce_ui_motion", true)
	UIManager.close(&"codex")
	var at_once: bool = not screen.visible
	SettingsManager.set_setting("reduce_ui_motion", false)
	UIManager.close_all_blocking()
	r._ok(sliding and shown and closed_for_logic and still_drawn and hidden and stayed and at_once, "POL2 screens ease: the codex slides in (%s) and rests (%s), a close is closed for the logic at once (%s) while it is still drawn (%s), hidden after the fade with its alpha back (%s), an open during the fade stays (%s), Reduce UI Motion hides at once (%s)" % [sliding, shown, closed_for_logic, still_drawn, hidden, stayed, at_once])

## TUT1 and TUT2: a hint is shown one at a time, follows a language switch, comes back with a new run after a death; the onboarding overlay has a Skip that closes it.
static func _tutorial(r: Node) -> void:
	var tutorial: Node = r.get_node("/root/TutorialSystem")
	var done0: Array = (tutorial.get("_completed_steps") as Array).duplicate()
	var active0: Variant = tutorial.get("_tutorial_active")
	tutorial.set("_completed_steps", [])
	tutorial.set("_tutorial_active", false)
	tutorial.call("_on_game_started")
	var panel := tutorial.get("_hint_panel") as Control
	var label := panel.find_child("HintText", true, false) as Label
	var shown: bool = panel.visible
	var lang0: String = LocalizationManager.current_lang
	LocalizationManager.set_language("en")
	var english: String = label.text
	LocalizationManager.set_language("de")
	await r.get_tree().process_frame
	var german: String = label.text
	LocalizationManager.set_language(lang0)
	panel.visible = false
	tutorial.call("_on_game_started")  # a new run after a death starts the tutorial's step again
	var back: bool = panel.visible and label.text != ""
	var panels: int = tutorial.find_children("TutorialHint", "Control", true, false).size()
	tutorial.set("_completed_steps", done0)
	tutorial.set("_tutorial_active", active0)
	panel.visible = false
	r._ok(shown and english != "" and german != english and back and panels == 1, "TUT1 hints: the first hint shows (%s), changes language with a switch (%s to %s), is back with a new run (%s), one hint panel only (%d)" % [shown, english, german, back, panels])
	var overlay: CanvasLayer = ONBOARDING.new()
	r.add_child(overlay)
	overlay.call("_build")
	overlay.call("_show_panel")
	var skip: Button = null
	for node: Node in overlay.find_children("*", "Button", true, false):
		if (node as Button).text == LocalizationManager.t("UI_SKIP"):
			skip = node as Button
	var paused: bool = r.get_tree().paused
	if skip != null:
		skip.pressed.emit()
	var closed: bool = not r.get_tree().paused and not bool(overlay.get("_showing"))
	overlay.queue_free()
	r.get_tree().paused = false
	r._ok(skip != null and paused and closed, "TUT2 onboarding: a Skip button is on the overlay (%s), the game was paused behind it (%s) and Skip closes it and unpauses (%s)" % [skip != null, paused, closed])
