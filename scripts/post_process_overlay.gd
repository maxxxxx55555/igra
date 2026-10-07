extends CanvasLayer

## The graphics tier (0 Low .. 3 Ultra) picks the layers: Low keeps the vignette alone, Medium adds the grain, High the
## chromatic aberration, Ultra the sprint motion blur. A layer with nothing to show is hidden: a screen-texture shader
## copies the whole frame every frame, even at amount 0, and a phone pays for that.
const TIER_GRAIN: int = 1
const TIER_CHROMA: int = 2
const TIER_BLUR: int = 3
const VISIBILITY_IDLE: float = 0.01  # below this the detection edge cannot be seen
const CHROMA_PULSE_PX: float = 2.0  # the aberration a hit starts from, in 1080p pixels
const CHROMA_PULSE_SEC: float = 0.25
const BLUR_MAX: float = 0.35
const BLUR_RATE: float = 8.0  # per second: how fast the blur follows the sprint
const BLUR_IDLE: float = 0.005  # below this the blur cannot be seen
const PLAYER_RUN: int = 2  # mirrors player_3d.gd: enum State { IDLE, WALK, RUN, STEALTH, CROUCH }

var _grain: ColorRect = null
var _vignette: ColorRect = null
var _chroma: ColorRect = null
var _visibility_overlay: ColorRect = null
var _visibility_detected: bool = false
var _visibility_timer: float = 0.0
var _tier: int = 2
var _chroma_base: float = 0.0
var _chroma_pulse: float = 0.0
var _pulse_tween: Tween = null
var _blur: ColorRect = null
var _blur_copy: BackBufferCopy = null
var _blur_strength: float = 0.0
var _player: Node = null

func _ready() -> void:
	layer = 100
	# Blur and chroma sample SCREEN_TEXTURE, so they must draw before the
	# grain/vignette overlays (plain color layers, no screen sampling) or they
	# would pick up their tint on the offset taps.
	_build_blur()
	_build_chroma()
	_build_grain()
	_build_vignette()
	_build_visibility_overlay()
	visible = true
	_tier = int(SettingsManager.get_setting("graphics_tier", 2))
	_apply_tier()
	EventBus.settings_changed.connect(_on_settings_changed)
	EventBus.player_detected.connect(_on_player_detected)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.game_state_changed.connect(_on_game_state)

## A paused tree stops _process, which would leave a half-faded blur over the menu: any state but PLAYING clears it now.
func _on_game_state(state: int) -> void:
	if state != GameManager.GameState.PLAYING:
		_blur_strength = 0.0
		_blur.visible = false

func _on_settings_changed(key: String, value: Variant) -> void:
	if key == "graphics_tier":
		_tier = int(value)
		_apply_tier()

## A hit smears the colour channels for a quarter of a second. It is a flash, so Reduce Flash turns it off. A tween that
## runs through the pause: a paused tree would freeze a half-decayed pulse on screen for as long as the menu stays open.
func _on_player_damaged(_amount: float) -> void:
	if _tier < TIER_CHROMA or bool(SettingsManager.get_setting("reduce_flash", false)):
		return
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pulse_tween.tween_method(_set_chroma_pulse, CHROMA_PULSE_PX, 0.0, CHROMA_PULSE_SEC)

func _set_chroma_pulse(px: float) -> void:
	_chroma_pulse = px
	_sync_chroma()

func _apply_tier() -> void:
	_grain.visible = _tier >= TIER_GRAIN
	_sync_chroma()
	if _tier < TIER_BLUR:
		_blur_strength = 0.0
		_blur.visible = false

func _build_blur() -> void:
	_blur = ColorRect.new()
	_blur.name = "MotionBlurOverlay"
	_blur.visible = false
	_blur.color = Color(0.047, 0.062, 0.086, 0.0)
	_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_blur)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/motion_blur.gdshader") as Shader
	_blur.material = mat
	# The canvas takes one screen copy per layer: without this node the chroma pass after the blur would read the unblurred copy and paint
	# it over the streaks. The node takes a fresh copy at its place in the draw order while the blur is on screen, and none otherwise.
	_blur_copy = BackBufferCopy.new()
	_blur_copy.name = "MotionBlurCopy"
	_blur_copy.copy_mode = BackBufferCopy.COPY_MODE_VIEWPORT
	_blur_copy.visible = false
	add_child(_blur_copy)
	_blur.visibility_changed.connect(func() -> void: _blur_copy.visible = _blur.visible)

## The blur follows the sprint by an exponential approach, so the same ramp plays at any frame rate.
func _process_blur(delta: float) -> void:
	var target: float = BLUR_MAX if _wants_blur() else 0.0
	if target == 0.0 and _blur_strength == 0.0:
		return
	_blur_strength = lerpf(_blur_strength, target, 1.0 - exp(-BLUR_RATE * delta))
	if target == 0.0 and _blur_strength < BLUR_IDLE:
		_blur_strength = 0.0
	_blur.visible = _blur_strength > 0.0
	(_blur.material as ShaderMaterial).set_shader_parameter("strength", _blur_strength)

func _wants_blur() -> bool:
	if _tier < TIER_BLUR or UIManager.is_hud_blocked() or bool(SettingsManager.get_setting("reduce_time_fx", false)):
		return false
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	return _player != null and int(_player.get("current_state")) == PLAYER_RUN

func _build_visibility_overlay() -> void:
	_visibility_overlay = ColorRect.new()
	_visibility_overlay.name = "VisibilityOverlay"
	_visibility_overlay.visible = false
	_visibility_overlay.color = Color(0.706, 0.271, 0.184, 0.0)
	_visibility_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visibility_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_visibility_overlay)
	var mat := ShaderMaterial.new()
	mat.shader = _visibility_shader()
	_visibility_overlay.material = mat

## Detection warning at the screen EDGE: 0 inside the middle 70 %, rising to
## the border. It was inverted (1 - smoothstep), so every detection painted
## the centre of the view ember and left the edges clear (rc14 boss frame).
func _visibility_shader() -> Shader:
	var s := Shader.new()
	s.code = "shader_type canvas_item; uniform vec4 edge_color : source_color = vec4(0.706, 0.271, 0.184, 1.0); uniform float pulse : hint_range(0.0, 1.0) = 0.0; void fragment(){ vec2 d = abs(UV - 0.5); float edge = smoothstep(0.35, 0.5, max(d.x, d.y)); COLOR = vec4(edge_color.rgb, edge * pulse * 0.6); }"
	return s

func _on_player_detected(_monster_id: StringName) -> void:
	_visibility_detected = true
	_visibility_timer = 3.0

func _process(delta: float) -> void:
	_process_blur(delta)
	if _visibility_detected:
		_visibility_timer -= delta
		if _visibility_timer <= 0.0:
			_visibility_detected = false
	var target_pulse := 1.0 if _visibility_detected else 0.0
	var current_pulse: float = _visibility_overlay.color.a
	var new_pulse: float = lerpf(current_pulse, target_pulse, clampf(delta * 4.0, 0.0, 1.0))
	_visibility_overlay.color.a = new_pulse
	_visibility_overlay.visible = new_pulse > VISIBILITY_IDLE
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
	_chroma_base = clampf(px_1080p, 0.0, 3.0)
	_sync_chroma()

## The shader gets an amount from the High tier up only, and the layer is drawn only while there is something to separate.
func _sync_chroma() -> void:
	if _chroma == null:
		return
	var mat := _chroma.material as ShaderMaterial
	var px: float = maxf(_chroma_base, _chroma_pulse) if _tier >= TIER_CHROMA else 0.0
	var vp := get_viewport()
	var h: float = float(vp.get_visible_rect().size.y) if vp else 1080.0
	_chroma.visible = px > 0.0
	mat.set_shader_parameter("amount_px_1080p", px)
	mat.set_shader_parameter("viewport_height", h)

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
## The hash takes a pixel cell plus a time shift of a few thousand at most. The old one multiplied
## (UV + TIME * 0.24) * 110 by 234.34 and 435.345, a number float32 cannot tell apart after
## about 20 minutes of uptime, and the grain faded to a constant.
func _grain_shader() -> Shader:
	var s := Shader.new()
	s.code = "shader_type canvas_item;\n" \
		+ "uniform float intensity : hint_range(0.0, 0.2) = 0.10;\n" \
		+ "uniform float speed : hint_range(0.0, 3.0) = 0.8;\n" \
		+ "float hash(vec2 p){ vec3 p3 = fract(p.xyx * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }\n" \
		+ "void fragment(){\n" \
		+ "  float g = hash(floor(FRAGCOORD.xy) + TIME * speed * vec2(61.7, 37.3));\n" \
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
