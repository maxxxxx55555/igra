extends Node

var _t: float = 0.0
var _player: Node = null
var _phase: int = 0
var _pickup_count_start: int = -1
var _puzzle_district: StringName = &""
var _puzzle_stage_before: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveSystem.reset_all()
	GameManager._change_state(GameManager.GameState.PLAYING)
	add_child(load("res://scenes/main_3d.tscn").instantiate())
	print("[gtest] main instantiated")

func _process(delta: float) -> void:
	_t += delta
	match _phase:
		0:
			if _t >= 3.0:
				_phase = 1
				_start_pickup()
		1:
			if _t >= 3.5:
				_phase = 2
				print("[gtest] interact target: ", _player.get("_interact_target"))
				InputService.interact_requested.emit()
				print("[gtest] interact pressed")
		2:
			if _t >= 5.0:
				_phase = 3
				_start_combat()
		3:
			if _t >= 7.5:
				_phase = 4
				_start_puzzle()
		4:
			if _t >= 8.0:
				_phase = 5
				InputService.interact_requested.emit()
				print("[gtest] puzzle interact pressed")
		5:
			if _t >= 9.0:
				_phase = 6
				_check_puzzle()
		6:
			if _t >= 10.0:
				_phase = 7
				_test_save()
				print("[gtest] triggering death")
				GameManager.trigger_death()
		7:
			if _t >= 10.5:
				_phase = 8
				print("[gtest] state: ", GameManager.current_state, " cache: ", UIManager._cache.keys())
				var d = UIManager._cache.get(&"death")
				print("[gtest] death screen visible: ", d != null and d.visible)
				GameManager.trigger_win()
		8:
			if _t >= 11.0:
				_phase = 9
				var w = UIManager._cache.get(&"win")
				print("[gtest] win screen visible: ", w != null and w.visible)
		9:
			if _t >= 11.5:
				_phase = 10
				_test_shop()
		10:
			if _t >= 12.5:
				_phase = 11
				_test_meta()
		11:
			if _t >= 13.5:
				_phase = 12
				print("[gtest] DONE")
				get_tree().quit(0)

func _start_pickup() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_pickup_count_start = _count_with_script("item_pickup")
	print("[gtest] pickups at start: ", _pickup_count_start)
	var pk := _first_with_script("item_pickup")
	if _player and pk:
		_player.global_position = pk.global_position
		print("[gtest] pickup: teleported to ", pk.global_position)

func _start_combat() -> void:
	var now: int = _count_with_script("item_pickup")
	if now >= _pickup_count_start:
		print("[gtest] pickup: NONE collected")
	else:
		var filled: int = 0
		for s in InventoryManager.slots:
			if s != null and s["item_id"] != &"":
				filled += 1
		print("[gtest] pickup: collected, slots filled=", filled)
	var enemies := get_tree().get_nodes_in_group("enemies")
	if _player and enemies.size() > 0:
		print("[gtest] hp before: ", _player.hp)
		_player.global_position = enemies[0].global_position + Vector2(20, 0)
	else:
		print("[gtest] combat: no player/enemies")

func _start_puzzle() -> void:
	var gen := _first_generator()
	if _player and gen:
		_puzzle_district = gen.get("district_id")
		_puzzle_stage_before = PowerGrid.get_stage(_puzzle_district)
		_player.global_position = gen.global_position
		print("[gtest] puzzle: teleported to generator in ", _puzzle_district, " stage=", _puzzle_stage_before)
	else:
		print("[gtest] puzzle: no generator found")

func _check_puzzle() -> void:
	if _puzzle_district == &"":
		return
	var now_stage: int = PowerGrid.get_stage(_puzzle_district)
	print("[gtest] puzzle stage: ", _puzzle_stage_before, " -> ", now_stage)
	var unlocked: bool = PowerGrid.is_unlocked(_puzzle_district)
	print("[gtest] district unlocked: ", unlocked)

func _test_save() -> void:
	print("[gtest] save_slot(0): ", SaveSystem.save_slot(0))
	print("[gtest] has_save: ", SaveSystem.has_save())
	print("[gtest] load_slot(0): ", SaveSystem.load_slot(0))
	SaveSystem.delete_slot(0)

func _test_screens() -> void:
	for id in UIManager.SCREENS.keys():
		UIManager.open(id)
		await get_tree().process_frame
		UIManager.close(id)
	print("[gtest] screens opened: ", UIManager.SCREENS.size())

func _test_shop() -> void:
	# Паков монет за донат больше нет — проверяем только покупку за игровые монеты.
	var up_before: int = CoinWallet.get_coins()
	ShopService.buy(&"upgrade_flashlight_brightness")
	print("[gtest] upgrade owned: ", ShopService.is_owned(&"upgrade_flashlight_brightness"), " coins ", up_before, " -> ", CoinWallet.get_coins())

func _test_meta() -> void:
	var saved_coins: int = CoinWallet.get_coins()
	SaveSystem.save_slot(1)
	CoinWallet.add(555)
	SaveSystem.load_slot(1)
	print("[gtest] coins restored: ", CoinWallet.get_coins(), " (saved ", saved_coins, ")")
	SaveSystem.delete_slot(1)
	CoinWallet.add(5000)
	ShopService.buy(&"upgrade_flashlight_brightness")
	print("[gtest] upgrade owned after money: ", ShopService.is_owned(&"upgrade_flashlight_brightness"))
	ShopService.buy(&"skin_survivor_ashen")
	print("[gtest] skin owned: ", ShopService.is_owned(&"skin_survivor_ashen"))
	print("[gtest] ng+ activate: ", NewGamePlus.activate_ng_plus(), " level=", NewGamePlus.get_current_ng_plus())
	NewGamePlus.reset_for_new_game()
	print("[gtest] ng+ reset ok: ", NewGamePlus.get_current_ng_plus() == 0)
	var cp_before: bool = SaveSystem.has_save()
	SaveSystem.set_checkpoint("res://scenes/main_3d.tscn", Vector3(123, 0, 456))
	print("[gtest] checkpoint autosave: ", SaveSystem.has_save())
	if not cp_before:
		DirAccess.remove_absolute("user://tls_savegame.save")

func _first_generator() -> Node:
	for n in _spawns():
		if n.get_script() and n.get_script().resource_path.get_file() == "puzzle_base.gd" and n.get("required_item") == &"":
			return n
	return null

func _count_with_script(fname: String) -> int:
	var n: int = 0
	for c in _spawns():
		if c.get_script() and c.get_script().resource_path.get_file() == fname + ".gd":
			n += 1
	return n

func _first_with_script(fname: String) -> Node:
	for n in _spawns():
		if n.get_script() and n.get_script().resource_path.get_file() == fname + ".gd":
			return n
	return null

func _spawns() -> Array:
	var world := get_tree().root.find_child("World", true, false)
	if not world:
		return []
	var spawns := world.find_child("Spawns", true, false)
	return spawns.get_children() if spawns else []
