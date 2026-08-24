extends ScrollContainer
class_name SkillTreeTab

@onready var skill_grid: GridContainer = $MarginContainer/VBoxContainer/SkillGrid

var _tree_id: StringName
var _tree_data: Dictionary
var _skill_buttons: Dictionary = {}

const SkillButtonScene := preload("res://scenes/ui/skill_button.tscn")

func setup(tree_id: StringName, tree_data: Dictionary) -> void:
	_tree_id = tree_id
	_tree_data = tree_data
	
	var skills = tree_data.skills
	skill_grid.columns = 4
	
	for skill_id in skills:
		var skill = skills[skill_id]
		var btn = SkillButtonScene.instantiate()
		skill_grid.add_child(btn)
		btn.setup(skill_id, skill)
		_skill_buttons[skill_id] = btn
		
		# Connect unlock signal
		btn.unlock_requested.connect(_on_unlock_requested)

func refresh() -> void:
	for skill_id in _skill_buttons:
		var btn = _skill_buttons[skill_id]
		btn.refresh()

func _on_unlock_requested(skill_id: StringName) -> void:
	if SkillTreeManager.unlock_skill(skill_id):
		refresh()
		# Show notification
		var skill = _tree_data.skills[skill_id]
		UIManager.show_notification(LocalizationManager.tf("Unlocked: %s", [LocalizationManager.t(skill.name)]))