extends Node3D
## HitSpark — спавнится в точке попадания пули/удара.
## Использование: var hs = HitSpark.new(); add_child(hs); hs.spawn(hit_pos, hit_normal)

const SPARK_COUNT := 6
const SPARK_SPEED := 4.0
const SPARK_LIFE  := 0.25

@export var spark_color: Color = Color(1.0, 0.7, 0.2, 1.0)

func spawn(pos: Vector3, normal: Vector3) -> void:
	global_position = pos
	for i in range(SPARK_COUNT):
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.025
		sm.height = 0.05
		mi.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = spark_color
		mat.emission_enabled = true
		mat.emission = spark_color
		mat.emission_energy_multiplier = 2.0
		mi.material_override = mat
		add_child(mi)
		var dir: Vector3 = (normal + Vector3(randf_range(-1, 1), randf_range(0, 1), randf_range(-1, 1))).normalized()
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(mi, "position", dir * SPARK_SPEED * SPARK_LIFE, SPARK_LIFE).set_ease(Tween.EASE_OUT)
		tw.tween_property(mi, "modulate:a", 0.0, SPARK_LIFE).set_ease(Tween.EASE_IN)
	var tw_self := create_tween()
	tw_self.tween_interval(SPARK_LIFE + 0.05)
	tw_self.tween_callback(queue_free)
