extends RefCounted
## rc16 closeout checks of beauty (Z-visual): wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const GRAIN_SHADER_PATH: String = "res://assets/shaders/grain_overlay.gdshader"

static func run(r: Node) -> void:
	_grain_sampler(r)

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
