extends RefCounted
## rc16 closeout checks of uifx: wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const CHROMA_PX: float = 0.75
## Overlay layer name -> its letter in the tier table: vignette, grain, chromatic aberration.
const LAYER_LETTERS: Dictionary = {"VignetteOverlay": "V", "GrainOverlay": "G", "ChromaOverlay": "C"}

static func run(r: Node) -> void:
	await _post_fx_tiers(r)
	await _damage_pulse(r)
	await _sprint_blur(r)

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

static func _blur_strength(blur: CanvasItem) -> float:
	return float(((blur as ColorRect).material as ShaderMaterial).get_shader_parameter("strength"))

## A real sprint (the stick forward with run held, as the movement check drives it) through the Ultra tier.
static func _sprint_blur(r: Node) -> void:
	var overlay: Node = r._main.get_node_or_null("PostProcessOverlay")
	var blur: CanvasItem = overlay.get_node_or_null("MotionBlurOverlay") as CanvasItem if overlay != null else null
	r._ok(blur != null, "UIFX1 the overlay has a motion blur layer")
	if blur == null:
		return
	r._playing()
	var player: Node3D = r._player
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var pos0: Vector3 = player.global_position
	SettingsManager.set_graphics_tier(3)
	player.global_position = Vector3(-8.0, 1.0, -8.0)  # open ground, where the movement check walks
	player.rotation.y = 0.0
	player.set("gameplay_active", true)
	player.set("stamina", 100.0)
	await r.get_tree().create_timer(0.6).timeout
	var still_clear: bool = not blur.visible
	InputService.set_joy_active(true)
	InputService.set_joy_move_dir(Vector2(0.0, -1.0))
	InputService.set_joy_run_held(true)
	await r.get_tree().create_timer(0.8).timeout
	var running: bool = int(player.get("current_state")) == int(player.State.RUN)
	var strength: float = _blur_strength(blur)
	var ultra_shows: bool = blur.visible
	SettingsManager.set_graphics_tier(2)
	var high_shows: bool = blur.visible
	SettingsManager.set_graphics_tier(3)
	InputService.set_joy_run_held(false)
	InputService.set_joy_active(false)
	InputService.set_joy_move_dir(Vector2.ZERO)
	await r.get_tree().create_timer(1.2).timeout
	var faded: bool = not blur.visible and _blur_strength(blur) == 0.0
	r._ok(still_clear and running and ultra_shows and strength > 0.2 and strength <= 0.35 and not high_shows and faded,
		"UIFX1 sprinting at Ultra blurs up to 0.35 (%.2f, state RUN %s), the layer is hidden when still, below Ultra and 1.2 s after the sprint (%s, %s, %s)" % [strength, running, still_clear, not high_shows, faded])
	SettingsManager.set_graphics_tier(tier0)
	player.global_position = pos0
