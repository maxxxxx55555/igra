extends Control
## Main menu with localized actions and a clear street-art backdrop.

const _LAYOUT := preload("res://scripts/ui/main_menu_layout.gd")
const _STENCIL := preload("res://assets/shaders/stencil_title.gdshader")

## Кнопка -> ключ перевода.
const LABELS: Dictionary = {
	"Continue": "continue",
	"Play": "menu_play",
	"Settings": "settings",
	"Difficulty": "difficulty",
	"Credits": "credits",
	"Quit": "menu_quit",
}

func _ready() -> void:
	# THEME UNIFICATION P0: was the only screen with no local theme override
	# at all - ThemeSetup's window-wide default doesn't reliably propagate
	# to Controls added after boot in this engine build (Control-to-Control
	# inheritance does; Window.theme does not - confirmed via probe), so
	# this screen silently rendered with zero chrome. Every other screen in
	# the project already opts in exactly like this.
	theme = ThemeProvider.build_theme()
	var vb: Node = get_node_or_null("VBox")
	if vb == null:
		return
	_install_background()
	_style_title(vb as VBoxContainer)
	_start_flicker()
	_ensure_continue(vb as VBoxContainer)
	_install_daily_card(vb as VBoxContainer)
	_LAYOUT.install(self, vb as VBoxContainer)
	resized.connect(_layout_menu)
	_connect(vb, "Continue", func() -> void:
		# continue_game() поднимает состояние автолоадов; сцену открываем сами.
		GameManager.continue_game()
		if GameManager.is_playing():
			Routes.goto(Routes.GAME))
	_connect(vb, "Play", _on_play_pressed)
	_connect(vb, "Settings", func() -> void: Routes.goto(Routes.SETTINGS))
	_connect(vb, "Difficulty", func() -> void: Routes.goto(Routes.DIFFICULTY))
	_connect(vb, "Credits", func() -> void: Routes.goto(Routes.CREDITS))
	_connect(vb, "Quit", func() -> void: Routes.goto("res://scenes/ui/confirm_quit.tscn"))
	_apply_localization()
	LocalizationManager.language_changed.connect(_apply_localization)
	# Возвращаем игру в состояние MENU (иначе после боя курсор остаётся
	# захваченным и по меню нечем кликать), но только если это ещё не сделано:
	# return_to_menu() дергает close_all_blocking() и шлёт game_state_changed.
	if not GameManager.is_menu():
		GameManager.return_to_menu()
	else:
		InputService.refresh_mouse_mode()

## T14: живой параллакс-фон (NIGHT/DAY/GENERATOR) между BG и Flicker.
func _install_background() -> void:
	if get_node_or_null("MenuBackground") != null:
		return
	var bg_script := load("res://scripts/ui/menu_background.gd")
	var bg := Control.new()
	bg.name = "MenuBackground"
	bg.set_script(bg_script)
	add_child(bg)
	var bg_flat := get_node_or_null("BG")
	move_child(bg, (bg_flat.get_index() + 1) if bg_flat else 0)
	_install_hero_bg_v2(bg)

## A restrained warm tint keeps the street artwork inside the night palette.
const HERO_TINT := Color(0.93, 0.91, 0.86)

## Hero art sits above the procedural backdrop and beneath the menu controls.
func _install_hero_bg_v2(after: Node) -> void:
	var path := "res://assets/ui/menu_city.png"
	if get_node_or_null("MenuHeroV2") != null or not ResourceLoader.exists(path):
		return
	var hero := TextureRect.new()
	hero.name = "MenuHeroV2"
	hero.texture = load(path)
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero.modulate = HERO_TINT
	preload("res://scripts/ui/menu_parallax.gd").attach(self, hero)  # B9: the backdrop drifts with the pointer
	hero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	move_child(hero, (after.get_index() + 1) if after else 0)

## A dark outline keeps the stencilled title readable over bright artwork.
func _style_title(vb: VBoxContainer) -> void:
	var title := vb.get_node_or_null("Title") as Label if vb != null else null
	if title == null:
		return
	# A CRLF checkout turns the scene's two-line title into CR+LF, which the Label
	# draws as two line breaks: a blank line between the words.
	title.text = title.text.replace("\r", "")
	title.add_theme_color_override("font_outline_color", Color(0.0235294, 0.0588235, 0.0745098))
	title.add_theme_font_override("font", ThemeProvider.wordmark_font())
	title.add_theme_constant_override("outline_size", 2)
	# V2 of Session 27: the title card is stencilled, one cut across the letters and their outline (assets/shaders/stencil_title.gdshader)
	var stencil := ShaderMaterial.new()
	stencil.shader = _STENCIL
	title.material = stencil
	title.resized.connect(func() -> void: stencil.set_shader_parameter("label_h", title.size.y))

## Restrained irregular lamp flicker preserves the scene's warm lighting cue.
func _start_flicker() -> void:
	var f: ColorRect = get_node_or_null("Flicker")
	if f == null:
		return
	f.color.a = 0.04
	_flicker_step(f)

func _flicker_step(f: ColorRect) -> void:
	if not is_instance_valid(f):
		return
	var tw := create_tween()
	tw.tween_property(f, "color:a", randf_range(0.02, 0.07), randf_range(0.15, 0.6))
	tw.tween_callback(_flicker_step.bind(f))

## «Продолжить» показываем только при наличии сохранения.
func _ensure_continue(vb: VBoxContainer) -> void:
	if vb.get_node_or_null("Continue") != null:
		return
	if not SaveSystem.has_method("has_save") or not SaveSystem.has_save():
		return
	var b := Button.new()
	b.name = "Continue"
	b.custom_minimum_size = Vector2(0, 52)  # same row height as the scene's buttons
	vb.add_child(b)
	vb.move_child(b, 1)

## GOLD MASTER v5 hooks pass: today's daily challenge + streak, a small
## card near the top of the menu — the return-tomorrow hook.
const _DAILY_TEXT_KEYS: Dictionary = {
	"kill_enemies": "DAILY_KILL_ENEMIES", "find_secrets": "DAILY_FIND_SECRETS",
	"light_streets": "DAILY_LIGHT_STREETS", "restore_districts": "DAILY_RESTORE_DISTRICTS",
	"play_minutes": "DAILY_PLAY_MINUTES", "photo_subject": "DAILY_PHOTO_SUBJECT",
	"no_flashlight_segment": "DAILY_NO_FLASHLIGHT_SEGMENT",
}
## A thin outline keeps the small print legible over the artwork.
func _legible(line: Label) -> void:
	line.add_theme_color_override("font_outline_color", Color(0.0235294, 0.0588235, 0.0745098))
	line.add_theme_constant_override("outline_size", 2)

func _install_daily_card(vb: VBoxContainer) -> void:
	if vb.get_node_or_null("DailyCard") == null:
		var card := VBoxContainer.new()
		card.name = "DailyCard"
		card.add_theme_constant_override("separation", 2)
		card.draw.connect(func() -> void:
			card.draw_rect(Rect2(Vector2.ZERO, card.size), Color(ThemeProvider.COLOR_BG_DARK, 0.6))
			card.draw_rect(Rect2(Vector2.ZERO, card.size), ThemeProvider.COLOR_BORDER, false, 1.0))
		vb.add_child(card)
		vb.move_child(card, 1)
		var title := Label.new()
		title.name = "Title"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
		card.add_child(title)
		var body := Label.new()
		body.name = "Body"
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
		card.add_child(body)
		var streak := Label.new()
		streak.name = "Streak"
		streak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		streak.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
		card.add_child(streak)
		for line: Label in [title, body, streak]:
			_legible(line)
			var inset := StyleBoxEmpty.new()
			inset.content_margin_left = 12.0
			inset.content_margin_right = 12.0
			inset.content_margin_top = 6.0 if line == title else 0.0
			inset.content_margin_bottom = 6.0 if line == streak else 0.0
			line.add_theme_stylebox_override(&"normal", inset)
		title.add_theme_font_override(&"font", ThemeProvider.heading_font())
	_refresh_daily_card(vb)

func _refresh_daily_card(vb: VBoxContainer) -> void:
	var card := vb.get_node_or_null("DailyCard")
	if card == null or DailyChallengeManager == null:
		return
	var t: Dictionary = DailyChallengeManager.get_today()
	if t.is_empty():
		card.visible = false
		return
	card.visible = true
	var text_key: String = _DAILY_TEXT_KEYS.get(String(t.get("type", "")), "")
	(card.get_node("Title") as Label).text = LocalizationManager.t("DAILY_CHALLENGE_TITLE")
	var target := int(t.get("target", 0))
	var desc := LocalizationManager.tf(text_key, [target]) if text_key != "" else ""
	var progress := DailyChallengeManager.get_progress()
	var done := DailyChallengeManager.is_completed_today()
	(card.get_node("Body") as Label).text = "%s  (%d/%d)%s" % [
		desc, mini(progress, target), target,
		("  " + LocalizationManager.t("DAILY_COMPLETED_LABEL")) if done else ""]
	var streak: int = SaveSystem.get_daily_streak() if SaveSystem != null else 0
	(card.get_node("Streak") as Label).text = LocalizationManager.tf("DAILY_STREAK_LABEL", [streak, DailyChallengeManager.streak_multiplier(streak)])

func _connect(vb: Node, node_name: String, cb: Callable) -> void:
	var b := vb.get_node_or_null(node_name) as Button
	if b == null:
		return
	b.focus_mode = Control.FOCUS_ALL
	if not b.pressed.is_connected(cb):
		b.pressed.connect(cb)
	if not b.pressed.is_connected(UISFX.click):
		b.pressed.connect(UISFX.click)
	if not b.pressed.is_connected(UISFX.press_pulse):
		b.pressed.connect(UISFX.press_pulse.bind(b))
	if not b.mouse_entered.is_connected(UISFX.hover):
		b.mouse_entered.connect(UISFX.hover)

## arena design audit P3: "Play" reset run progress with zero warning, and
## with no indication a just-activated NG+ level was about to start. Confirm
## before the irreversible reset (only when there's a save to lose); the NG+
## suffix on the button itself is handled in _apply_localization() below.
func _on_play_pressed() -> void:
	if not SaveSystem.has_save():
		Routes.start_game()
		return
	var ng := NewGamePlus.get_current_ng_plus()
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = LocalizationManager.tf("NGP_NEW_GAME_CONFIRM_BODY", [ng]) if ng > 0 \
		else LocalizationManager.t("NGP_NEW_GAME_CONFIRM_BODY_BASE")
	dlg.get_ok_button().text = LocalizationManager.t("NGP_NEW_GAME_CONFIRM_START")
	dlg.get_cancel_button().text = LocalizationManager.t("NGP_NEW_GAME_CONFIRM_KEEP")
	dlg.confirmed.connect(Routes.start_game)
	dlg.confirmed.connect(dlg.queue_free)
	dlg.canceled.connect(dlg.queue_free)
	add_child(dlg)
	dlg.popup_centered()

func _apply_localization(_lang: Variant = null) -> void:
	var vb: Node = get_node_or_null("VBox")
	if vb == null:
		return
	var title := vb.get_node_or_null("Title") as Label
	if title != null:
		title.text = LocalizationManager.t("menu_title").to_upper()  # v10 N083: Bebas has no lower case; the other five titles are in capitals
	for node_name in LABELS:
		var b := vb.get_node_or_null(String(node_name)) as Button
		if b != null:
			b.text = LocalizationManager.t(String(LABELS[node_name]))
	_apply_ngp_status(vb)
	_refresh_daily_card(vb as VBoxContainer)
	_layout_menu.call_deferred()

func _layout_menu() -> void:
	var column := get_node_or_null("VBox") as VBoxContainer
	if column != null:
		_LAYOUT.fit(self, column)

## arena design audit P3: neither button told the player NG+ was active or
## which one actually starts a run - "Continue" resumes the exact save,
## "Play" is the only path to a fresh NG+ run (and now confirms before it
## resets progress, see _on_play_pressed()).
## The action the player most likely wants stands out from the column: Continue when there is a save, else Play.
func _mark_primary(button: Button) -> void:
	ThemeProvider.style_control(button, &"primary")

func _apply_ngp_status(vb: Node) -> void:
	var play_btn := vb.get_node_or_null("Play") as Button
	var continue_btn := vb.get_node_or_null("Continue") as Button
	var ng := NewGamePlus.get_current_ng_plus() if NewGamePlus else 0
	if play_btn != null:
		# beside Continue, Play starts over (it asks first): it says so
		play_btn.text = LocalizationManager.tf("NGP_NEW_GAME_ACTION", [ng]) if ng > 0 \
			else LocalizationManager.t("new_game" if continue_btn != null else String(LABELS["Play"]))
	var primary := continue_btn if continue_btn != null else play_btn
	if primary != null:
		_mark_primary(primary)
	if continue_btn != null and ng > 0:
		continue_btn.text = LocalizationManager.t("NGP_CONTINUE_SAVED")
	var status := get_node_or_null("NGPStatus") as Label
	if ng > 0:
		if status == null:
			status = Label.new()
			status.name = "NGPStatus"
			status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			status.custom_minimum_size = Vector2(280, 0)
			status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			status.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
			_legible(status)
			vb.add_child(status)
			vb.move_child(status, 0)
		status.text = LocalizationManager.tf("NGP_MENU_STATUS", [ng])
	elif status != null:
		status.queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Routes.goto("res://scenes/ui/confirm_quit.tscn")
