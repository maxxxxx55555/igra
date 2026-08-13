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
		# Путь вёл в res://scripts/systems/quest_manager.gd, которого нет:
		# preload несуществующего файла — это ошибка парсинга, скрипт целиком
		# не компилируется. Реальный менеджер квестов лежит в scripts/core.
		current = preload("res://scripts/core/quest_manager.gd").new()
		add_child(current)