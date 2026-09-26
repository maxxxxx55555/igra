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

const _SLOT: int = 95  # scratch pair 95/96 (the swap check below uses _SLOT+1=96 too), different from _save_integrity_check.gd's 97

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
	_check_ng_plus_modifiers_revalidated()
	_check_ng_plus_unsigned_file_rejected()
	_check_reset_progress_clears_ng_plus()
	_check_flashlight_upgrade_forgery_rejected()
	_check_daily_challenge_forgery_rejected()
	_check_daily_clock_rollback_rejected()
	_check_progress_tracker_grant_unlocks_real_achievement()
	_check_main_authority_schema()
	_check_district_id_and_player_pos_validated()
	_check_integrity_guard_wired()
	_check_lan_payload_validation()
	_check_coin_wallet_absurd_values()
	_check_district_id_injection_defended()
	_check_cross_save_swap_rejected()
	_check_release_has_no_ad_stub()
	_check_leaderboard_signed_and_validated()
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

# ── daily challenge: forged content must not be trusted ──────────────────
## BREAK_REPORT B6: tls_daily.json was plain JSON - hand-editing
## last_completed_day (to skip a day and re-trigger streak bonuses) or
## progress (to instant-complete without earning it) was a one-line forge,
## no signature to break. Now HMAC-signed like achievements.cfg: a body
## edited without the real key fails to verify and loads as a fresh,
## not-yet-completed day rather than trusting the forged content.
## Honest limit, not claimed fixed: full file DELETION can't be defended
## against by any client-side signature - there's no data left to verify.
## Signing raises the cost (the flag isn't the only thing at risk if this
## file is deliberately kept separate from the main save, though deletion
## itself stays free either way) rather than closing deletion outright;
## documented as an inherent residual, same class as SECURITY_PATCH_SPEC's
## own client-side-unclosable findings, not swept in with what signing
## actually does close (content forgery).
func _check_daily_challenge_forgery_rejected() -> void:
	var path := "user://tls_daily.json"
	var had_file := FileAccess.file_exists(path)
	var backup := ""
	if had_file:
		var bf := FileAccess.open(path, FileAccess.READ)
		backup = bf.get_as_text()
		bf.close()
	var today: int = DailyChallengeManager.call("_today_index")
	# Forge "completed yesterday" (so a streak-continuation check would
	# treat today as the next consecutive day) under a wrong signature -
	# simulates editing the real file without the key.
	var forged_body := JSON.stringify({
		"today_id": "forged", "progress": 999, "last_completed_day": today - 1,
	})
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"hmac": "0000deadbeef0000", "data_json": forged_body}))
	f.close()
	# Reset to the class's own untouched defaults before loading, same
	# "clear, then assert the forgery didn't apply" shape as the
	# achievements check above.
	DailyChallengeManager._last_completed_day = -1
	DailyChallengeManager._progress = 0
	DailyChallengeManager.call("_load_state")
	_ok(DailyChallengeManager._last_completed_day == -1 and DailyChallengeManager._progress == 0,
		"forged tls_daily.json (wrong hmac) is rejected, not trusted")
	if had_file:
		var wf := FileAccess.open(path, FileAccess.WRITE)
		wf.store_string(backup)
		wf.close()
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	DailyChallengeManager.call("_load_state")

## SECURITY_PATCH_SPEC R-08: a launch whose clock was set back after a claim
## must not reopen an earlier day (the replay test used to be `==`).
func _check_daily_clock_rollback_rejected() -> void:
	var saved := [DailyChallengeManager._day, DailyChallengeManager._last_completed_day,
		DailyChallengeManager._completed_today, DailyChallengeManager._today,
		DailyChallengeManager._today_id]
	var today: int = DailyChallengeManager.call("_today_index")
	DailyChallengeManager._last_completed_day = today
	DailyChallengeManager._completed_today = false
	DailyChallengeManager.call("_roll_for_day", today - 1)
	_ok(DailyChallengeManager._completed_today and DailyChallengeManager._day == today - 1,
		"daily: a clock set back after a claim does not reopen an earlier day")
	DailyChallengeManager._day = saved[0]
	DailyChallengeManager._last_completed_day = saved[1]
	DailyChallengeManager._completed_today = saved[2]
	DailyChallengeManager._today = saved[3]
	DailyChallengeManager._today_id = saved[4]

# ── ProgressTracker short-id grants must go through the real API ─────────
## BREAK_REPORT B7: ProgressTracker._grant() used to emit
## EventBus.achievement_unlocked directly with short ids ("first_light"),
## bypassing AchievementManager.unlock() entirely - the real ach_01 row
## never actually unlocked (missing from the trophy list forever), while
## rewards_manager.gd's blanket "any emit pays REWARD_ACHIEVEMENT" handler
## paid coins anyway since it doesn't check which id fired. Drives the
## real signal (EventBus.puzzle_solved) rather than calling _grant()
## directly, so this proves the whole chain, not just the one function.
func _check_progress_tracker_grant_unlocks_real_achievement() -> void:
	# Full isolation, not just "first_light": _check_achievements() also
	# grants district_one/shadow_slayer/secret_hunter from whatever state
	# PowerGrid/kills/secrets happen to be in - a boot default (or an
	# earlier check) can leave one of those already satisfied, which paid
	# out a second, real 100 coins and made this look like a double-pay
	# bug in the fix being tested here, when it was really test isolation.
	PowerGrid.reset()
	ProgressTracker.puzzles = 0
	ProgressTracker.shadow_kills = 0
	ProgressTracker.secrets = 0
	ProgressTracker._ach_done.clear()
	AchievementManager._unlocked.erase("ach_01")
	CoinWallet.from_dict({})
	var before: int = CoinWallet.get_coins()
	var expected_reward: int = int(RewardsManager.REWARD_ACHIEVEMENT * NewGamePlus.get_modifier_multiplier("rewards"))
	EventBus.puzzle_solved.emit(&"fuse_substation", &"substation")
	_ok(AchievementManager.is_unlocked(&"ach_01"),
		"ProgressTracker's first_light grant actually unlocks the real ach_01 row")
	_ok(CoinWallet.get_coins() == before + expected_reward,
		"achievement reward pays exactly once (%d), not double (got %d -> %d)" % [
			expected_reward, before, CoinWallet.get_coins()])
	AchievementManager._unlocked.erase("ach_01")
	AchievementManager._save()
	CoinWallet.from_dict({})

# ── NG+ level forgery ───────────────────────────────────────────────────
## SECURITY_PATCH_SPEC P-03: ng_plus_data.json is now a signed envelope
## (SaveSystem's own HMAC, matching daily_challenge_manager.gd's B6 fix) -
## every test file below must be written through this so it survives the
## envelope check and actually reaches the clamp/revalidation logic under
## test, rather than being rejected outright before it does.
func _write_ngp_test_file(data: Dictionary) -> void:
	var path := "user://ng_plus_data.json"
	var body := JSON.stringify(data)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"hmac": SaveSystem.call("_sign", body), "data_json": body}))
	f.close()

func _check_ng_plus_level_clamped() -> void:
	var path := "user://ng_plus_data.json"
	var had_file := FileAccess.file_exists(path)
	var backup := ""
	if had_file:
		var bf := FileAccess.open(path, FileAccess.READ)
		backup = bf.get_as_text()
		bf.close()
	_write_ngp_test_file({"ng_plus": 99, "active": true, "modifiers": []})
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

## BREAK_REPORT B5: _load_save() used to append every id from the file
## straight into _active_modifiers with no can_select() gate at all - a
## forged file could list more modifiers than levels unlocked, or two
## mutually-exclusive ones (sprint/whisper, content/ngp_modifiers.json)
## together. Same backup/restore pattern as the level-clamp check above.
func _check_ng_plus_modifiers_revalidated() -> void:
	var path := "user://ng_plus_data.json"
	var had_file := FileAccess.file_exists(path)
	var backup := ""
	if had_file:
		var bf := FileAccess.open(path, FileAccess.READ)
		backup = bf.get_as_text()
		bf.close()
	_write_ngp_test_file({
		"ng_plus": 3, "active": true,
		"modifiers": ["sprint", "whisper", "keepers_pact", "ghost"],
	})
	NewGamePlus._load_save()
	var active: Array = NewGamePlus.get_active_modifiers()
	_ok(not ("sprint" in active and "whisper" in active),
		"forged file can't seat both exclusive modifiers (sprint+whisper) at once")
	_ok(active.size() <= NewGamePlus.get_current_ng_plus(),
		"forged file can't seat more modifiers (%d) than unlocked levels (%d)" % [
			active.size(), NewGamePlus.get_current_ng_plus()])
	if had_file:
		var wf := FileAccess.open(path, FileAccess.WRITE)
		wf.store_string(backup)
		wf.close()
	else:
		DirAccess.remove_absolute(path)
	NewGamePlus._load_save()

## SECURITY_PATCH_SPEC P-03: ng_plus_data.json used to be plain, unsigned
## JSON - active/modifiers/ng_plus control real difficulty, rewards,
## battery and time-pressure scaling with no proof any of it was earned.
## Writes a plain (unsigned) file with a maxed-out, fully-active state and
## confirms _load_save() now leaves the CURRENT in-memory state alone
## rather than adopting it.
func _check_ng_plus_unsigned_file_rejected() -> void:
	var path := "user://ng_plus_data.json"
	var had_file := FileAccess.file_exists(path)
	var backup := ""
	if had_file:
		var bf := FileAccess.open(path, FileAccess.READ)
		backup = bf.get_as_text()
		bf.close()
	NewGamePlus.reset_for_new_game()  # known baseline: ng_plus=0, active=false
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"ng_plus": 3, "active": true, "modifiers": ["ghost"]}))
	f.close()
	NewGamePlus._load_save()
	_ok(NewGamePlus.get_current_ng_plus() == 0 and not NewGamePlus.is_ng_plus_active(),
		"unsigned ng_plus_data.json is rejected, not adopted (got ng_plus=%d active=%s)" % [
			NewGamePlus.get_current_ng_plus(), NewGamePlus.is_ng_plus_active()])
	if had_file:
		var wf := FileAccess.open(path, FileAccess.WRITE)
		wf.store_string(backup)
		wf.close()
	else:
		DirAccess.remove_absolute(path)
	NewGamePlus._load_save()

## SECURITY_PATCH_SPEC P-04: flashlight_upgrades.cfg used to be plain,
## unsigned, unclamped JSON directly granting real flashlight bonuses
## (brightness/range/stability/angle/battery all change player_3d.gd's
## light output) with no coins ever spent. Writes an unsigned file with
## every branch at 999 and confirms it's rejected outright (levels stay
## at whatever they were, never adopt the forged value).
func _check_flashlight_upgrade_forgery_rejected() -> void:
	var path := "user://flashlight_upgrades.cfg"
	var had_file := FileAccess.file_exists(path)
	var backup := ""
	if had_file:
		var bf := FileAccess.open(path, FileAccess.READ)
		backup = bf.get_as_text()
		bf.close()
	var before := FlashlightUpgradeManager.get_level("brightness")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"brightness": 999, "range": 999, "stability": 999, "angle": 999, "battery": 999}))
	f.close()
	FlashlightUpgradeManager._load()
	_ok(FlashlightUpgradeManager.get_level("brightness") == before,
		"unsigned flashlight_upgrades.cfg is rejected, not adopted (got %d, expected unchanged %d)" % [
			FlashlightUpgradeManager.get_level("brightness"), before])
	if had_file:
		var wf := FileAccess.open(path, FileAccess.WRITE)
		wf.store_string(backup)
		wf.close()
	else:
		DirAccess.remove_absolute(path)
	FlashlightUpgradeManager._load()

## SECURITY_PATCH_SPEC P-07/C-04: signed authority bodies had no semantic
## validation at all - "HMAC-valid" was being treated as "game-valid".
## Covers the four loaders given schema fixes: PowerGrid (stage clamp),
## InventoryManager (item allowlist + stack-size clamp, already partly
## covered elsewhere), ProgressTracker (secrets/shadow_kills bounds), and
## QuestManager (progress/done consistency).
func _check_main_authority_schema() -> void:
	# PowerGrid: absurd stage clamps to FULL, not left at the forged value.
	PowerGrid.from_dict({"stages": {"suburbs": 99}})
	_ok(PowerGrid.get_stage(&"suburbs") <= DistrictData.Stage.FULL,
		"forged district stage 99 clamps to FULL, got %d" % PowerGrid.get_stage(&"suburbs"))
	PowerGrid.reset()
	# InventoryManager: absurd count on a real stackable item clamps to its
	# own max_stack, not left at the forged value.
	InventoryManager.from_dict({"slots": [{"item_id": "scrap", "count": 999999}]})
	var scrap_count: int = 0
	for s in InventoryManager.slots:
		if s != null and String(s.get("item_id", "")) == "scrap":
			scrap_count = int(s.get("count", 0))
	var scrap_data: ItemData = ItemDatabase.get_item(&"scrap")
	_ok(scrap_data != null and scrap_count <= scrap_data.max_stack,
		"forged scrap count 999999 clamps to max_stack (%s), got %d" % [
			scrap_data.max_stack if scrap_data else "?", scrap_count])
	InventoryManager.from_dict({})
	# ProgressTracker: secrets beyond the real 26-secret total clamps down;
	# shadow_kills can never exceed kills.
	ProgressTracker.from_dict({"secrets": 9999, "kills": 5, "shadow_kills": 9999})
	_ok(ProgressTracker.secrets <= ProgressTracker.MAX_SECRETS,
		"forged secrets 9999 clamps to the real total (%d), got %d" % [ProgressTracker.MAX_SECRETS, ProgressTracker.secrets])
	_ok(ProgressTracker.shadow_kills <= ProgressTracker.kills,
		"forged shadow_kills (9999) can't exceed kills (%d), got %d" % [ProgressTracker.kills, ProgressTracker.shadow_kills])
	ProgressTracker.from_dict({})
	# QuestManager: done=true with zero progress on a real quest is not
	# accepted as a genuine completion.
	QuestManager.from_dict({"q_connect_cables": {"progress": 0, "done": true}})
	var forged_q: Dictionary = QuestManager.quests.get("q_connect_cables", {})
	_ok(not bool(forged_q.get("done", false)),
		"forged done=true with progress=0 is not accepted as a real completion")
	QuestManager.reset()

## SECURITY_PATCH_SPEC R-03: a forged/corrupt main save could set district
## to an id outside DistrictManager.DISTRICTS, or player_pos to a value
## that overflows to a non-finite float once narrowed into a real
## Vector3 (1e40 is valid finite JSON but exceeds float32 range) - both
## used to be applied directly with no check.
func _check_district_id_and_player_pos_validated() -> void:
	var main_path := "user://tls_savegame.save"
	var backups: Dictionary = {}
	for p in [main_path, main_path + ".bak"]:
		if FileAccess.file_exists(p):
			var bf := FileAccess.open(p, FileAccess.READ)
			backups[p] = bf.get_as_text()
			bf.close()
	var dm := get_node_or_null("/root/DistrictManager")
	var before_district: String = String(dm.current_district) if dm else ""
	SaveSystem._write_atomic(main_path, {
		"version": SaveSystem.SAVE_VERSION,
		"district": "hacked_evil_district",
		"player_pos": [1e40, 0.0, 0.0],
	})
	SaveSystem.load_all()
	_ok(dm == null or String(dm.current_district) != "hacked_evil_district",
		"forged district id 'hacked_evil_district' is not adopted (current_district=%s)" % (String(dm.current_district) if dm else "?"))
	_ok(SaveSystem.consume_pending_player_pos() == Vector3.INF,
		"a player_pos that overflows to non-finite is treated as 'no saved position', not applied")
	for p in backups:
		var wf := FileAccess.open(p, FileAccess.WRITE)
		wf.store_string(backups[p])
		wf.close()
	if backups.is_empty():
		for p in [main_path, main_path + ".bak"]:
			if FileAccess.file_exists(p):
				DirAccess.remove_absolute(p)
	SaveSystem.load_all()

## SECURITY_PATCH_SPEC R-01: integrity_guard.gd implemented a real runtime
## watchdog (economy clamp, missing-player detection, fell-through-floor/
## non-finite position restore, HP/battery/stamina range checks) but was
## never in project.godot's [autoload] list - the threat model called it a
## live watchdog when nothing was actually running it. Confirms it's now
## registered AND its economy clamp fires live (bypassing CoinWallet's own
## from_dict() clamp by writing the public var directly, so this actually
## exercises IntegrityGuard's own check, not CoinWallet's).
func _check_integrity_guard_wired() -> void:
	var ig := get_node_or_null("/root/IntegrityGuard")
	_ok(ig != null, "IntegrityGuard is registered as a live autoload (was dormant per R-01)")
	if ig == null:
		return
	var before: int = CoinWallet.get_coins()
	CoinWallet.coins = 99999999999
	ig._check_economy()
	_ok(CoinWallet.get_coins() <= ig.MAX_COINS,
		"IntegrityGuard's live economy check clamps an absurd wallet value (got %d, cap %d)" % [CoinWallet.get_coins(), ig.MAX_COINS])
	CoinWallet.coins = before

## SECURITY_PATCH_SPEC R-07: LAN RPC payloads (non-finite position, unknown
## district) used to be trusted and re-emitted directly. Covers the payload
## half here (finite/allowlist checks) - the sender-binding half needs a
## real second peer to exercise multiplayer.get_remote_sender_id()
## meaningfully, which a single-process headless test can't simulate; a
## direct call here always presents as sender_id 0 (the local-echo case
## the fix deliberately doesn't reject), so that half isn't covered by
## this gate. No consumer of these signals exists yet either way
## (confirmed by grep), so there is no live exploitable effect today.
func _check_lan_payload_validation() -> void:
	var got_state := [false]
	var state_listener := func(_id, _pos, _yaw, _district): got_state[0] = true
	EventBus.remote_player_state.connect(state_listener)
	LANNetwork.rpc_player_state(1, Vector3(NAN, 0.0, 0.0), 0.0, &"suburbs")
	_ok(not got_state[0], "non-finite remote player position is rejected, not re-emitted")
	got_state[0] = false
	LANNetwork.rpc_player_state(1, Vector3.ZERO, 0.0, &"not_a_real_district")
	_ok(not got_state[0], "unknown district in remote player state is rejected")
	got_state[0] = false
	LANNetwork.rpc_player_state(1, Vector3.ZERO, 0.0, &"suburbs")
	_ok(got_state[0], "a valid remote player state still gets through")
	EventBus.remote_player_state.disconnect(state_listener)

	var got_power := [false]
	var power_listener := func(_d, _p): got_power[0] = true
	EventBus.remote_power_changed.connect(power_listener)
	LANNetwork.rpc_power_changed(&"not_a_real_district", true)
	_ok(not got_power[0], "unknown district in remote power event is rejected")
	LANNetwork.rpc_power_changed(&"suburbs", true)
	_ok(got_power[0], "a valid remote power event still gets through")
	EventBus.remote_power_changed.disconnect(power_listener)

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

## SECURITY_PATCH_SPEC P-06/C-02: slots used to share one HMAC key with no
## slot identity in the signed body, so a validly-signed save copied from
## slot B over slot A's file loaded cleanly AS slot A - a silent
## profile-swap with no corruption signal at all. slot_id is now part of
## the signed payload; load_slot() rejects a file whose slot_id doesn't
## match. This intentionally changes the old test's own expectation
## (renamed from _check_cross_save_swap_no_corruption): slot identity is
## now a real boundary, not a documented "drag files to swap saves"
## feature - there is no player-facing UI for that today (the slot picker
## is archived per KNOWN_ISSUES.md), so nothing currently promises it.
func _check_cross_save_swap_rejected() -> void:
	var slot_a := _SLOT
	var slot_b := _SLOT + 1
	CoinWallet.from_dict({}); CoinWallet.add(111)
	SaveSystem.save_slot(slot_a)
	CoinWallet.from_dict({}); CoinWallet.add(222)
	SaveSystem.save_slot(slot_b)
	var path_a := "user://tls_savegame_slot%d.save" % slot_a
	var path_b := "user://tls_savegame_slot%d.save" % slot_b
	DirAccess.copy_absolute(path_b, path_a)  # foreign (but validly signed) file dropped into slot A
	CoinWallet.from_dict({}); CoinWallet.add(111)  # restore A's pre-load wallet state to check against
	var loaded := SaveSystem.load_slot(slot_a)
	_ok(not loaded and CoinWallet.get_coins() == 111,
		"a validly-signed save from another slot is rejected by slot_id, not silently adopted as this slot (loaded=%s coins=%d)" % [loaded, CoinWallet.get_coins()])
	_ok(SaveSystem.load_slot(slot_b), "slot B still loads fine under its own, correct slot_id")
	for suffix in ["", ".bak", ".bak2", ".bak3"]:
		for p in [path_a + suffix, path_b + suffix]:
			if FileAccess.file_exists(p):
				DirAccess.remove_absolute(p)
	CoinWallet.from_dict({})

## BREAK_REPORT B5: wipe_all_saves() (the real "Reset Progress" action)
## deleted the main save + all slots and called reset_all(), but never
## touched NewGamePlus's own separate save file at all - an earned NG+
## level survived a player asking for a genuinely fresh start. Backs up
## and restores SAVE_PATH/.bak around the call since wipe_all_saves()
## operates on the real main save path, not a scratch slot like every
## other check in this file (MAX_SLOTS=4, so the 96/97 scratch slots
## other checks use are outside its per-slot delete loop and unaffected).
func _check_reset_progress_clears_ng_plus() -> void:
	var main_path := "user://tls_savegame.save"
	var backups: Dictionary = {}
	for p in [main_path, main_path + ".bak"]:
		if FileAccess.file_exists(p):
			var bf := FileAccess.open(p, FileAccess.READ)
			backups[p] = bf.get_as_text()
			bf.close()
	var ngp_path := "user://ng_plus_data.json"
	var had_ngp := FileAccess.file_exists(ngp_path)
	var ngp_backup := ""
	if had_ngp:
		var nf := FileAccess.open(ngp_path, FileAccess.READ)
		ngp_backup = nf.get_as_text()
		nf.close()
	_write_ngp_test_file({"ng_plus": 2, "active": true, "modifiers": ["ghost"]})
	NewGamePlus._load_save()
	SaveSystem.wipe_all_saves()
	_ok(NewGamePlus.get_current_ng_plus() == 0 and not FileAccess.file_exists(ngp_path),
		"Reset Progress clears NewGamePlus's own save file, not just SaveSystem's")
	for p in backups:
		var wf := FileAccess.open(p, FileAccess.WRITE)
		wf.store_string(backups[p])
		wf.close()
	if had_ngp:
		var wf2 := FileAccess.open(ngp_path, FileAccess.WRITE)
		wf2.store_string(ngp_backup)
		wf2.close()
	NewGamePlus._load_save()

## SECURITY_SWEEP_V2 #2: a release build without an AppLovin key must get no
## provider (offers hide themselves); the claim stub is debug-only.
func _check_release_has_no_ad_stub() -> void:
	var release: Object = AdService._default_provider(false)
	var debug: Object = AdService._default_provider(true)
	_ok(OS.has_feature("mobile") or OS.has_feature("web") or (release == null and debug != null),
		"release build gets no ad provider, debug keeps the stub (release=%s)" % [release])

## SECURITY_SWEEP_V2 #5: tampered signed leaderboard rejected; a legacy plain
## file keeps only well-formed entries and is re-saved signed.
func _check_leaderboard_signed_and_validated() -> void:
	var path: String = LocalLeaderboard.PATH
	var had := FileAccess.file_exists(path)
	var backup := FileAccess.get_file_as_string(path) if had else ""
	var runs_before: Array = LocalLeaderboard._runs.duplicate(true)
	var good := {"time": 100.0, "kills": 3, "districts": 11, "ending": "light", "unix": 1.0}
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify([good, "junk", {"time": "fast", "kills": 1, "districts": 1, "unix": 1.0}]))
	f.close()
	LocalLeaderboard._runs = []
	LocalLeaderboard._load()
	var migrated: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_ok(LocalLeaderboard._runs.size() == 1 and migrated is Dictionary and migrated.has("hmac"),
		"legacy leaderboard keeps only well-formed entries and is re-saved signed (%d kept)" % LocalLeaderboard._runs.size())
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"hmac": "0000deadbeef0000", "data_json": JSON.stringify([good, good])}))
	f.close()
	LocalLeaderboard._runs = []
	LocalLeaderboard._load()
	_ok(LocalLeaderboard._runs.is_empty(), "tampered signed leaderboard is rejected")
	if had:
		var wf := FileAccess.open(path, FileAccess.WRITE)
		wf.store_string(backup)
		wf.close()
	else:
		DirAccess.remove_absolute(path)
	LocalLeaderboard._runs = runs_before

func _cleanup() -> void:
	CoinWallet.from_dict({})
