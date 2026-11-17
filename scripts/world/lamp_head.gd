extends RefCounted
## W4 of docs/VISUAL_PASS.md section 8: the material of the lamp heads. It is mat_lamp_flicker.tres (assets/shaders/streetlight_flicker.gdshader: a flicker per lamp from a hash of its place, the off colour to the lit colour by `lit`),
## copied per district because `lit` is the power stage of that district: dark 0, partial 0.45, streets and full 1, and the head a quarter hotter at full. A stage that raises it ramps over RAMP_SEC (the turn-on of a
## restore); a lower one drops at once. Reduce Flash stills the shimmer and the dropouts, as it does for the lights themselves (streetlight_3d.gd). The hum is left at 1.0: the Hum bus was removed in rc14.

const MATERIAL: String = "res://assets/env/mat_lamp_flicker.tres"
const LIT_BY_STAGE: Array[float] = [0.0, 0.45, 1.0, 1.0]
const ENERGY_BY_STAGE: Array[float] = [1.6, 1.6, 1.6, 2.0]
const RAMP_SEC: float = 1.2

static var _shared: ShaderMaterial = null
static var _materials: Array[WeakRef] = []

static func make() -> ShaderMaterial:
	var mat := (load(MATERIAL) as ShaderMaterial).duplicate() as ShaderMaterial
	_prune_materials()
	_materials.append(weakref(mat))
	if not EventBus.settings_changed.is_connected(_on_setting_changed):
		EventBus.settings_changed.connect(_on_setting_changed)
	_apply_comfort(mat, bool(SettingsManager.get_setting("reduce_flash", false)))
	return mat

static func _prune_materials() -> void:
	for i: int in range(_materials.size() - 1, -1, -1):
		if _materials[i].get_ref() == null:
			_materials.remove_at(i)

static func _on_setting_changed(key: String, value: Variant) -> void:
	if key != "reduce_flash":
		return
	_prune_materials()
	for reference: WeakRef in _materials:
		_apply_comfort(reference.get_ref() as ShaderMaterial, bool(value))

static func _apply_comfort(mat: ShaderMaterial, calm: bool) -> void:
	# Null restores the authored shader defaults when comfort is switched off.
	mat.set_shader_parameter("flicker_depth", 0.0 if calm else null)
	mat.set_shader_parameter("hum_shimmer", 0.0 if calm else null)
	mat.set_shader_parameter("dropout_threshold", 1.0 if calm else null)

## The one material of the lamp meshes that stand alone (an unbatched streetlight), lit.
static func shared() -> ShaderMaterial:
	if _shared == null:
		_shared = make()
	return _shared

static func apply_stage(mat: ShaderMaterial, stage: int, owner: Node) -> void:
	var i: int = clampi(stage, 0, LIT_BY_STAGE.size() - 1)
	var from: float = float(mat.get_shader_parameter("lit"))
	mat.set_shader_parameter("energy_mult", ENERGY_BY_STAGE[i])
	if LIT_BY_STAGE[i] > from and owner.is_inside_tree():
		owner.create_tween().tween_method(func(v: float) -> void: mat.set_shader_parameter("lit", v), from, LIT_BY_STAGE[i], RAMP_SEC)
	else:
		mat.set_shader_parameter("lit", LIT_BY_STAGE[i])
