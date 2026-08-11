extends Node3D

var _phase: int = 0
var _sub: float = 0.0
var _t: float = 0.0
var _player: Node3D
var _sb: Node3D
var _fails: Array = []
var _hp_before: float = 0.0
var _target: Node
var _puzzle_done: bool = false
var _boss_step: int = 0
## Одноразовые флаги вместо окон вида `_sub < 0.05`: в headless кадр может быть
## длиннее окна, и шаг молча пропускался — тест падал на ровном месте.
var _dmg_done: bool = false
var _death_done: bool = false

func _ready() -> void:
	GameManager._change_state(GameManager.GameState.PLAYING)
	var main: Node = load("res://scenes/main_3d.tscn").instantiate()
	add_child(main)
	_log("phase0 scene loaded, waiting for world")

func _process(delta: float) -> void:
	_t += delta
	match _phase:
		0:
			if _t > 3.0:
				_player = get_tree().get_first_node_in_group("player")
				_sb = get_tree().root.find_child("StreetBuilder", true, false)
				_check(_player != null, "player spawned")
				_check(_sb != null, "street builder exists")
				var monsters: Array = get_tree().get_nodes_in_group("destroyers") + get_tree().get_nodes_in_group("shadow") + get_tree().get_nodes_in_group("crawlers")
				_check(monsters.size() > 0, "monsters spawned: %d" % monsters.size())
				var pickups: Array = get_tree().get_nodes_in_group("pickups")
				_check(pickups.size() > 0, "pickups spawned: %d" % pickups.size())
				var constants: Dictionary = load("res://scripts/world/street_builder.gd").get_script_constant_map()
				_check(constants.get("GENERATOR_FUEL", &"") == &"gas_canister", "generator uses registered fuel item")
				_target = monsters[0] if monsters.size() > 0 else null
				_phase = 1; _sub = 0.0; _log("phase1 combat: damage " + (_target.name if _target else "NONE"))
		1:
			_sub += delta
			if not _dmg_done:
				_dmg_done = true
				if _target and is_instance_valid(_target):
					_hp_before = _target.get("hp") if _target.get("hp") != null else -1.0
					if _target.has_method("take_damage"):
						_target.take_damage(10.0)
			elif _sub > 0.5:
				if _target and is_instance_valid(_target):
					var hp_after: float = _target.get("hp") if _target.get("hp") != null else -1.0
					_check(hp_after < _hp_before, "monster hp %s -> %s" % [str(_hp_before), str(hp_after)])
				else:
					_check(false, "monster freed unexpectedly, hp_before=%s" % str(_hp_before))
				_phase = 2; _sub = 0.0; _log("phase2 inventory")
		2:
			var before: int = InventoryManager.count_of(&"battery")
			var ok: bool = InventoryManager.try_add(&"battery", 1)
			_check(ok, "inventory add battery")
			var after: int = InventoryManager.count_of(&"battery")
			_check(after == before + 1, "battery count %d -> %d" % [before, after])
			_phase = 3; _sub = 0.0; _log("phase3 flashlight battery")
		3:
			var b0: float = _player.get_battery()
			_player.consume_battery(10.0)
			var b1: float = _player.get_battery()
			_check(b1 < b0, "battery %s -> %s" % [str(b0), str(b1)])
			_player.add_battery(50.0)
			_check(_player.get_battery() > b1, "battery restored")
			_phase = 4; _sub = 0.0; _log("phase4 generator puzzle")
		4:
			_sub += delta
			if not _puzzle_done:
				_puzzle_done = true
				if not InventoryManager.has(&"gas_canister", 1):
					InventoryManager.try_add(&"gas_canister", 1)
				var ps := get_tree().root.get_node_or_null("PuzzleSystem")
				_check(ps != null, "PuzzleSystem autoload exists")
				if ps:
					var started: bool = ps.start_puzzle("cables_suburb")
					_check(started, "puzzle start")
					ps.mark_solved("cables_suburb")
					_check(ps.is_solved("cables_suburb"), "puzzle solved")
			elif _sub > 1.0:
				var stage: int = PowerGrid.get_stage(&"suburbs")
				_check(stage == 3, "district stage after puzzle: %d" % stage)
				_phase = 5; _sub = 0.0; _log("phase5 save/load")
		5:
			var ok: bool = SaveSystem.save_slot(3)
			_check(ok, "save_slot(3)")
			var has: bool = SaveSystem.has_save()
			_check(has, "has_save")
			var loaded: bool = SaveSystem.load_slot(3)
			_check(loaded, "load_slot(3)")
			SaveSystem.delete_slot(3)
			_phase = 6; _sub = 0.0; _log("phase6 coins/shop")
		6:
			var c0: int = CoinWallet.coins
			CoinWallet.add(100)
			_check(CoinWallet.coins == c0 + 100, "coins %d -> %d" % [c0, CoinWallet.coins])
			var up := ShopService.get_item(&"upgrade_flashlight_battery")
			_check(up != null, "upgrade item exists")
			CoinWallet.add(3000)
			ShopService.buy(&"upgrade_flashlight_battery")
			_check(CoinWallet.coins == c0 + 3100 - 2500, "upgrade bought: coins %d" % CoinWallet.coins)
			_check(UpgradeSystem.is_applied(&"upgrade_flashlight_battery"), "upgrade applied")
			_phase = 7; _sub = 0.0; _log("phase7 boss architect")
		7:
			_boss_step += 1
			var boss: Node = get_tree().get_first_node_in_group("boss")
			match _boss_step:
				1:
					_check(boss != null, "boss spawned")
					if boss:
						var area: Node = boss.get("_detect_area")
						var conns: Array = area.body_entered.get_connections() if area else []
						_check(conns.size() > 0, "boss DetectArea connected: %d" % conns.size())
						_player.hp = 9999.0
						boss.take_damage(300.0)
						_check(boss.hp < 800.0, "boss P1 damage: hp=%s" % str(boss.hp))
				20:
					_check(int(boss.get("phase")) == 0, "boss phase P1 at >66%%: %s" % str(boss.get("phase")))
					boss.take_damage(50.0)
					boss.player_ref = _player
				40:
					_check(int(boss.get("phase")) == 1, "boss phase P2 at <66%%: %s" % str(boss.get("phase")))
					boss.set("_is_in_flashlight", false)
					var hp_before: float = boss.hp
					boss.take_damage(100.0)
					_check(absf(boss.hp - hp_before) < 0.01, "boss P2 light-gated: hp=%s" % str(boss.hp))
					boss.call("_throw_energy_ball")
					_hp_before = float(get_tree().get_nodes_in_group("shadow").size())
					for i in 4:
						boss.call("_summon_minion")
				60:
					var ball_count: int = 0
					for a in get_tree().root.find_children("*", "Area3D", true, false):
						if a.get("_damage") != null:
							ball_count += 1
					_check(ball_count > 0, "boss energy ball spawned: %d" % ball_count)
					var shadows_after: int = get_tree().get_nodes_in_group("shadow").size()
					_check(shadows_after - int(_hp_before) >= 1 and shadows_after - int(_hp_before) <= 3,
						"boss minion cap 3: %d -> %d" % [int(_hp_before), shadows_after])
					boss.hp = 200.0
				80:
					_check(int(boss.get("phase")) == 2, "boss phase P3 at <33%%: %s" % str(boss.get("phase")))
					boss.take_damage(50.0)
					_check(boss.hp < 200.0, "boss P3 vulnerable: hp=%s" % str(boss.hp))
					boss.hp = 800.0
					boss.set("_is_in_flashlight", false)
					boss.player_ref = null
					_player.hp = 100.0
					_phase = 8; _sub = 0.0; _log("phase8 death screen")
		8:
			_sub += delta
			if not _death_done and _player:
				_death_done = true
				if _player.has_method("take_damage"):
					_player.take_damage(9999.0)
			elif _sub > 1.0:
				var screens: Node = get_tree().root.find_child("Screens", true, false)
				var death_open: bool = screens and screens.get("_active_screen") == "Death"
				_check(death_open, "death screen opened: %s" % str(screens.get("_active_screen") if screens else "no screens"))
				_finish()
		9:
			_finish()

func _check(cond: bool, label: String) -> void:
	var status: String = "OK" if cond else "FAIL"
	print("[3dtest] [", status, "] ", label)
	if not cond:
		_fails.append(label)

func _log(msg: String) -> void:
	print("[3dtest] ", msg)

func _finish() -> void:
	if _fails.is_empty():
		print("[3dtest] ALL PASSED")
	else:
		print("[3dtest] FAILED: ", str(_fails))
	get_tree().quit()
