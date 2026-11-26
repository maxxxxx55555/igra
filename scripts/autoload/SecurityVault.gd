extends Node
## Register as the first Autoload singleton named `SecurityVault`.
## Provides authenticated AES checkpoints (including legacy CBC reads), dynamic XOR runtime memory
## guards, and SHA-256 asset integrity verification for Windows and Android.

signal tamper_detected(key: StringName)

const SAVE := "user://last_streetlight.vault"
const KEY_DIR := "user://last_streetlight.keys"
const KEY_FILE := KEY_DIR + "/master"
const MANIFEST := "res://data/integrity_manifest.json"
const APP_PEPPER := "TLS_2026_NA_SODIUM_ARC_9F3A7C1E"
const LIMIT := 4 * 1024 * 1024
const HEADER := 36 # LSV1, 16-byte salt, 16-byte IV
const TAG := 32
const CORE_INT_KEYS := [&"coins", &"skill_points"]
const CORE_FLOAT_KEYS := [&"battery", &"warmth", &"health"]

var integrity_ok: bool = false
var last_load_error: Error = OK
var save_rejected: bool = false
var _crypto := Crypto.new()
var _session: PackedByteArray
var _primary: Dictionary[StringName, PackedByteArray] = {}
var _shadow: Dictionary[StringName, PackedByteArray] = {}
var _dynamic_int_keys: Dictionary[StringName, bool] = {}
var _dynamic_float_keys: Dictionary[StringName, bool] = {}
var _cached_save: Dictionary = {}


func _init() -> void:
	_cached_save = default_save()
	_session = _crypto.generate_random_bytes(32)
	if _session.size() != 32:
		push_error("SecurityVault could not initialize the memory guard.")
		return
	for key: StringName in CORE_INT_KEYS:
		set_guarded_int(key, 0)
	for key: StringName in CORE_FLOAT_KEYS:
		set_guarded_float(key, 0.0)


func _ready() -> void:
	verify_integrity()
	load_game()


func _abs(virtual_path: String) -> String:
	return ProjectSettings.globalize_path(virtual_path)


func _warn(key: StringName) -> void:
	push_warning("SecurityVault detected invalid data: %s" % key)
	tamper_detected.emit(key)


func _mac(key: PackedByteArray, data: PackedByteArray) -> PackedByteArray:
	return _crypto.hmac_digest(HashingContext.HASH_SHA256, key, data)


func _read(path: String, maximum: int) -> PackedByteArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	var length := file.get_length()
	if length <= 0 or length > maximum:
		return PackedByteArray()
	var data := file.get_buffer(length)
	return data if data.size() == length else PackedByteArray()


func _write(path: String, data: PackedByteArray) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var stored := file.store_buffer(data)
	file.flush()
	var error := file.get_error()
	file.close()
	if not stored and error == OK:
		return ERR_FILE_CANT_WRITE
	return error


func _temporary(prefix: String) -> String:
	var nonce := _crypto.generate_random_bytes(16)
	return prefix + "." + nonce.hex_encode() if nonce.size() == 16 else ""


func _master(create: bool) -> PackedByteArray:
	var abs_key_dir := _abs(KEY_DIR)
	if DirAccess.dir_exists_absolute(abs_key_dir) or not create or FileAccess.file_exists(SAVE):
		return _read(KEY_FILE, 32)
	var staging := _temporary(KEY_DIR)
	var abs_staging := _abs(staging)
	var secret := _crypto.generate_random_bytes(32)
	if staging.is_empty() or secret.size() != 32 or DirAccess.make_dir_recursive_absolute(abs_staging) != OK:
		return PackedByteArray()
	if _write(staging + "/master", secret) == OK:
		if DirAccess.rename_absolute(abs_staging, abs_key_dir) == OK:
			return secret
	DirAccess.remove_absolute(_abs(staging + "/master"))
	DirAccess.remove_absolute(abs_staging)
	return _read(KEY_FILE, 32)


func _subkey(master: PackedByteArray, salt: PackedByteArray, purpose: String) -> PackedByteArray:
	var context := (APP_PEPPER + ":" + purpose).to_utf8_buffer() + salt
	return _mac(master, context)


func _aes(data: PackedByteArray, key: PackedByteArray, iv: PackedByteArray, mode: AESContext.Mode) -> PackedByteArray:
	var aes := AESContext.new()
	if aes.start(mode, key, iv) != OK:
		return PackedByteArray()
	var result := aes.update(data)
	aes.finish()
	return result


func default_save() -> Dictionary:
	return {
		"coins": 0,
		"skill_points": 0,
		"unlocked_skills": [],
		"streak_days": 0,
		"completed_districts": [],
		"settings": {},
		"vault_ints": {},
		"vault_floats": {}
	}


func _is_allowed_int_key(key: StringName) -> bool:
	if CORE_INT_KEYS.has(key):
		return true
	var s := String(key)
	return s.begins_with("runtime_") or s.begins_with("district_") or s.begins_with("fog_")


func _is_allowed_float_key(key: StringName) -> bool:
	if CORE_FLOAT_KEYS.has(key):
		return true
	var s := String(key)
	return s.begins_with("runtime_") or s.begins_with("district_")


func _plain_value(value: Variant, depth: int) -> bool:
	if depth > 32:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING, TYPE_STRING_NAME:
			return true
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			for item: Variant in value:
				if not _plain_value(item, depth + 1):
					return false
		TYPE_DICTIONARY:
			for key: Variant in value:
				if typeof(key) not in [TYPE_STRING, TYPE_STRING_NAME] or not _plain_value(value[key], depth + 1):
					return false
		_:
			return false
	return true


func _valid_save(data: Dictionary) -> bool:
	if data.size() < 6 or data.size() > 9:
		return false
	for key: String in ["coins", "skill_points", "streak_days"]:
		if typeof(data.get(key)) != TYPE_INT or data[key] < 0:
			return false
	for key: String in ["unlocked_skills", "completed_districts"]:
		if typeof(data.get(key)) not in [TYPE_ARRAY, TYPE_DICTIONARY]:
			return false
	if typeof(data.get("settings")) != TYPE_DICTIONARY:
		return false
	if data.has("vault_ints") and typeof(data["vault_ints"]) != TYPE_DICTIONARY:
		return false
	if data.has("vault_floats") and typeof(data["vault_floats"]) != TYPE_DICTIONARY:
		return false
	for key: Variant in data.get("vault_floats", {}):
		var value: Variant = data.vault_floats[key]
		if not (value is float or value is int) or not is_finite(float(value)):
			return false
		if CORE_FLOAT_KEYS.has(StringName(key)) and (value < 0.0 or value > 100.0):
			return false
	if data.has("bonus_ledger") and not _valid_bonus_ledger(data.bonus_ledger):
		return false
	return _plain_value(data, 0)


func _valid_bonus_ledger(value: Variant) -> bool:
	if not (value is Dictionary) or value.size() != 9:
		return false
	for key in ["version", "last_claim_utc", "max_seen_utc", "utc_day", "daily_count"]:
		if typeof(value.get(key)) != TYPE_INT or value[key] < 0:
			return false
	if value.version != 1 or value.max_seen_utc < value.last_claim_utc or value.daily_count > 3:
		return false
	if value.utc_day != value.last_claim_utc / 86400:
		return false
	if not (value.get("revive_used") is bool and value.get("battery_used") is bool):
		return false
	var run: Variant = value.get("run_id")
	var receipt: Variant = value.get("last_claim_id")
	if not (run is String and run.length() == 16 and run.is_valid_hex_number(false) and run == run.to_lower()):
		return false
	if not (receipt is String):
		return false
	if value.last_claim_utc == 0:
		return receipt.is_empty() and value.daily_count == 0 and not value.revive_used and not value.battery_used
	return value.daily_count >= 1 and receipt.length() == 32 and receipt.is_valid_hex_number(false) and receipt == receipt.to_lower()


func bonus_ledger() -> Dictionary:
	return (_cached_save.get("bonus_ledger", {}) as Dictionary).duplicate()


## Reauthenticate the stored ledger without restoring an older snapshot of live guards.
func bonus_integrity_ok() -> bool:
	return integrity_ok and not save_rejected and _ledger_matches_disk()


func _ledger_matches_disk() -> bool:
	var verified := _read_save()
	if save_rejected:
		return false
	if verified.get("bonus_ledger", {}) != _cached_save.get("bonus_ledger", {}):
		_reject_save()
		return false
	return true


func save_game(data: Dictionary = {}, vitals: Dictionary = {}) -> Error:
	if save_rejected or (_cached_save.has("bonus_ledger") and not _ledger_matches_disk()):
		return ERR_FILE_CORRUPT
	var payload := _cached_save.duplicate(true)
	payload["coins"] = maxi(0, get_guarded_int(&"coins"))
	payload["skill_points"] = maxi(0, get_guarded_int(&"skill_points"))
	for k: Variant in data:
		payload[String(k)] = data[k]
	var v_ints: Dictionary = {}
	for k: StringName in _dynamic_int_keys:
		v_ints[String(k)] = get_guarded_int(k)
	var v_floats: Dictionary = {}
	for k: StringName in CORE_FLOAT_KEYS:
		v_floats[String(k)] = vitals.get(String(k), get_guarded_float(k))
	for k: StringName in _dynamic_float_keys:
		v_floats[String(k)] = get_guarded_float(k)
	payload["vault_ints"] = v_ints
	payload["vault_floats"] = v_floats
	if not _valid_save(payload):
		return ERR_INVALID_DATA
	var plain := var_to_bytes(payload)
	if plain.is_empty() or plain.size() > LIMIT:
		return ERR_INVALID_DATA
	var error := OK if write_checkpoint(SAVE, plain) else ERR_FILE_CANT_WRITE
	if error == OK:
		_cached_save = payload.duplicate(true)
		for k: StringName in CORE_INT_KEYS:
			if data.has(k):
				set_guarded_int(k, int(payload[k]))
		for k: StringName in CORE_FLOAT_KEYS:
			if vitals.has(k):
				set_guarded_float(k, float(v_floats[k]))
	return error


func _reject_save() -> Dictionary:
	last_load_error = ERR_FILE_CORRUPT
	save_rejected = true
	_warn(&"save")
	return default_save()


func _read_save() -> Dictionary:
	last_load_error = OK
	if has_checkpoint(SAVE):
		for rank in CHECKPOINT_DEPTH + 1:
			var recovered := _checkpoint_bytes(SAVE, rank)
			if recovered.is_empty():
				continue
			var value: Variant = bytes_to_var(recovered)
			if value is Dictionary and _valid_save(value):
				if rank > 0:
					_warn(&"save_backup_recovered")
				return value
		return _reject_save()
	if not FileAccess.file_exists(SAVE):
		last_load_error = ERR_FILE_NOT_FOUND
		return default_save()
	var raw := _read(SAVE, HEADER + LIMIT + 16 + TAG)
	var count := raw.size() - HEADER - TAG
	if count < 16 or count % 16 != 0 or raw.slice(0, 4) != "LSV1".to_ascii_buffer():
		return _reject_save()
	var master := _master(false)
	if master.size() != 32:
		return _reject_save()
	var salt := raw.slice(4, 20)
	var end := raw.size() - TAG
	var expected := _mac(_subkey(master, salt, "LSV1/sign"), raw.slice(0, end))
	if not _crypto.constant_time_compare(expected, raw.slice(end)):
		return _reject_save()
	var plain := _aes(
		raw.slice(HEADER, end),
		_subkey(master, salt, "LSV1/encrypt"),
		raw.slice(20, HEADER),
		AESContext.MODE_CBC_DECRYPT
	)
	if plain.size() != count:
		return _reject_save()
	var padding := int(plain[-1])
	if padding < 1 or padding > 16 or count <= padding or count - padding > LIMIT:
		return _reject_save()
	for index: int in range(count - padding, count):
		if plain[index] != padding:
			return _reject_save()
	plain.resize(count - padding)
	var decoded: Variant = bytes_to_var(plain)
	if typeof(decoded) != TYPE_DICTIONARY or not _valid_save(decoded):
		return _reject_save()
	return decoded


func load_game() -> Dictionary:
	var loaded := _read_save()
	if save_rejected:
		return default_save()
	if last_load_error != OK:
		if _cached_save.has("bonus_ledger"):
			return _reject_save()
		_cached_save = loaded.duplicate(true)
		return loaded
	set_guarded_int(&"coins", int(loaded.get("coins", 0)))
	set_guarded_int(&"skill_points", int(loaded.get("skill_points", 0)))
	var v_ints: Variant = loaded.get("vault_ints", {})
	if typeof(v_ints) == TYPE_DICTIONARY:
		for k: Variant in v_ints:
			var key_sn := StringName(String(k))
			if _is_allowed_int_key(key_sn) and typeof(v_ints[k]) == TYPE_INT:
				set_guarded_int(key_sn, int(v_ints[k]))
	var v_floats: Variant = loaded.get("vault_floats", {})
	if typeof(v_floats) == TYPE_DICTIONARY:
		for k: Variant in v_floats:
			var key_sn := StringName(String(k))
			if _is_allowed_float_key(key_sn) and (typeof(v_floats[k]) == TYPE_FLOAT or typeof(v_floats[k]) == TYPE_INT):
				set_guarded_float(key_sn, float(v_floats[k]))
	_cached_save = loaded.duplicate(true)
	return loaded


func set_guarded_int(key: StringName, val: int) -> void:
	if not _is_allowed_int_key(key):
		push_error("Invalid guarded integer key: %s" % key)
		return
	if not CORE_INT_KEYS.has(key) and not String(key).begins_with("runtime_"):
		_dynamic_int_keys[key] = true
	var safe_val: int = clampi(val, 0, 999999)
	if key == &"coins" or key == &"skill_points":
		safe_val = clampi(val, 0, 999)
	var bits := PackedByteArray()
	bits.resize(8)
	bits.encode_s64(0, safe_val)
	_store_guard(key, bits)


func get_guarded_int(key: StringName, default_val: int = 0) -> int:
	if not _is_allowed_int_key(key):
		push_error("Invalid guarded integer key: %s" % key)
		return default_val
	if not _primary.has(key) and not _shadow.has(key):
		return default_val
	var bits := _load_guard(key)
	return bits.decode_s64(0) if bits.size() == 8 else default_val


func set_guarded_float(key: StringName, val: float) -> void:
	if not _is_allowed_float_key(key) or not is_finite(val):
		push_error("Invalid guarded float: %s" % key)
		return
	if not CORE_FLOAT_KEYS.has(key) and not String(key).begins_with("runtime_"):
		_dynamic_float_keys[key] = true
	var safe_val: float = val
	if key == &"battery" or key == &"warmth" or key == &"health":
		safe_val = clampf(val, 0.0, 100.0)
	var bits := PackedByteArray()
	bits.resize(8)
	bits.encode_double(0, safe_val)
	_store_guard(key, bits)


func get_guarded_float(key: StringName, default_val: float = 0.0) -> float:
	if not _is_allowed_float_key(key):
		push_error("Invalid guarded float key: %s" % key)
		return default_val
	if not _primary.has(key) and not _shadow.has(key):
		return default_val
	var bits := _load_guard(key)
	return bits.decode_double(0) if bits.size() == 8 else default_val


func _mask(slot: PackedByteArray, nonce: PackedByteArray, bits: PackedByteArray) -> PackedByteArray:
	var pad := _mac(_session, "mask".to_ascii_buffer() + slot + nonce)
	var masked := bits.duplicate()
	for index: int in range(8):
		masked[index] ^= pad[index]
	return masked


func _seal(slot: PackedByteArray, bits: PackedByteArray) -> PackedByteArray:
	var nonce := _crypto.generate_random_bytes(16)
	if nonce.size() != 16:
		return PackedByteArray()
	var payload := nonce + _mask(slot, nonce, bits)
	return payload + _mac(_session, "tag".to_ascii_buffer() + slot + payload)


func _open_guard(slot: PackedByteArray, record: PackedByteArray) -> PackedByteArray:
	if record.size() != 56:
		return PackedByteArray()
	var expected := _mac(_session, "tag".to_ascii_buffer() + slot + record.slice(0, 24))
	if not _crypto.constant_time_compare(expected, record.slice(24)):
		return PackedByteArray()
	return _mask(slot, record.slice(0, 16), record.slice(16, 24))


func _store_guard(key: StringName, bits: PackedByteArray) -> void:
	if _session.size() != 32:
		return
	if _primary.has(key) or _shadow.has(key):
		if _load_guard(key) == bits:
			return
	_write_guard(key, bits)

func _write_guard(key: StringName, bits: PackedByteArray) -> void:
	var primary := _seal((String(key) + "/primary").to_ascii_buffer(), bits)
	var shadow := _seal((String(key) + "/shadow").to_ascii_buffer(), bits)
	if primary.size() != 56 or shadow.size() != 56:
		push_error("SecurityVault could not update the guard.")
		return
	_primary[key] = primary
	_shadow[key] = shadow


func _load_guard(key: StringName) -> PackedByteArray:
	if _session.size() != 32:
		return PackedByteArray()
	var primary := _open_guard(
		(String(key) + "/primary").to_ascii_buffer(),
		_primary.get(key, PackedByteArray())
	)
	var shadow := _open_guard(
		(String(key) + "/shadow").to_ascii_buffer(),
		_shadow.get(key, PackedByteArray())
	)
	if primary.size() == 8 and primary == shadow:
		return primary
	var recovered := shadow if shadow.size() == 8 else primary
	if recovered.is_empty():
		recovered.resize(8)
	_write_guard(key, recovered)
	_warn(key)
	return recovered


func verify_integrity() -> bool:
	integrity_ok = false
	if not FileAccess.file_exists(MANIFEST):
		_warn(&"integrity_manifest")
		return false
	var bytes := _read(MANIFEST, LIMIT)
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		_warn(&"integrity_manifest")
		return false
	var manifest: Dictionary = parsed
	var files: Variant = manifest.get("files", manifest)
	if typeof(files) != TYPE_DICTIONARY or files.is_empty():
		_warn(&"integrity_manifest")
		return false
	for raw_path: Variant in files:
		var path_str := String(raw_path)
		if path_str == "schema_version" or path_str == "generated_at":
			continue
		var res_path := path_str if path_str.begins_with("res://") else "res://" + path_str
		if res_path.ends_with(".gd") and not FileAccess.file_exists(res_path) and FileAccess.file_exists(res_path + "c"):
			continue
		if not FileAccess.file_exists(res_path):
			_warn(StringName(res_path))
			return false
		var actual_sha := FileAccess.get_sha256(res_path).to_lower()
		var entry: Variant = files[raw_path]
		var expected_sha := ""
		if typeof(entry) == TYPE_DICTIONARY:
			var entry_dict: Dictionary = entry
			expected_sha = String(entry_dict.get("sha256", entry_dict.get("hash", ""))).to_lower()
		else:
			expected_sha = String(entry).to_lower()
		if actual_sha.is_empty() or expected_sha.is_empty() or actual_sha != expected_sha:
			_warn(StringName(res_path))
			return false
	integrity_ok = true
	return true

# The installation keeps an authenticated high-water mark outside each rotating save.
# Only its current digest may occupy the live slot. Older digests belong to backups.
const CHECKPOINT_MAGIC := "TLS2"
const CHECKPOINT_DEPTH := 3

func _checkpoint_path_ok(path: String) -> bool:
	var name := path.trim_prefix("user://")
	return name != path and not name.is_empty() and not name.begins_with("/") and not name.contains(":") and not name.contains("..") and not name.contains("\\")

func _anchor_path(path: String) -> String:
	return KEY_DIR + "/" + path.sha256_text()

func has_checkpoint(path: String) -> bool:
	return _checkpoint_path_ok(path) and FileAccess.file_exists(_anchor_path(path))

func _anchor(path: String, master: PackedByteArray) -> Dictionary:
	var raw := _read(_anchor_path(path), 4096)
	if raw.size() <= TAG:
		return {}
	var data := raw.slice(TAG)
	if not _crypto.constant_time_compare(raw.slice(0, TAG), _mac(_subkey(master, path.to_utf8_buffer(), "counter"), data)):
		return {}
	var state: Variant = bytes_to_var(data)
	if not state is Dictionary or not state.get("count") is int or not state.get("heads") is Array:
		return {}
	return state

func _sha(data: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(data)
	return ctx.finish().hex_encode()

# AES in counter mode. A fresh random nonce and installation-derived key protect
# each checkpoint. The HMAC covers the format, monotonic counter, nonce and bytes.
func _crypt_checkpoint(data: PackedByteArray, master: PackedByteArray, nonce: PackedByteArray) -> PackedByteArray:
	var blocks := PackedByteArray()
	blocks.resize(ceili(data.size() / 16.0) * 16)
	for offset in range(0, blocks.size(), 16):
		blocks.encode_u64(offset + 8, offset / 16)
	var stream := _aes(blocks, _subkey(master, nonce, "checkpoint/encrypt"), PackedByteArray(), AESContext.MODE_ECB_ENCRYPT)
	if stream.size() != blocks.size():
		return PackedByteArray()
	var result := data.duplicate()
	for i in result.size():
		result[i] ^= stream[i]
	return result

func _checkpoint_bytes(path: String, rank: int) -> PackedByteArray:
	if not _checkpoint_path_ok(path) or rank < 0 or rank > CHECKPOINT_DEPTH:
		return PackedByteArray()
	var master := _master(false)
	if master.size() != 32:
		return PackedByteArray()
	var state := _anchor(path, master)
	if state.is_empty() or state.heads.is_empty():
		return PackedByteArray()
	var heads: Array = state.heads
	var suffix := "" if rank == 0 else (".bak" if rank == 1 else ".bak%d" % rank)
	var raw := _read(path + suffix, LIMIT + 60)
	if rank == 0 and FileAccess.file_exists(path + ".tmp"):
		var staged := _read(path + ".tmp", LIMIT + 60)
		if not staged.is_empty() and _sha(staged) == heads[0]:
			raw = staged
	if raw.size() <= 28 + TAG or raw.slice(0, 4).get_string_from_ascii() != CHECKPOINT_MAGIC:
		return PackedByteArray()
	var digest := _sha(raw)
	var index := heads.find(digest)
	if index < 0 or (rank == 0 and index != 0) or (rank > 0 and index == 0):
		return PackedByteArray()
	var counter := raw.decode_s64(4)
	if counter != int(state.count) - index:
		return PackedByteArray()
	var body := raw.slice(0, raw.size() - TAG)
	var expected := _mac(_subkey(master, path.to_utf8_buffer(), "checkpoint/sign"), body)
	if not _crypto.constant_time_compare(expected, raw.slice(body.size())):
		return PackedByteArray()
	return _crypt_checkpoint(body.slice(28), master, body.slice(12, 28))

func write_checkpoint(path: String, data: PackedByteArray) -> bool:
	if not _checkpoint_path_ok(path) or data.is_empty() or data.size() > LIMIT:
		return false
	var master := _master(true)
	if master.size() != 32:
		return false
	var state := _anchor(path, master)
	if state.is_empty():
		if has_checkpoint(path):
			return false
		state = {"count": 0, "heads": []}
	var nonce := _crypto.generate_random_bytes(16)
	if nonce.size() != 16:
		return false
	var cipher := _crypt_checkpoint(data, master, nonce)
	if cipher.size() != data.size():
		return false
	var count := int(state.count) + 1
	var body := CHECKPOINT_MAGIC.to_ascii_buffer()
	body.resize(12)
	body.encode_s64(4, count)
	body.append_array(nonce)
	body.append_array(cipher)
	body.append_array(_mac(_subkey(master, path.to_utf8_buffer(), "checkpoint/sign"), body))
	# Finish any previously committed rename before reusing the staging file.
	if FileAccess.file_exists(path + ".tmp") and not state.heads.is_empty():
		if _sha(_read(path + ".tmp", LIMIT + 60)) == state.heads[0] and DirAccess.rename_absolute(_abs(path + ".tmp"), _abs(path)) != OK:
			return false
	if _write(path + ".tmp", body) != OK:
		return false
	var heads: Array = state.heads.duplicate()
	if not heads.is_empty() and FileAccess.file_exists(path) and _sha(_read(path, LIMIT + 60)) == heads[0]:
		for i in range(CHECKPOINT_DEPTH, 0, -1):
			var source := path if i == 1 else (path + ".bak" if i == 2 else path + ".bak%d" % (i - 1))
			var destination := path + (".bak" if i == 1 else ".bak%d" % i)
			if FileAccess.file_exists(source) and DirAccess.copy_absolute(_abs(source), _abs(destination)) != OK:
				return false
	heads.push_front(_sha(body))
	heads.resize(mini(heads.size(), CHECKPOINT_DEPTH + 1))
	var record := var_to_bytes({"count":count, "heads":heads})
	var anchor_file := _anchor_path(path)
	if _write(anchor_file + ".tmp", _mac(_subkey(master, path.to_utf8_buffer(), "counter"), record) + record) != OK:
		return false
	if DirAccess.rename_absolute(_abs(anchor_file + ".tmp"), _abs(anchor_file)) != OK:
		return false
	# At this point the pending file is committed and also readable after a crash.
	DirAccess.rename_absolute(_abs(path + ".tmp"), _abs(path))
	return true



func forget_runtime_guard(key: StringName) -> void:
	if String(key).begins_with("runtime_"):
		_primary.erase(key)
		_shadow.erase(key)
