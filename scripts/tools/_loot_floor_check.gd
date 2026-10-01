extends Node3D
## Every pickup, document and secret a district places needs floor under it: one that
## hovers over the gap between two streets can only be reached by stepping into the
## void (a repair part there stalled the bot, X21). Loads each district, casts a ray
## down from each one, and fails on any with no floor.
##   godot --headless --path . res://scenes/tools/loot_floor_check_scene.tscn

const DISTRICTS: Array[StringName] = [
	&"suburbs", &"residential", &"park", &"school", &"hospital", &"gas_station",
	&"police", &"warehouses", &"industrial", &"substation", &"power_station",
]

var _fails := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager._change_state(GameManager.GameState.PLAYING)
	add_child(load("res://scenes/main_3d.tscn").instantiate())
	call_deferred("_run")

func _run() -> void:
	await get_tree().create_timer(3.0).timeout
	for id in DISTRICTS:
		EventBus.district_entered.emit(id)
		await get_tree().create_timer(2.0).timeout
		await get_tree().physics_frame
		await get_tree().physics_frame
		var total := 0
		var floating: Array[String] = []
		var spots: Array = get_tree().get_nodes_in_group("pickup")
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.get("secret_id") != null:
				spots.append(n)
		spots.append_array(get_tree().get_nodes_in_group("hiding_spot"))
		for p in spots:
			var node := p as Node3D
			if node == null or not node.is_visible_in_tree():
				continue
			total += 1
			if not _has_floor(node.global_position):
				floating.append("%s@%s" % [str(node.get("item_id")) if node.get("item_id") != null else str(node.name), str(node.global_position.round())])
		print("[lootfloor] %s spots=%d floating=%d %s" % [id, total, floating.size(), str(floating)])
		if not floating.is_empty():
			_fails += 1
	print("[lootfloor] DONE fails=%d" % _fails)
	get_tree().quit(1 if _fails > 0 else 0)

func _has_floor(pos: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(pos + Vector3(0.0, 0.3, 0.0), pos + Vector3(0.0, -4.0, 0.0))
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
