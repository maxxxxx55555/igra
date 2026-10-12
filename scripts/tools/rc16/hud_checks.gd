extends RefCounted
## Session 22 (the HUD pass, docs/HUD_PLAN.md): what the HUD shows and when. Wired into _closeout_check_runner.gd as `await Rc22Hud.run(self)`;
## CLOSEOUT_ONLY=s22 runs only these. Every state a check touches is put back. The layout check reads every HUD caption in 13 languages at the
## three Text Sizes (the game's UI scales) and holds the corner clusters inside the screen.

const FADE_WAIT_SEC: float = 4.0

static func run(r: Node) -> void:
	r._playing()
	UIManager.close_all_blocking()
	var hud: Node = r._main.get_node_or_null("HUD")
	if hud == null:
		r._ok(false, "HUD0 the main scene has a HUD")
		return
	_battery_is_segments(r, hud)
	_one_map_in_play(r, hud)
	_touch_only_buttons(r, hud)
	await _tracker_is_on_screen(r)
	await _rows_are_contextual(r, hud)
	await _layout_holds(r, hud)
	r._playing()

## HUD2: the flashlight charge is eight whole segments (a charge of 0.31 lights three) behind seven gaps.
static func _battery_is_segments(r: Node, hud: Node) -> void:
	var whole: bool = is_equal_approx(float(hud.call("_pip_fill", 0.31)), 0.375) and is_equal_approx(float(hud.call("_pip_fill", 0.0)), 0.0) \
		and is_equal_approx(float(hud.call("_pip_fill", 1.0)), 1.0)
	var gaps: int = 0
	for child: Node in hud.get_node("TopLeft/Bat").get_children():
		if child is ColorRect and (child as ColorRect).size.x == 2.0:
			gaps += 1
	r._ok(whole and gaps == 7, "HUD2 the battery is eight whole segments behind seven gaps (0.31 lights 3 of 8: %s, gaps %d)" % [whole, gaps])

## HUD3: one map in play. The radar fills its frame and has no caption; the city minimap is off until its setting is on.
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
		"HUD3 one map in play: the minimap is off by default (%s) and on by its setting (%s), the radar fills its frame (%s), no RADAR caption" % [off, on, seated])

## HUD5: the Map and Pause buttons are touch controls; on a keyboard the map has its key and the pause button only rests dim.
static func _touch_only_buttons(r: Node, hud: Node) -> void:
	var map_button := hud.get_node_or_null("MapButton") as Button
	var pause_button := hud.get_node_or_null("BtnPause") as Button
	var touch: bool = bool(hud.call("has_touch_ui"))
	var ok: bool = map_button != null and pause_button != null and map_button.visible == touch
	if not touch:
		ok = ok and is_equal_approx(pause_button.self_modulate.a, 0.5) and pause_button.visible
	r._ok(ok, "HUD5 the Map button shows only with a touch screen (touch %s, shown %s) and the Pause button rests dim on a keyboard" % [touch, map_button.visible if map_button != null else "none"])

## HUD4: the objective list is on the screen (it was drawn at x = -320), lets every click through, and shows when an objective changes.
static func _tracker_is_on_screen(r: Node) -> void:
	var overlay := UIManager.get("_quest_hud") as Control
	var container := overlay.get_node_or_null("QuestHUDContainer") as Control if overlay != null else null
	if container == null or not container.is_visible_in_tree():
		r._ok(false, "HUD4 the quest tracker shows its list (container %s)" % [container])
		return
	overlay.call("_refresh")
	await r.get_tree().create_timer(0.3).timeout
	var view := Rect2(Vector2.ZERO, r.get_viewport().get_visible_rect().size)
	var inside: bool = view.encloses(container.get_global_rect())
	var through: bool = _lets_clicks_through(container) and overlay.mouse_filter == Control.MOUSE_FILTER_IGNORE
	r._ok(inside and through and container.modulate.a > 0.99,
		"HUD4 the objective list is on screen (%s, at x %d), lets every click through (%s) and shows when an objective changes (alpha %.2f)" % [inside, container.get_global_rect().position.x, through, container.modulate.a])

static func _lets_clicks_through(node: Node) -> bool:
	if node is Control and (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return false
	for child: Node in node.get_children():
		if not _lets_clicks_through(child):
			return false
	return true

## HUD1: health and stamina show while they matter and are gone at rest: they fade after full health and full stamina, wake on a hit, and hold a
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
	r._ok(rest and woke and holds, "HUD1 the health and stamina rows rest faded (alpha %s), wake on a hit (%s) and hold a moment after the value is whole (%s)" % [rest_alphas, woke_alphas, holds])

## HUD6: every HUD caption fits its label in 13 languages at the three Text Sizes, and the corner clusters stay on the screen.
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
				if label == null or label.get_minimum_size().x > label.size.x + 0.5:
					bad.append("%s/%d %s %s" % [lang, size_idx, name_, label.get_minimum_size().x if label != null else -1.0])
			for path: String in ["TopLeft", "TopRight/RadarFrame", "BottomCenter"]:
				var cluster := hud.get_node_or_null(path) as Control
				if cluster == null or not view.encloses(cluster.get_global_rect()):
					bad.append("%s/%d %s outside the screen" % [lang, size_idx, path])
			checked += 1
	LocalizationManager.set_language(lang0)
	SettingsManager.set_text_size(size0)
	r._ok(bad.is_empty() and checked == 39, "HUD6 the HUD holds in %d language and Text Size pairs: every caption fits its label, the corners stay on screen (%s)" % [checked, bad.slice(0, 4)])
