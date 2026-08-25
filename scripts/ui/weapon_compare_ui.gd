extends CanvasLayer

## T13: сравнение оружия бок о бок при переключении — лучше=зелёный, хуже=красный.
## GDD §V.5 9.8 "сравнение оружия side-by-side".

const PANEL := Color("#141b24")
const BRASS_DIM := Color("#8a7338")
const BONE_TEXT := Color("#d8d2c4")
const GOOD := Color("#5f8a4e")
const BAD := Color("#b4452f")
const VISIBLE_TIME := 3.0

## Строка: [i18n_key, getter(WeaponBase)->float, lower_is_better]
const _ROWS := [
	["WEAPON_COMPARE_DAMAGE", "damage", false],
	["WEAPON_COMPARE_RATE", "fire_rate", true],
	["WEAPON_COMPARE_RANGE", "range", false],
	["WEAPON_COMPARE_MAG", "max_ammo", false],
	["WEAPON_COMPARE_RELOAD", "reload_time", true],
]

var _panel: PanelContainer = null
var _rows_box: VBoxContainer = null
var _hide_timer: Timer = null
var _prev_weapon: WeaponBase = null

func _ready() -> void:
	layer = 15
	_build_ui()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_panel.offset_left = -160
	_panel.offset_right = 160
	_panel.offset_top = 90
	_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(PANEL.r, PANEL.g, PANEL.b, 0.92)
	sb.border_color = BRASS_DIM
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_panel.add_theme_stylebox_override("panel", sb)
	_apply_panel_shader()
	add_child(_panel)
	_panel.resized.connect(_sync_panel_shader_size)
	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 3)
	_panel.add_child(_rows_box)
	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.wait_time = VISIBLE_TIME
	_hide_timer.timeout.connect(_hide)
	add_child(_hide_timer)

## One of the 2-3 key panels wired to the art pass's chamfered-panel shader
## (per scope). Panel height grows with row count, so rect_px is resynced
## on every resize rather than set once.
func _apply_panel_shader() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/ui_panel.gdshader")
	_panel.material = mat

func _sync_panel_shader_size() -> void:
	if _panel.material is ShaderMaterial:
		(_panel.material as ShaderMaterial).set_shader_parameter("rect_px", _panel.size)

## Вызывается WeaponManager-ом при смене оружия — сравнивает с предыдущим.
func on_weapon_switched(weapon: WeaponBase) -> void:
	if weapon == null:
		return
	if _prev_weapon != null and is_instance_valid(_prev_weapon) and _prev_weapon != weapon:
		_show_compare(_prev_weapon, weapon)
	_prev_weapon = weapon

func _show_compare(from_w: WeaponBase, to_w: WeaponBase) -> void:
	for c in _rows_box.get_children():
		c.queue_free()
	# P2 (FINAL INTEGRATION wave): real weapon render icons either side of
	# the arrow, keyed off weapon_name.to_lower() (matches the delivered
	# icons/weapons/{pistol,rifle,shotgun}_128.png filenames exactly).
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 6)
	_rows_box.add_child(title_row)
	_add_weapon_icon(title_row, from_w)
	var title := Label.new()
	title.text = String(from_w.weapon_name) + "  →  " + String(to_w.weapon_name)
	title.add_theme_color_override("font_color", BONE_TEXT)
	title.add_theme_font_size_override("font_size", 12)
	title_row.add_child(title)
	_add_weapon_icon(title_row, to_w)
	for row in _ROWS:
		_rows_box.add_child(_make_row(row[0], float(from_w.get(row[1])), float(to_w.get(row[1])), row[2]))
	_panel.visible = true
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.15)
	_hide_timer.start(VISIBLE_TIME)

func _make_row(key: String, from_v: float, to_v: float, lower_is_better: bool) -> HBoxContainer:
	var hb := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = LocalizationManager.t(key)
	lbl.custom_minimum_size = Vector2(90, 0)
	lbl.add_theme_color_override("font_color", BRASS_DIM)
	lbl.add_theme_font_size_override("font_size", 10)
	hb.add_child(lbl)
	var val := Label.new()
	val.text = "%s → %s" % [_fmt(from_v), _fmt(to_v)]
	val.add_theme_font_size_override("font_size", 10)
	var better: bool = (to_v > from_v) if not lower_is_better else (to_v < from_v)
	var worse: bool = (to_v < from_v) if not lower_is_better else (to_v > from_v)
	if better:
		val.add_theme_color_override("font_color", GOOD)
	elif worse:
		val.add_theme_color_override("font_color", BAD)
	else:
		val.add_theme_color_override("font_color", BONE_TEXT)
	hb.add_child(val)
	return hb

func _add_weapon_icon(parent: Node, weapon: WeaponBase) -> void:
	var id := String(weapon.weapon_name).to_lower()
	if id == "":
		return
	var path := "res://assets/textures/icons/weapons/%s_128.png" % id
	if not ResourceLoader.exists(path):
		return
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.texture = load(path)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(icon)

func _fmt(v: float) -> String:
	return str(v) if v != roundf(v) else str(int(v))

func _hide() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): _panel.visible = false)
