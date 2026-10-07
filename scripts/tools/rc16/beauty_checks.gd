extends RefCounted
## rc16 closeout checks of beauty (Z-visual): wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const GRAIN_SHADER_PATH: String = "res://assets/shaders/grain_overlay.gdshader"
const DAMAGE_SHADER_PATH: String = "res://assets/shaders/damage_vignette.gdshader"
const INDICATOR_PATH: String = "res://scenes/effects/damage_indicator.tscn"
## The damage flash fades in 0.55 s: its strength is read 0.2 s into it, then 0.8 s later.
const FLASH_MID_SEC: float = 0.2
const FLASH_REST_SEC: float = 0.8

static func run(r: Node) -> void:
	_grain_sampler(r)
	await _damage_flash(r)
	_grain_hash(r)
	_overlay_grain_hash(r)

static func _shader_code(path: String) -> String:
	var shader: Shader = load(path) as Shader
	return shader.code if shader != null else ""

## BEAUTY1: the HUD grain pass reads the screen 1:1 at SCREEN_UV, so its screen sampler asks for a plain linear filter, not a mipmap one.
static func _grain_sampler(r: Node) -> void:
	var sampler: String = ""
	for line in _shader_code(GRAIN_SHADER_PATH).split("\n"):
		if line.contains("hint_screen_texture"):
			sampler = line
	r._ok(sampler.contains("filter_linear") and not sampler.contains("mipmap"),
		"BEAUTY1 the HUD grain pass samples the screen with a plain linear filter and no mipmap filter (%s)" % sampler.strip_edges())

## BEAUTY2: a hit starts the ember vignette on the peak of its beat. The beat runs on `age`, which a hit sets to 0 together with strength 1, and the strength is 0 when the fade is over.
## It ran on the free-running TIME before, so the corner alpha of a hit landed anywhere from 0.10 to 1.00 (46 % of the hits below 0.5).
static func _damage_flash(r: Node) -> void:
	r._playing()
	var beat_line: String = ""
	for line in _shader_code(DAMAGE_SHADER_PATH).split("\n"):
		if line.contains("float beat"):
			beat_line = line
	var flash0: bool = bool(SettingsManager.get_setting("reduce_flash", false))
	SettingsManager.set_setting("reduce_flash", false)
	var indicator: Node = (load(INDICATOR_PATH) as PackedScene).instantiate()
	r.add_child(indicator)
	var mat: ShaderMaterial = (indicator.get_node("Vignette") as ColorRect).material as ShaderMaterial
	indicator.call("_on_damaged", 5)
	var age: Variant = mat.get_shader_parameter("age")
	var first: Variant = mat.get_shader_parameter("strength")
	await r.get_tree().create_timer(FLASH_MID_SEC).timeout
	var mid: float = float(mat.get_shader_parameter("strength"))
	await r.get_tree().create_timer(FLASH_REST_SEC).timeout
	var last: float = float(mat.get_shader_parameter("strength"))
	var on_age: bool = beat_line.contains("age") and not beat_line.contains("TIME")
	var peak: bool = age is float and is_zero_approx(float(age)) and first is float and is_equal_approx(float(first), 1.0)
	r._ok(on_age and peak and mid > 0.2 and mid < 1.0 and is_zero_approx(last),
		"BEAUTY2 a hit starts the damage vignette on its peak: the beat runs on age, not TIME, a hit sets age 0 and strength 1 at once and the strength is 0 when the fade is over (%s; age %s, strength %s, then %.2f at %.1f s, %.2f at %.1f s)" % [beat_line.strip_edges(), age, first, mid, FLASH_MID_SEC, last, FLASH_MID_SEC + FLASH_REST_SEC])
	indicator.queue_free()
	SettingsManager.set_setting("reduce_flash", flash0)

## BEAUTY3: the HUD grain hashes each pixel cell without a repeat. The old hash took fract(cell * (127.1, 311.7)): the multipliers are whole numbers plus .1 and .7, so the noise was one 10 x 10 px tile repeated over the screen (autocorrelation 0.96 at a lag of 10 px in the shader's own float math, about 0 for the new hash).
static func _grain_hash(r: Node) -> void:
	var code: String = _shader_code(GRAIN_SHADER_PATH)
	r._ok(not code.contains("127.1") and not code.contains("311.7") and code.contains("0.1031") and code.contains("33.33"),
		"BEAUTY3 the HUD grain hash has no 127.1 / 311.7 multipliers (a 10 px repeat) and is the 0.1031 / 33.33 hash")

## BEAUTY4: the grain of the post-process overlay does not fade with uptime. The old hash multiplied (UV + TIME * 0.24) * 110 by 234.34 and
## 435.345: after about 20 minutes float32 cannot tell those numbers apart and the grain became a constant (alpha 0 from about 1400 s). The new hash
## takes the pixel and a time shift of a few thousand at most, and has no such multiplier.
static func _overlay_grain_hash(r: Node) -> void:
	var overlay: Node = r._main.get_node_or_null("PostProcessOverlay")
	var shader: Shader = overlay.call("_grain_shader") as Shader if overlay != null else null
	var code: String = shader.code if shader != null else ""
	r._ok(code != "" and not code.contains("234.34") and not code.contains("435.345") and code.contains("0.1031") and code.contains("FRAGCOORD"),
		"BEAUTY4 the post-process grain hashes the pixel with the 0.1031 hash and has no 234.34 / 435.345 multipliers (%d characters of shader)" % code.length())
