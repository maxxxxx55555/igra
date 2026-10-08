extends RefCounted
## rc16 FINISH closeout checks: the two player-visible defects the S8 frame read found in rc15 (docs/KNOWN_ISSUES.md).
## Wired into _closeout_check_runner.gd as `await Rc16Finish.run(self)`; CLOSEOUT_ONLY=finish runs only these (a windowed run also writes the two frames).

## The Screens card fades in over 0.18 s and the skill tree slides in; the layout is settled well before.
const SETTLE_SEC: float = 0.4
const TEXT_SIZES: Array[int] = [0, 1, 2]
## A rect edge may be off by half a pixel after the container rounds.
const EDGE_PX: float = 0.5
const MAX_LISTED: int = 6
## Raw frames of a windowed run; tools/qa_sim/stamp_frames.py gives them their AF3 names (docs/stills/rc16_f1/).
const FRAME_DIR: String = "res://docs/stills/rc16_f1_raw"
## The frames show the screens in the language of the rc15 frames, where the defects were found.
const FRAME_LANG: String = "ru"

static func run(r: Node) -> void:
	r._playing()
	var lang0: String = LocalizationManager.current_lang
	var size0: int = int(SettingsManager.get_setting("text_size", 1))
	await _skill_tree_close(r)
	await _shop_buy_buttons(r)
	LocalizationManager.set_language(lang0)
	SettingsManager.set_text_size(size0)

static func _frame(r: Node, frame_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var dir: String = ProjectSettings.globalize_path(FRAME_DIR)
	DirAccess.make_dir_recursive_absolute(dir)
	await RenderingServer.frame_post_draw
	r.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, frame_name])

## CLOSE1: the skill tree's Close button is the BTN_CLOSE string of the language, at the first open and after every live switch.
## It stayed the scene's English "Close" in the 12 other languages.
static func _skill_tree_close(r: Node) -> void:
	LocalizationManager.set_language(FRAME_LANG)
	UIManager.open(&"skill_tree")
	await r.get_tree().create_timer(SETTLE_SEC).timeout
	var screen: Control = UIManager._get_screen(&"skill_tree")
	var button: Button = screen.find_child("CloseButton", true, false) as Button if screen != null else null
	if button == null:
		r._ok(false, "CLOSE1 the skill tree opens and has a CloseButton")
		return
	await _frame(r, "A09_skill_tree")
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
## last row was cut by the scroll area. The text size is a window-wide scale factor (GDD 14, SettingsManager), so the three sizes may give the
## same geometry in logical pixels; the message reports the grid width per size in English instead of assuming they differ.
static func _shop_buy_buttons(r: Node) -> void:
	var screens: Node = r._main.get_node_or_null("Screens")
	if screens == null:
		r._ok(false, "SHOP1 the main scene has a Screens node")
		return
	var outside: Array[String] = []
	var empty: Array[String] = []
	var first_outside: String = ""
	var cases: int = 0
	var grid_widths: Array[float] = []
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
				grid_widths.append(grid.size.x)
			if lang == FRAME_LANG and size_idx == 1:
				await _frame(r, "A06_shop")
			if lang == "ar" and size_idx == 1:
				await _frame(r, "A06_shop_ar")
			var where: String = _button_outside(grid)
			if where != "":
				outside.append(tag)
				first_outside = first_outside if first_outside != "" else "%s: %s" % [tag, where]
	screens.call("hide_all")
	r._ok(cases > 0 and empty.is_empty() and outside.is_empty(),
		"SHOP1 every Buy button is inside its card and the grid, %d languages x %d text sizes (%d cases; no cards: %s; outside: %s; first outside: %s; English grid width at the three text sizes %s px)"
		% [LocalizationManager.SUPPORTED.size(), TEXT_SIZES.size(), cases, empty.slice(0, MAX_LISTED), outside.slice(0, MAX_LISTED), first_outside, grid_widths])

## "" when every Buy button lies inside its card and the grid, else the rects of the first one that does not.
static func _button_outside(grid: Control) -> String:
	var grid_rect: Rect2 = grid.get_global_rect().grow(EDGE_PX)
	for card_node: Node in grid.get_children():
		var card: Control = card_node as Control
		if card == null:
			continue
		var card_rect: Rect2 = card.get_global_rect().grow(EDGE_PX)
		for child: Node in card.get_children():
			var button: Button = child as Button
			if button != null and not (card_rect.encloses(button.get_global_rect()) and grid_rect.encloses(button.get_global_rect())):
				return "button %s '%s' minimum %s, card %s, grid %s" % [button.get_global_rect(), button.text, button.get_combined_minimum_size(), card_rect, grid_rect]
	return ""
