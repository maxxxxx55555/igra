extends Node

func spawn(effect_name: String, pos: Vector3, normal: Vector3 = Vector3.UP) -> void:
	var scene_path := "res://scenes/effects/" + effect_name + ".tscn"
	if not ResourceLoader.exists(scene_path):
		return
	var effect: Node3D = load(scene_path).instantiate()
	effect.position = pos
	if normal != Vector3.UP:
		effect.look_at(pos + normal)
	if get_tree().current_scene:
		get_tree().current_scene.add_child(effect)
	if effect is GPUParticles3D:
		effect.emitting = true
	var timer := 1.0
	await get_tree().create_timer(timer).timeout
	if is_instance_valid(effect):
		effect.queue_free()
