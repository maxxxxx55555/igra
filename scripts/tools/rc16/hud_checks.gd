extends RefCounted
## Session 22 (the HUD pass, docs/HUD_PLAN.md): what the HUD shows and when. Wired into _closeout_check_runner.gd as `await Rc22Hud.run(self)`;
## CLOSEOUT_ONLY=s22 runs only these. Every state a check touches is put back. The layout check reads every HUD caption in 13 languages at the
## three Text Sizes (the game's UI scales) and holds the corner clusters inside the screen.

const FADE_WAIT_SEC: float = 4.0
const CAPTION_W: float = 120.0  # the width hud_3d.gd gives a caption
const HUD_SCENE := preload("res://scenes/ui/hud_3d.tscn")

static func run(r: Node) -> void:
	r._playing()
	UIManager.close_all_blocking()
	var hud: Node = r._main.get_node_or_null("HUD")
	if hud == null:
		r._ok(false, "HUDP0 the main scene has a HUD")
		return
	_battery_is_segments(r, hud)
	_one_map_in_play(r, hud)
	_touch_only_buttons(r, hud)
	await _tracker_is_on_screen(r)
	await _rows_are_contextual(r, hud)
	await _prompt_fades(r, hud)
	await _touch_cluster_is_clear(r)
	_joystick_fades_only_its_ring(r)
	await _touch_buttons_scale_clear(r)
	await _combat_hud_rests(r, hud)
	await _layout_holds(r, hud)
	r._playing()

## HUDP2: the flashlight charge is eight whole segments (a charge of 0.31 lights three) behind seven gaps.
static func _battery_is_segments(r: Node, hud: Node) -> void:
	var whole: bool = is_equal_approx(float(hud.call("_pip_fill", 0.31)), 0.375) and is_equal_approx(float(hud.call("_pip_fill", 0.0)), 0.0) \
		and is_equal_approx(float(hud.call("_pip_fill", 1.0)), 1.0)
	var gaps: int = 0
	for child: Node in hud.get_node("TopLeft/Bat").get_children():
		if child is ColorRect and (child as ColorRect).size.x == 2.0:
			gaps += 1
	r._ok(whole and gaps == 7, "HUDP2 the battery is eight whole segments behind seven gaps (0.31 lights 3 of 8: %s, gaps %d)" % [whole, gaps])

## HUDP3: one map in play. The radar fills its frame and has no caption; the city minimap is off until its setting is on.
static func _one_map_in_play(r: Node, hud: Node) -> void:
	r._playing()
	UIManager.call("_sync_minimap")
	var off: bool = not (UIManager.get("_minimap") as Control).visible
	SettingsManager.set_setting("show_minimap", true)
	var on: bool = (UIManager.get("_minimap") as Control).visible
	SettingsManager.set_setting("show_minimap", false)
	var radar := hud.get_node_or_null("TopRight/RadarFrame/Radar") as Control
	var frame := hud.get_node_or_null("TopRight/RadarFrame") as Control
	var seated: bool = radar != null and frame != null and radar.get_global_rect().is_equal_approx(frame.get_global_rect())
	var caption := hud.get_node_or_null("TopRight/RadarLabel") as Control
	r._ok(off and on and seated and caption != null and not caption.visible,
		"HUDP3 one map in play: the minimap is off by default (%s) and on by its setting (%s), the radar fills its frame (%s), no RADAR caption" % [off, on, seated])

## HUDP5: the Map and Pause buttons are touch controls; on a keyboard the map has its key and the pause button only rests dim.
static func _touch_only_buttons(r: Node, hud: Node) -> void:
	var map_button := hud.get_node_or_null("MapButton") as Button
	var pause_button := hud.get_node_or_null("BtnPause") as Button
	var touch: bool = bool(hud.call("has_touch_ui"))
	var ok: bool = map_button != null and pause_button != null and map_button.visible == touch
	if not touch:
		ok = ok and is_equal_approx(pause_button.self_modulate.a, 0.5) and pause_button.visible
	r._ok(ok, "HUDP5 the Map button shows only with a touch screen (touch %s, shown %s) and the Pause button rests dim on a keyboard" % [touch, map_button.visible if map_button != null else "none"])

## HUDP4: the objective list is on the screen (it was drawn at x = -320), lets every click through, and shows when an objective changes.
static func _tracker_is_on_screen(r: Node) -> void:
	var overlay := UIManager.get("_quest_hud") as Control
	var container := overlay.get_node_or_null("QuestHUDContainer") as Control if overlay != null else null
	if container == null or not container.is_visible_in_tree():
		r._ok(false, "HUDP4 the quest tracker shows its list (container %s)" % [container])
		return
	overlay.call("_refresh")
	await r.get_tree().create_timer(0.3).timeout
	var view := Rect2(Vector2.ZERO, r.get_viewport().get_visible_rect().size)
	var inside: bool = view.encloses(container.get_global_rect())
	var through: bool = _lets_clicks_through(container) and overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE
	r._ok(inside and through and container.modulate.a > 0.99,
		"HUDP4 the objective list is on screen (%s, at x %d), lets every click through (%s) and shows when an objective changes (alpha %.2f)" % [inside, container.get_global_rect().position.x, through, container.modulate.a])

static func _lets_clicks_through(node: Node) -> bool:
	if node is Control and (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return false
	for child: Node in node.get_children():
		if not _lets_clicks_through(child):
			return false
	return true

## HUDP1: health and stamina show while they matter and are gone at rest: they fade after full health and full stamina, wake on a hit, and hold a
## moment once whole. (The noise and visibility rows follow the player's own state and are read in the frames, not here.)
static func _rows_are_contextual(r: Node, hud: Node) -> void:
	var hp_row := hud.get_node("TopLeft/HP") as Control
	var stam_row := hud.get_node("TopLeft/Stam") as Control
	EventBus.player_health_changed.emit(1.0)
	EventBus.player_stamina_changed.emit(1.0)
	await r.get_tree().create_timer(FADE_WAIT_SEC).timeout
	var rest: bool = hp_row.modulate.a < 0.01 and stam_row.modulate.a < 0.01
	var rest_alphas: String = "%.2f, %.2f" % [hp_row.modulate.a, stam_row.modulate.a]
	EventBus.player_health_changed.emit(0.5)
	EventBus.player_stamina_changed.emit(0.4)
	await r.get_tree().create_timer(0.4).timeout
	var woke: bool = hp_row.modulate.a > 0.99 and stam_row.modulate.a > 0.99
	var woke_alphas: String = "%.2f, %.2f" % [hp_row.modulate.a, stam_row.modulate.a]
	EventBus.player_health_changed.emit(1.0)
	EventBus.player_stamina_changed.emit(1.0)
	await r.get_tree().create_timer(0.2).timeout
	var holds: bool = hp_row.modulate.a > 0.99
	r._ok(rest and woke and holds, "HUDP1 the health and stamina rows rest faded (alpha %s), wake on a hit (%s) and hold a moment after the value is whole (%s)" % [rest_alphas, woke_alphas, holds])

## HUDP8: the interact prompt fades in when something is in reach, and out (still there, part way, then hidden) when it is not.
static func _prompt_fades(r: Node, hud: Node) -> void:
	var prompt := hud.get("prompt") as Label
	EventBus.interact_prompt_changed.emit("Open")
	EventBus.player_interact_available.emit(true)
	await r.get_tree().create_timer(0.35).timeout
	var shown: bool = prompt.visible and prompt.self_modulate.a > 0.99
	EventBus.player_interact_available.emit(false)
	await r.get_tree().create_timer(0.1).timeout
	var leaving: bool = prompt.visible and prompt.self_modulate.a < 0.99
	await r.get_tree().create_timer(0.4).timeout
	r._ok(shown and leaving and not prompt.visible, "HUDP8 the interact prompt fades in (%s), is part way out after 0.1 s (%s, alpha %.2f) and hidden after 0.5 s (%s)" % [shown, leaving, prompt.self_modulate.a, not prompt.visible])

## HUDP9: the four touch action buttons sit inside the screen and do not overlap (the cluster's offsets were laid out from a corner it was not anchored
## at: Attack and Stealth overlapped and the side buttons sat on them). A HUD built for the check shows the touch clusters the desktop HUD hides.
static func _touch_cluster_is_clear(r: Node) -> void:
	var hud := HUD_SCENE.instantiate()
	r.get_tree().root.add_child(hud)
	(hud.get_node("BottomRight") as Control).visible = true
	await r.get_tree().process_frame
	await r.get_tree().process_frame
	var view := Rect2(Vector2.ZERO, r.get_viewport().get_visible_rect().size)
	var rects: Array[Rect2] = []
	for path: String in ["BottomRight/BtnAttack", "BottomRight/BtnSprint", "BottomRight/BtnStealth", "BottomRight/BtnInteract"]:
		rects.append((hud.get_node(path) as Control).get_global_rect())
	var clear: bool = true
	for i: int in rects.size():
		clear = clear and view.encloses(rects[i])
		for j: int in range(i + 1, rects.size()):
			clear = clear and not rects[i].intersects(rects[j])
	hud.queue_free()
	r._ok(clear, "HUDP9 the touch action buttons are on screen and clear of each other (%s)" % [rects])

## HUDP10: the joystick fades only the ring it sits in. The first-run calibration dialog hosts one in a container, which must keep its alpha while
## the thumb goes down and after it lifts (the dialog was left at the ring's rest alpha, 0.55).
static func _joystick_fades_only_its_ring(r: Node) -> void:
	var container := VBoxContainer.new()
	var ring := Panel.new()
	r.add_child(container)
	r.add_child(ring)
	ring.modulate.a = 0.55  # the alpha the HUD rests its ring at
	var joysticks: Array[Control] = []
	for host: Control in [container, ring]:
		var joystick := Control.new()
		joystick.set_script(load("res://scripts/ui/virtual_joystick.gd"))
		joystick.size = Vector2(160.0, 160.0)
		host.add_child(joystick)
		joysticks.append(joystick)
	var touch := InputEventScreenTouch.new()
	touch.position = Vector2(80.0, 80.0)
	touch.pressed = true
	for joystick: Control in joysticks:
		joystick.call("_gui_input", touch)
		joystick.call("_process", 0.016)
	var going_down: float = container.modulate.a
	for joystick: Control in joysticks:
		joystick.call("_process", 0.2)
	var ring_down: float = ring.modulate.a
	touch.pressed = false
	for joystick: Control in joysticks:
		joystick.call("_gui_input", touch)
		joystick.call("_process", 0.2)
	var kept: bool = is_equal_approx(going_down, 1.0) and is_equal_approx(container.modulate.a, 1.0)
	var ring_wakes: bool = ring_down > 0.99 and is_equal_approx(ring.modulate.a, 0.55)
	container.queue_free()
	ring.queue_free()
	r._ok(kept and ring_wakes, "HUDP10 the joystick fades only its ring: a container keeps alpha 1 as the thumb goes down (%.2f) and lifts (%.2f), the ring goes full (%.2f) and rests (%.2f)" % [going_down, container.modulate.a, ring_down, ring.modulate.a])

## HUDP11: Button Size grows the side buttons with the action buttons, so the eight touch buttons stay on screen and clear of each other from 0.8 to 1.5
## (the side buttons stayed put while Interact grew over Jump and Flash from 1.10). A HUD built under touch emulation carries all eight.
static func _touch_buttons_scale_clear(r: Node) -> void:
	var emulate0: Variant = ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse", false)
	var calibrated0: Variant = SettingsManager.get_setting("touch_calibration_done", false)
	var size0: float = float(SettingsManager.get_setting("button_size", 1.0))
	SettingsManager.set_setting("touch_calibration_done", true)
	SettingsManager.set_button_size(1.0)
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", true)
	var hud := HUD_SCENE.instantiate()
	r.get_tree().root.add_child(hud)
	await r.get_tree().process_frame
	var view := Rect2(Vector2.ZERO, r.get_viewport().get_visible_rect().size)
	var bad: Array[String] = []
	var found: int = 0
	for factor: float in [0.8, 1.0, 1.5]:
		SettingsManager.set_button_size(factor)  # what the slider calls
		await r.get_tree().process_frame
		await r.get_tree().process_frame
		var rects: Dictionary = {}
		for button_name: String in ["BtnAttack", "BtnSprint", "BtnStealth", "BtnInteract", "BtnJump", "BtnFlash", "BtnStrobe", "BtnWheel"]:
			var button := hud.find_child(button_name, true, false) as Control
			if button != null:
				var drawn: Transform2D = button.get_global_transform()  # a Control's global rect ignores the scale of its parent
				rects[button_name] = Rect2(drawn * Vector2.ZERO, drawn.basis_xform(button.size))
		found = rects.size()
		var names: Array = rects.keys()
		for i: int in names.size():
			if not view.encloses(rects[names[i]]):
				bad.append("%s outside at %.1f" % [names[i], factor])
			for j: int in range(i + 1, names.size()):
				if (rects[names[i]] as Rect2).intersects(rects[names[j]]):
					bad.append("%s over %s at %.1f" % [names[i], names[j], factor])
	hud.queue_free()
	ProjectSettings.set_setting("input_devices/pointing/emulate_touch_from_mouse", emulate0)
	SettingsManager.set_button_size(size0)
	SettingsManager.set_setting("touch_calibration_done", calibrated0)
	r._ok(found == 8 and bad.is_empty(), "HUDP11 the eight touch buttons stay on screen and clear of each other at Button Size 0.8, 1.0 and 1.5 (found %d, problems %s)" % [found, bad.slice(0, 4)])

## HUDP7: the crosshair rests faded, wakes on a shot and fades five seconds after it.
static func _combat_hud_rests(r: Node, hud: Node) -> void:
	var crosshair := hud.get("_crosshair") as Control
	EventBus.crosshair_state_changed.emit(&"default")
	await r.get_tree().create_timer(0.4).timeout
	var woke: bool = crosshair.self_modulate.a > 0.99
	await r.get_tree().create_timer(5.8).timeout
	var rest: bool = crosshair.self_modulate.a < 0.01
	r._ok(woke and rest, "HUDP7 the crosshair wakes on a shot (%s) and is faded 6 s later (%s, alpha %.2f)" % [woke, rest, crosshair.self_modulate.a])

## HUDP6: every HUD caption fits its label in 13 languages at the three Text Sizes, and the corner clusters stay on the screen.
static func _layout_holds(r: Node, hud: Node) -> void:
	var lang0: String = LocalizationManager.current_lang
	var size0: int = int(SettingsManager.get_setting("text_size", 1))
	var bad: Array[String] = []
	var checked: int = 0
	for lang: String in LocalizationManager.LANG_NAMES.keys():
		for size_idx: int in [0, 1, 2]:
			LocalizationManager.set_language(lang)
			SettingsManager.set_text_size(size_idx)
			await r.get_tree().process_frame
			await r.get_tree().process_frame
			var view := Rect2(Vector2.ZERO, r.get_viewport().get_visible_rect().size)
			for name_: String in ["_bat_caption", "_hp_caption", "_stam_caption", "noise_caption", "vis_caption"]:
				var label := hud.get(name_) as Label
				if label == null or label.get_minimum_size().x > CAPTION_W:  # a Label grows to its text, so the designed width is the bound
					bad.append("%s/%d %s %s" % [lang, size_idx, name_, label.get_minimum_size().x if label != null else -1.0])
			for path: String in ["TopLeft", "TopRight/RadarFrame", "BottomCenter"]:
				var cluster := hud.get_node_or_null(path) as Control
				if cluster == null or not view.encloses(cluster.get_global_rect()):
					bad.append("%s/%d %s outside the screen" % [lang, size_idx, path])
			checked += 1
	LocalizationManager.set_language(lang0)
	SettingsManager.set_text_size(size0)
	r._ok(bad.is_empty() and checked == 39, "HUDP6 the HUD holds in %d language and Text Size pairs: every caption fits its label, the corners stay on screen (%s)" % [checked, bad.slice(0, 4)])
