extends Control
## G26 (GDD §24.2): the photo album, a Codex tab. Three categories (Photos, Creatures, Artifacts), a thumbnail
## for every photo earned (the snapshot taken at that moment, ProgressTracker._snap_thumbnail) and the count
## against everything the game can give.

var embedded: bool = false

const CATEGORIES: Array[String] = ["photos", "creatures", "artifacts"]
const CATEGORY_KEYS: Dictionary = {
	"photos": "PHOTO_CAT_PHOTOS", "creatures": "PHOTO_CAT_CREATURES", "artifacts": "PHOTO_CAT_ARTIFACTS",
}
const CELL := Vector2(128, 72)
const COLUMNS: int = 6

var _category: String = "photos"
var _grid: GridContainer = null
var _counter: Label = null
var _buttons: Array[Button] = []
var _textures: Dictionary = {}

## The category a photo id belongs to: creature_*, secret_* and artifact_* have their own tabs.
static func category_of(id: String) -> String:
	if id.begins_with("creature_"):
		return "creatures"
	if id.begins_with("secret_") or id.begins_with("artifact_"):
		return "artifacts"
	return "photos"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = ThemeProvider.build_theme()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_counter = Label.new()
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	root.add_child(_counter)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	root.add_child(row)
	for category in CATEGORIES:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_show_category.bind(category))
		row.add_child(button)
		_buttons.append(button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_grid)
	LocalizationManager.language_changed.connect(func(_lang: String) -> void: _refresh())
	EventBus.photo_added.connect(func(_total: int) -> void: _refresh())
	visibility_changed.connect(func() -> void:
		if visible:
			_refresh())
	_refresh()

func _show_category(category: String) -> void:
	_category = category
	_refresh()

func _refresh() -> void:
	_counter.text = LocalizationManager.tf("PHOTO_COUNT", [SaveSystem.get_photo_count(), ProgressTracker.photo_total()])
	for i in CATEGORIES.size():
		_buttons[i].text = LocalizationManager.t(String(CATEGORY_KEYS[CATEGORIES[i]]))
		var col: Color = ThemeProvider.COLOR_AMBER if CATEGORIES[i] == _category else ThemeProvider.COLOR_TEXT_DIM
		_buttons[i].add_theme_color_override("font_color", col)
	for cell in _grid.get_children():
		cell.queue_free()
	for id in SaveSystem.get_photos():
		if category_of(String(id)) == _category:
			_grid.add_child(_cell(String(id)))

func _cell(id: String) -> Control:
	var tex := _thumbnail(id)
	if tex == null:
		var blank := ColorRect.new()
		blank.color = ThemeProvider.COLOR_BG_PANEL2
		blank.custom_minimum_size = CELL
		return blank
	var shot := TextureRect.new()
	shot.texture = tex
	shot.custom_minimum_size = CELL
	shot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	return shot

## The snapshot taken when the photo was earned; none exists for photos earned headless or before the album.
func _thumbnail(id: String) -> Texture2D:
	if _textures.has(id):
		return _textures[id]
	var path: String = ProgressTracker.PHOTO_DIR + id + ".png"
	if not FileAccess.file_exists(path):
		return null
	var shot := Image.load_from_file(path)
	if shot == null or shot.is_empty():
		return null
	var tex := ImageTexture.create_from_image(shot)
	_textures[id] = tex
	return tex
