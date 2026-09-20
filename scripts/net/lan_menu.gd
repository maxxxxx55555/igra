extends CanvasLayer
## LANMenu: minimal host/join form.

var _root: Control
var _bus: Node
var _title: Label
var _host_btn: Button
var _ip_edit: LineEdit
var _join_btn: Button
var _close_btn: Button

func _ready() -> void:
	layer = 60
	_bus = get_node_or_null("/root/EventBus")
	_build()
	visible = false
	_apply_localization()
	LocalizationManager.language_changed.connect(func(_l: String) -> void: _apply_localization())

func _build() -> void:
	_root = Control.new()
	_root.anchor_right = 1.0
	_root.anchor_bottom = 1.0
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	_root.add_child(bg)
	var box := VBoxContainer.new()
	box.position = Vector2(440, 220)
	box.add_theme_constant_override("separation", 16)
	_root.add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 32)
	_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(_title)
	_host_btn = Button.new()
	_host_btn.pressed.connect(_on_host)
	box.add_child(_host_btn)
	_ip_edit = LineEdit.new()
	_ip_edit.custom_minimum_size = Vector2(400, 0)
	box.add_child(_ip_edit)
	_join_btn = Button.new()
	_join_btn.pressed.connect(_on_join.bind(_ip_edit))
	box.add_child(_join_btn)
	_close_btn = Button.new()
	_close_btn.pressed.connect(func(): visible = false)
	box.add_child(_close_btn)

## arena design audit P2: every label here was a raw English literal,
## bypassing LocalizationManager entirely despite being wired live in
## scenes/main_3d.tscn (player-reachable).
func _apply_localization() -> void:
	_title.text = LocalizationManager.t("LAN_TITLE")
	_host_btn.text = LocalizationManager.t("LAN_HOST")
	_ip_edit.placeholder_text = LocalizationManager.t("LAN_HOST_IP_PLACEHOLDER")
	_join_btn.text = LocalizationManager.t("LAN_JOIN")
	_close_btn.text = LocalizationManager.t("LAN_CLOSE")

func _on_host() -> void:
	var lan := get_node_or_null("/root/LANNetwork")
	if lan != null and lan.has_method("host"):
		var r = lan.host()
		if r == OK:
			visible = false

func _on_join(edit: LineEdit) -> void:
	var lan := get_node_or_null("/root/LANNetwork")
	if lan == null or not lan.has_method("join"):
		return
	var ip := edit.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	var r = lan.join(ip)
	if r == OK:
		visible = false

func toggle() -> void:
	visible = not visible