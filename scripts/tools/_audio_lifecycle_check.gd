extends Node
## Terminal music must release ownership when the player returns to the menu.

var _fails: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	(MusicManager as Node).set_process(false)
	_check_notice_before_input()
	_ok(not MusicManager._active.playing, "menu music waits for the first real input")
	MusicManager._unlock_audio()
	await _check_licensed_music()
	_check_notice_feedback()
	_check_physical_pickup()
	_check_pointer_feedback()
	GameManager._change_state(GameManager.GameState.WIN)
	MusicManager._on_game_won()
	_ok(MusicManager.mood == MusicDirector.Mood.VICTORY, "victory starts its musical state")
	_ok(MusicManager._wow_cue.playing, "victory starts its one-shot cue")
	GameManager.return_to_menu()
	MusicManager._evaluate()
	_ok(MusicManager.mood == MusicDirector.Mood.MENU, "return from victory resumes menu music")
	_ok(MusicManager._active.stream.resource_path == MusicManager.TRACKS[MusicDirector.Mood.MENU], "menu uses its own theme after victory")
	_ok(not MusicManager._wow_cue.playing, "victory cue cannot overlap the menu theme")
	GameManager._change_state(GameManager.GameState.WIN)
	MusicManager._on_game_won()
	MusicManager._on_game_started()
	_ok(not MusicManager._wow_cue.playing, "victory cue cannot overlap a new run")
	_ok(MusicManager.mood == MusicDirector.Mood.AMBIENT, "new run resumes district ambience")
	MusicManager._collect_preloads(true)
	await get_tree().process_frame
	print("[audio-lifecycle] DONE fails=%d" % _fails)
	get_tree().quit(0 if _fails == 0 else 1)

func _check_notice_before_input() -> void:
	var before: int = UISFX.get_child_count()
	EventBus.inventory_notice.emit("Found ammunition")
	_ok(UISFX.get_child_count() == before, "notice remains silent before the first input")

func _check_licensed_music() -> void:
	_ok(MusicManager._active.playing and MusicManager._active.bus == &"Music" and MusicManager._active.stream.resource_path.ends_with("scott_buckley_hymn.ogg"),
		"first input starts the credited Hymn recording on Music")
	var kept: Dictionary = PowerGrid.to_dict().duplicate(true)
	var district: StringName = MusicManager._current_district
	PowerGrid.get_district(&"suburbs").stage = DistrictData.Stage.STREETS
	MusicManager._on_district_entered(&"suburbs")
	MusicManager.set_mood(MusicDirector.Mood.AMBIENT, true, true)
	_ok(MusicManager._active.playing and MusicManager._active.bus == &"Music" and MusicManager._active.stream.resource_path.ends_with("scott_buckley_moonlight.ogg"),
		"restored calm exploration plays the credited Moonlight recording")
	PowerGrid.get_district(&"suburbs").stage = DistrictData.Stage.DARK
	MusicManager._on_district_stage_changed(&"suburbs", DistrictData.Stage.DARK)
	_ok(MusicManager._active.stream.resource_path.ends_with("suburbs_dark.ogg"), "unpowered exploration retains its district-specific dark signature")
	PowerGrid.from_dict(kept)
	MusicManager._on_district_entered(district)
	MusicManager.set_mood(MusicDirector.Mood.MENU, true, true)
	var lang: String = LocalizationManager.current_lang
	for code: String in LocalizationManager.SUPPORTED:
		LocalizationManager.set_language(code)
		var credits: Control = (load("res://scenes/ui/credits.tscn") as PackedScene).instantiate() as Control
		add_child(credits)
		await get_tree().process_frame
		await get_tree().process_frame
		var text: String = ""
		var wrapped: bool = true
		for label: Label in credits.find_children("*", "Label", true, false):
			text += label.text + "\n"
			if label.text.contains("Scott Buckley"):
				wrapped = wrapped and label.autowrap_mode != TextServer.AUTOWRAP_OFF and label.get_global_rect().end.x <= get_viewport().get_visible_rect().end.x
		_ok(text.contains("Hymn") and text.contains("Moonlight") and text.contains("Scott Buckley") and text.contains("creativecommons.org/licenses/by/4.0/") and text.contains("scottbuckley.com.au/library/") and text.contains("Changes:") and text.contains("Lyria") and wrapped,
			"credits retain AI disclosure and wrapped artist, titles, source, licence and changes: " + code)
		credits.free()
	LocalizationManager.set_language(lang)

func _check_notice_feedback() -> void:
	for message: String in ["Found ammunition", "Rested", "Checkpoint saved"]:
		_clear_feedback()
		EventBus.inventory_notice.emit(message)
		_ok(_ui_players().is_empty() and _pool_players() == 0, "text notice adds no error or generic beep: " + message)
	_clear_feedback()
	EventBus.purchase_failed.emit("fixture_item", "not_enough_coins")
	_ok(_ui_players().size() == 1 and _pool_players() == 0, "explicit purchase rejection has one UI owner")
	_clear_feedback()
	var balance: int = CoinWallet.coins
	CoinWallet.coins = 0
	CoinWallet.try_spend(1)
	CoinWallet.coins = balance
	var errors: int = 0
	for player: AudioStreamPlayer in _ui_players():
		if player.stream.resource_path.ends_with("ui_error.wav"):
			errors += 1
	_ok(errors == 1 and _ui_players().size() == 1, "wallet rejection retains exactly one explicit error cue")
	_clear_feedback()

func _check_physical_pickup() -> void:
	_clear_feedback()
	var kept: Dictionary = InventoryManager.to_dict().duplicate(true)
	InventoryManager.from_dict({"slots": []})
	var pickup: ItemPickup3D = (load("res://scenes/pickups/item_pickup_3d.tscn") as PackedScene).instantiate() as ItemPickup3D
	pickup.item_id = &"battery"
	add_child(pickup)
	var body := Node3D.new()
	body.add_to_group("player")
	add_child(body)
	pickup.call("_on_body_entered", body)
	var clips: int = 0
	for player: AudioStreamPlayer3D in AudioManager.get("_pool_3d"):
		if player.playing and player.bus == &"UI" and player.stream.resource_path.ends_with("loot_pickup_generic.wav"):
			clips += 1
	_ok(pickup.get("_picked_up") and clips == 1, "physical pickup plays its existing action-specific loot clip")
	_ok(_pool_players() == 0 and _ui_players().is_empty(), "physical pickup adds no generic two-note blip or notice beep")
	InventoryManager.from_dict(kept)
	pickup.free()
	body.free()
	for player: AudioStreamPlayer3D in AudioManager.get("_pool_3d"):
		player.stop()
	_clear_feedback()

func _check_pointer_feedback() -> void:
	UISFX.hover()
	_ok(_ui_players().is_empty(), "pointer hover remains visual without repetitive audio")
	_clear_feedback()
	UISFX.click()
	var players: Array[AudioStreamPlayer] = _ui_players()
	_ok(players.size() == 1 and players[0].bus == &"UI" and players[0].stream.resource_path.ends_with("ui_menu_click.ogg"),
		"activation retains the existing mechanical UI clip")
	_clear_feedback()

func _ui_players() -> Array[AudioStreamPlayer]:
	var players: Array[AudioStreamPlayer] = []
	for child: Node in UISFX.get_children():
		if child is AudioStreamPlayer and (child as AudioStreamPlayer).playing:
			players.append(child as AudioStreamPlayer)
	return players

func _pool_players() -> int:
	var count: int = 0
	for player: AudioStreamPlayer in AudioManager.get("_pool"):
		count += 1 if player.playing else 0
	return count

func _clear_feedback() -> void:
	for player: AudioStreamPlayer in _ui_players():
		player.stop()
		player.free()
	for player: AudioStreamPlayer in AudioManager.get("_pool"):
		player.stop()

func _ok(condition: bool, label: String) -> void:
	if not condition:
		_fails += 1
	print("[audio-lifecycle] %s %s" % ["OK" if condition else "FAIL", label])
