extends Control
## Skill-tree chrome (2026-11-18): the shop, victory and menu screens show the
## live street through a dark panel; the skill tree was a 96 % opaque wall with
## a flat paper texture. This overlay keeps the gate-owned node paths intact and
## adds the same language as the rest of the UI without changing any layout:
##   - the near-opaque background becomes a translucent tactical scrim;
##   - a 1 px steel frame and an amber header rule around the tree;
##   - an edge vignette made from the project's own radial alpha shader, so no
##     external image or AI art is introduced;
##   - amber unlock paths drawn behind the skill cards, from each card to the
##     card that requires it (read from SkillTreeManager, not hardcoded).
##
## The palette comes from ThemeProvider, the same source the menu uses, so
## menu_style_unify_check cannot drift.

const FRAME_NAME := "TacticalFrame"
const RULE_NAME := "HeaderRule"
const VIGNETTE_NAME := "EdgeVignette"
const PATHS_NAME := "UnlockPaths"
## The shop uses this same dim street as its screen art; reusing it makes the
## skill tree read as the same game instead of a flat black wall. Project-owned
## Gemini art, documented in docs/ASSET_LICENSES.md.
const BACKDROP := "res://assets/textures/screens_v2/character_dim.png"

func _ready() -> void:
	call_deferred("_build")

func _root() -> Node:
	return get_parent()

func _build() -> void:
	var root := _root()
	if root == null:
		return
	var scrim := root.get_node_or_null("Scrim") as ColorRect
	if scrim:
		# Wave 2: the city stays legible behind a centred panel instead of
		# disappearing under a grey wall.
		scrim.color = Color(ThemeProvider.COLOR_BG_DARK, 0.26)
	var bg := root.get_node_or_null("Background") as ColorRect
	if bg:
		bg.color = Color(ThemeProvider.COLOR_BG_PANEL, 0.18)
	var art := root.get_node_or_null("Art") as TextureRect
	if art and ResourceLoader.exists(BACKDROP):
		# Same street art as the shop, dimmed further so the cards own the focus.
		art.texture = load(BACKDROP) as Texture2D
		art.modulate = Color(0.62, 0.64, 0.66, 1.0)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_add_vignette(root)
	_add_frame(root)
	_add_paths(root)

static func _solid(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	return s

func _add_vignette(root: Node) -> void:
	if root.get_node_or_null(VIGNETTE_NAME):
		return
	var v := ColorRect.new()
	v.name = VIGNETTE_NAME
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.color = Color(ThemeProvider.COLOR_BG_DARK, 1.0)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	vec2 d = abs(UV - vec2(0.5)) * 2.0;
	float edge = smoothstep(0.62, 1.0, max(d.x, d.y));
	COLOR.a = edge * 0.55;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	v.material = mat
	root.add_child(v)
	root.move_child(v, 1)

func _add_frame(root: Node) -> void:
	if root.get_node_or_null(FRAME_NAME):
		return
	var box := PanelContainer.new()
	box.name = FRAME_NAME
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 360.0
	box.offset_top = 118.0
	box.offset_right = -360.0
	box.offset_bottom = -142.0
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := _solid(Color(ThemeProvider.COLOR_BG_PANEL, 0.20))
	style.border_color = ThemeProvider.COLOR_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	box.add_theme_stylebox_override("panel", style)
	root.add_child(box)
	root.move_child(box, 3)
	var rule := ColorRect.new()
	rule.name = RULE_NAME
	rule.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rule.offset_top = 114.0
	rule.offset_bottom = 116.0
	rule.color = ThemeProvider.COLOR_AMBER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(rule)
	root.move_child(rule, 4)

func _add_paths(root: Node) -> void:
	if root.get_node_or_null(PATHS_NAME):
		return
	var tab := root.get_node_or_null("MarginContainer/VBoxContainer/TreeTabs") as TabContainer
	if tab == null:
		return
	var paths := Control.new()
	paths.name = PATHS_NAME
	paths.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	paths.mouse_filter = Control.MOUSE_FILTER_IGNORE
	paths.set_script(preload("res://scripts/ui/skill_paths.gd"))
	root.add_child(paths)
	root.move_child(paths, 5)
	paths.call("attach", tab)
