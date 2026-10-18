extends RefCounted
## The two hooks of W1 that the retention runner (scripts/tools/_retention_runner.gd) adds after its seven: a secret and an ending. Each is driven through the entry that the game itself uses and judged by what it leaves behind.
##   secret  a secret of the district (the node that DistrictLoot builds from content/secrets.json), taken through interact(): the coins of REWARD_SECRET, the XP, the count of the tracker, the photo and the two notices
##           are there once, the node is gone, and a district built again does not place it again
##   ending  a win (GameManager.trigger_win): the win screen shows the title of the ending that the run earned, in the language of the player, and its "One More Run" button opens the New Game+ screen
## Frames -> docs/stills/retention/09_codex_photos and 10_win_ending.

static func run(r: Node) -> void:
	await _secret(r)
	await _ending(r)

static func _secret(r: Node) -> void:
	var root := Node3D.new()
	r.add_child(root)
	var placed: int = DistrictLoot._spawn_secrets(root, &"suburbs")
	if placed == 0:
		r._hook("secret", false, "the suburbs place no secret")
		root.free()
		return
	var node: Node = root.get_child(0)
	var id: String = String(node.get("secret_id"))
	var coins0: int = CoinWallet.get_coins()
	var found0: int = ProgressTracker.secrets
	var photos0: int = SaveSystem.get_photo_count()
	var xp: Array[int] = []
	var toasts: Array[String] = []
	var on_xp := func(amount: int) -> void: xp.append(amount)
	var on_toast := func(text: String, _kind: String) -> void: toasts.append(text)
	r._heard.clear()
	XpManager.xp_gained.connect(on_xp)
	EventBus.toast_requested.connect(on_toast)
	EventBus.inventory_notice.connect(r._listen)
	node.call("interact")
	await r.get_tree().create_timer(0.6).timeout
	XpManager.xp_gained.disconnect(on_xp)
	EventBus.toast_requested.disconnect(on_toast)
	EventBus.inventory_notice.disconnect(r._listen)
	var gone: bool = not is_instance_valid(node)
	var again := Node3D.new()
	r.add_child(again)
	var placed_again: int = DistrictLoot._spawn_secrets(again, &"suburbs")
	again.free()
	root.free()
	var pay: int = int(RewardsManager.REWARD_SECRET * NewGamePlus.get_modifier_multiplier("rewards"))
	var coins: int = CoinWallet.get_coins() - coins0
	var toasted: bool = toasts.any(func(text: String) -> bool: return text.begins_with(LocalizationManager.t("SECRET_FOUND")))
	var paid: bool = (r._heard as Array).has(LocalizationManager.tf("REWARD_SECRET", [pay]))
	var photos: int = SaveSystem.get_photo_count()
	await r._open_tab(&"photos")
	await r._snap("09_codex_photos")
	await r._close_codex()
	var ok: bool = gone and ProgressTracker.is_secret_found(id) and ProgressTracker.secrets == found0 + 1 and coins >= pay and xp.size() >= 1 and xp.max() >= 75 and photos > photos0 and placed_again == placed - 1 and toasted and paid
	r._hook("secret", ok, "%s: node gone %s, coins +%d (the secret pays %d, notice %s; the document it unlocks and the achievements pay more), xp %s, found %d -> %d, photos %d -> %d, toast %s, placed %d then %d" % [id, gone, coins, pay, paid, xp, found0, ProgressTracker.secrets, photos0, photos, toasted, placed, placed_again])

## The win screen is set again when it is shown again, not when the language changes under it (the player cannot change it there); closing fades it out, and an open during the fade keeps it as it was.
static func _reopen(r: Node) -> void:
	UIManager.close(&"win")
	await r.get_tree().create_timer(0.6).timeout
	UIManager.open(&"win")
	await r.get_tree().create_timer(0.6).timeout

static func _ending(r: Node) -> void:
	GameManager.trigger_win()
	await r.get_tree().create_timer(2.5).timeout
	var cache: Dictionary = UIManager.get("_cache") as Dictionary
	var screen: Control = cache.get(&"win", null) as Control
	if screen == null or not screen.is_visible_in_tree():
		r._hook("ending", false, "the win screen is not shown (built %s)" % [screen != null])
		return
	var data: Dictionary = EndingsManager.get_ending_data()
	var en: Array[String] = r._labels(screen)
	LocalizationManager.set_language("ru")
	await _reopen(r)
	var ru: Array[String] = r._labels(cache.get(&"win", null) as Control)
	LocalizationManager.set_language("en")
	await _reopen(r)
	screen = cache.get(&"win", null) as Control
	await r._snap("10_win_ending")
	var opened: bool = false
	for node: Node in screen.find_children("*", "Button", true, false):
		var more := node as Button
		if more.text == LocalizationManager.t("NGP_SETUP_ACTION"):
			more.pressed.emit()
			await r.get_tree().create_timer(0.7).timeout
			var ng: Control = cache.get(&"new_game_plus", null) as Control
			opened = ng != null and ng.is_visible_in_tree()
			UIManager.close(&"new_game_plus")
			break
	var title: String = String(data.get("title", ""))
	r._hook("ending", title != "" and en.has(title) and not ru.has(title) and opened, "ending %s, title [%s] shown %s, the Russian page differs %s, One More Run opens the New Game+ screen %s" % [EndingsManager.get_ending(), title, en.has(title), not ru.has(title), opened])
