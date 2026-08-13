extends Control

## Stats screen — экран статистики игрока.
## Показывает: время игры, убийства, расстояние, пазлы, фото, монеты и т.д.

@onready var _title: Label = $Panel/VBox/Title
@onready var _close_btn: Button = $Panel/VBox/CloseBtn
@onready var _stats_list: VBoxContainer = $Panel/VBox/ScrollStats/StatsList

func _ready() -> void:
	_apply_localization()
	_close_btn.pressed.connect(_on_close)
	_build_stats()
	LocalizationManager.language_changed.connect(_apply_localization)

func _apply_localization(_lang: Variant = null) -> void:
	_title.text = LocalizationManager.t("stats_title")
	_close_btn.text = LocalizationManager.t("ui_close")

func _build_stats() -> void:
	for c in _stats_list.get_children():
		c.queue_free()
	await get_tree().process_frame

	var stats := _get_stats_data()
	for key in stats:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var label := Label.new()
		label.text = LocalizationManager.t(key)
		label.add_theme_color_override("font_color", Color("aeb6bf"))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var val := Label.new()
		val.text = str(stats[key])
		val.add_theme_color_override("font_color", Color("c9a24a"))
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(val)

		_stats_list.add_child(row)

func _get_stats_data() -> Dictionary:
	var data := {}
	var stats: Dictionary = ProgressTracker.get_stats()
	data["stats_time_played"] = _format_time(int(stats.get("time_played", 0)))
	data["stats_coins"] = str(CoinWallet.get_coins())
	data["stats_districts"] = str(PowerGrid.powered_count()) + "/11"
	# Заряд берём у живого игрока: SaveLoad хранил собственную копию, которая
	# расходилась с фактическим battery игрока.
	data["hud_battery"] = str(int(_battery_ratio() * 100)) + "%"
	data["stats_level"] = str(XpManager.get_level())
	data["stats_xp"] = str(XpManager.get_current_xp())
	data["stats_enemies_killed"] = str(stats.get("kills", 0))
	data["stats_puzzles"] = str(stats.get("puzzles", 0))
	data["stats_secrets"] = str(stats.get("secrets", 0))
	data["stats_districts_restored"] = str(PowerGrid.powered_count())
	return data

func _battery_ratio() -> float:
	var p := get_tree().get_first_node_in_group("player")
	if p != null and "battery" in p and "battery_max" in p:
		return clampf(float(p.battery) / maxf(0.001, float(p.battery_max)), 0.0, 1.0)
	return 0.0

func _get_persist(key: String, default_val: Variant) -> Variant:
	return default_val

func _format_time(seconds: int) -> String:
	var h := seconds / 3600
	var m := (seconds % 3600) / 60
	var s := seconds % 60
	return "%02d:%02d:%02d" % [h, m, s]

func _on_close() -> void:
	queue_free()
