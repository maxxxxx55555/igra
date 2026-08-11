extends CanvasLayer

var _grain: ColorRect = null
var _vignette: ColorRect = null
var _visibility_overlay: ColorRect = null
var _visibility_detected: bool = false
var _visibility_timer: float = 0.0

func _ready() -> void:
	layer = 100
	_build_grain()
	_build_vignette()
	_build_visibility_overlay()
	visible = true
	EventBus.player_detected.connect(_on_player_detected)

func _build_visibility_overlay() -> void:
	_visibility_overlay = ColorRect.new()
	_visibility_overlay.name = "VisibilityOverlay"
	_visibility_overlay.color = Color(0.706, 0.271, 0.184, 0.0)
	_visibility_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visibility_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_visibility_overlay)
	var mat := ShaderMaterial.new()
	mat.shader = _visibility_shader()
	_visibility_overlay.material = mat

func _visibility_shader() -> Shader:
	var s := Shader.new()
	s.code = "shader_type canvas_item; uniform vec4 edge_color : source_color = vec4(0.706, 0.271, 0.184, 1.0); uniform float pulse : hint_range(0.0, 1.0) = 0.0; void fragment(){ vec2 uv = UV; vec2 d = abs(uv - 0.5); float v = smoothstep(0.5, 0.35, max(d.x, d.y)); float edge = 1.0 - smoothstep(0.35, 0.5, max(d.x, d.y)); COLOR = vec4(edge_color.rgb, edge * pulse * 0.6); }"
	return s

func _on_player_detected(_monster_id: StringName) -> void:
	_visibility_detected = true
	_visibility_timer = 3.0

func _process(delta: float) -> void:
	if _visibility_detected:
		_visibility_timer -= delta
		if _visibility_timer <= 0.0:
			_visibility_detected = false
	var target_pulse := 1.0 if _visibility_detected else 0.0
	var current_pulse: float = _visibility_overlay.color.a
	var new_pulse: float = lerpf(current_pulse, target_pulse, clampf(delta * 4.0, 0.0, 1.0))
	_visibility_overlay.color.a = new_pulse
	var mat := _visibility_overlay.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("pulse", new_pulse)

func _build_grain() -> void:
	_grain = ColorRect.new()
	_grain.name = "GrainOverlay"
	_grain.color = Color(0.0, 0.0, 0.0, 0.0)
	_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_grain)
	var mat := ShaderMaterial.new()
	mat.shader = _grain_shader()
	_grain.material = mat

func _grain_shader() -> Shader:
	var s := Shader.new()
	s.code = "shader_type canvas_item; uniform float intensity: hint_range(0,1) = 0.05; void fragment(){ float line = mod(floor(FRAGCOORD.y), 2.0); COLOR = vec4(0.0, 0.0, 0.0, line * intensity); }"
	return s

func _build_vignette() -> void:
	_vignette = ColorRect.new()
	_vignette.name = "VignetteOverlay"
	_vignette.color = Color(0.0, 0.0, 0.0, 0.25)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_vignette)
	var mat := ShaderMaterial.new()
	mat.shader = _vignette_shader()
	_vignette.material = mat

func _vignette_shader() -> Shader:
	var s := Shader.new()
	s.code = "shader_type canvas_item; void fragment(){ vec2 d = abs(UV - 0.5); float v = smoothstep(0.2, 0.5, max(d.x, d.y)); COLOR.a *= v; }"
	return s

func set_grain_intensity(v: float) -> void:
	if _grain and _grain.material is ShaderMaterial:
		_grain.material.set_shader_parameter("intensity", clampf(v, 0.0, 0.15))

func set_vignette_strength(v: float) -> void:
	if _vignette:
		_vignette.color.a = clampf(v, 0.0, 0.7)
