extends Control
class_name QuestTrackerHUD

# S5.3: HUD quest tracker - right top under minimap
# Shows up to 3 active objectives with progress, optional direction arrow

const PANEL_WIDTH := 300
const PANEL_HEIGHT := 200
const PANEL_MARGIN := 20
## Below the top-right maps, not just below the radar. The comment here used to
## read "ниже миникарты" at 140, which was never true: the radar spans y 16..180
## (radar.gd) and the bigger UIManager minimap y 16..236 (minimap.gd SIZE 220),
## so the panel sat on top of both - they all live on UIManager's layer 10 and
## this panel is added last, so it drew over the minimap and hid the minimap's
## lower-left corner (96 px of overlap, including the legend chip/minimap.gd).
## 236 + PANEL_MARGIN clears the taller disc, so the panel stays put whichever of
## the two maps survives the pending "which top-right map wins" decision.
const PANEL_TOP := 252

var _container: VBoxContainer
var _title_lbl: Label
var _objectives_vbox: VBoxContainer
## One entry per drawn row: {"arrow": TextureRect, "quest": Dictionary,
## "pos": Variant} - pos is the last resolved world position, or null when the
## target has no single location (see _objective_position()).
var _markers: Array[Dictionary] = []
## Group scans are throttled: they walk every interactable/enemy in the
## district, and a direction arrow does not need per-frame precision.
const _RESOLVE_INTERVAL := 0.4
var _resolve_timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	
	QuestManager.quest_started.connect(_refresh)
	QuestManager.quest_completed.connect(_refresh)
	QuestManager.quest_progress.connect(_refresh)
	
	EventBus.settings_changed.connect(_on_settings_changed)
	# Static audit 2026-09-08: title on this always-on gameplay HUD was set
	# once and never retranslated. The objective rows themselves are built from
	# get_title()/tf() inside _refresh(), so the same switch has to rebuild them
	# too - re-texting the title alone left the list in the old language.
	LocalizationManager.language_changed.connect(func(_l: String) -> void: _refresh())
	_refresh()

func _build_ui() -> void:
	# Панель справа сверху, под миникартой.
	# size у заякоренного Control игнорируется, а из четырёх отступов задавались
	# только два — панель схлопывалась в ~70 px, и текст переносился по одной
	# букве в строку. Задаём пресет и все четыре отступа явно.
	_container = VBoxContainer.new()
	_container.name = "QuestHUDContainer"
	_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_container.offset_left = -(PANEL_WIDTH + PANEL_MARGIN)
	_container.offset_right = -PANEL_MARGIN
	_container.offset_top = PANEL_TOP
	_container.offset_bottom = PANEL_TOP + PANEL_HEIGHT
	_container.add_theme_constant_override("separation", 8)
	add_child(_container)

	# Background panel
	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", _make_stylebox())
	_container.add_child(bg)

	var inner_vb := VBoxContainer.new()
	inner_vb.add_theme_constant_override("separation", 6)
	bg.add_child(inner_vb)
	
	# Title
	_title_lbl = Label.new()
	_title_lbl.text = LocalizationManager.t("QUEST_OBJECTIVES")
	_title_lbl.add_theme_font_size_override("font_size", 14)
	_title_lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vb.add_child(_title_lbl)
	
	# Objectives list
	_objectives_vbox = VBoxContainer.new()
	_objectives_vbox.add_theme_constant_override("separation", 6)
	inner_vb.add_child(_objectives_vbox)
	
	_container.visible = false

func _make_stylebox() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.05, 0.07, 0.85)
	# GDD 11.4: panel fill + 1 px panel-edge frame + light drop shadow. The
	# amber accent stays on the title and the checkbox row, not on the frame.
	sb.border_color = ThemeProvider.COLOR_BORDER
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0.0, 2.0)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 0
	sb.corner_radius_top_right = 0
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	return sb

func _on_settings_changed(key: String, value: Variant) -> void:
	if key == "hints" or key == "objective_markers":
		_refresh()

## Три сигнала разной арности: quest_started(1), quest_completed(1),
## quest_progress(3). Берём максимум, иначе трекер не обновляется ни по одному.
func _refresh(_a: Variant = null, _b: Variant = null, _c: Variant = null) -> void:
	for c in _objectives_vbox.get_children():
		c.queue_free()
	_markers.clear()
	
	var active_quests: Array = QuestManager.get_active_quests()
	if active_quests.is_empty():
		_container.visible = false
		return
	
	_container.visible = true
	
	var show_markers := bool(SettingsManager.get_setting("objective_markers", true))
	
	_title_lbl.text = LocalizationManager.t("QUEST_OBJECTIVES")
	_title_lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_AMBER)

	var count := 0
	for quest in active_quests:
		if count >= 3:
			break
		var current := int(quest.get("progress", 0))
		var target := int(quest.get("target_count", 1))

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		_objectives_vbox.add_child(hb)

		var checkbox := CheckBox.new()
		checkbox.disabled = true
		checkbox.button_pressed = current >= target
		hb.add_child(checkbox)

		var obj_lbl := Label.new()
		obj_lbl.text = "%s (%d/%d)" % [QuestManager.get_title(quest), current, target]
		obj_lbl.add_theme_font_size_override("font_size", 13)
		obj_lbl.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT)
		obj_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		# Без растяжения контейнер выдаёт метке минимальную ширину, и перенос
		# по словам вырождается в перенос по буквам.
		obj_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(obj_lbl)

		# The arrow used to be drawn for every objective and always pointed
		# right - pure decoration that read as a direction. It is now rotated
		# toward the quest target (see _process / _objective_position), and
		# hidden whenever the target has no single place in the world.
		var arrow: TextureRect = null
		if show_markers:
			arrow = TextureRect.new()
			arrow.texture = _make_arrow_texture()
			arrow.custom_minimum_size = Vector2(16, 16)  # size внутри контейнера игнорируется
			arrow.pivot_offset = Vector2(8, 8)
			arrow.visible = false
			hb.add_child(arrow)
		_markers.append({"arrow": arrow, "quest": quest, "pos": null})

		count += 1

	# GDD V.1 3.3/3.16: the sheet's list is "up to 3 active" and the loop above
	# stops there, but anything past the third used to vanish without a word - a
	# player holding four objectives could not tell whether the tracker had lost
	# one. Count them instead of hiding them.
	if count < active_quests.size():
		var more := Label.new()
		more.name = "MoreActiveLabel"
		more.text = LocalizationManager.tf("QUEST_MORE_ACTIVE", [active_quests.size() - count])
		more.add_theme_font_size_override("font_size", 12)
		more.add_theme_color_override("font_color", ThemeProvider.COLOR_TEXT_DIM)
		_objectives_vbox.add_child(more)

func _process(delta: float) -> void:
	if _markers.is_empty() or not _container.visible:
		return
	_resolve_timer -= delta
	if _resolve_timer <= 0.0:
		_resolve_timer = _RESOLVE_INTERVAL
		for m in _markers:
			m["pos"] = _objective_position(m["quest"])
	_rotate_markers()

## Points each arrow at its objective in screen space. The texture is drawn
## pointing right, and atan2(x, -z) is 0 for "straight ahead", so the rotation
## is that angle minus a quarter turn.
func _rotate_markers() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	for m in _markers:
		var arrow: TextureRect = m["arrow"]
		if arrow == null or not is_instance_valid(arrow):
			continue
		var pos = m["pos"]
		if pos == null or cam == null:
			arrow.visible = false
			continue
		var local: Vector3 = cam.global_transform.basis.inverse() * ((pos as Vector3) - cam.global_position)
		# Camera-local to screen axes: +x right, +y down, so an objective
		# straight ahead (local z = -1) lands on (0, -1) = straight up and the
		# right-pointing texture ends up pointing up too.
		var screen_dir := Vector2(local.x, local.z)
		arrow.rotation = screen_dir.angle() if screen_dir.length_squared() > 0.0001 else -PI * 0.5
		arrow.visible = true

## Best-effort world position for a quest target, using the same identity rules
## quest_manager.gd ticks progress by. Returns null when the objective has no
## single location, in which case the caller hides the arrow instead of
## inventing a direction:
##   - COLLECT/CRAFT span every pickup of an item, there is no one place;
##   - EXPLORE targets are ZoneTrigger nodes, which join no group and carry no
##     id another system can look up by;
##   - INTERACT (q_connect_cables) is completed through
##     QuestManager.complete_objective() from the puzzle, not by node identity.
## The three types below do resolve: REPAIR through power_switch.district_id,
## SECRET through secret.secret_id, KILL through base_monster.monster_id.
func _objective_position(quest: Dictionary) -> Variant:
	var target := String(quest.get("target", ""))
	match String(quest.get("type", "")):
		"REPAIR":
			return _nearest_with(&"interactable", &"district_id", target)
		"SECRET":
			return _nearest_secret()
		"KILL":
			return _nearest_enemy(target)
	return null

func _nearest_with(group: StringName, prop: StringName, value: String) -> Variant:
	if value == "":
		return null
	var player: Variant = _player_position()
	if player == null:
		return null
	var best: Variant = null
	var best_dist := INF
	for n in get_tree().get_nodes_in_group(group):
		if not (n is Node3D) or not is_instance_valid(n) or not (prop in n):
			continue
		if String(n.get(prop)) != value:
			continue
		if n.has_method("can_interact") and not bool(n.call("can_interact")):
			continue
		var dist: float = (n as Node3D).global_position.distance_to(player)
		if dist < best_dist:
			best_dist = dist
			best = (n as Node3D).global_position
	return best

## Secrets all share the quest target "secret", so the arrow points at the
## closest one still takeable.
func _nearest_secret() -> Variant:
	var player: Variant = _player_position()
	if player == null:
		return null
	var best: Variant = null
	var best_dist := INF
	for n in get_tree().get_nodes_in_group("interactable"):
		if not (n is Node3D) or not is_instance_valid(n) or not ("secret_id" in n):
			continue
		if n.has_method("can_interact") and not bool(n.call("can_interact")):
			continue
		var dist: float = (n as Node3D).global_position.distance_to(player)
		if dist < best_dist:
			best_dist = dist
			best = (n as Node3D).global_position
	return best

## Same substring rule quest_manager._on_enemy_killed uses, over living enemies.
func _nearest_enemy(target: String) -> Variant:
	if target == "":
		return null
	var player: Variant = _player_position()
	if player == null:
		return null
	var best: Variant = null
	var best_dist := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D) or not is_instance_valid(e) or not ("monster_id" in e):
			continue
		if "ai_state" in e and int(e.ai_state) == BaseMonster.State.DEAD:
			continue
		if not String(e.get("monster_id")).contains(target):
			continue
		var dist: float = (e as Node3D).global_position.distance_to(player)
		if dist < best_dist:
			best_dist = dist
			best = (e as Node3D).global_position
	return best

func _player_position() -> Variant:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not is_instance_valid(player):
		return null
	return player.global_position

func _make_arrow_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var color := ThemeProvider.COLOR_AMBER
	# Draw simple arrow pointing right
	for y in range(16):
		for x in range(16):
			if x >= 4 and x <= 11 and y >= 5 and y <= 10:
				if absf(y - 7.5) <= (x - 7.5) * 0.5:
					img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)