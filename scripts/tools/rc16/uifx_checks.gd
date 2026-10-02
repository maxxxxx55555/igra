extends RefCounted
## rc16 closeout checks of uifx: wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const CHROMA_PX: float = 0.75
## Overlay layer name -> its letter in the tier table: vignette, grain, chromatic aberration.
const LAYER_LETTERS: Dictionary = {"VignetteOverlay": "V", "GrainOverlay": "G", "ChromaOverlay": "C"}

static func run(r: Node) -> void:
	await _post_fx_tiers(r)
	await _damage_pulse(r)

static func _chroma_px(overlay: Node) -> float:
	var mat := (overlay.get_node("ChromaOverlay") as ColorRect).material as ShaderMaterial
	return float(mat.get_shader_parameter("amount_px_1080p"))

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
	var chroma0: float = _chroma_px(overlay)
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

## One hit through the real signal; the aberration on screen 0.05 s later and again 0.5 s later.
static func _hit_and_read(r: Node, overlay: Node) -> PackedFloat32Array:
	EventBus.player_damaged.emit(5.0)
	await r.get_tree().create_timer(0.05).timeout
	var early: float = _chroma_px(overlay)
	await r.get_tree().create_timer(0.5).timeout
	return PackedFloat32Array([early, _chroma_px(overlay)])

static func _damage_pulse(r: Node) -> void:
	var overlay: Node = r._main.get_node_or_null("PostProcessOverlay")
	if overlay == null:
		return
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var flash0: bool = bool(SettingsManager.get_setting("reduce_flash", false))
	SettingsManager.set_graphics_tier(2)
	SettingsManager.set_setting("reduce_flash", false)
	var chroma0: float = _chroma_px(overlay)
	overlay.call("set_chroma_amount", 0.0)  # nothing from the district, so only the hit can show
	var high: PackedFloat32Array = await _hit_and_read(r, overlay)
	var pulses: bool = high[0] > 0.0 and high[0] <= 2.0 and high[1] == 0.0 and not (overlay.get_node("ChromaOverlay") as CanvasItem).visible
	r._ok(pulses, "UIFX2 a hit pulses the chromatic aberration up to 2 px and it is gone 0.5 s later, layer hidden again (%.2f px, then %.2f px)" % [high[0], high[1]])
	SettingsManager.set_graphics_tier(0)
	var low: PackedFloat32Array = await _hit_and_read(r, overlay)
	SettingsManager.set_graphics_tier(2)
	SettingsManager.set_setting("reduce_flash", true)
	var calm: PackedFloat32Array = await _hit_and_read(r, overlay)
	r._ok(pulses and low[0] == 0.0 and calm[0] == 0.0, "UIFX2 the pulse stays 0 at the Low tier and under Reduce Flash (%.2f px, %.2f px)" % [low[0], calm[0]])
	SettingsManager.set_setting("reduce_flash", flash0)
	overlay.call("set_chroma_amount", chroma0)
	SettingsManager.set_graphics_tier(tier0)
