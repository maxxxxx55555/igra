class_name BatteryBar
extends Control

@onready var battery_fill: ColorRect = %BatteryFill
@onready var battery_label: Label = %BatteryLabel


func update_battery(current_charge: float, max_charge: float) -> void:
	if max_charge > 0.0:
		var ratio: float = current_charge / max_charge
		battery_fill.scale.x = ratio
		if ratio < 0.3:
			battery_fill.color = Color("#b4452f")
		else:
			battery_fill.color = Color("#5f8a4e")
	battery_label.text = str(ceili(current_charge)) + "/" + str(ceili(max_charge))
