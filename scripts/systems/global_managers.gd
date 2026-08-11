extends Node

func set_quest_progress(data: Dictionary) -> void:
	# Implementation would go here to save quest progress to SaveData
	pass

func get_quest_progress() -> Dictionary:
	# Implementation to return current quest progress
	return {}

# Global reference
var current = null

func _ready() -> void:
	if current == null:
		current = preload("res://scripts/systems/quest_manager.gd").new()
		add_child(current)