extends CanvasLayer

var _grain: ColorRect = null
var _vignette: ColorRect = null
var _chroma: ColorRect = null
var _visibility_overlay: ColorRect = null
var _visibility_detected: bool = false
var _visibility_timer: float = 0.0

func _ready() -> void:
	layer = 100
	# Chroma samples SCREEN_TEXTURE, so it must draw before the grain/vignette
	# overlays (plain color layers, no screen sampling) or it would pick up
	# their tint on its R/B offset taps.
	_build_chroma()
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

## Радиальная хроматическая аберрация (assets/textures/postfx/README.md
## "Chroma" layer). amount_px_1080p=0 -> identity (R=G=B, no sampling
## offset), so districts with no preset entry render unchanged.
func _build_chroma() -> void:
	_chroma = ColorRect.new()
	_chroma.name = "ChromaOverlay"
	_chroma.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chroma.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_chroma)
	var mat := ShaderMaterial.new()
	mat.shader = _chroma_shader()
	mat.set_shader_parameter("amount_px_1080p", 0.0)
	mat.set_shader_parameter("viewport_height", 1080.0)
	_chroma.material = mat

func _chroma_shader() -> Shader:
	var s := Shader.new()
	s.code = "shader_type canvas_item;\n" \
		+ "uniform sampler2D screen_texture : hint_screen_texture, filter_linear;\n" \
		+ "uniform float amount_px_1080p : hint_range(0.0, 3.0) = 0.0;\n" \
		+ "uniform float viewport_height : hint_range(1.0, 8192.0) = 1080.0;\n" \
		+ "void fragment(){\n" \
		+ "  vec2 centered = UV - 0.5;\n" \
		+ "  float px = amount_px_1080p * (viewport_height / 1080.0);\n" \
		+ "  vec2 offset = centered * (px / max(viewport_height, 1.0));\n" \
		+ "  float r = textureLod(screen_texture, SCREEN_UV + offset, 0.0).r;\n" \
		+ "  float g = textureLod(screen_texture, SCREEN_UV, 0.0).g;\n" \
		+ "  float b = textureLod(screen_texture, SCREEN_UV - offset, 0.0).b;\n" \
		+ "  COLOR = vec4(r, g, b, 1.0);\n" \
		+ "}"
	return s

func set_chroma_amount(px_1080p: float) -> void:
	if _chroma and _chroma.material is ShaderMaterial:
		var vp := get_viewport()
		var h: float = float(vp.get_visible_rect().size.y) if vp else 1080.0
		_chroma.material.set_shader_parameter("amount_px_1080p", clampf(px_1080p, 0.0, 3.0))
		_chroma.material.set_shader_parameter("viewport_height", h)

func _build_grain() -> void:
	_grain = ColorRect.new()
	_grain.name = "GrainOverlay"
	_grain.color = Color(1.0, 1.0, 1.0, 1.0)
	_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_grain)
	var mat := ShaderMaterial.new()
	mat.shader = _grain_shader()
	_grain.material = mat

## Плёночное зерно по GDD §11.4 (8–12% непрозрачности). Раньше здесь были
## статичные строки развёртки (mod по Y) — это скан-лайны из CRT-эффекта,
## а не зерно: картинка выглядела как старый телевизор и не шевелилась.
func _grain_shader() -> Shader:
	var s := Shader.new()
	s.code = "shader_type canvas_item;\n" \
		+ "uniform float intensity : hint_range(0.0, 0.2) = 0.10;\n" \
		+ "uniform float speed : hint_range(0.0, 3.0) = 0.8;\n" \
		+ "uniform float scale : hint_range(40.0, 200.0) = 110.0;\n" \
		+ "float hash(vec2 p){ p = fract(p * vec2(234.34, 435.345)); p += dot(p, p + 34.23); return fract(p.x * p.y); }\n" \
		+ "void fragment(){\n" \
		+ "  vec2 off = vec2(TIME * speed * 0.3, TIME * speed * 0.17);\n" \
		+ "  float g = hash((UV + off) * scale);\n" \
		+ "  COLOR = vec4(vec3(g), (g - 0.5) * intensity + intensity * 0.5);\n" \
		+ "}"
	return s

func _build_vignette() -> void:
	_vignette = ColorRect.new()
	_vignette.name = "VignetteOverlay"
	_vignette.color = Color(0.047, 0.062, 0.086, 0.55)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_vignette)
	var mat := ShaderMaterial.new()
	mat.shader = _vignette_shader()
	_vignette.material = mat

## Виньетка уходит в #0c1016 (bg-deep, цвет ColorRect по умолчанию), а не в чистый
## чёрный — канон GDD §11.2. RGB берётся из COLOR, чтобы S03 мог тонировать край в ember.
func _vignette_shader() -> Shader:
	var s := Shader.new()
	s.code = "shader_type canvas_item;\n" \
		+ "void fragment(){\n" \
		+ "  vec2 d = (UV - 0.5) * vec2(1.7, 1.0);\n" \
		+ "  float v = smoothstep(0.3, 1.0, length(d));\n" \
		+ "  COLOR = vec4(COLOR.rgb, COLOR.a * v);\n" \
		+ "}"
	return s

func set_grain_intensity(v: float) -> void:
	if _grain and _grain.material is ShaderMaterial:
		_grain.material.set_shader_parameter("intensity", clampf(v, 0.0, 0.15))

func set_vignette_strength(v: float) -> void:
	if _vignette:
		_vignette.color.a = clampf(v, 0.0, 0.7)
