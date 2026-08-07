extends CanvasLayer
## LANMenu: minimal host/join form.

var _root: Control
var _bus: Node

func _ready() -> void:
	layer = 60
	_bus = get_node_or_null("/root/EventBus")
	_build()
	visible = false

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
	var title := Label.new()
	title.text = "LAN"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(title)
	var host_btn := Button.new()
	host_btn.text = "Host"
	host_btn.pressed.connect(_on_host)
	box.add_child(host_btn)
	var ip_edit := LineEdit.new()
	ip_edit.placeholder_text = "host ip (e.g. 192.168.1.10)"
	ip_edit.custom_minimum_size = Vector2(400, 0)
	box.add_child(ip_edit)
	var join_btn := Button.new()
	join_btn.text = "Join"
	join_btn.pressed.connect(_on_join.bind(ip_edit))
	box.add_child(join_btn)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): visible = false)
	box.add_child(close_btn)

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