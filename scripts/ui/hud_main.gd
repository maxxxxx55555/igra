extends CanvasLayer

var banner: Control
var minimap: Control
var lives_label: Label
var coins_label: Label

func _ready() -> void:
	layer = 10
	banner = load("res://scripts/ui/hud_banner.gd").new()
	banner.position = Vector2(16, 16)
	add_child(banner)
	minimap = load("res://scripts/ui/hud_minimap.gd").new()
	minimap.position = Vector2(16, 530)
	add_child(minimap)
	lives_label = Label.new()
	lives_label.position = Vector2(1110, 24)
	lives_label.add_theme_font_size_override("font_size", 24)
	lives_label.text = "♥ ♥ ♥"
	add_child(lives_label)
	coins_label = Label.new()
	coins_label.position = Vector2(1090, 640)
	coins_label.add_theme_font_size_override("font_size", 28)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	coins_label.text = "● 0"
	add_child(coins_label)

func _process(_d: float) -> void:
	var pg := get_tree().root.get_node_or_null("PowerGrid")
	if pg != null and banner != null and banner.has_method("set_progress"):
		var prog: Dictionary = pg.get_progress()
		banner.set_progress(int(prog.get("powered", 0)), int(prog.get("total", 11)))
	var sl := get_tree().root.get_node_or_null("SaveLoad")
	if sl != null:
		if coins_label != null:
			coins_label.text = "● %d" % int(sl.get_coins())
		if lives_label != null:
			var h := ""
			for i in range(max(0, int(sl.get_lives()))):
				h += "♥ "
			lives_label.text = h.strip_edges()
	var p := get_tree().get_first_node_in_group("player")
	if p != null and minimap != null and minimap.has_method("set_player"):
		minimap.set_player(p.global_position, 0.0)