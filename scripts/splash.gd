extends Control

@onready var logo: ColorRect = $Logo
@onready var label: Label = $Title

func _ready() -> void:
	add_to_group("ui_root")
	logo.color = Color("#1D1812")
	label.text = "THE LAST STREETLIGHT"
	label.add_theme_color_override("font_color", Color("#E2A33C"))
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.0)
	tw.tween_interval(2.0)
	tw.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/ui/boot_loading.tscn"))
