extends Button
class_name SkillButton

signal unlock_requested(skill_id: StringName)

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var desc_label: Label = $VBoxContainer/DescLabel
@onready var cost_label: Label = $VBoxContainer/HBoxContainer/CostLabel
@onready var level_label: Label = $VBoxContainer/HBoxContainer/LevelLabel
@onready var req_label: Label = $VBoxContainer/ReqLabel

var _skill_id: StringName
var _skill_data: Dictionary

func setup(skill_id: StringName, skill_data: Dictionary) -> void:
	_skill_id = skill_id
	_skill_data = skill_data
	
	# WAVE 6 P0.2: skill_data.name/description now store i18n KEYS
	# (SKILL_TREES in skill_tree_manager.gd), not raw English text.
	name_label.text = LocalizationManager.t(skill_data.name)
	desc_label.text = LocalizationManager.t(skill_data.description)
	cost_label.text = LocalizationManager.tf("SKILL_COST_SP", [skill_data.cost])
	level_label.text = ""
	req_label.text = ""
	
	pressed.connect(_on_pressed)
	refresh()

func refresh() -> void:
	var level = SkillTreeManager.get_skill_level(_skill_id)
	var max_level = _skill_data.max_level
	var can_unlock = SkillTreeManager.can_unlock(_skill_id)
	
	if level > 0:
		level_label.text = LocalizationManager.tf("SKILL_LEVEL_FMT", [level, max_level])
		self.disabled = level >= max_level
		self.tooltip_text = LocalizationManager.t("SKILL_ALREADY_UNLOCKED")
	else:
		level_label.text = LocalizationManager.t("SKILL_LOCKED")
		self.disabled = not can_unlock
		if not can_unlock:
			var reqs = _skill_data.requires
			if reqs.size() > 0:
				var req_names = []
				for r in reqs:
					var r_data = _get_skill_data(r)
					if r_data:
						req_names.append(LocalizationManager.t(r_data.name))
				req_label.text = LocalizationManager.tf("SKILL_REQUIRES", [", ".join(req_names)])
			else:
				req_label.text = LocalizationManager.t("SKILL_NOT_ENOUGH_POINTS")

func _on_pressed() -> void:
	if not self.disabled:
		unlock_requested.emit(_skill_id)

func _get_skill_data(skill_id: StringName) -> Dictionary:
	for tree in SkillTreeManager.get_all_trees().values():
		if tree.skills.has(skill_id):
			return tree.skills[skill_id]
	return {}