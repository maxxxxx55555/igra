extends Node3D
## PowerSwitch: visible panel with OmniLight3D. Toggle PowerGrid on interact.

@export var district_id: StringName = &""
@export var locked: bool = false

var _panel: MeshInstance3D
var _light: OmniLight3D
var _label: Label3D
var _bus: Node

func _ready() -> void:
	_bus = get_node_or_null("/root/EventBus")
	_build_visual()
	call_deferred("_refresh_visual")

func _build_visual() -> void:
	_panel = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.8, 1.6, 0.2)
	_panel.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.3)
	mat.emission_energy_multiplier = 0.4
	_panel.material_override = mat
	add_child(_panel)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.7, 0.3)
	_light.light_energy = 0.0
	_light.omni_range = 6.0
	_light.position = Vector3(0, 0.6, 0.6)
	add_child(_light)

	_label = Label3D.new()
	_label.text = String(district_id).to_upper()
	_label.font_size = 32
	_label.position = Vector3(0, 1.8, 0.1)
	_label.modulate = Color(1.0, 0.85, 0.4)
	add_child(_label)

func _refresh_visual() -> void:
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null:
		return
	var on: bool = pg.is_powered(district_id)
	_light.light_energy = 1.5 if on else 0.0
	var mat := _panel.material_override as StandardMaterial3D
	if mat != null:
		mat.emission_energy_multiplier = 1.5 if on else 0.2
	if _bus != null and not _bus.district_powered.is_connected(_refresh_visual):
		_bus.district_powered.connect(_refresh_visual)

func interact(player: Node) -> void:
	if locked:
		return
	if district_id == &"":
		return
	var pg := get_node_or_null("/root/PowerGrid")
	if pg == null:
		return
	pg.toggle_district(district_id)
	var tw := create_tween()
	tw.tween_property(_light, "light_energy", 2.5, 0.08)
	tw.tween_property(_light, "light_energy", 1.5 if pg.is_powered(district_id) else 0.0, 0.35)