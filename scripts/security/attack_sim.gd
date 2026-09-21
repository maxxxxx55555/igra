extends Node
## Gate: adversarial attack simulation, headless.
## Scene: scenes/tools/attack_sim_scene.tscn
##
## docs/QA_SWARM_FINDINGS.md's cheater-persona pass found real gaps this gate
## exists to prove closed and keep closed. Byte-flip/truncation/envelope
## fuzzing of the MAIN save already has a dedicated 50-mutant gate
## (scripts/tools/_save_integrity_check.gd, "целостность сейва") - not
## duplicated here. This covers the attack surface that gate doesn't:
## achievement-file forgery, NG+ level forgery, absurd economy values, and
## district-id injection into the scene loader.

const _SLOT: int = 96  # a different scratch slot than _save_integrity_check.gd's 97

var _fails: int = 0
var _done: bool = false

## HANG FOUND LIVE (2026-09-21): autoload boot (MapController -> city_map.gd
## -> ThemeProvider) can grind for 50+ minutes loading dozens of UI textures
## when the .godot/imported/ cache is stale, unrelated to anything this gate
## itself does - but it happens BEFORE _ready() below ever runs a single
## check, so this script has no chance to catch it internally. A real
## process-level watchdog belongs one layer up (a hard OS timeout on every
## Godot invocation, not just this one) - this in-scene one is the second
## layer, in case a FUTURE case in this file itself (not boot) ever stalls.
func _ready() -> void:
	get_tree().create_timer(45.0).timeout.connect(func() -> void:
		if not _done:
			print("[attack-sim] WATCHDOG stall past 45s - quitting")
			get_tree().quit(2))
	await get_tree().process_frame
	_check_achievements_forgery_rejected()
	_check_achievements_legacy_migrates()
	_check_ng_plus_level_clamped()
	_check_coin_wallet_absurd_values()
	_check_district_id_injection_defended()
	_check_cross_save_swap_no_corruption()
	_cleanup()
	_done = true
	print("[attack-sim] DONE fails=", _fails)
	get_tree().quit(0 if _fails == 0 else 1)

func _ok(cond: bool, what: String) -> void:
	if cond:
		print("[attack-sim] OK  ", what)
	else:
		_fails += 1
		print("[attack-sim] FAIL ", what)

# ── achievements.cfg: forged-unlock rejection + legacy migration ──────────
func _check_achievements_forgery_rejected() -> void:
	var path := "user://achievements.cfg"
	AchievementManager._unlocked.clear()
	AchievementManager._progress.clear()
	AchievementManager._save()
	_ok(FileAccess.file_exists(path), "achievements.cfg written")

	# Hand-forge an "everything unlocked" body under a WRONG signature
	# (simulating a player editing the file directly) and reload.
	var forged_body := JSON.stringify({"unlocked": {"ach_01": true, "ach_02": true}, "progress": {}})
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"hmac": "0000deadbeef0000", "data_json": forged_body}))
	f.close()
	AchievementManager._unlocked.clear()
	AchievementManager._load()
	_ok(not AchievementManager.is_unlocked(&"ach_01"),
		"forged achievements.cfg (wrong hmac) is rejected, not trusted")

	# A validly re-signed body (the honest path: real grant, real _save())
	# must still load correctly - the fix isn't a one-way brick.
	AchievementManager._unlocked.clear()
	AchievementManager._unlock(&"ach_01")
	var was_unlocked: bool = AchievementManager.is_unlocked(&"ach_01")
	AchievementManager._unlocked.clear()
	AchievementManager._load()
	_ok(was_unlocked and AchievementManager.is_unlocked(&"ach_01"),
		"honestly-signed achievements.cfg still round-trips")

func _check_achievements_legacy_migrates() -> void:
	var path := "user://achievements.cfg"
	# Pre-signing players have a PLAIN (unsigned) file on disk - it must
	# still be trusted once and migrated forward, not wiped.
	var legacy := JSON.stringify({"unlocked": {"ach_01": true}, "progress": {}})
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(legacy)
	f.close()
	AchievementManager._unlocked.clear()
	AchievementManager._load()
	_ok(AchievementManager.is_unlocked(&"ach_01"),
		"legacy unsigned achievements.cfg is trusted once (compat, not a wipe)")
	var f2 := FileAccess.open(path, FileAccess.READ)
	var migrated = JSON.parse_string(f2.get_as_text())
	f2.close()
	_ok(migrated is Dictionary and migrated.has("hmac"),
		"legacy file is re-signed on load, not left plain forever")
	AchievementManager._unlocked.clear()
	AchievementManager._progress.clear()
	AchievementManager._save()

# ── NG+ level forgery ───────────────────────────────────────────────────
func _check_ng_plus_level_clamped() -> void:
	var path := "user://ng_plus_data.json"
	var had_file := FileAccess.file_exists(path)
	var backup := ""
	if had_file:
		var bf := FileAccess.open(path, FileAccess.READ)
		backup = bf.get_as_text()
		bf.close()
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"ng_plus": 99, "active": true, "modifiers": []}))
	f.close()
	NewGamePlus._load_save()
	_ok(NewGamePlus.get_current_ng_plus() <= NewGamePlus.get_max_ng_plus(),
		"forged ng_plus=99 is clamped to MAX_NG_PLUS (%d), got %d" % [NewGamePlus.get_max_ng_plus(), NewGamePlus.get_current_ng_plus()])
	if had_file:
		var wf := FileAccess.open(path, FileAccess.WRITE)
		wf.store_string(backup)
		wf.close()
	else:
		DirAccess.remove_absolute(path)
	NewGamePlus._load_save()

# ── economy: absurd values can't desync CoinWallet ─────────────────────
func _check_coin_wallet_absurd_values() -> void:
	CoinWallet.from_dict({"coins": 999999999999})
	_ok(CoinWallet.get_coins() == CoinWallet.MAX_COINS, "absurd huge coins clamps to MAX_COINS")
	CoinWallet.from_dict({"coins": -500})
	_ok(CoinWallet.get_coins() == 0, "negative coins clamps to 0")
	CoinWallet.from_dict({"coins": "not_a_number"})
	var c: int = CoinWallet.get_coins()
	_ok(c >= 0 and c <= CoinWallet.MAX_COINS, "non-numeric coins field doesn't crash or desync (%d)" % c)
	CoinWallet.from_dict({})

# ── district-id injection into the scene loader ─────────────────────────
func _check_district_id_injection_defended() -> void:
	var probe := Node3D.new()
	add_child(probe)
	for malicious in ["../../../../etc/passwd", "res://project.godot", "<script>", ""]:
		var root := DistrictSceneFactory.build(probe, StringName(malicious))
		_ok(root != null, "malicious district_id %s doesn't crash the scene factory" % malicious)
		if root != null:
			root.queue_free()
	probe.queue_free()

# ── cross-save swap: copying a foreign signed save over a slot ─────────
func _check_cross_save_swap_no_corruption() -> void:
	var slot_a := _SLOT
	var slot_b := _SLOT + 1
	CoinWallet.from_dict({}); CoinWallet.add(111)
	SaveSystem.save_slot(slot_a)
	CoinWallet.from_dict({}); CoinWallet.add(222)
	SaveSystem.save_slot(slot_b)
	var path_a := "user://tls_savegame_slot%d.save" % slot_a
	var path_b := "user://tls_savegame_slot%d.save" % slot_b
	DirAccess.copy_absolute(path_b, path_a)  # foreign (but validly signed) file dropped into slot A
	CoinWallet.from_dict({})
	var loaded := SaveSystem.load_slot(slot_a)
	_ok(loaded and CoinWallet.get_coins() == 222,
		"a validly-signed save from another slot loads cleanly, no corruption (got %d)" % CoinWallet.get_coins())
	for suffix in ["", ".bak", ".bak2", ".bak3"]:
		for p in [path_a + suffix, path_b + suffix]:
			if FileAccess.file_exists(p):
				DirAccess.remove_absolute(p)
	CoinWallet.from_dict({})

func _cleanup() -> void:
	CoinWallet.from_dict({})
