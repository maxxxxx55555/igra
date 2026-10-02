extends RefCounted
## rc16 closeout checks of uifx: wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const CHROMA_PX: float = 0.75
## Overlay layer name -> its letter in the tier table: vignette, grain, chromatic aberration.
const LAYER_LETTERS: Dictionary = {"VignetteOverlay": "V", "GrainOverlay": "G", "ChromaOverlay": "C"}

static func run(r: Node) -> void:
	await _post_fx_tiers(r)

static func _layers_on(overlay: Node) -> String:
	var shown := ""
	for layer_name in LAYER_LETTERS:
		var layer := overlay.get_node_or_null(String(layer_name)) as CanvasItem
		if layer != null and layer.visible:
			shown += String(LAYER_LETTERS[layer_name])
	return shown

static func _post_fx_tiers(r: Node) -> void:
	var overlay: Node = r._main.get_node_or_null("PostProcessOverlay")
	r._ok(overlay != null, "UIFX1 the game scene carries the post-fx overlay")
	if overlay == null:
		return
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	SettingsManager.set_graphics_tier(2)
	var chroma_mat := (overlay.get_node("ChromaOverlay") as ColorRect).material as ShaderMaterial
	var chroma0: float = float(chroma_mat.get_shader_parameter("amount_px_1080p"))
	overlay.call("set_chroma_amount", CHROMA_PX)  # a district preset: the aberration has something to show
	var seen := PackedStringArray()
	for tier in 4:
		SettingsManager.set_graphics_tier(tier)
		await r.get_tree().process_frame
		seen.append(_layers_on(overlay))
	r._ok(seen == PackedStringArray(["V", "VG", "VGC", "VGC"]),
		"UIFX1 the tier table: Low draws the vignette alone, Medium adds the grain, High the chromatic aberration (Low..Ultra: %s)" % ", ".join(seen))
	overlay.call("set_chroma_amount", chroma0)
	SettingsManager.set_graphics_tier(tier0)
