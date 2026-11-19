extends Node
## Local connection offers. A claim becomes visible only after its checkpoint
## and its authenticated profile allowance have both been written.

signal availability_changed(reward_id: StringName, state: StringName, seconds_left: int)
signal claimed(reward_id: StringName)
signal claim_failed(reward_id: StringName, reason: StringName)

const COOLDOWN_SEC: int = 3600
const DAILY_LIMIT: int = 3
const READY := &"BONUS_READY"
const UNKNOWN := &"BONUS_UNKNOWN"
const SAVE_FAILED := &"BONUS_SAVE_FAILED"
const REWARDS := [&"revive", &"extra_battery", &"bonus_coins"]
const VIRTUAL_ADAPTERS := ["loopback", "pseudo", "vethernet", "docker", "wsl", "vmware",
	"virtualbox", "hyper-v", "tailscale", "zerotier", "tap", "tun"]

var _offers: Dictionary[StringName, int] = {}
var _shown: Dictionary = {}
var _poll_time: float = 0.0
var _claiming: bool = false
var _pending_run: String = ""
var _clock_utc: int
var _clock_ticks: int
var _window: Object
var _web_callback: Object

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var ledger := SecurityVault.bonus_ledger()
	_clock_utc = maxi(_wall_seconds(), int(ledger.get("max_seen_utc", 0)))
	_clock_ticks = _ticks_msec()
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		_window = JavaScriptBridge.get_interface("window")
		if _window != null:
			_web_callback = JavaScriptBridge.create_callback(_web_connection_changed)
			_window.addEventListener("online", _web_callback)
			_window.addEventListener("offline", _web_callback)
	set_process(false)

func _exit_tree() -> void:
	if _window != null and _web_callback != null:
		_window.removeEventListener("online", _web_callback)
		_window.removeEventListener("offline", _web_callback)
	_web_callback = null
	_window = null

func _notification(what: int) -> void:
	if not is_node_ready():
		return
	if what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		_refresh()
	elif what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST]:
		checkpoint_clock()

func _wall_seconds() -> int:
	return int(Time.get_unix_time_from_system())

func _ticks_msec() -> int:
	return Time.get_ticks_msec()

func _now() -> int:
	return _clock_utc + maxi(0, _ticks_msec() - _clock_ticks) / 1000

## Normal saves persist the highest observed time along with their guarded values.
func checkpoint_clock() -> void:
	var ledger := SecurityVault.bonus_ledger()
	if not ledger.is_empty() and int(ledger.max_seen_utc) < _now() and SecurityVault.bonus_integrity_ok():
		ledger.max_seen_utc = _now()
		SecurityVault.save_game({"bonus_ledger": ledger})

func begin_run(run_id: String) -> void:
	_pending_run = run_id
	_store_new_run()

func _store_new_run() -> bool:
	if _pending_run.is_empty():
		return true
	if not SecurityVault.bonus_integrity_ok():
		return false
	var ledger := _ledger()
	ledger.run_id = _pending_run
	ledger.revive_used = false
	ledger.battery_used = false
	ledger.max_seen_utc = maxi(int(ledger.max_seen_utc), _now())
	if SecurityVault.save_game({"bonus_ledger": ledger}) != OK:
		return false
	_pending_run = ""
	return true

func _ledger() -> Dictionary:
	var ledger := SecurityVault.bonus_ledger()
	if not ledger.is_empty():
		return ledger
	return {"version": 1, "run_id": SaveSystem.get_run_id(), "revive_used": false,
		"battery_used": false, "last_claim_utc": 0, "max_seen_utc": 0,
		"utc_day": 0, "daily_count": 0, "last_claim_id": ""}

func open_offer(reward_id: StringName) -> void:
	_offers[reward_id] = _offers.get(reward_id, 0) + 1
	set_process(true)
	_shown.erase(reward_id)
	_refresh()

func close_offer(reward_id: StringName) -> void:
	if _offers.get(reward_id, 0) > 1:
		_offers[reward_id] -= 1
	else:
		_offers.erase(reward_id)
		_shown.erase(reward_id)
	set_process(not _offers.is_empty())

func _process(delta: float) -> void:
	_poll_time += delta
	if _poll_time >= 2.0:
		_refresh()

func _web_connection_changed(_args: Array) -> void:
	_refresh()

func _refresh() -> void:
	_poll_time = 0.0
	if _offers.is_empty() or _claiming:
		return
	var network := _connection_state()
	var run_saved := _store_new_run()
	var ledger := _ledger()
	for id: StringName in _offers.keys():
		var state := _state(id, network, ledger) if run_saved else SAVE_FAILED
		var seconds := _cooldown_left(ledger) if state == &"BONUS_COOLDOWN" else 0
		var info := [state, seconds]
		if _shown.get(id) != info:
			_shown[id] = info
			availability_changed.emit(id, state, seconds)

func _cooldown_left(ledger: Dictionary) -> int:
	if int(ledger.last_claim_utc) == 0:
		return 0
	return maxi(0, int(ledger.last_claim_utc) + COOLDOWN_SEC - _now())

func _state(id: StringName, network: StringName, ledger: Dictionary) -> StringName:
	if id not in REWARDS:
		return &"BONUS_INAPPLICABLE"
	if id == &"revive" and (GameManager.run_hardcore or SettingsManager.difficulty_scale("revive") <= 0.0):
		return &"BONUS_DIFFICULTY"
	if GameManager.bonus_target(id).is_empty():
		return &"BONUS_INAPPLICABLE"
	if not SecurityVault.integrity_ok or SecurityVault.save_rejected:
		return SAVE_FAILED
	# An older manual slot may refer to a run the compact profile ledger has retired.
	if id in [&"revive", &"extra_battery"] and ledger.run_id != SaveSystem.get_run_id():
		return &"BONUS_RUN_LIMIT"
	if (id == &"revive" and ledger.revive_used) or (id == &"extra_battery" and ledger.battery_used):
		return &"BONUS_RUN_LIMIT"
	if int(ledger.utc_day) == _now() / 86400 and int(ledger.daily_count) >= DAILY_LIMIT:
		return &"BONUS_DAY_LIMIT"
	if _cooldown_left(ledger) > 0:
		return &"BONUS_COOLDOWN"
	return network

func request_claim(reward_id: StringName) -> void:
	if _claiming:
		claim_failed.emit(reward_id, &"BONUS_CHECKING")
		return
	_claiming = true
	var result := _claim(reward_id)
	if result == READY:
		claimed.emit(reward_id)
	else:
		claim_failed.emit(reward_id, result)
	_claiming = false
	_refresh()

func _claim(id: StringName) -> StringName:
	if id not in REWARDS:
		return &"BONUS_INAPPLICABLE"
	if not _store_new_run() or not SecurityVault.bonus_integrity_ok():
		return SAVE_FAILED
	var ledger := _ledger()
	var state := _state(id, _connection_state(), ledger)
	if state != READY:
		return state
	var now := _now()
	var day := now / 86400
	ledger.daily_count = int(ledger.daily_count) + 1 if int(ledger.utc_day) == day else 1
	ledger.utc_day = day
	ledger.last_claim_utc = now
	ledger.max_seen_utc = now
	ledger.last_claim_id = Crypto.new().generate_random_bytes(16).hex_encode()
	if id == &"revive":
		ledger.revive_used = true
	elif id == &"extra_battery":
		ledger.battery_used = true
	var target := GameManager.bonus_target(id)
	state = SaveSystem.commit_bonus(ledger, target, _connection_state)
	if state == READY:
		GameManager.apply_saved_bonus(id, target)
	return state

func _connection_state() -> StringName:
	if OS.has_feature("android"):
		if not Engine.has_singleton("AndroidRuntime") or not Engine.has_singleton("JavaClassWrapper"):
			return UNKNOWN
		return android_state(Engine.get_singleton("AndroidRuntime"), Engine.get_singleton("JavaClassWrapper"))
	if OS.has_feature("web"):
		if not Engine.has_singleton("JavaScriptBridge"):
			return UNKNOWN
		var navigator := JavaScriptBridge.get_interface("navigator")
		if navigator == null or not (navigator.onLine is bool):
			return UNKNOWN
		return READY if navigator.onLine else &"BONUS_NEEDS_NETWORK"
	return desktop_state(IP.get_local_interfaces())

static func _has_java(object: Object, method: StringName) -> bool:
	return object != null and object.has_method("has_java_method") and object.has_java_method(method)

static func android_state(runtime: Object, java: Object) -> StringName:
	if java == null or not java.has_method("get_exception") or not _has_java(runtime, &"getActivity"):
		return UNKNOWN
	var activity: Object = runtime.getActivity()
	if java.get_exception() != null or not _has_java(activity, &"getSystemService"):
		return UNKNOWN
	var manager: Object = activity.getSystemService("connectivity")
	if java.get_exception() != null or not _has_java(manager, &"getActiveNetwork"):
		return UNKNOWN
	var network: Object = manager.getActiveNetwork()
	if java.get_exception() != null or not _has_java(manager, &"getNetworkCapabilities"):
		return UNKNOWN
	if network == null:
		return &"BONUS_NEEDS_WIFI"
	var capabilities: Object = manager.getNetworkCapabilities(network)
	if java.get_exception() != null or not _has_java(capabilities, &"hasTransport"):
		return UNKNOWN
	var wifi: Variant = capabilities.hasTransport(1)
	if java.get_exception() != null or not (wifi is bool):
		return UNKNOWN
	return READY if wifi else &"BONUS_NEEDS_WIFI"

static func desktop_state(interfaces: Array) -> StringName:
	for adapter: Dictionary in interfaces:
		var names := ("%s %s" % [adapter.get("name", ""), adapter.get("friendly", "")]).to_lower()
		var virtual_adapter := false
		for marker: String in VIRTUAL_ADAPTERS:
			if names.contains(marker):
				virtual_adapter = true
				break
		if virtual_adapter:
			continue
		for address: String in adapter.get("addresses", []):
			if _usable_address(address):
				return READY
	return &"BONUS_NEEDS_NETWORK"

static func _usable_address(address: String) -> bool:
	var ip := address.get_slice("%", 0).to_lower()
	if not ip.is_valid_ip_address():
		return false
	if ip.begins_with("::ffff:") and ip.contains("."):
		ip = ip.trim_prefix("::ffff:")
	if not ip.contains(":"):
		return not (ip.begins_with("127.") or ip.begins_with("169.254.") or ip == "0.0.0.0")
	var prefix := ip.get_slice(":", 0).hex_to_int()
	if (prefix & 0xffc0) == 0xfe80:
		return false
	# Both compressed and expanded unspecified/loopback IPv6 spellings.
	var words := ip.split(":", false)
	for i in range(words.size() - 1):
		if words[i].hex_to_int() != 0:
			return true
	return not words.is_empty() and words[-1].hex_to_int() > 1
