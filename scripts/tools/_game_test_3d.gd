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

## Overall ceiling: a phase that stalls (seen intermittently in the phase1
## combat step under --headless — monster AI physics timing) must not hang
## CI forever. Same safety net as _boot_check_runner.gd. The reliable
## coverage now lives in tools/qa_sim/headless_suite (P2 districts+loot,
## P6 soak) + tools/flow_check.py; this scene stays as the fuller manual
## smoke. See docs/KNOWN_ISSUES.md.
const HARD_TIMEOUT_SEC: float = 150.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager._change_state(GameManager.GameState.PLAYING)
	var main: Node = load("res://scenes/main_3d.tscn").instantiate()
	add_child(main)
	get_tree().create_timer(HARD_TIMEOUT_SEC).timeout.connect(_on_hard_timeout)
	_log("phase0 scene loaded, waiting for world")

func _on_hard_timeout() -> void:
	if _phase >= 9:
		return
	_check(false, "hard timeout at phase %d — stalled, not completed" % _phase)
	_finish()

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
				# CHALLENGE-01 root cause (docs/REDTEAM_CHALLENGE.md): this phase
				# used to solve puzzle_system.gd's "cables_suburb" entry, but that
				# entry was trimmed from _puzzle_data as unreachable dead data
				# (see puzzle_system.gd's own STATIC_AUDIT #31 comment) - district
				# stage progression is live exclusively through power_switch.gd's
				# item-cost repair loop now. start_puzzle()/mark_solved() on a
				# stale ID still returned true (the dict just records an ID with
				# no reward wiring), so this test kept "passing" step 4 while
				# silently never advancing the district PowerGrid was tracking -
				# and phase7's boss (gated on district progress) then never
				# spawned, which is what actually surfaced as "null boss" crashes
				# at every later boss_step. Exercise the real mechanism instead.
				InventoryManager.try_add(&"cable", 1)
				var sw: Node = get_tree().root.find_child("PowerSwitch", true, false)
				_check(sw != null, "PowerSwitch exists")
				if sw and sw.has_method("interact"):
					sw.interact(_player)
			elif _sub > 1.0:
				var stage: int = PowerGrid.get_stage(&"suburbs")
				_check(stage == DistrictData.Stage.PARTIAL, "district stage after repair: %d" % stage)
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
			# CHALLENGE-01 root cause, part 2 (docs/REDTEAM_CHALLENGE.md): the
			# real boss only spawns via finale_director.gd once ALL 11
			# districts reach FULL and the player enters power_station - this
			# isolated phase-test was never going to satisfy that through a
			# few synthetic item/puzzle calls (phase 4's stale puzzle wiring
			# only ever made it LOOK reachable by "passing" without actually
			# advancing anything, per the phase4 fix above). This scene tests
			# the boss's OWN mechanics in isolation (damage/phase/summon/
			# energy-ball), same as phases 1-6 test their systems directly
			# rather than replaying the whole campaign - so spawn it directly,
			# the same way finale_director.gd's own _spawn_boss() does.
			if boss == null and _boss_step == 1:
				var boss_scene: PackedScene = load("res://scenes/enemies/boss_architect_3d.tscn")
				var spawned: Node3D = boss_scene.instantiate() as Node3D
				get_tree().current_scene.add_child(spawned)
				spawned.global_position = _player.global_position + _player.global_transform.basis * Vector3(0, 0, -6.0)
				boss = spawned
			# Defensive guard (the concrete crash docs/REDTEAM_CHALLENGE.md
			# flagged, "null boss get() errors"): steps 20/40/60/80 all call
			# boss.get(...)/boss.take_damage(...) unconditionally. If the
			# boss were ever freed mid-fight (e.g. a future change makes the
			# synthetic damage above lethal), this turned into a hard crash
			# instead of a normal _check() failure - fail once, cleanly, and
			# stop the phase instead of throwing.
			if boss == null and _boss_step > 1:
				_check(false, "boss missing at step %d (freed mid-test?)" % _boss_step)
				return _finish()
			match _boss_step:
				1:
					_check(boss != null, "boss spawned")
					if boss:
						var area: Node = boss.get("_detect_area")
						var conns: Array = area.body_entered.get_connections() if area else []
						_check(conns.size() > 0, "boss DetectArea connected: %d" % conns.size())
						_player.hp = 9999.0
						# CHALLENGE-01, part 3: the raw amount passed to take_damage()
						# is NOT what lands on hp - boss_3d.gd's own take_damage()
						# applies armor (25% per enemy_roster_data.gd &"beast") AND a
						# BULLET resistance of 0.5 (same table), for a combined 0.375
						# effective multiplier. This step's original 300 only ever
						# removed 112.5 real hp (800->687.5, 85.9%) - nowhere near
						# enough for step 40 below to ever see the P1->P2 threshold
						# (66%) cross, which is exactly the second failure this
						# uncovered once the crash above stopped masking it. 600 raw
						# (=225 real, 800->575, 71.9%) keeps this step's own "still
						# P1" intent intact while leaving room for step 20's dose to
						# cross the line.
						boss.take_damage(600.0)
						_check(boss.hp < 800.0, "boss P1 damage: hp=%s" % str(boss.hp))
				20:
					_check(int(boss.get("phase")) == 0, "boss phase P1 at >66%%: %s" % str(boss.get("phase")))
					# 200 raw (=75 real) brings cumulative real damage to 300/800
					# (62.5% remaining) - inside the P2 band (33-66%) for step 40's
					# check below. See step 1's comment for the armor+resistance math.
					boss.take_damage(200.0)
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
					# CHALLENGE-01, part 4: same class of bug as the boss damage
					# calibration above, found the same way (by finally reaching
					# this phase instead of crashing before it). player_3d.gd's
					# take_damage() hard-caps every hit at 12.0 (a boss-fight
					# winnability mechanic, its own comment: "no dodge -> death
					# spiral") and gates repeats behind a grace timer - so the
					# single take_damage(9999.0) call below only ever removed 12
					# real hp, never enough to kill a 100-hp player. Start just
					# under the cap so the one real (uncapped-relevant) hit lands
					# exactly on the actual clampf(hp-amount,0,max) path real
					# combat uses, not a bypass.
					_player.hp = 10.0
					_phase = 8; _sub = 0.0; _log("phase8 death screen")
		8:
			_sub += delta
			if not _death_done and _player:
				_death_done = true
				if _player.has_method("take_damage"):
					# CHALLENGE-01, part 5: even with hp set just under the 12.0
					# cap, the boss fight above can leave _damage_grace_timer
					# (0.8s post-hit invincibility, player_3d.gd:773-775) still
					# counting down from an autonomous boss/minion hit landed
					# during phase 7's real-time simulation - which silently
					# no-ops this call entirely (line 773: "if
					# _damage_grace_timer > 0.0: return", before hp is ever
					# touched). Clear both grace mechanisms right before the
					# kill blow so this phase tests death-screen wiring, not
					# whether a stray boss attack happened to land recently.
					_player.set("_damage_grace_timer", 0.0)
					_player.set("_iframes", 0.0)
					_player.take_damage(9999.0)
			elif _sub > 1.0:
				var screens: Node = get_tree().root.find_child("Screens", true, false)
				var death_open: bool = screens and screens.get("_active_screen") == "Death"
				# NEW FINDING (separate from CHALLENGE-01's phase-7 target, which
				# is fully fixed above): confirmed via a diagnostic print (since
				# removed) that hp reaches exactly 0.0 and GameManager.current_state
				# correctly becomes DEAD(4) - the game-state machine and
				# _on_game_state_changed's DEAD mapping both work. _active_screen
				# stays empty anyway, meaning screen_flow_manager.gd's cached
				# _screens reference or its state sync doesn't come up correctly
				# when boot is bypassed (this scene skips splash/menu straight to
				# main_3d.tscn, same shortcut every phase here relies on). Recorded
				# as its own open item rather than chased further under
				# CHALLENGE-01's name - see docs/FUNCTION_MATRIX.md / KNOWN_ISSUES.md.
				_check(death_open, "death screen opened: %s (state=%s)" % [
					str(screens.get("_active_screen") if screens else "no screens"), str(GameManager.current_state)])
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

var _finished: bool = false

func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _fails.is_empty():
		print("[3dtest] ALL PASSED")
	else:
		print("[3dtest] FAILED: ", str(_fails))
	get_tree().quit(mini(_fails.size(), 250))
