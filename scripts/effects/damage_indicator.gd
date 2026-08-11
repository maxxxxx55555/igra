
extends CanvasLayer

@onready 
var vignette: ColorRect = $Vignette

func _ready() -> void:
	vignette.color = Color(1, 0, 0, 0)
	EventBus.player_damaged.connect(_on_damaged)

func _on_damaged(_amount: int) -> void:
	vignette.color = Color(1, 0, 0, 0.4)
	
	var tween := create_tween()
	tween.tween_property(vignette, "color:a", 0.0, 0.5)
