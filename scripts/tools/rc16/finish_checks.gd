extends RefCounted
## rc16 FINISH closeout checks: the two player-visible defects the S8 frame read found in rc15 (docs/KNOWN_ISSUES.md).
## Wired into _closeout_check_runner.gd as `await Rc16Finish.run(self)`.

## The Screens card fades in over 0.18 s; the layout is settled well before.
const SETTLE_SEC: float = 0.4
const TEXT_SIZES: Array[int] = [0, 1, 2]
## A rect edge may be off by half a pixel after the container rounds.
const EDGE_PX: float = 0.5
const MAX_LISTED: int = 6

static func run(r: Node) -> void:
	r._playing()
	var lang0: String = LocalizationManager.current_lang
	var size0: int = int(SettingsManager.get_setting("text_size", 1))
	await _skill_tree_close(r)
	await _shop_buy_buttons(r)
	LocalizationManager.set_language(lang0)
	SettingsManager.set_text_size(size0)

## CLOSE1: the skill tree's Close button is the BTN_CLOSE string of the language, at the first open and after every live switch.
## It stayed the scene's English "Close" in the 12 other languages.
static func _skill_tree_close(r: Node) -> void:
	LocalizationManager.set_language("en")
	UIManager.open(&"skill_tree")
	await r.get_tree().process_frame
	var screen: Control = UIManager._get_screen(&"skill_tree")
	var button: Button = screen.find_child("CloseButton", true, false) as Button if screen != null else null
	if button == null:
		r._ok(false, "CLOSE1 the skill tree opens and has a CloseButton")
		return
	var wrong: Array[String] = []
	for lang: String in LocalizationManager.SUPPORTED:
		LocalizationManager.set_language(lang)
		await r.get_tree().process_frame
		if button.text != LocalizationManager.t("BTN_CLOSE") or (lang != "en" and button.text == "Close"):
			wrong.append("%s=%s" % [lang, button.text])
	UIManager.close(&"skill_tree")
	r._ok(wrong.is_empty(), "CLOSE1 the skill tree's Close button follows the language in all %d (wrong: %s)" % [LocalizationManager.SUPPORTED.size(), wrong])

## SHOP1: in every language and at every text size each Buy button lies inside its card and inside the grid. The button asks for 20 px,
## a Button cannot be smaller than its theme minimum (about 40), and the card was 80 px: the button reached the next row and the
## last row was cut by the scroll area. TEXT1 keeps the case honest: the text size reaches the button, so the three sizes are three layouts.
static func _shop_buy_buttons(r: Node) -> void:
	var screens: Node = r._main.get_node_or_null("Screens")
	if screens == null:
		r._ok(false, "SHOP1 the main scene has a Screens node")
		return
	var outside: Array[String] = []
	var empty: Array[String] = []
	var cases: int = 0
	var min_heights: Array[float] = [0.0, 0.0, 0.0]
	for lang: String in LocalizationManager.SUPPORTED:
		LocalizationManager.set_language(lang)
		for size_idx: int in TEXT_SIZES:
			SettingsManager.set_text_size(size_idx)
			screens.call("show_screen", "Shop")
			await r.get_tree().create_timer(SETTLE_SEC).timeout
			cases += 1
			var tag: String = "%s/%d" % [lang, size_idx]
			var grid: Control = screens.find_child("ShopGrid", true, false) as Control
			if grid == null or grid.get_child_count() == 0:
				empty.append(tag)
				continue
			if lang == "en":
				min_heights[size_idx] = _button_min_height(grid)
			if _button_outside(grid):
				outside.append(tag)
	screens.call("hide_all")
	r._ok(empty.is_empty() and outside.is_empty(),
		"SHOP1 every Buy button is inside its card and the grid, %d languages x %d text sizes (%d cases; no cards: %s; outside: %s)"
		% [LocalizationManager.SUPPORTED.size(), TEXT_SIZES.size(), cases, empty.slice(0, MAX_LISTED), outside.slice(0, MAX_LISTED)])
	r._ok(min_heights[0] < min_heights[1] and min_heights[1] < min_heights[2],
		"TEXT1 the text size reaches the Buy button: its minimum height grows with it (%s px)" % [min_heights])

static func _button_min_height(grid: Control) -> float:
	for card: Node in grid.get_children():
		for child: Node in card.get_children():
			if child is Button:
				return (child as Button).get_combined_minimum_size().y
	return 0.0

static func _button_outside(grid: Control) -> bool:
	var grid_rect: Rect2 = grid.get_global_rect().grow(EDGE_PX)
	for card_node: Node in grid.get_children():
		var card: Control = card_node as Control
		if card == null:
			continue
		var card_rect: Rect2 = card.get_global_rect().grow(EDGE_PX)
		for child: Node in card.get_children():
			var button: Button = child as Button
			if button != null and not (card_rect.encloses(button.get_global_rect()) and grid_rect.encloses(button.get_global_rect())):
				return true
	return false
