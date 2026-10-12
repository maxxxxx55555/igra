extends ColorRect
## Rain on the lens (docs/VFX_BUDGET.md): in a shower or a storm drops slide down the glass and bend what is behind them. It copies the frame
## like the sprint blur does, so it is drawn only on the Ultra tier, only while it rains hard enough, and never with Motion Comfort on.
## A child of the post-process overlay; WeatherSystem's rain strength (0 to 1) arrives with EventBus.weather_changed.

const TIER_LENS: int = 3
const MIN_RAIN: float = 0.5
const CELLS: float = 7.0
const SHADER_CODE := "shader_type canvas_item;\n" \
	+ "uniform sampler2D screen_texture : hint_screen_texture, filter_linear;\n" \
	+ "uniform float strength : hint_range(0.0, 1.0) = 0.0;\n" \
	+ "uniform float cells = 7.0;\n" \
	+ "float hash(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }\n" \
	+ "void fragment() {\n" \
	+ "\tfloat aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;\n" \
	+ "\tvec2 grid = SCREEN_UV * vec2(cells * aspect, cells);\n" \
	+ "\tvec2 id = floor(grid);\n" \
	+ "\tvec2 f = fract(grid) - 0.5;\n" \
	+ "\tfloat roll = hash(id);\n" \
	+ "\tfloat t = fract(TIME * 0.07 + roll * 9.0);\n" \
	+ "\tvec2 centre = vec2((hash(id + 3.7) - 0.5) * 0.5, mix(0.42, -0.42, t));\n" \
	+ "\tvec2 d = (f - centre) * vec2(1.0, 0.75);\n" \
	+ "\tfloat drop = smoothstep(0.17, 0.0, length(d)) * step(roll, strength) * smoothstep(0.0, 0.12, t) * smoothstep(1.0, 0.85, t);\n" \
	+ "\tvec2 bend = normalize(d + 0.0001) * drop * 0.012;\n" \
	+ "\tCOLOR = vec4(textureLod(screen_texture, SCREEN_UV + bend, 0.0).rgb * (1.0 - 0.18 * drop), 1.0);\n" \
	+ "}\n"

var _rain: float = 0.0

func _ready() -> void:
	name = "RainLens"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("cells", CELLS)
	material = mat
	visible = false
	var weather := get_node_or_null("/root/WeatherSystem")
	if weather != null:
		_rain = float(weather.call("rain_strength"))
	EventBus.weather_changed.connect(func(_id: int, _label: String, _fog: float, rain: float) -> void:
		_rain = rain
		sync())
	EventBus.settings_changed.connect(func(_key: String, _value: Variant) -> void: sync())
	sync()

## Drawn only when it can be seen: a copy of the whole frame is the price.
func sync() -> void:
	var tier: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var comfort: bool = bool(SettingsManager.get_setting("reduce_camera_motion", false))
	visible = tier >= TIER_LENS and _rain >= MIN_RAIN and not comfort
	(material as ShaderMaterial).set_shader_parameter("strength", clampf((_rain - MIN_RAIN) / (1.0 - MIN_RAIN) * 0.6 + 0.3, 0.0, 1.0))
