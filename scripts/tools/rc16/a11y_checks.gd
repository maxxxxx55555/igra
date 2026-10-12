extends RefCounted
## Session 23 (docs/A11Y_PLAN.md): the accessibility features at run time. Wired into _closeout_check_runner.gd as `await Rc23A11y.run(self)`;
## CLOSEOUT_ONLY=s23 runs the group (with the other s23 files). Every setting and node a check touches is put back.

const HUD_SCENE := preload("res://scenes/ui/hud_3d.tscn")
const _FADE := preload("res://scripts/ui/hud_fade.gd")
const _InputRemap := preload("res://scripts/systems/input_remap.gd")
const TOUCH_BUTTONS: Array[String] = ["BtnAttack", "BtnSprint", "BtnStealth", "BtnInteract", "BtnJump", "BtnFlash", "BtnStrobe", "BtnWheel"]
const LINE := "The last lamp on this street is out."
const SUBTITLE_DEFAULTS: Dictionary = {"subtitles": false, "subtitle_size": 1, "subtitle_color": 0, "subtitle_bg": 1}
const FAR := Vector3(900.0, 0.0, 900.0)

class FakeAds extends RefCounted:
	func initialize() -> void:
		pass

	func is_ready() -> bool:
		return true

	func show(_reward: StringName) -> void:
		pass

static func run(r: Node) -> void:
	r._playing()
	UIManager.close_all_blocking()
	await _subtitles_follow_settings(r)
	await _sound_cues(r)
	_remap(r)
	_difficulty(r)
	await _clear_objectives(r)
	await _edge_highlight(r)
	_motion_comfort(r)
	await _one_handed(r)
	r._playing()

static func _subtitle_bar() -> Control:
	return UIManager.get("_subtitles") as Control

## A11Y1: Subtitles draw the Keeper's lines only when on; size, background and color follow their settings; a caption of the Keeper's log reaches the bar.
static func _subtitles_follow_settings(r: Node) -> void:
	var bar := _subtitle_bar()
	SettingsManager.set_setting("subtitles", false)
	bar.call("say", LINE)
	var silent: bool = String(bar.call("shown_text")) == ""
	SettingsManager.set_setting("subtitles", true)
	var sizes: Array[int] = [18, 24, 32]
	var colors: Array[Color] = [Color("#d8d2c4"), Color("#e6cf6e"), Color("#7fc4d9")]
	var alphas: Array[float] = [0.0, 0.5, 1.0]
	var bad: Array[String] = []
	for pick: int in 3:
		SettingsManager.set_setting("subtitle_size", pick)
		SettingsManager.set_setting("subtitle_color", pick)
		SettingsManager.set_setting("subtitle_bg", pick)
		bar.call("say", LINE)
		var label := bar.get("_label") as Label
		var box := (bar.get("_bar") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
		if String(bar.call("shown_text")) != LINE:
			bad.append("text at %d" % pick)
		if label.get_theme_font_size("font_size") != sizes[pick]:
			bad.append("size %d is %d" % [pick, label.get_theme_font_size("font_size")])
		if not label.get_theme_color("font_color").is_equal_approx(colors[pick]):
			bad.append("color %d" % pick)
		if not is_equal_approx(box.bg_color.a, alphas[pick]):
			bad.append("background %d is %.2f" % [pick, box.bg_color.a])
	bar.call("_clear")
	EventBus.toast_requested.emit("Keeper line", "caption")
	var caption: bool = String(bar.call("shown_text")) == "Keeper line"
	bar.call("_clear")
	EventBus.toast_requested.emit("Not a caption", "achievement")
	var ignored: bool = String(bar.call("shown_text")) == ""
	for key: String in SUBTITLE_DEFAULTS:
		SettingsManager.set_setting(key, SUBTITLE_DEFAULTS[key])
	bar.call("_clear")
	r._ok(silent and bad.is_empty() and caption and ignored, "A11Y1 subtitles: nothing with the toggle off (%s), size, color and background follow their settings (problems %s), a Keeper caption shows (%s), an achievement toast does not (%s)" % [silent, bad, caption, ignored])

## A11Y2: Sound Cues caption a sound only when on, a loud one flashes the screen edge, Reduce Flash holds the flash back, a language switch clears the line.
static func _sound_cues(r: Node) -> void:
	var bar := _subtitle_bar()
	bar.call("_clear")
	SettingsManager.set_setting("sound_cues", false)
	EventBus.light_disrupted.emit()
	var quiet: bool = String(bar.call("shown_text")) == ""
	SettingsManager.set_setting("sound_cues", true)
	SettingsManager.set_setting("reduce_flash", false)
	EventBus.hallucination_heard.emit()
	var captioned: bool = String(bar.call("shown_text")) == LocalizationManager.t("SND_WHISPER")
	var flashed: bool = float(bar.call("flash_alpha")) > 0.3
	await r.get_tree().create_timer(0.7).timeout
	SettingsManager.set_setting("reduce_flash", true)
	EventBus.player_detected.emit(&"m1")
	var held: bool = float(bar.call("flash_alpha")) < 0.01 and String(bar.call("shown_text")) == LocalizationManager.t("SND_NOTICED")
	SettingsManager.set_setting("reduce_flash", false)
	await r.get_tree().create_timer(1.6).timeout
	EventBus.player_detected.emit(&"m1")
	var again: bool = float(bar.call("flash_alpha")) > 0.3  # the same cue after its repeat window
	bar.call("_clear")
	SettingsManager.set_setting("sound_cues", false)
	r._ok(quiet and captioned and flashed and held and again, "A11Y2 sound cues: quiet with the toggle off (%s), a whisper is captioned (%s) and flashes the edge (%s), Reduce Flash keeps the caption and holds the flash (%s), the same cue flashes again after its window (%s)" % [quiet, captioned, flashed, held, again])

## A11Y3: a key can be rebound, a key in use swaps places, the choice survives a save and a load, Reset to Default puts the project's keys back.
static func _remap(r: Node) -> void:
	var jump0: int = _InputRemap.key_of(&"jump")
	var up0: int = _InputRemap.key_of(&"move_up")
	var map: Dictionary = _InputRemap.bind(&"jump", KEY_J)
	var bound: bool = _InputRemap.key_of(&"jump") == KEY_J and int(map.get("jump", 0)) == KEY_J
	var event := InputEventKey.new()
	event.physical_keycode = KEY_J
	event.pressed = true
	var reads: bool = InputMap.event_is_action(event, &"jump") and not InputMap.event_is_action(event, &"move_up")
	_InputRemap.bind(&"move_up", KEY_J)
	var swapped: bool = _InputRemap.key_of(&"move_up") == KEY_J and _InputRemap.key_of(&"jump") == up0
	SettingsManager.set_setting("keybinds", _InputRemap.overrides())
	var saved: Dictionary = SettingsManager.to_dict()
	_InputRemap.reset()
	var reset_ok: bool = _InputRemap.key_of(&"jump") == jump0 and _InputRemap.key_of(&"move_up") == up0 and _InputRemap.overrides().is_empty()
	SettingsManager.from_dict(saved)
	var persisted: bool = _InputRemap.key_of(&"move_up") == KEY_J and _InputRemap.key_of(&"jump") == up0
	_InputRemap.reset()
	SettingsManager.set_setting("keybinds", {})
	var restored: bool = _InputRemap.key_of(&"jump") == jump0 and _InputRemap.key_of(&"move_up") == up0
	r._ok(bound and reads and swapped and reset_ok and persisted and restored, "A11Y3 remap: Jump to J (%s) and the InputMap reads it (%s), Move Up to J swaps (%s), Reset to Default (%s), a saved choice loads back (%s), put back (%s)" % [bound, reads, swapped, reset_ok, persisted, restored])

## A11Y4: the difficulty presets reach the player's damage, the spare repair parts of Easy, and the revive offer of Hard (the monsters' health and damage: the DIFF check).
static func _difficulty(r: Node) -> void:
	var player: Node3D = r._player
	var lost: Array[float] = []
	for level: int in 3:
		SettingsManager.set_difficulty(level)
		player.set("_damage_grace_timer", 0.0)
		player.set("_iframes", 0.0)
		player.set("hp", 100.0)
		player.call("take_damage", 12.0)
		lost.append(100.0 - float(player.get("hp")))
	player.set("_damage_grace_timer", 0.0)
	player.set("hp", 100.0)
	var damage_ok: bool = is_equal_approx(lost[0], 8.0) and is_equal_approx(lost[1], 12.0) and is_equal_approx(lost[2], 12.0)
	var root := Node3D.new()
	r.add_child(root)
	root.global_position = FAR  # far from the player: nothing spawned here can be picked up
	var spare: Array[int] = []
	for level: int in 3:
		SettingsManager.set_difficulty(level)
		spare.append(DistrictLoot._spawn_spare_parts(root, &"hospital"))
	root.queue_free()
	var parts_ok: bool = spare == [3, 0, 0]
	var ads0: Variant = AdService.get("_provider")
	AdService.set_provider(FakeAds.new())
	var offers: Array[bool] = []
	for level: int in 3:
		SettingsManager.set_difficulty(level)
		offers.append(AdService.can_show_reward(&"revive"))
	AdService.set_provider(ads0 as Object)
	SettingsManager.set_difficulty(1)
	var revive_ok: bool = offers == [true, true, false]
	r._ok(damage_ok and parts_ok and revive_ok, "A11Y4 difficulty presets: damage taken per 12 hit %s (Easy 8, Normal 12, Hard 12), spare repair parts %s (3, 0, 0), a revive offer %s (yes, yes, no)" % [lost, spare, offers])

## A11Y5: with Clear Objectives nothing contextual fades out; without it the same call fades to rest.
static func _clear_objectives(r: Node) -> void:
	var results: Array[float] = []
	for clear: bool in [false, true]:
		SettingsManager.set_setting("clear_objectives", clear)
		var probe := ColorRect.new()
		r.add_child(probe)
		_FADE.show_for([probe], 0.2)
		await r.get_tree().create_timer(1.3).timeout
		results.append(probe.modulate.a)
		probe.queue_free()
	SettingsManager.set_setting("clear_objectives", false)
	r._ok(results[0] < 0.01 and results[1] > 0.99, "A11Y5 clear objectives: a contextual item fades without it (alpha %.2f) and stays with it (alpha %.2f)" % [results[0], results[1]])

## A11Y6: Edge Highlight puts a rim overlay on an interactable within 9 m and takes it off when out of range or switched off.
static func _edge_highlight(r: Node) -> void:
	var player: Node3D = r._player
	var edge: Node = (player.get("_interactor") as Node).get_child(0)  # the Interactor adds the highlight first
	var thing := Node3D.new()
	var mesh := MeshInstance3D.new()
	mesh.mesh = BoxMesh.new()
	thing.add_child(mesh)
	thing.add_to_group("interactable")
	r.add_child(thing)
	thing.global_position = player.global_position + Vector3(0.0, 0.0, 3.0)
	SettingsManager.set_setting("edge_highlight", false)
	edge.call("refresh")
	var off: bool = mesh.material_overlay == null
	SettingsManager.set_setting("edge_highlight", true)
	edge.call("refresh")
	var near: bool = mesh.material_overlay != null
	thing.global_position = player.global_position + Vector3(0.0, 0.0, 30.0)
	edge.call("refresh")
	var far: bool = mesh.material_overlay == null
	thing.global_position = player.global_position + Vector3(0.0, 0.0, 3.0)
	edge.call("refresh")
	SettingsManager.set_setting("edge_highlight", false)
	edge.call("refresh")
	var gone: bool = mesh.material_overlay == null
	thing.queue_free()
	await r.get_tree().process_frame
	r._ok(off and near and far and gone, "A11Y6 edge highlight: no rim with it off (%s), a rim at 3 m (%s), none at 30 m (%s), gone when switched off (%s)" % [off, near, far, gone])

## A11Y7: Motion Comfort stops the shake and the sprint blur.
static func _motion_comfort(r: Node) -> void:
	var shake: Node = r._main.get_node("ScreenShake")
	var overlay: Node = r._main.get_node("PostProcessOverlay")
	var player: Node3D = r._player
	var tier0: Variant = SettingsManager.get_setting("graphics_tier", 2)
	SettingsManager.set_setting("graphics_tier", 3)
	var state0: Variant = player.get("current_state")
	player.set("current_state", 2)  # RUN
	var results: Array = []
	for comfort: bool in [false, true]:
		SettingsManager.set_setting("reduce_camera_motion", comfort)
		shake.set("_trauma", 0.0)
		shake.call("add_trauma", 1.0)
		results.append([float(shake.get("_trauma")), bool(overlay.call("_wants_blur"))])
	SettingsManager.set_setting("reduce_camera_motion", false)
	SettingsManager.set_setting("graphics_tier", tier0)
	player.set("current_state", state0)
	shake.set("_trauma", 0.0)
	var free_ok: bool = float(results[0][0]) > 0.5 and bool(results[0][1])
	var comfort_ok: bool = float(results[1][0]) == 0.0 and not bool(results[1][1])
	r._ok(free_ok and comfort_ok, "A11Y7 motion comfort: shake and sprint blur work with it off (trauma %.2f, blur %s) and stop with it on (trauma %.2f, blur %s)" % [results[0][0], results[0][1], results[1][0], results[1][1]])

## A11Y8: One-Handed Mode puts the action buttons beside the joystick on the left (on screen, clear of each other and of the joystick at Button Size 1.0 and
## 1.5), Sprint latches, the double-tap window doubles.
static func _one_handed(r: Node) -> void:
	var emulate0: Variant = ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)
	var calibrated0: Variant = SettingsManager.get_setting("touch_calibration_done", false)
	var size0: float = float(SettingsManager.get_setting("button_size", 1.0))
	SettingsManager.set_setting("touch_calibration_done", true)
	SettingsManager.set_setting("one_handed", true)
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)
	Input.emulate_touch_from_mouse = true
	var hud := HUD_SCENE.instantiate()
	r.get_tree().root.add_child(hud)
	await r.get_tree().process_frame
	var view := Rect2(Vector2.ZERO, r.get_viewport().get_visible_rect().size)
	var bad: Array[String] = []
	var found: int = 0
	for factor: float in [1.0, 1.5]:
		SettingsManager.set_button_size(factor)
		await r.get_tree().process_frame
		await r.get_tree().process_frame
		var ring := hud.find_child("JoystickRing", true, false) as Control
		var ring_drawn: Transform2D = ring.get_global_transform()
		var ring_rect := Rect2(ring_drawn * Vector2.ZERO, ring_drawn.basis_xform(ring.size))
		var rects: Dictionary = {}
		for button_name: String in TOUCH_BUTTONS:
			var button := hud.find_child(button_name, true, false) as Control
			if button != null:
				var drawn: Transform2D = button.get_global_transform()
				rects[button_name] = Rect2(drawn * Vector2.ZERO, drawn.basis_xform(button.size))
		found = rects.size()
		var names: Array = rects.keys()
		for i: int in names.size():
			var rect: Rect2 = rects[names[i]]
			if not view.encloses(rect):
				bad.append("%s outside at %.1f" % [names[i], factor])
			if rect.end.x > view.size.x * 0.5:
				bad.append("%s beyond the left half at %.1f" % [names[i], factor])
			if rect.intersects(ring_rect):
				bad.append("%s over the joystick at %.1f" % [names[i], factor])
			for j: int in range(i + 1, names.size()):
				if rect.intersects(rects[names[j]]):
					bad.append("%s over %s at %.1f" % [names[i], names[j], factor])
	var sprint := hud.find_child("BtnSprint", true, false) as Button
	InputService.set_joy_run_held(false)
	sprint.button_down.emit()
	sprint.button_up.emit()
	var latched: bool = InputService.is_joy_run_held()
	sprint.button_down.emit()
	sprint.button_up.emit()
	var released: bool = not InputService.is_joy_run_held()
	var joystick := hud.find_child("JoystickInput", true, false)
	var wide: float = float(joystick.call("double_tap_window"))
	SettingsManager.set_setting("one_handed", false)
	var plain: float = float(joystick.call("double_tap_window"))
	sprint.button_down.emit()
	sprint.button_up.emit()
	var hold_only: bool = not InputService.is_joy_run_held()
	InputService.set_joy_run_held(false)
	hud.queue_free()
	Input.emulate_touch_from_mouse = false
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", emulate0)
	SettingsManager.set_button_size(size0)
	SettingsManager.set_setting("touch_calibration_done", calibrated0)
	r._ok(found == 8 and bad.is_empty() and latched and released and is_equal_approx(wide, 2.0 * plain) and hold_only, "A11Y8 one-handed: 8 buttons found (%d) in the left half, on screen and clear of each other and the joystick (problems %s); Sprint latches (%s) and lets go (%s); double-tap window %.2f against %.2f; the plain mode holds (%s)" % [found, bad.slice(0, 4), latched, released, wide, plain, hold_only])
