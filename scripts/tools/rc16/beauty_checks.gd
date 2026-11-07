extends RefCounted
## rc16 closeout checks of beauty (Z-visual): wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const DAMAGE_SHADER_PATH: String = "res://assets/shaders/damage_vignette.gdshader"
const INDICATOR_PATH: String = "res://scenes/effects/damage_indicator.tscn"
## The damage flash fades in 0.55 s: its strength is read 0.2 s into it, then 0.8 s later.
const FLASH_MID_SEC: float = 0.2
const FLASH_REST_SEC: float = 0.8

static func run(r: Node) -> void:
	_grain_single_owner(r)
	await _damage_flash(r)
	await _grain_tier(r)
	_overlay_grain_hash(r)

static func _shader_code(path: String) -> String:
	var shader: Shader = load(path) as Shader
	return shader.code if shader != null else ""

## Every grain pass of the game scene: a node named GrainOverlay, or a canvas item whose shader file is a grain shader.
static func _grain_nodes(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	if root.name == "GrainOverlay":
		out.append(root)
	elif root is CanvasItem and (root as CanvasItem).material is ShaderMaterial:
		var sh: Shader = ((root as CanvasItem).material as ShaderMaterial).shader
		if sh != null and sh.resource_path.contains("grain"):
			out.append(root)
	for c in root.get_children():
		out.append_array(_grain_nodes(c))
	return out

## BEAUTY1: the post-process overlay is the SINGLE grain owner. The HUD used to run its own grain pass on top of the
## overlay's, so the screen was grained twice; the game scene now carries exactly one grain pass, the overlay's, and the HUD none.
static func _grain_single_owner(r: Node) -> void:
	var overlay: Node = r._main.get_node_or_null("PostProcessOverlay")
	var grain: ColorRect = overlay.get_node_or_null("GrainOverlay") as ColorRect if overlay != null else null
	var shader: Shader = (grain.material as ShaderMaterial).shader if grain != null and grain.material is ShaderMaterial else null
	var hud: Node = r._main.get_node_or_null("HUD")
	var hud_grain: Node = hud.find_child("GrainOverlay", true, false) if hud != null else null
	var owners: Array[Node] = _grain_nodes(r._main)
	r._ok(hud != null and hud_grain == null and shader != null and owners.size() == 1 and owners[0] == grain,
		"BEAUTY1 the post-process overlay owns the only grain pass: the HUD has none (%s) and the game scene carries exactly one (%d)" % [hud_grain == null, owners.size()])

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

## BEAUTY3: the single grain pass follows the graphics tier: off on Low, on from Medium up. The HUD's own grain pass used to
## stay on at Low while the overlay's went off, so Low grained the screen once through the HUD anyway.
static func _grain_tier(r: Node) -> void:
	var overlay: Node = r._main.get_node_or_null("PostProcessOverlay")
	var grain: CanvasItem = overlay.get_node_or_null("GrainOverlay") as CanvasItem if overlay != null else null
	if grain == null:
		r._ok(false, "BEAUTY3 the post-process overlay has no grain layer to gate by tier")
		return
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	SettingsManager.set_graphics_tier(0)
	var low: bool = not grain.visible
	SettingsManager.set_graphics_tier(1)
	var medium: bool = grain.visible
	SettingsManager.set_graphics_tier(tier0)
	r._ok(low and medium,
		"BEAUTY3 the single grain pass is off on the Low tier and on from Medium up (Low hidden %s, Medium shown %s)" % [low, medium])

## BEAUTY4: the grain of the post-process overlay does not fade with uptime. The old hash multiplied (UV + TIME * 0.24) * 110 by 234.34 and
## 435.345: after about 20 minutes float32 cannot tell those numbers apart and the grain became a constant (alpha 0 from about 1400 s). The new hash
## takes the pixel and a time shift of a few thousand at most, and has no such multiplier.
static func _overlay_grain_hash(r: Node) -> void:
	var overlay: Node = r._main.get_node_or_null("PostProcessOverlay")
	var shader: Shader = overlay.call("_grain_shader") as Shader if overlay != null else null
	var code: String = shader.code if shader != null else ""
	r._ok(code != "" and not code.contains("234.34") and not code.contains("435.345") and code.contains("0.1031") and code.contains("FRAGCOORD"),
		"BEAUTY4 the post-process grain hashes the pixel with the 0.1031 hash and has no 234.34 / 435.345 multipliers (%d characters of shader)" % code.length())
