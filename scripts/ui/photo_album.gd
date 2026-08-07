extends Control
## Photo album UI — shows collected photos, creatures, artifacts.

@onready var _grid: GridContainer = $Panel/VBox/Scroll/Grid
@onready var _title: Label = $Panel/VBox/Title
@onready var _close_btn: Button = $Panel/VBox/CloseBtn
@onready var _counter: Label = $Panel/VBox/Counter

var _current_tab: String = "photos"

func _ready() -> void:
	_apply_localization()
	_close_btn.pressed.connect(_on_close)
	_load_photos()
	LocalizationManager.language_changed.connect(_apply_localization)

func _apply_localization(_lang: Variant = null) -> void:
	_title.text = LocalizationManager.t("stats_photos")
	_close_btn.text = LocalizationManager.t("ui_close")

func _load_photos() -> void:
	for c in _grid.get_children():
		c.queue_free()
	await get_tree().process_frame
	var collected: Array = SaveSystem.get_photos() if SaveSystem else []
	if collected.is_empty():
		_show_fallback_photos()
		return
	for i in range(collected.size()):
		var tex := TextureRect.new()
		tex.custom_minimum_size = Vector2(64, 64)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_grid.add_child(tex)
	_counter.text = "%d/%d" % [collected.size(), _get_total()]

func _show_fallback_photos() -> void:
	var fallback := ["abandoned_street", "dark_alley", "old_park", "broken_lamp", "foggy_avenue", "ruined_school", "empty_hospital", "night_substation", "warehouse_shadow", "last_streetlight"]
	for name in fallback:
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(64, 64)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var path := "res://assets/photos/%s.png" % name
		if ResourceLoader.exists(path):
			tex_rect.texture = load(path)
		_grid.add_child(tex_rect)
	_counter.text = "0/%d" % _get_total()

func _get_collected() -> Array:
	return SaveSystem.get_photos() if SaveSystem else []

func take_photo(photo_name: String) -> void:
	if SaveSystem:
		SaveSystem.add_photo(photo_name)
		_load_photos()

func _get_total() -> int:
	return 200

func _on_close() -> void:
	queue_free()
