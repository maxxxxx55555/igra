extends Control
## Amber unlock paths behind the skill cards. Drawn from the live
## SkillTreeManager requires-table, so a content change cannot leave a stale
## hardcoded graph. The forbidden colours are the palette gate's business:
## the amber below is ThemeProvider.COLOR_AMBER at low alpha, a guide, not a wire.

const PATH_COLOR := Color(0.7882, 0.6353, 0.2902, 0.55)  # COLOR_AMBER, dimmed

var _tabs: TabContainer
var _last_tab: int = -1

func attach(tabs: TabContainer) -> void:
	_tabs = tabs
	tabs.tab_changed.connect(_on_tab_changed)
	set_process(true)
	queue_redraw()

func _on_tab_changed(_index: int) -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	if _tabs == null:
		return
	var index: int = _tabs.get_current_tab()
	if index != _last_tab:
		_last_tab = index
		queue_redraw()

func _draw() -> void:
	if _tabs == null:
		return
	var tab_node: Node = _tabs.get_child(_tabs.get_current_tab()) if _tabs.get_tab_count() > 0 else null
	if not (tab_node is SkillTreeTab):
		return
	var grid := (tab_node as SkillTreeTab).get_node_or_null("MarginContainer/VBoxContainer/SkillGrid") as GridContainer
	if grid == null:
		return
	var origin: Vector2 = global_position
	for button in grid.get_children():
		if not (button is SkillButton):
			continue
		var reqs: Array = (button as SkillButton).get("_skill_data").get("requires", [])
		for req in reqs:
			var from := _find_button(grid, String(req))
			if from == null:
				continue
			var a: Vector2 = (from as Control).global_position + (from as Control).size * 0.5 - origin
			var b: Vector2 = (button as Control).global_position + (button as Control).size * 0.5 - origin
			draw_line(a, b, PATH_COLOR, 2.0, true)

static func _find_button(grid: GridContainer, id: String) -> Control:
	for b in grid.get_children():
		if b is SkillButton and String((b as SkillButton).get("_skill_id")) == id:
			return b as Control
	return null
