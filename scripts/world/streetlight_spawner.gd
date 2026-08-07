extends Node3D
class_name StreetLightSpawner

@export var street_builder_path: NodePath = ^"StreetBuilder"
@export var spacing: float = 12.0
@export var light_color: Color = Color("#f4c95d")
@export var light_energy: float = 1.2
@export var light_range: float = 6.0

var _street = null

func _ready() -> void:
	_street = get_node_or_null(street_builder_path)
	if _street == null:
		return
	if not _street.streets_ready.is_connected(_spawn_lights):
		_street.streets_ready.connect(_spawn_lights)

func _spawn_lights() -> void:
	var roads: Array = _street.roads
	var tile: float = _street.tile_size
	var step_n: int = max(1, int(spacing / tile))
	for road in roads:
		var steps: int = int(float(road.get("length", 0.0)) / tile)
		for s in range(0, steps, step_n):
			var pos: Vector3 = _street.road_step_pos(road, s)
			_place_lamp(pos, String(road.get("dir", "h")))

func _place_lamp(pos: Vector3, dir: String) -> void:
	var lateral: Vector3 = Vector3(0, 0, 4.0) if dir == "h" else Vector3(4.0, 0, 0)
	var base: Vector3 = pos + lateral
	var pole := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.15, 3.5, 0.15)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#1a1a1a")
	bm.material = mat
	pole.mesh = bm
	pole.position = base + Vector3(0, 1.75, 0)
	add_child(pole)
	var head := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.3, 0.15, 0.3)
	var hm_mat := StandardMaterial3D.new()
	hm_mat.albedo_color = Color.BLACK
	hm_mat.emission_enabled = true
	hm_mat.emission = light_color
	hm_mat.emission_energy_multiplier = 3.0
	hm.material = hm_mat
	head.mesh = hm
	head.position = base + Vector3(0, 3.6, 0)
	add_child(head)
	var lamp := OmniLight3D.new()
	lamp.light_color = light_color
	lamp.light_energy = light_energy
	lamp.omni_range = light_range
	lamp.shadow_enabled = false
	lamp.position = base + Vector3(0, 3.4, 0)
	add_child(lamp)
