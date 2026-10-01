extends Node3D
class_name HidingSpot

## S2.3 hiding spot: locker / dumpster / car / crate / bush / dark corner (GDD §7). Player enters with
## interact, monsters lose track while occupied. Builds its own mesh + body when the
## scene has no children (DistrictLoot spawns bare nodes).

@export var spot_type: String = "locker"
@export var capacity: int = 1
## Monsters within this radius can still spot the player entering.
@export var enter_radius: float = 2.0
## Where the player steps out: the unit direction from the spot toward the street.
@export var exit_dir: Vector3 = Vector3(0.0, 0.0, 1.0)

const TYPE_SIZES := {
	"locker":   Vector3(0.9, 2.0, 0.7),
	"dumpster": Vector3(1.8, 1.2, 1.0),
	"car":      Vector3(4.2, 1.4, 2.0),
	"crate":    Vector3(1.2, 1.2, 1.2),
	"bush":     Vector3(1.6, 1.1, 1.0),
	"dark_corner": Vector3(1.6, 2.2, 0.5),
}
const TYPE_COLORS := {
	"locker":   Color(0.22, 0.26, 0.30),
	"dumpster": Color(0.18, 0.28, 0.22),
	"car":      Color(0.24, 0.22, 0.26),
	"crate":    Color(0.30, 0.24, 0.16),
	"bush":     Color(0.09, 0.16, 0.12),
	"dark_corner": Color(0.043, 0.059, 0.078),
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
	if spot_type == "dumpster":
		var tex: Texture2D = load("res://assets/textures/surfaces/dumpster_metal_512.png")
		if tex:
			mat.albedo_texture = tex
			mat.metallic = 0.5
			mat.roughness = 0.55
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
	# The player stands inside the spot's own collider while hidden: let it through.
	var body := get_node_or_null("Body") as CollisionObject3D
	if body != null and player is PhysicsBody3D:
		(player as PhysicsBody3D).add_collision_exception_with(body)
	return true

func exit() -> void:
	var player := _occupant
	_occupied = false
	_occupant = null
	if player == null or not is_instance_valid(player):
		return
	var body := get_node_or_null("Body") as CollisionObject3D
	if body != null and player is PhysicsBody3D:
		(player as PhysicsBody3D).remove_collision_exception_with(body)
	var half_depth: float = (TYPE_SIZES.get(spot_type, TYPE_SIZES["locker"]) as Vector3).z * 0.5
	var out := global_position + exit_dir.normalized() * (half_depth + 0.9)
	player.global_position = Vector3(out.x, player.global_position.y, out.z)

func is_occupied() -> bool:
	return _occupied

## Укрытие всегда принимает нажатие: занятое собой — чтобы выйти.
## Без этого Interactor скрывал подсказку, как только игрок залезал внутрь,
## и выбраться можно было только через старую ветку опроса клавиши.
func can_interact() -> bool:
	return not _occupied or _occupant != null

func interact(player: Node) -> void:
	if player == null or not player.has_method("toggle_hiding"):
		return
	player.call("toggle_hiding", self)

func interact_prompt() -> String:
	if _occupied:
		return LocalizationManager.t("PROMPT_LEAVE_HIDE")
	return LocalizationManager.t("PROMPT_HIDE")
