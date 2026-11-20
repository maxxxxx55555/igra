extends Node
## Exercise the production claim, save and reward owners with a controlled clock and link.
const Bonus = preload("res://scripts/monetization/wifi_bonus_service.gd")
const Guard = preload("res://scripts/core/qa_launch_guard.gd")
const START_UTC := 2208988800 # Midnight UTC, 2040-01-01.

class TestService extends Bonus:
	var wall: int = START_UTC
	var ticks: int = 0
	var network := &"BONUS_READY"
	var readings: Array[StringName] = []

	func _wall_seconds() -> int:
		return wall

	func _ticks_msec() -> int:
		return ticks

	func _connection_state() -> StringName:
		return readings.pop_front() if not readings.is_empty() else network

class AndroidBridge extends RefCounted:
	var wifi: bool = false
	var exception: bool = false
	var active: bool = true

	func has_java_method(method: StringName) -> bool:
		return has_method(method)

	func get_exception() -> Object:
		return self if exception else null

	func getActivity() -> Object:
		return self

	func getSystemService(name_: String) -> Object:
		return self if name_ == "connectivity" else null

	func getActiveNetwork() -> Object:
		return self if active else null

	func getNetworkCapabilities(network: Object) -> Object:
		return self if network == self else null

	func hasTransport(id: int) -> bool:
		return id == 1 and wifi

class TestPlayer extends Node3D:
	var hp := 100.0
	var stamina := 100.0
	var battery := 70.0
	var battery_max := 100.0
	var warmth := 100.0
	var gameplay_active := true

	func heal(amount: float) -> void:
		hp = minf(hp + amount, 100.0)

	func add_battery(amount: float) -> void:
		battery = minf(battery + amount, battery_max)

var failures := 0
var checks := 0
var granted: Array[StringName] = []
var rejected: Array[StringName] = []
var states: Dictionary = {}
var service: TestService

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	checks += 1
	print("[wifi-bonus] ", "PASS " if ok else "FAIL ", description)
	if not ok:
		failures += 1

func _platforms() -> void:
	var bridge := AndroidBridge.new()
	_check(Bonus.android_state(bridge, bridge) == &"BONUS_NEEDS_WIFI", "cellular-only guest is ineligible")
	bridge.wifi = true
	# The fixture deliberately offers no internet-validation method.
	_check(Bonus.android_state(bridge, bridge) == Bonus.READY, "local Wi-Fi grants without validated internet")
	bridge.active = false
	_check(Bonus.android_state(bridge, bridge) == &"BONUS_NEEDS_WIFI", "no default network is ineligible")
	bridge.exception = true
	_check(Bonus.android_state(bridge, bridge) == Bonus.UNKNOWN, "Android platform error fails closed")
	var excluded := [{"name": "Ethernet", "addresses": ["127.0.0.1", "::1", "169.254.1.2", "fe80::9%3"]},
		{"friendly": "vEthernet (WSL)", "addresses": ["172.29.1.1"]}]
	_check(Bonus.desktop_state(excluded) == &"BONUS_NEEDS_NETWORK", "loopback, link-local and virtual links are ineligible")
	excluded.append({"friendly": "Ethernet", "addresses": ["2001:db8::1"]})
	_check(Bonus.desktop_state(excluded) == Bonus.READY, "physical IPv6 network is eligible")

func _attach(wall: int = START_UTC) -> void:
	service = TestService.new()
	service.wall = wall
	service.claimed.connect(func(id: StringName) -> void: granted.append(id))
	service.claim_failed.connect(func(_id: StringName, reason: StringName) -> void: rejected.append(reason))
	service.availability_changed.connect(func(id: StringName, state: StringName, _seconds: int) -> void: states[id] = state)
	add_child(service)

func _run() -> void:
	_platforms()
	var base := OS.get_user_data_dir()
	var snapshot := base + ".bonus_test_" + str(OS.get_process_id())
	if not Guard.snapshot(base, snapshot, OS.get_process_id()):
		_check(false, "could not protect profile")
		get_tree().quit(1)
		return
	# Seed an actual encrypted legacy record (the shipped pre-ledger schema).
	SecurityVault._cached_save = SecurityVault.default_save()
	SecurityVault.save_rejected = false
	_check(SecurityVault.save_game() == OK and not SecurityVault.load_game().has("bonus_ledger"), "encrypted legacy vault loads")
	_attach()
	GameManager.start_new_game()
	SettingsManager.set_difficulty(1)
	GameManager.run_hardcore = false
	var player := TestPlayer.new()
	add_child(player)
	player.add_to_group("player")
	var run := SaveSystem.get_run_id()
	var initial := CoinWallet.get_coins()
	var ledger := SecurityVault.bonus_ledger()
	_check(ledger.get("run_id", "") == run, "explicit New Game records a run")
	var block := ProjectSettings.globalize_path(SaveSystem.BONUS_STAGE + ".tmp")
	if DirAccess.make_dir_absolute(block) == OK:
		service.request_claim(&"bonus_coins")
		_check(rejected.back() == Bonus.SAVE_FAILED and CoinWallet.get_coins() == initial and SecurityVault.bonus_ledger() == ledger, "failed checkpoint leaves wallet and allowance untouched")
		DirAccess.remove_absolute(block)
	else:
		_check(false, "could not install failed-write fixture")
	service.readings.assign([Bonus.READY, &"BONUS_NEEDS_NETWORK"])
	service.request_claim(&"bonus_coins")
	_check(rejected.back() == &"BONUS_NEEDS_NETWORK" and CoinWallet.get_coins() == initial and SecurityVault.bonus_ledger() == ledger, "disconnect before commit leaves claim retryable")
	service.claimed.connect(func(id: StringName) -> void: service.request_claim(id), CONNECT_ONE_SHOT)
	service.request_claim(&"bonus_coins")
	_check(granted.size() == 1 and rejected.back() == &"BONUS_CHECKING" and CoinWallet.get_coins() == initial + 100, "retry and reentrant double-tap pay exactly 100")
	service.wall -= 86400
	service.ticks += 3500 * 1000
	service.checkpoint_clock()
	service.free()
	_attach(START_UTC - 86400)
	service.request_claim(&"extra_battery")
	_check(rejected.back() == &"BONUS_COOLDOWN" and player.battery == 70.0, "shared cooldown survives restart and wall-clock rollback")
	service.ticks += 100 * 1000
	service.request_claim(&"extra_battery")
	_check(granted.back() == &"extra_battery" and player.battery == 100.0, "battery reward caps at capacity")
	player.battery = 60.0
	service.request_claim(&"extra_battery")
	_check(rejected.back() == &"BONUS_RUN_LIMIT", "second battery refused in same run")
	service.ticks += 3600 * 1000
	service.network = &"BONUS_NEEDS_NETWORK"
	GameManager.current_state = GameManager.GameState.DEAD
	player.hp = 0.0
	get_tree().paused = true
	service.open_offer(&"revive")
	_check(states.get(&"revive") == &"BONUS_NEEDS_NETWORK", "paused death offer opens with offline reason")
	service.network = Bonus.READY
	await get_tree().create_timer(2.3, true).timeout
	_check(states.get(&"revive") == Bonus.READY, "visible offer automatically detects reconnection while paused")
	GameManager.run_hardcore = true
	service.request_claim(&"revive")
	_check(rejected.back() == &"BONUS_DIFFICULTY", "hardcore prevents revive")
	var death: Control = preload("res://scenes/ui/death_screen.tscn").instantiate()
	add_child(death)
	_check(not death.get("_b").disabled and not death.get("_b2").disabled and death.get("_b").is_visible_in_tree(), "death screen keeps Retry and Menu actionable")
	await get_tree().process_frame
	await get_tree().process_frame
	death.queue_free()
	await get_tree().process_frame
	GameManager.run_hardcore = false
	service.request_claim(&"revive")
	_check(granted.back() == &"revive" and player.hp == 50.0 and GameManager.is_playing() and not get_tree().paused, "independent revive allowance restores paused player")
	GameManager.current_state = GameManager.GameState.DEAD
	player.hp = 0.0
	service.close_offer(&"revive")
	service.open_offer(&"revive")
	_check(states.get(&"revive") == &"BONUS_RUN_LIMIT", "reopening death screen preserves revive use")
	service.close_offer(&"revive")
	_check(SaveSystem.load_all() and SaveSystem.get_run_id() == run and SecurityVault.bonus_ledger().revive_used, "Continue preserves the run and its use flags")
	GameManager.start_new_game()
	ledger = SecurityVault.bonus_ledger()
	_check(ledger.run_id != run and not ledger.revive_used and not ledger.battery_used and ledger.daily_count == 3, "new run resets independent uses and preserves profile daily count")
	service.ticks += 3600 * 1000
	service.request_claim(&"bonus_coins")
	_check(rejected.back() == &"BONUS_DAY_LIMIT", "fourth profile claim rejected")
	service.ticks += 86400 * 1000
	service.request_claim(&"bonus_coins")
	_check(granted.size() == 4 and SecurityVault.bonus_ledger().daily_count == 1, "next UTC day starts a new allowance")
	ledger = SecurityVault.bonus_ledger()
	var vault := FileAccess.open(SecurityVault.SAVE, FileAccess.READ_WRITE)
	if vault != null:
		vault.seek_end(-1)
		var byte := vault.get_8()
		vault.seek_end(-1)
		vault.store_8(byte ^ 1)
		vault.close()
		service.request_claim(&"bonus_coins")
		_check(rejected.back() == Bonus.SAVE_FAILED and SecurityVault.save_rejected and SecurityVault.bonus_ledger() == ledger, "failed authentication preserves allowance and disables claims")
	else:
		_check(false, "could not open encrypted test record")
	service.free()
	player.free()
	get_tree().paused = false
	_check(Guard.restore(base, snapshot) == 0, "restored profile")
	print("[wifi-bonus] DONE checks=", checks, " fails=", failures)
	get_tree().quit(1 if failures else 0)
