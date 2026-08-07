class_name FuseBox
extends Node3D

@onready var fuse_slot_1: Node3D = %FuseSlot1
@onready var fuse_slot_2: Node3D = %FuseSlot2
@onready var fuse_slot_3: Node3D = %FuseSlot3
@onready var interact_area: Area3D = %InteractArea

var fuses_inserted: int = 0
var fuses_required: int = 3
var is_solved: bool = false
var is_player_near: bool = false

signal fuse_inserted(slot: int)
signal fuse_removed(slot: int)
signal fuse_box_solved()


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)


func interact() -> void:
	if is_solved:
		return
	if _has_fuse_in_inventory():
		_insert_fuse()
	else:
		push_warning("FuseBox: No fuse in inventory.")


func _has_fuse_in_inventory() -> bool:
	var player: Node = get_tree().root.get_node_or_null("Main3D/Player3D")
	if player and player.has_method("has_item"):
		return player.has_item("fuse")
	return false


func _insert_fuse() -> void:
	if fuses_inserted < fuses_required:
		fuses_inserted += 1
		fuse_inserted.emit(fuses_inserted)
		if fuses_inserted >= fuses_required:
			is_solved = true
			fuse_box_solved.emit()


func remove_fuse(slot: int) -> void:
	if slot >= 1 and slot <= fuses_required and not is_solved:
		if fuses_inserted > 0:
			fuses_inserted -= 1
			fuse_removed.emit(slot)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_near = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_near = false
