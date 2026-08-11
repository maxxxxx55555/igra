class_name WeightBar
extends Control

@onready var weight_fill: ColorRect = %WeightFill
@onready var weight_label: Label = %WeightLabel
@onready var weight_warning: Label = %WeightWarning


func update_weight(current_weight: float, max_weight: float) -> void:
	if max_weight > 0.0:
		var ratio: float = current_weight / max_weight
		weight_fill.scale.x = ratio
		if ratio > 0.9:
			weight_fill.color = Color("#b4452f")
			weight_warning.visible = true
		elif ratio > 0.7:
			weight_fill.color = Color("#c9a24a")
			weight_warning.visible = false
		else:
			weight_fill.color = Color("#aeb6bf")
			weight_warning.visible = false
	weight_label.text = str(ceili(current_weight)) + "/" + str(ceili(max_weight))
