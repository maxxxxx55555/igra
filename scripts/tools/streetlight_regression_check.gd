extends Node
## Covers Reduce Flash changes reaching lamps and lamp materials that already exist.

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
	EventBus.district_stage_changed.emit(&"suburbs", 3)
	var batched: ShaderMaterial = LAMP_HEAD.make()
	var standalone: ShaderMaterial = LAMP_HEAD.shared()
	get_tree().paused = true
	SettingsManager.set_setting("reduce_flash", true)
	get_tree().paused = false
	_expect(_lowest(lamp, spot) > 1.0, "Reduce Flash immediately removes the dip of an existing lamp")
	for material: ShaderMaterial in [batched, standalone]:
		_expect(_uniform(material, "flicker_depth", 0.15) == 0.0
			and _uniform(material, "hum_shimmer", 0.02) == 0.0
			and _uniform(material, "dropout_threshold", 0.96) >= 1.0,
			"Reduce Flash immediately stills an existing lamp material")
	SettingsManager.set_setting("reduce_flash", false)
	_expect(_lowest(lamp, spot) < 1.0, "Disabling Reduce Flash restores the dip")
	for material: ShaderMaterial in [batched, standalone]:
		_expect(_uniform(material, "flicker_depth", 0.15) > 0.0
			and _uniform(material, "hum_shimmer", 0.02) > 0.0
			and _uniform(material, "dropout_threshold", 0.96) < 1.0,
			"Disabling Reduce Flash restores existing material animation")
	EventBus.district_stage_changed.emit(&"suburbs", 0)
	lamp.call("_process", 0.1)
	_expect(spot.light_energy == 0.0 and glow.light_energy == 0.0,
		"Blackout stays dark after processing")
	lamp.queue_free()
	SettingsManager.set_setting("reduce_flash", original)
	print("[streetlight-regression] DONE fails=", _fails)
	get_tree().quit(1 if _fails > 0 else 0)

## The lowest spot energy over two seconds of flicker.
func _lowest(lamp: Node3D, spot: SpotLight3D) -> float:
	var low: float = INF
	for step: int in 240:
		lamp.call("_process", 1.0 / 120.0)
		low = minf(low, spot.light_energy)
	return low

func _uniform(material: ShaderMaterial, key: StringName, fallback: float) -> float:
	var value: Variant = material.get_shader_parameter(key)
	return fallback if value == null else float(value)

func _expect(ok: bool, message: String) -> void:
	if not ok:
		_fails += 1
	print("[streetlight-regression] ", "PASS " if ok else "FAIL ", message)
