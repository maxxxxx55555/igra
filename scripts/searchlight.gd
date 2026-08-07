class_name Searchlight
extends Node3D

@export var light_id: String = "search_001"
@export var rotate_speed: float = 0.5
@export var light_range: float = 20.0

@onready var spot: SpotLight3D = get_node_or_null("SpotLight3D")


func _ready() -> void:
	add_to_group("searchlights")
	if spot:
		spot.light_color = Color("#d4a04a")
		spot.light_energy = 3.0
		spot.spot_range = light_range
		spot.spot_angle = 30.0
		spot.shadow_enabled = false



func _process(delta: float) -> void:
	rotate_y(rotate_speed * delta)
