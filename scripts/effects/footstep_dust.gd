extends Node3D
## FootstepDust — пыль при шаге. Вызывается из player_fps.gd по _step_timer.
## Использование: footstep_dust.puff(pos)

const PUFF_COUNT := 4

@export var dust_color: Color = Color(0.7, 0.65, 0.55, 0.6)

func puff(pos: Vector3) -> void:
	global_position = pos
	for i in range(PUFF_COUNT):
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.06
		sm.height = 0.12
		mi.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = dust_color
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = mat
		add_child(mi)
		var dir := Vector3(randf_range(-1, 1), randf_range(0.2, 0.8), randf_range(-1, 1)).normalized()
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(mi, "position", dir * 0.4, 0.3).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
		tw.tween_property(mi, "scale", Vector3(2.5, 2.5, 2.5), 0.3).set_ease(Tween.EASE_OUT)
	var tw_self := create_tween()
	tw_self.tween_interval(0.35)
	tw_self.tween_callback(queue_free)
