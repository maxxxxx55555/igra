extends Node3D
class_name HidingSpot

## S2.3 hiding spot: locker / dumpster / car. Player enters with interact,
## monsters lose track while occupied. Builds its own mesh + body when the
## scene has no children (StreetBuilder spawns bare nodes).

@export var spot_type: String = "locker"
@export var capacity: int = 1
## Monsters within this radius can still spot the player entering.
@export var enter_radius: float = 2.0

const TYPE_SIZES := {
	"locker":   Vector3(0.9, 2.0, 0.7),
	"dumpster": Vector3(1.8, 1.2, 1.0),
	"car":      Vector3(2.0, 1.4, 4.2),
	"crate":    Vector3(1.2, 1.2, 1.2),
}
const TYPE_COLORS := {
	"locker":   Color(0.22, 0.26, 0.30),
	"dumpster": Color(0.18, 0.28, 0.22),
	"car":      Color(0.24, 0.22, 0.26),
	"crate":    Color(0.30, 0.24, 0.16),
}

var _occupied: bool = false
var _occupant: Node3D = null

func _ready() -> void:
	add_to_group("hiding_spot")
	add_to_group("interactable")
	if get_child_count() == 0:
		_build_visual()

## Procedural body so spots are visible and block movement without art assets.
func _build_visual() -> void:
	var size: Vector3 = TYPE_SIZES.get(spot_type, TYPE_SIZES["locker"])
	var col: Color = TYPE_COLORS.get(spot_type, TYPE_COLORS["locker"])

	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var box := BoxMesh.new()
	box.size = size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.9
	box.material = mat
	mi.mesh = box
	mi.position = Vector3(0, size.y * 0.5, 0)
	add_child(mi)

	var body := StaticBody3D.new()
	body.name = "Body"
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(cs)
	add_child(body)

func can_enter() -> bool:
	return not _occupied

func enter(player: Node3D) -> bool:
	if _occupied:
		return false
	_occupied = true
	_occupant = player
	return true

func exit() -> void:
	_occupied = false
	_occupant = null

func is_occupied() -> bool:
	return _occupied

func interact_prompt() -> String:
	return "Hide" if can_enter() else "Occupied"
