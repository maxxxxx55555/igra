extends Node
## Autoload "WowDirector" — a light touch of juice at the three moments that
## carry the game in a short: the first streetlight coming back on, the grid
## cascade (every district restored), and the victory ending.
##
## Everything here is ADDITIVE and REVERSIBLE — a screen-shake burst (through
## ScreenShake, so "Reduce Screen Shake" still suppresses it), a brief
## full-screen colour flash on its own CanvasLayer, and — only when the
## opt-in Trailer Mode is on — a short slow-mo + FOV punch and the HUD
## hidden. No persistent game state is touched. Camera *position* paths are
## deliberately not done here (they need a Godot pass to frame); the preset
## table below is where they would slot in.

const _PRESETS: Dictionary = {
	"first_light": {"trauma": 0.30, "flash": Color(1.00, 0.82, 0.45), "flash_a": 0.20, "flash_t": 0.5, "slowmo": 1.0, "fov": 0.0},
	"cascade":     {"trauma": 0.55, "flash": Color(1.00, 0.95, 0.80), "flash_a": 0.28, "flash_t": 0.8, "slowmo": 0.5, "fov": 4.0},
	"ending":      {"trauma": 0.45, "flash": Color(0.92, 0.62, 0.32), "flash_a": 0.26, "flash_t": 1.0, "slowmo": 0.4, "fov": 3.0},
}

var _first_light_done: bool = false
var _flash_layer: CanvasLayer = null
var _flash: ColorRect = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.streetlight_activated.connect(_on_streetlight)
	EventBus.district_restored.connect(_on_district_restored)
	EventBus.game_won.connect(func() -> void: _wow("ending"))
	EventBus.game_started.connect(func() -> void: _first_light_done = false)

func _on_streetlight(_id: Variant) -> void:
	if _first_light_done:
		return
	_first_light_done = true
	_wow("first_light")

func _on_district_restored(_id: Variant, _stage: Variant) -> void:
	var pg := get_node_or_null("/root/PowerGrid")
	if pg != null and pg.has_method("all_restored") and pg.all_restored():
		_wow("cascade")

func _wow(kind: String) -> void:
	var p: Dictionary = _PRESETS.get(kind, {})
	if p.is_empty():
		return
	var ss := _screen_shake()
	if ss != null and ss.has_method("add_trauma"):
		ss.add_trauma(float(p["trauma"]))
	_flash(p["flash"], float(p["flash_a"]), float(p["flash_t"]))
	if _trailer_on():
		EventBus.hud_visibility_changed.emit(false)
		_cinematic(p)

func _trailer_on() -> bool:
	var sm := get_node_or_null("/root/SettingsManager")
	return sm != null and sm.has_method("get_setting") and bool(sm.get_setting("trailer_mode", false))

func _cinematic(p: Dictionary) -> void:
	var slow: float = float(p.get("slowmo", 1.0))
	var cam := get_viewport().get_camera_3d()
	var fov_add: float = float(p.get("fov", 0.0))
	if cam != null and fov_add > 0.0:
		var base: float = cam.fov
		var tw := create_tween()
		tw.tween_property(cam, "fov", base - fov_add, 0.25)
		tw.tween_property(cam, "fov", base, 0.9)
	if slow < 1.0:
		Engine.time_scale = slow
		await get_tree().create_timer(0.9 * slow).timeout
		Engine.time_scale = 1.0

func _flash(col: Color, alpha: float, dur: float) -> void:
	if not is_instance_valid(_flash):
		_flash_layer = CanvasLayer.new()
		_flash_layer.layer = 190
		_flash_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_flash_layer)
		_flash = ColorRect.new()
		_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_flash_layer.add_child(_flash)
	_flash.color = Color(col.r, col.g, col.b, 0.0)
	_flash.visible = true
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", alpha, dur * 0.25)
	tw.tween_property(_flash, "color:a", 0.0, dur * 0.75)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_flash):
			_flash.visible = false)

func _screen_shake() -> Node:
	var cs := get_tree().current_scene
	return cs.get_node_or_null("ScreenShake") if cs != null else null
