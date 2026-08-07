class_name RagdollComponent
extends Node

@export var ragdoll_scene: PackedScene
@export var despawn_time: float = 5.0

func trigger_ragdoll(body: CharacterBody3D) -> void:
	if not ragdoll_scene:
		return
	var ragdoll: Node3D = ragdoll_scene.instantiate()
	ragdoll.global_transform = body.global_transform
	body.get_parent().add_child(ragdoll)
	body.queue_free()
	await get_tree().create_timer(despawn_time).timeout
	if is_instance_valid(ragdoll):
		ragdoll.queue_free()
