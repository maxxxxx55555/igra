extends Node
## Covers stage energy lost on the next frame and comfort changes on existing lamps.

const LAMP_SCENE := preload("res://scenes/props/streetlight_3d.tscn")
const LAMP_HEAD := preload("res://scripts/world/lamp_head.gd")
var _fails: int = 0

func _ready() -> void:
	var original: bool = bool(SettingsManager.get_setting("reduce_flash", false))
	SettingsManager.set_setting("reduce_flash", false)
	var lamp := LAMP_SCENE.instantiate() as Node3D
	lamp.set("district_id", &"suburbs")
	add_child(lamp)
	lamp.set_process(false)
	var spot := lamp.get_node("SpotLight") as SpotLight3D
	var glow := lamp.get_node("Glow") as OmniLight3D
	var energies: Array[Vector2] = []
	for stage: int in [2, 3]:
		EventBus.district_stage_changed.emit(&"suburbs", stage)
		# Equal phases isolate stage brightness from the intentional flicker.
		lamp.set("_t", 0.0)
		lamp.call("_process", 0.0)
		energies.append(Vector2(spot.light_energy, glow.light_energy))
	_expect(is_equal_approx(energies[1].x / energies[0].x, 1.4)
		and is_equal_approx(energies[1].y / energies[0].y, 1.5),
		"FULL retains its brighter spot and glow after processing: %s" % str(energies))
	var batched: ShaderMaterial = LAMP_HEAD.make()
	var standalone: ShaderMaterial = LAMP_HEAD.shared()
	get_tree().paused = true
	SettingsManager.set_setting("reduce_flash", true)
	_expect(is_equal_approx(spot.light_energy, 3.5) and is_equal_approx(glow.light_energy, 1.5),
		"Reduce Flash restores steady stage energy while paused, before processing")
	get_tree().paused = false
	var calm: bool = true
	for step: int in 240:
		lamp.call("_process", 1.0 / 120.0)
		calm = calm and is_equal_approx(spot.light_energy, 3.5) and is_equal_approx(glow.light_energy, 1.5)
	_expect(calm, "Reduce Flash immediately keeps existing FULL lamp steady at stage energy")
	for material: ShaderMaterial in [batched, standalone]:
		_expect(_uniform(material, "flicker_depth", 0.15) == 0.0
			and _uniform(material, "hum_shimmer", 0.02) == 0.0
			and _uniform(material, "dropout_threshold", 0.96) >= 1.0,
			"Reduce Flash immediately stills an existing lamp material")
	SettingsManager.set_setting("reduce_flash", false)
	var low: float = INF
	var high: float = -INF
	for step: int in 240:
		lamp.call("_process", 1.0 / 120.0)
		low = minf(low, spot.light_energy)
		high = maxf(high, spot.light_energy)
	_expect(high - low > 0.1, "Disabling Reduce Flash restores light animation")
	for material: ShaderMaterial in [batched, standalone]:
		_expect(_uniform(material, "flicker_depth", 0.15) > 0.0
			and _uniform(material, "hum_shimmer", 0.02) > 0.0
			and _uniform(material, "dropout_threshold", 0.96) < 1.0,
			"Disabling Reduce Flash restores existing material animation")
	# Find a real PARTIAL subset member instead of forcing the lamp on.
	for x: int in 100:
		lamp.position.x = float(x)
		if bool(lamp.call("_in_partial_set")):
			break
	EventBus.district_stage_changed.emit(&"suburbs", 1)
	lamp.set("_t", 0.0)
	lamp.call("_process", 0.0)
	_expect(is_equal_approx(spot.light_energy, 1.19) and is_equal_approx(glow.light_energy, 0.425),
		"PARTIAL applies flicker to its own baseline without a second dimming factor")
	lamp.set("lamp_flicker", false)
	for calm_setting: bool in [true, false]:
		SettingsManager.set_setting("reduce_flash", calm_setting)
		lamp.call("_process", 0.2)
		_expect(is_equal_approx(spot.light_energy, 1.4) and is_equal_approx(glow.light_energy, 0.5),
			"A lamp with flicker disabled remains steady across comfort changes")
	EventBus.district_stage_changed.emit(&"suburbs", 0)
	lamp.call("_process", 0.1)
	_expect(spot.light_energy == 0.0 and glow.light_energy == 0.0,
		"Blackout stays dark after processing")
	lamp.queue_free()
	SettingsManager.set_setting("reduce_flash", original)
	print("[streetlight-regression] DONE fails=", _fails)
	get_tree().quit(1 if _fails > 0 else 0)

func _uniform(material: ShaderMaterial, key: StringName, fallback: float) -> float:
	var value: Variant = material.get_shader_parameter(key)
	return fallback if value == null else float(value)

func _expect(ok: bool, message: String) -> void:
	if not ok:
		_fails += 1
	print("[streetlight-regression] ", "PASS " if ok else "FAIL ", message)
