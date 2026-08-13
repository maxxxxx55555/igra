

extends Node3D

@onready var bar_background: ColorRect = $BarBackground
@onready var bar_fill: ColorRect = $BarFill
@onready var health_label: Label = $HealthLabel

var max_health: int = 100
var current_health: int = 100
var _target: Node3D = null

func _ready() -> void:
	# Find parent enemy
	var parent = get_parent()
	if parent and parent.has_node("HealthComponent"):
		var health = parent.get_node("HealthComponent")
		max_health = health.max_health
		# Компонентов здоровья в проекте два, и поле у них называется
		# по-разному: current_health в components/health_component.gd и
		# health в scripts/components/health_component.gd. Берём то, что
		# реально есть, иначе полоска молча читает null.
		if "current_health" in health:
			current_health = health.current_health
		elif "health" in health:
			current_health = health.health
		health.health_changed.connect(_on_health_changed)
	_target = parent

func _process(_delta: float) -> void:
	if _target:
		look_at(_target.global_position + Vector3.UP)
		# Always face camera
	rotate_y(PI)

func _on_health_changed(new_health: int) -> void:
	current_health = new_health
	var percent = float(current_health) / float(max_health)
	bar_fill.scale.x = percent
	if percent > 0.6:
		bar_fill.color = Color(0.2, 1.0, 0.2)
	elif percent > 0.3:
		bar_fill.color = Color(1.0, 0.8, 0.2)
	else:
		bar_fill.color = Color(1.0, 0.2, 0.2)
	health_label.text = str(current_health) + "/" + str(max_health)