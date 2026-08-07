extends Control
class_name SkillTreeUI

@onready var tree_tabs: TabContainer = $MarginContainer/VBoxContainer/TreeTabs
@onready var skill_points_label: Label = $MarginContainer/VBoxContainer/SkillPointsLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(600, 500)
	
	SkillTreeManager.skill_unlocked.connect(_refresh)
	EventBus.settings_changed.connect(_on_settings_changed)
	
	close_button.pressed.connect(_close)
	_build_trees()
	_refresh()

func _on_settings_changed(setting: String, value: Variant) -> void:
	if setting == "skill_points":
		_refresh()

func _build_trees() -> void:
	const SkillTreeTabScene := preload("res://scenes/ui/skill_tree_tab.tscn")
	for tree_id in SkillTreeManager.get_all_trees():
		var tree_data = SkillTreeManager.get_tree_data(tree_id)
		var tab = SkillTreeTabScene.instantiate()
		tree_tabs.add_child(tab)
		tab.setup(tree_id, tree_data)
		tree_tabs.set_tab_title(tree_tabs.get_child_count() - 1, tr(tree_data.name))

## skill_unlocked эмитит id навыка — без параметра дерево не перерисовывалось
## после покупки.
func _refresh(_skill_id: Variant = null) -> void:
	skill_points_label.text = tr("Skill Points: %d") % SkillTreeManager.get_skill_points()
	
	for tab in tree_tabs.get_children():
		if tab is SkillTreeTab:
			tab.refresh()

func _close() -> void:
	UIManager.close(&"skill_tree")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("skill_tree_toggle"):
			if UIManager._is_open(&"skill_tree"):
				UIManager.close(&"skill_tree")
			else:
				UIManager.open(&"skill_tree")