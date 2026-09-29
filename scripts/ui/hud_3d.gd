extends CanvasLayer

const BAR_W: float = 220.0
const BAR_H: float = 16.0
const BAR_ROW_PITCH: float = 34.0
const BAR_ROW_TOP: float = 30.0
const _SLOT_ITEMS: Array = [&"flashlight", &"battery", &"medkit", &"key", &"cable", &"fuse"]

var _hp: float = 1.0
var _stam: float = 1.0
var _bat: float = 1.0
var _battery_ad_button: Button = null
var _vignette_default_color: Color
## Shared by the hit beat and the sustained low-HP tint (see _on_hp).
var _vignette_tween: Tween
## Whether the dense low-HP state is currently on, so entry/exit is a one-shot.
var _vignette_low: bool = false
var _enemy_hp_tween: Tween
## PHASE 1 (languages = settings): HP/Stam/Bat captions are plain Labels
## created once in _add_captions(); cached here so a live language switch
## can re-text them without re-running that function's layout math.
var _hp_caption: Label
var _stam_caption: Label
var _bat_caption: Label

@onready var hp_fill: ColorRect = $TopLeft/HP/HPF
@onready var hp_val: Label = $TopLeft/HP/HPVal
@onready var stam_fill: ColorRect = $TopLeft/Stam/StamF
@onready var stam_val: Label = $TopLeft/Stam/StamVal
@onready var bat_fill: ColorRect = $TopLeft/Bat/BatF
@onready var bat_val: Label = $TopLeft/Bat/BatVal
@onready var ammo_val: Label = $AmmoCounter/AmmoVal
@onready var prompt: Label = $PromptLabel
@onready var notice: Label = $NoticeLabel
## VignetteOverlay создаётся PostProcessOverlay уже после готовности HUD,
## поэтому @onready ловил null и виньетка урона не работала — ищем лениво.
var _vignette_cache: ColorRect = null
var vignette: ColorRect:
	get:
		if is_instance_valid(_vignette_cache):
			return _vignette_cache
		_vignette_cache = get_tree().root.find_child("VignetteOverlay", true, false) as ColorRect
		return _vignette_cache
@onready var enemy_name_label: Label = $EnemyName
@onready var enemy_hp_bar: ColorRect = $EnemyHPBar

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_canonical_theme()
	_remove_dup_leftbottom()
	_apply_touch_visibility()
	_fix_radar_anchor()
	InputService.quick_slot_requested.connect(_on_quick_slot_key)
	hp_fill.color = Color(0.706, 0.271, 0.184)
	stam_fill.color = Color(0.373, 0.541, 0.306)
	bat_fill.color = Color(0.788, 0.635, 0.290)
	var player := get_tree().get_first_node_in_group("player")
	var hp_ratio := 1.0
	var stam_ratio := 1.0
	var bat_ratio := 1.0
	if player:
		var p_hp = player.get("hp")
		var p_stats = player.get("stats")
		var p_max_hp = p_stats.max_hp if (p_stats and "max_hp" in p_stats and p_stats.max_hp > 0) else 100.0
		hp_ratio = clampf(p_hp / p_max_hp, 0.0, 1.0) if (p_hp != null) else 1.0
		var p_bat = player.get("battery")
		bat_ratio = clampf(p_bat / 100.0, 0.0, 1.0) if (p_bat != null) else 1.0
	# _hp/_stam/_bat are the HUD's own memory of the last reported values (the
	# bars' widths are painted straight from the ratios above). Leaving _hp at its
	# 1.0 default meant a run that starts already hurt - continue after death, a
	# loaded save - had a stale "full health" until the first health event, which
	# every damage comparison and the low-HP tint below read.
	_hp = hp_ratio
	_stam = stam_ratio
	_bat = bat_ratio
	hp_fill.offset_right = hp_ratio * BAR_W
	stam_fill.offset_right = stam_ratio * BAR_W
	bat_fill.offset_right = bat_ratio * BAR_W
	hp_val.text = str(int(hp_ratio * 100))
	stam_val.text = str(int(stam_ratio * 100))
	bat_val.text = str(int(bat_ratio * 100))
	# Цвет по умолчанию читаем отложенно — оверлея ещё нет на этом кадре.
	call_deferred("_cache_vignette_default")
	_add_captions()
	_localize_static_labels()
	LocalizationManager.language_changed.connect(func(_l: String) -> void:
		_localize_static_labels()
		if _hp_caption: _hp_caption.text = LocalizationManager.t("HUD_HP")
		if _stam_caption: _stam_caption.text = LocalizationManager.t("HUD_STAMINA")
		if _bat_caption: _bat_caption.text = LocalizationManager.t("HUD_BATTERY"))
	_setup_number_fonts()
	_setup_slot_placeholders()
	_setup_radar()
	_setup_button_feedback()
	_apply_text_outlines()
	EventBus.player_health_changed.connect(_on_hp)
	if EventBus.has_signal(&"crosshair_state_changed"):
		EventBus.crosshair_state_changed.connect(_on_crosshair_state)
	EventBus.player_stamina_changed.connect(_on_stam)
	EventBus.player_battery_changed.connect(_on_bat)
	_add_battery_ad_button()
	_maybe_show_touch_calibration()
	EventBus.ammo_changed.connect(_on_ammo_changed)
	EventBus.player_interact_available.connect(func(avail: bool): prompt.visible = avail)
	EventBus.player_interact_available.connect(_pulse_interact_button)
	# Подсказка была вечно пустой строкой: текст в неё никто не писал.
	EventBus.interact_prompt_changed.connect(func(text: String) -> void: prompt.text = _interact_key_hint() + text)
	EventBus.inventory_weight_changed.connect(_on_weight_changed)
	# Badge counts froze at their _ready()-time snapshot: nothing refreshed
	# them on pickup/use/craft even though inventory_changed fires for all
	# three (inventory_manager.gd).
	EventBus.inventory_changed.connect(_refresh_slot_badges)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.item_consumed.connect(_on_item_consumed)
	EventBus.inventory_notice.connect(func(msg: String): _show_notice(msg))
	EventBus.player_detected.connect(_on_monster_spotted)
	EventBus.enemy_hp_updated.connect(_on_enemy_hp_updated)
	enemy_name_label.add_theme_font_size_override("font_size", 18)
	enemy_name_label.add_theme_color_override("font_color", Color(0.706, 0.271, 0.184))
	enemy_name_label.visible = false
	enemy_hp_bar.visible = false
	prompt.visible = false
	_setup_weight_bar()
	_setup_nv_poll()
	# Paint the real ammo/melee state on the first frame instead of leaving the
	# scene's placeholder "0 / 0" up for the first poll interval.
	_poll_weapon_state()
	_setup_status_row()
	_setup_weapon_compare()
	_setup_quick_wheel()
	_setup_grain_overlay()
	_setup_damage_indicator()
	_setup_heal_flash()
	_setup_blackout_flash()
	_setup_context_hints()
	$BtnPause.pressed.connect(_on_pause)
	_add_map_button()
	EventBus.game_state_changed.connect(_on_game_state)
	EventBus.hud_visibility_changed.connect(_on_hud_visibility)
	_apply_hud_opacity_setting()
	_on_game_state(int(GameManager.current_state))

func _cache_vignette_default() -> void:
	var v := vignette
	if v != null:
		_vignette_default_color = v.color
		# The overlay does not exist on the HUD's _ready frame, so the dense
		# low-HP state has to wait for its colour: a run that starts below the
		# threshold (respawn, loaded save) gets its tint here instead of never.
		_refresh_low_hp_vignette()

## Settings' "HUD Opacity" slider dims every node in the "hud" group
## (settings_manager.gd::set_hud_opacity), and nothing in the project ever
## joined that group — the 0.5..1.0 slider did nothing at all. hud_3d itself is
## a CanvasLayer, not a CanvasItem, so the group marks its top-level Controls
## instead: set_hud_opacity() skips non-CanvasItems, and a Control's modulate
## carries down to its whole subtree. Toasts are deliberately left out — they
## carry text the player may still need at 50 % opacity (QA-AC-03).
func _apply_hud_opacity_setting() -> void:
	for child in get_children():
		if child is Control:
			(child as Control).add_to_group("hud")
	# from_dict() re-applies the accessibility toggles after a config load, but
	# not the opacity slider, so the HUD paints the stored value itself.
	_apply_hud_opacity(float(SettingsManager.get_setting("hud_opacity", 1.0)))
	EventBus.settings_changed.connect(func(key: String, value: Variant) -> void:
		if key == "hud_opacity":
			_apply_hud_opacity(float(value)))

func _apply_hud_opacity(v: float) -> void:
	var a := clampf(v, 0.0, 1.0)
	for child in get_children():
		if child is Control:
			(child as Control).modulate.a = a

func _setup_nv_poll() -> void:
	var nv_poll := Timer.new()
	nv_poll.name = "NVPollTimer"
	nv_poll.wait_time = 0.1
	nv_poll.autostart = true
	nv_poll.timeout.connect(_poll_noise_visibility)
	nv_poll.timeout.connect(_poll_status_effects)
	nv_poll.timeout.connect(_poll_aim_target)
	nv_poll.timeout.connect(_poll_weapon_state)
	add_child(nv_poll)

## 3.12/6.5: полоска статусов игрока (BLEED/BURN/POISON/SLOW/STUN) — иконка 32x32
## с полоской длительности снизу, tween при появлении/исчезновении.
## glyph — запасной вариант, если PNG от арт-агента вдруг нет на диске.
##
## FEAR is deliberately absent from this table. Monsters do inflict it (the
## `roster` entry carrying [BLEED, FEAR] and base_monster.gd::_inflict_statuses
## pass it to the player, where status_effects.gd records it in `active`), but
## the effect itself is mob-only: it drives `_trigger_flee()` / State.FLEE, and
## the player has neither. On the player it is an inert timer, so drawing an
## icon would advertise an effect that does not exist - see the cross-zone note
## in the PR. DOT (BLEED/BURN/POISON) and SLOW are real on the player: the HUD
## reads the same `status_fx.active` the tick loop writes.
const _STATUS_ICONS: Dictionary = {
	EnemyRosterData.Status.BLEED: ["🩸", Color(0.706, 0.271, 0.184), "res://assets/textures/ui/status_bleed.png"],
	EnemyRosterData.Status.BURN: ["🔥", Color(0.851, 0.408, 0.176), "res://assets/textures/ui/status_burn.png"],
	EnemyRosterData.Status.POISON: ["☠", Color(0.373, 0.541, 0.306), "res://assets/textures/ui/status_poison.png"],
	EnemyRosterData.Status.SLOW: ["🐌", Color(0.541, 0.451, 0.220), "res://assets/textures/ui/status_slow.png"],
	EnemyRosterData.Status.STUN: ["💫", Color(0.788, 0.635, 0.290), "res://assets/textures/ui/status_stun.png"],
}
const _STATUS_ICON_SIZE: float = 32.0

var _status_row: HBoxContainer = null
var _status_icons: Dictionary = {}  # {int: Control}

func _setup_status_row() -> void:
	_status_row = HBoxContainer.new()
	_status_row.name = "StatusRow"
	_status_row.add_theme_constant_override("separation", 6)
	_status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tl: Control = $TopLeft
	_status_row.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_status_row.position = Vector2(tl.offset_left, tl.offset_bottom + 8.0)
	add_child(_status_row)

func _poll_status_effects() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var active: Dictionary = {}
	if player and "status_fx" in player and player.status_fx:
		active = player.status_fx.active
	for status in _STATUS_ICONS:
		var has: bool = active.has(status)
		var icon: Control = _status_icons.get(status)
		if has and icon == null:
			_status_icons[status] = _spawn_status_icon(status)
		elif not has and icon != null:
			_despawn_status_icon(status, icon)
		if has and _status_icons.has(status):
			_update_status_icon(_status_icons[status], active[status])

func _spawn_status_icon(status: int) -> Control:
	var data: Array = _STATUS_ICONS[status]
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(_STATUS_ICON_SIZE, _STATUS_ICON_SIZE)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.078, 0.098, 0.129, 0.85)
	sb.border_color = data[1]
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	box.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	box.add_child(vb)
	var icon_path: String = data[2]
	if ResourceLoader.exists(icon_path):
		var tex_rect := TextureRect.new()
		tex_rect.texture = load(icon_path)
		tex_rect.custom_minimum_size = Vector2(22.0, 22.0)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vb.add_child(tex_rect)
	else:
		var lbl := Label.new()
		lbl.text = data[0]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 16)
		vb.add_child(lbl)
	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.047, 0.063, 0.086)
	bar_bg.custom_minimum_size = Vector2(_STATUS_ICON_SIZE - 8.0, 3.0)
	vb.add_child(bar_bg)
	var bar_fill := ColorRect.new()
	bar_fill.name = "Fill"
	bar_fill.color = data[1]
	bar_fill.size = Vector2(_STATUS_ICON_SIZE - 8.0, 3.0)
	bar_bg.add_child(bar_fill)
	box.modulate.a = 0.0
	box.scale = Vector2(0.6, 0.6)
	box.pivot_offset = box.custom_minimum_size * 0.5
	_status_row.add_child(box)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(box, "modulate:a", 1.0, 0.2)
	tw.tween_property(box, "scale", Vector2.ONE, 0.2)
	return box

func _update_status_icon(icon: Control, state: Dictionary) -> void:
	var fill := icon.find_child("Fill", true, false) as ColorRect
	if fill == null:
		return
	var t: float = float(state.get("t", 0.0))
	var mx: float = maxf(float(state.get("max", 1.0)), 0.001)
	fill.size.x = (_STATUS_ICON_SIZE - 8.0) * clampf(t / mx, 0.0, 1.0)

func _despawn_status_icon(status: int, icon: Control) -> void:
	_status_icons.erase(status)
	var tw := create_tween()
	tw.tween_property(icon, "modulate:a", 0.0, 0.2)
	tw.tween_callback(icon.queue_free)

## T13: сравнение оружия при переключении. WeaponManager сейчас не привязан
## ни к одному игровому узлу (боевая система на мили) — ищем его мягко,
## без него виджет просто не появляется.
func _setup_weapon_compare() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var wm := player.get_node_or_null("WeaponManager")
	if wm == null or not wm.has_signal("weapon_switched"):
		return
	var ui_script := load("res://scripts/ui/weapon_compare_ui.gd")
	var ui := CanvasLayer.new()
	ui.set_script(ui_script)
	add_child(ui)
	wm.weapon_switched.connect(ui.on_weapon_switched)

## Permanent-night film grain, per art pass. Off on the LOW graphics tier
## (cheap fragment shader but still a full-screen sampled pass — not worth
## it once QualityManager has already dropped to LOW to protect FPS).
var _grain_rect: ColorRect = null

func _setup_grain_overlay() -> void:
	_grain_rect = ColorRect.new()
	_grain_rect.name = "GrainOverlay"
	_grain_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/grain_overlay.gdshader")
	_grain_rect.material = mat
	add_child(_grain_rect)
	_apply_grain_tier(int(SettingsManager.get_setting("graphics_tier", 2)))
	EventBus.settings_changed.connect(func(key: String, value: Variant) -> void:
		if key == "graphics_tier":
			_apply_grain_tier(int(value)))

func _apply_grain_tier(tier: int) -> void:
	if _grain_rect:
		_grain_rect.visible = tier > 0

## 3.15: damage direction indicator. `scripts/effects/damage_indicator.gd` and
## `scenes/effects/damage_indicator.tscn` were both committed and complete
## (pointer texture, screen-space direction math, its own ember shader) and
## player_3d.gd already emits EventBus.player_damage_direction from the real
## hit path — but no scene anywhere instantiated the indicator, so the pointer
## never rendered. This is the missing instance link only; the effect itself is
## unchanged.
var _damage_indicator: CanvasLayer = null

func _setup_damage_indicator() -> void:
	if _damage_indicator != null:
		return
	var indicator_scene: PackedScene = load("res://scenes/effects/damage_indicator.tscn")
	if indicator_scene == null:
		return
	_damage_indicator = indicator_scene.instantiate() as CanvasLayer
	if _damage_indicator == null:
		return
	add_child(_damage_indicator)

## A nested CanvasLayer keeps drawing even when the HUD layer it hangs under is
## hidden, so the indicator mirrors the HUD's own visibility instead.
func _sync_damage_indicator_visibility() -> void:
	if _damage_indicator != null and is_instance_valid(_damage_indicator):
		_damage_indicator.visible = visible

## T15: колесо быстрых слотов (удержание + аналоговый выбор из 6).
var _quick_wheel: Control = null

func _setup_quick_wheel() -> void:
	var wheel_script := load("res://scripts/ui/quick_wheel_ui.gd")
	_quick_wheel = Control.new()
	_quick_wheel.set_script(wheel_script)
	add_child(_quick_wheel)

func _setup_weight_bar() -> void:
	var w := $WeightBar
	if not w:
		return
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	if inv and inv.has_method("weight_ratio"):
		var ratio: float = inv.weight_ratio()
		w.value = ratio * 100.0
		_set_weight_color(w, ratio)
	var poll := Timer.new()
	poll.name = "WeightPollTimer"
	poll.wait_time = 0.2
	poll.autostart = true
	poll.timeout.connect(_poll_weight)
	add_child(poll)

## Бары шум/заметность (спека 3.10/3.11). Заполняются по игроку.
## get_node_or_null, а не $: при отсутствии ноды $ роняет весь _ready() HUD-а
## ("Node not found: TopLeft/NoiseLabel"), и вместе с ним гаснут HP/батарея.
## Ниже по коду все обращения и так закрыты проверками `if noise_fill:`.
@onready var noise_fill: ColorRect = get_node_or_null("TopLeft/NoiseF") as ColorRect
@onready var noise_caption: Label = get_node_or_null("TopLeft/NoiseLabel") as Label
@onready var vis_fill: ColorRect = get_node_or_null("TopLeft/VisibilityF") as ColorRect
@onready var vis_caption: Label = get_node_or_null("TopLeft/VisibilityLabel") as Label

const _BAR_L: float = 88.0
const _BAR_W: float = 222.0  # 88 -> 310 px

func _poll_noise_visibility() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		if noise_fill: noise_fill.visible = false
		if vis_fill: vis_fill.visible = false
		return
	var noise: float = 0.0
	if player.has_method("get_noise_level"):
		noise = float(player.get_noise_level())
	elif "noise_level" in player:
		noise = float(player.noise_level)
	noise = clampf(noise, 0.0, 1.0)
	var vis: float = 1.0
	if "visibility" in player:
		vis = float(player.visibility)
	vis = clampf(vis, 0.0, 1.0)
	if noise_fill:
		noise_fill.offset_right = _BAR_L + noise * _BAR_W
		noise_fill.color = _pick_noise_color(noise)
	if vis_fill:
		vis_fill.offset_right = _BAR_L + vis * _BAR_W
		vis_fill.color = _pick_vis_color(vis)

func _pick_noise_color(v: float) -> Color:
	if v < 0.34: return Color(0.373, 0.541, 0.306)  # stamina
	elif v < 0.67: return Color(0.788, 0.635, 0.290)  # brass
	else: return Color(0.706, 0.271, 0.184)  # ember

func _pick_vis_color(v: float) -> Color:
	# Видимость «наоборот» от шума: тихий+тёмный = зелёный.
	if v < 0.15: return Color(0.373, 0.541, 0.306)
	elif v < 0.5: return Color(0.788, 0.635, 0.290)
	else: return Color(0.706, 0.271, 0.184)

## 3.6 Спека: прицел меняет цвет по наведению на врага
## YAGNI: не делаем RayCast-tick, а слушаем EventBus.
## WAVE 6 P4: crosshair_state_changed раньше не слал никто и никогда -
## прицел был статичным ColorRect на одном and том же цвете всю игру.
## Теперь настоящая TextureRect-иконка (crosshair_64.png), а "hit" —
## не персистентное состояние, а отдельная вспышка hitmarker_64.png.
@onready var _crosshair: TextureRect = $Crosshair
@onready var _hit_marker: TextureRect = $HitMarker
var _hit_tween: Tween

const _CROSSHAIR_NAMES: Dictionary = {
	"default": Color(0.541, 0.451, 0.220, 0.85),   # brass-dim, hipfire
	"aim": Color(0.788, 0.635, 0.290, 0.95),        # brass, aiming down sights
	"enemy":  Color(0.706, 0.271, 0.184, 0.95),     # ember
	"disabled": Color(0.165, 0.200, 0.251, 0.6),    # panel-edge (недоступно/прицел-вне-врага)
}

func _update_crosshair(state: StringName) -> void:
	if state == &"hit":
		_flash_hit_marker()
		return
	if _crosshair == null:
		return
	if _CROSSHAIR_NAMES.has(state):
		_crosshair.modulate = _CROSSHAIR_NAMES[state]
	_crosshair.scale = Vector2(0.7, 0.7) if state == &"aim" else Vector2.ONE

func _flash_hit_marker() -> void:
	if _hit_marker == null:
		return
	if _hit_tween != null and _hit_tween.is_valid():
		_hit_tween.kill()
	_hit_marker.modulate.a = 1.0
	_hit_tween = create_tween()
	_hit_tween.tween_property(_hit_marker, "modulate:a", 0.0, 0.25)

## Last state the bus reported, so the empty-magazine override below can be
## lifted again the moment ammo comes back.
var _crosshair_state: StringName = &"default"
## -1 = no ammo_changed has arrived yet, so nothing overrides the crosshair.
var _ammo_current: int = -1

## Triggered по сигналу EventBus.crosshair_state_changed.
## Caller: игрок или система взаимодействия.
func _on_crosshair_state(state: StringName) -> void:
	# "hit" is a one-shot marker flash, not a persistent colour state - it must
	# keep working even with an empty magazine.
	if state == &"hit":
		_update_crosshair(state)
		return
	_crosshair_state = state
	_apply_crosshair_state()

## 3.6: the state table has a "disabled" colour documented as "недоступно", but
## nothing could ever reach it. An empty magazine is the one such condition the
## HUD can see for itself (EventBus.ammo_changed, already connected here), so it
## overrides the bus-reported state until a reload refills. "enemy" comes from
## the aim scan below - the bus itself only ever reports "default" (on fire) and
## the one-shot "hit" (enemy damaged).
func _apply_crosshair_state() -> void:
	if _ammo_current == 0:
		_update_crosshair(&"disabled")
	elif _aiming_at_enemy:
		_update_crosshair(&"enemy")
	else:
		_update_crosshair(_crosshair_state)

## The "enemy" colour had no producer anywhere in the project: the weapon emits
## "default" on fire, an enemy emits "hit" when hurt, and nothing ever said what
## the crosshair was pointed at. The HUD resolves the missing state itself, over
## the cone weapon_base.gd::_apply_auto_aim uses (12 deg), so the crosshair
## lights up on exactly the target auto-aim would help with. Runs on the
## existing 0.1 s NV poll.
const _AIM_CONE_DEG: float = 12.0
const _AIM_RANGE: float = 40.0
var _aiming_at_enemy: bool = false

func _poll_aim_target() -> void:
	if not GameManager.is_playing() or UIManager.is_hud_blocked():
		_set_aiming_at_enemy(false)
		return
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		_set_aiming_at_enemy(false)
		return
	var from: Vector3 = cam.global_position
	var forward: Vector3 = -cam.global_transform.basis.z
	var min_dot: float = cos(deg_to_rad(_AIM_CONE_DEG))
	var best: Node3D = null
	var best_dot: float = min_dot
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is Node3D) or not is_instance_valid(e) or not ("monster_id" in e):
			continue
		if "ai_state" in e and int(e.ai_state) == BaseMonster.State.DEAD:
			continue
		var to_enemy: Vector3 = (e as Node3D).global_position - from
		var dist: float = to_enemy.length()
		if dist > _AIM_RANGE or dist < 0.01:
			continue
		var dot: float = forward.dot(to_enemy / dist)
		if dot > best_dot:
			best_dot = dot
			best = e
	var target: Node3D = best if (best != null and _has_clear_shot(cam, best)) else null
	_set_aiming_at_enemy(target != null)
	if target != null:
		_show_enemy_bar(StringName(target.get("monster_id")), _hp_ratio_of(target))

## One raycast for the single best candidate rather than one per enemy per tick:
## the crosshair must not light up on a monster standing behind a wall. The ray
## starts at the camera, which sits inside the player's own capsule, so that
## body is excluded; whatever it does hit has to belong to an enemy.
func _has_clear_shot(cam: Camera3D, enemy: Node3D) -> bool:
	var space := cam.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, enemy.global_position + Vector3(0, 1.0, 0))
	var player := get_tree().get_first_node_in_group("player")
	var exclude_rids: Array[RID] = []
	if player is CollisionObject3D:
		exclude_rids.append((player as CollisionObject3D).get_rid())
	query.exclude = exclude_rids
	var result := space.intersect_ray(query)
	if result.is_empty():
		return false
	var collider: Object = result.get("collider")
	return collider is Node3D and (collider as Node3D).is_in_group("enemies")

func _set_aiming_at_enemy(on: bool) -> void:
	if on == _aiming_at_enemy:
		return
	_aiming_at_enemy = on
	_apply_crosshair_state()


func _poll_weight() -> void:
	var w := $WeightBar
	if not w:
		return
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	if inv and inv.has_method("weight_ratio"):
		var ratio: float = inv.weight_ratio()
		w.value = ratio * 100.0
		_set_weight_color(w, ratio)

## RELEASE CONVERGENCE STEP 4: a headless_suite language-switch scenario
## (mid scene-reload) intermittently fired this while the HUD was detached
## from the tree - get_tree() returning null then crashed on .root. Same
## root cause as world_env_setup.gd's _on_district_stage_changed guard
## below; the fix is the same shape: no-op when not attached, there is
## nothing meaningful to update on a detached node anyway.
func _on_weight_changed(weight: float) -> void:
	if not is_inside_tree():
		return
	var w := $WeightBar
	if not w:
		return
	var ratio := weight
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	if inv and inv.has_method("weight_ratio"):
		ratio = inv.weight_ratio()
	w.value = clampf(ratio * 100.0, 0.0, 100.0)
	_set_weight_color(w, ratio)

func _set_weight_color(w: Control, ratio: float) -> void:
	if ratio < 0.5:
		w.modulate = Color(0.373, 0.541, 0.306)
	elif ratio < 0.8:
		w.modulate = Color(0.788, 0.635, 0.290)
	else:
		w.modulate = Color(0.706, 0.271, 0.184)

func _on_game_state(state: int) -> void:
	visible = state == GameManager.GameState.PLAYING or state == GameManager.GameState.PAUSED
	if visible:
		# HUD лежит на layer 20, а все экраны UIManager — на layer 10, поэтому
		# бары и кнопка паузы рисовались ПОВЕРХ меню паузы и «Кодекса».
		# UIManager уже сообщает, когда открыт блокирующий экран, — слушаем его.
		visible = not UIManager.is_hud_blocked()
	_sync_damage_indicator_visibility()

## UIManager шлёт это при открытии/закрытии любого блокирующего экрана
## (пауза, кодекс, карта, настройки) и при входе/выходе из фоторежима.
func _on_hud_visibility(v: bool) -> void:
	visible = v and (GameManager.is_playing() or GameManager.is_paused())
	_sync_damage_indicator_visibility()

func has_touch_ui() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")

## GDD V.1 3.7: the prompt said what the interaction does ("Open", "Search",
## "Repair") but never which button does it. The key is read from the project's
## own "interact" action, so a rebound control shows the player's own binding;
## touch builds already get an on-screen button (_pulse_interact_button) and
## take no key prefix. The action is bound by physical keycode in project.godot,
## so keycode == KEY_NONE is the normal case here, not an edge one.
func _interact_key_hint() -> String:
	if has_touch_ui() or not InputMap.has_action(&"interact"):
		return ""
	for ev in InputMap.action_get_events(&"interact"):
		if ev is InputEventKey:
			var key := ev as InputEventKey
			var code: int = key.keycode if key.keycode != KEY_NONE else key.physical_keycode
			if code != KEY_NONE:
				return "[%s] " % OS.get_keycode_string(code)
	return ""

func _apply_touch_visibility() -> void:
	if not has_touch_ui():
		for path in ["BottomLeft", "BottomRight"]:
			var n := get_node_or_null(path) as CanvasItem
			if n != null:
				n.visible = false
		return
	_install_joystick()

## JoystickRing в сцене был просто нарисованным кольцом — двигать им игрока было
## нельзя. Вешаем на него virtual_joystick.gd, который пишет в InputService;
## отдельный джойстик из main_3d.gd больше не создаётся (было два кольца).
func _install_joystick() -> void:
	var ring := get_node_or_null("BottomLeft/JoystickRing") as Control
	if ring == null or ring.get_script() != null:
		return
	var js: Script = load("res://scripts/ui/virtual_joystick.gd")
	if js == null:
		return
	var joy := Control.new()
	joy.name = "JoystickInput"
	joy.set_script(js)
	joy.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joy.mouse_filter = Control.MOUSE_FILTER_STOP
	ring.add_child(joy)

func _fix_radar_anchor() -> void:
	var tr := get_node_or_null("TopRight") as Control
	if tr == null:
		return
	tr.grow_vertical = Control.GROW_DIRECTION_END
	tr.offset_bottom = tr.offset_top + tr.get_combined_minimum_size().y

## THEME UNIFICATION P0: hud_3d.tscn's root is a CanvasLayer, not a
## Control, so it has no .theme property of its own and can't inherit one
## from an ancestor Window either (confirmed empirically: Window.theme
## does not propagate to Controls added later in this engine build/
## context, only Control-to-Control ancestry does). 19 individual leaf
## nodes used to hardcode theme = data/ui/theme_main.tres directly (a
## separate, rounded-corner, pre-chamfer-canon theme) - setting the real
## theme once on each top-level Control child here reaches every one of
## them via normal Control ancestry, same coverage as before.
func _apply_canonical_theme() -> void:
	var t := ThemeProvider.build_theme()
	for child in get_children():
		if child is Control:
			(child as Control).theme = t

func _remove_dup_leftbottom() -> void:
	var vp := get_viewport().get_visible_rect().size
	for c in get_children():
		if c is Control and c.visible and c.name != "BottomLeft":
			var cr: Rect2 = c.get_global_rect()
			if cr.position.x < vp.x * 0.25 and cr.position.y + cr.size.y > vp.y * 0.75:
				c.queue_free()

## Noise/visibility/ammo/radar captions and the sprint/stealth touch
## buttons were hardcoded raw text (mixed Russian/English) in the .tscn
## with no code path ever overriding .text - permanently stuck in that
## exact mixed-language state in every locale.
func _localize_static_labels() -> void:
	if noise_caption != null:
		noise_caption.text = LocalizationManager.t("HUD_NOISE")
	if vis_caption != null:
		vis_caption.text = LocalizationManager.t("HUD_VISIBILITY")
	_apply_ammo_caption()
	var radar_label := get_node_or_null("TopRight/RadarLabel") as Label
	if radar_label != null:
		radar_label.text = LocalizationManager.t("HUD_RADAR")
	var btn_sprint := get_node_or_null("BottomRight/BtnSprint") as Button
	if btn_sprint != null:
		btn_sprint.text = LocalizationManager.t("HUD_SPRINT")
	var btn_stealth := get_node_or_null("BottomRight/BtnStealth") as Button
	if btn_stealth != null:
		btn_stealth.text = LocalizationManager.t("HUD_STEALTH")

func _add_captions() -> void:
	var data := [
		[LocalizationManager.t("HUD_HP"), $TopLeft/HP],
		[LocalizationManager.t("HUD_STAMINA"), $TopLeft/Stam],
		[LocalizationManager.t("HUD_BATTERY"), $TopLeft/Bat]
	]
	var outline_col := Color(0.047, 0.063, 0.086, 1.0)
	var shadow_col := Color(0.0, 0.0, 0.0, 0.5)
	var row: int = 0
	for d in data:
		var lbl := Label.new()
		lbl.text = d[0]
		lbl.mouse_filter = 2
		lbl.add_theme_color_override("font_color", Color(0.682, 0.714, 0.749))
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_outline_color", outline_col)
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.add_theme_color_override("font_shadow_color", shadow_col)
		lbl.add_theme_constant_override("shadow_offset_x", 1)
		lbl.add_theme_constant_override("shadow_offset_y", 1)
		d[1].add_child(lbl)
		var cap_h: float = maxf(lbl.get_combined_minimum_size().y, 12.0)
		lbl.size = Vector2(120, cap_h)
		lbl.position = Vector2(0, -cap_h - 2.0)
		var bar: Control = d[1]
		bar.position.y = float(row) * (BAR_ROW_PITCH)
		bar.offset_top = float(row) * BAR_ROW_PITCH + BAR_ROW_TOP
		bar.offset_bottom = bar.offset_top + BAR_H
		match row:
			0: _hp_caption = lbl
			1: _stam_caption = lbl
			2: _bat_caption = lbl
		row += 1
	row = _layout_extra_rows(row)
	var tl: Control = $TopLeft
	tl.offset_bottom = tl.offset_top + BAR_ROW_TOP + float(row) * BAR_ROW_PITCH

## Бары шума и заметности лежат в сцене с фиксированными y (66 и 86), а ряды
## HP/Stam/Bat выше раскладываются по BAR_ROW_PITCH и уезжают на 30/64/98.
## В итоге «ШУМ» рисовался ровно поверх выносливости, а «ЗАМЕТ.» — поверх
## батареи. Ставим их следующими рядами той же сетки.
func _layout_extra_rows(start_row: int) -> int:
	var rows := [
		[noise_caption, noise_fill, get_node_or_null("TopLeft/NoiseT")],
		[vis_caption, vis_fill, get_node_or_null("TopLeft/VisibilityT")],
	]
	var row := start_row
	for r in rows:
		var caption: Control = r[0]
		if caption == null:
			continue
		var top := float(row) * BAR_ROW_PITCH + BAR_ROW_TOP
		caption.offset_top = top
		caption.offset_bottom = top + BAR_H
		# Полоса и её подложка чуть тоньше подписи и выровнены по её центру.
		for bar in [r[2], r[1]]:
			var c: Control = bar
			if c == null:
				continue
			c.offset_top = top + 2.0
			c.offset_bottom = top + BAR_H - 2.0
		row += 1
	return row

func _setup_number_fonts() -> void:
	for lbl in [hp_val, stam_val, bat_val]:
		lbl.add_theme_color_override("font_color", Color(0.847, 0.824, 0.769))
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.text = "100"

func _apply_text_outlines() -> void:
	var outline_col := Color(0.047, 0.063, 0.086, 1.0)
	var shadow_col := Color(0.0, 0.0, 0.0, 0.5)
	for lbl in [hp_val, stam_val, bat_val, prompt, notice]:
		if lbl:
			lbl.add_theme_color_override("font_outline_color", outline_col)
			lbl.add_theme_constant_override("outline_size", 2)
			lbl.add_theme_color_override("font_shadow_color", shadow_col)
			lbl.add_theme_constant_override("shadow_offset_x", 1)
			lbl.add_theme_constant_override("shadow_offset_y", 1)
	_outline_recursive(self, outline_col, shadow_col)

func _outline_recursive(node: Node, oc: Color, sc: Color) -> void:
	if node is Label:
		node.add_theme_color_override("font_outline_color", oc)
		node.add_theme_constant_override("outline_size", 2)
		node.add_theme_color_override("font_shadow_color", sc)
		node.add_theme_constant_override("shadow_offset_x", 1)
		node.add_theme_constant_override("shadow_offset_y", 1)
	for c in node.get_children():
		_outline_recursive(c, oc, sc)

## GDD.md:213 (S03): noise indicator is an ember-vignette pulse at the
## screen edge, not a number. Reuses the same sin-pulse idiom the low-
## battery fill above already does. Same 0..1 noise scale as the noise bar
## (_poll_noise_visibility): RUN 0.8, WALK 0.4, STEALTH 0.3.
## Gated by reduce_flash (a11y_probe_scene already proves that toggle
## suppresses juice like this).
const _VIGNETTE_BG_DEEP := Color(0.047, 0.062, 0.086)
const _VIGNETTE_EMBER := Color(0.706, 0.271, 0.184)
const _VIGNETTE_PULSE_RATE: float = 0.006  # radians per ms (~1 s period)
## Cached for the per-frame vignette; re-fetched only after the player is freed.
var _vignette_player: Node = null
var _noise_reduce_flash_cache: bool = false
var _noise_reduce_flash_t: float = 0.0

func _process(delta: float) -> void:
	if _bat < 0.25:
		var pulse: float = sin(Time.get_ticks_msec() * 0.0095) * 0.5 + 0.5
		bat_fill.color = Color(0.788, 0.635, 0.290).lerp(Color(0.706, 0.271, 0.184), pulse)
	else:
		bat_fill.color = Color(0.788, 0.635, 0.290)
	_process_noise_vignette(delta)
	_process_enemy_bar(delta)

func _process_noise_vignette(delta: float) -> void:
	var v := vignette
	if v == null:
		return
	_noise_reduce_flash_t += delta
	if _noise_reduce_flash_t >= 1.0:
		_noise_reduce_flash_t = 0.0
		_noise_reduce_flash_cache = bool(SettingsManager.get_setting("reduce_flash", false))
	var pulse := 0.0
	if not is_instance_valid(_vignette_player):
		_vignette_player = get_tree().get_first_node_in_group("player")
	var player := _vignette_player
	if not _noise_reduce_flash_cache and player != null and player.has_method("get_noise_level"):
		var noise_ratio: float = clampf(float(player.get_noise_level()), 0.0, 1.0)
		pulse = (sin(Time.get_ticks_msec() * _VIGNETTE_PULSE_RATE) * 0.5 + 0.5) * noise_ratio
	# Only the tint pulses; alpha stays with the damage/low-HP tweens.
	var c := Color(_VIGNETTE_BG_DEEP, v.color.a).lerp(Color(_VIGNETTE_EMBER, v.color.a), pulse)
	if not v.color.is_equal_approx(c):
		v.color = c

## player_detected всегда шлёт StringName (см. event_bus.gd) — ветка на TYPE_INT
## никогда не выполнялась, а "ember #" + id было мусором, который игрок видел
## на каждой встрече с монстром в любой локали. Имя берём из тех же i18n-
## ключей, что уже наполнены для энциклопедии (MONSTER_SHADOW и т.д.).
func _on_monster_spotted(monster_id: StringName) -> void:
	_show_enemy_bar(monster_id, -1.0)

func _on_enemy_hp_updated(monster_id: StringName, ratio: float) -> void:
	_show_enemy_bar(monster_id, ratio)

## The enemy name/HP readout lives here, fed by three producers: the "spotted"
## event, a damage report, and - in the build that actually ships - the aim scan
## above, because EventBus.enemy_hp_updated still has no emitter (see the PR's
## cross-zone request). Each handler used to build its own tween and restart its
## own 2 s fade, so two producers could fight over the same nodes; the hold
## timer below is now the single owner of the fade-out and aiming at a living
## enemy simply keeps refreshing it.
const _ENEMY_BAR_HOLD: float = 2.0
var _enemy_bar_hold: float = 0.0
var _enemy_bar_id: String = ""

func _show_enemy_bar(monster_id: StringName, ratio: float) -> void:
	_enemy_bar_hold = _ENEMY_BAR_HOLD
	if ratio >= 0.0:
		enemy_hp_bar.scale.x = clampf(ratio, 0.0, 1.0)
	# Fresh target: (re)name the readout and fade it in once. Repeated ticks for
	# the same enemy only move the bar, so the fade cannot thrash at 10 Hz.
	if String(monster_id) == _enemy_bar_id and enemy_hp_bar.visible:
		return
	_enemy_bar_id = String(monster_id)
	# C04: routes through the same arachnophobia name-swap the encyclopedia
	# uses, so the "spotted" label never shows "Crawler" with the toggle on.
	var key := "MONSTER_" + String(LocalizationManager._display_monster_id(monster_id)).to_upper()
	enemy_name_label.text = LocalizationManager.t(key)
	enemy_name_label.visible = true
	enemy_hp_bar.visible = true
	if _enemy_hp_tween and _enemy_hp_tween.is_valid():
		_enemy_hp_tween.kill()
	_enemy_hp_tween = create_tween()
	_enemy_hp_tween.tween_property(enemy_name_label, "modulate:a", 1.0, 0.3).from(0.0)
	_enemy_hp_tween.parallel().tween_property(enemy_hp_bar, "modulate:a", 1.0, 0.3).from(0.0)

func _process_enemy_bar(delta: float) -> void:
	if _enemy_bar_hold <= 0.0:
		return
	_enemy_bar_hold -= delta
	if _enemy_bar_hold > 0.0:
		return
	_enemy_bar_id = ""
	if _enemy_hp_tween and _enemy_hp_tween.is_valid():
		_enemy_hp_tween.kill()
	_enemy_hp_tween = create_tween()
	_enemy_hp_tween.tween_property(enemy_name_label, "modulate:a", 0.0, 0.3)
	_enemy_hp_tween.parallel().tween_property(enemy_hp_bar, "modulate:a", 0.0, 0.3)
	_enemy_hp_tween.tween_callback(func() -> void:
		if is_instance_valid(enemy_name_label):
			enemy_name_label.visible = false
		if is_instance_valid(enemy_hp_bar):
			enemy_hp_bar.visible = false)

## -1 means "this enemy does not publish a health pool", which _show_enemy_bar
## reads as "leave the bar as it is" rather than as a full or empty pool.
func _hp_ratio_of(enemy: Node3D) -> float:
	if not ("hp" in enemy) or not ("max_hp" in enemy):
		return -1.0
	return clampf(float(enemy.get("hp")) / maxf(float(enemy.get("max_hp")), 0.001), 0.0, 1.0)



## GAMEFEEL_SPEC.md (`player_healed`): "soft green flash on HUD, no shake",
## cap "flash <= 120ms", toggle reduce_flash. EventBus.player_healed exists but
## has no emitter on it (player_3d.gd::heal() restores hp and stays quiet), so
## the HUD keys off the signal the consume path does send: inventory_manager.gd
## emits EventBus.item_consumed with _effect_name() == &"HEAL" for every
## healing consumable.
var _heal_flash: ColorRect = null
var _heal_tween: Tween

func _setup_heal_flash() -> void:
	_heal_flash = ColorRect.new()
	_heal_flash.name = "HealFlash"
	_heal_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_heal_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_heal_flash.color = Color(0.373, 0.541, 0.306, 0.0)
	_heal_flash.visible = false
	add_child(_heal_flash)

func _on_item_consumed(_item_id: StringName, effect: String, _value: float) -> void:
	# inventory_manager emits this *before* the effect is applied, so _hp here is
	# the pre-heal value: at full health the medkit is wasted and a green "you
	# were healed" flash would be a lie.
	if effect == "HEAL" and _hp < 1.0:
		_flash_heal()

## 50 + 70 ms = the 120 ms the spec allows, and a full-rect tint, so it goes
## through the same reduce_flash gate as the damage beat above (GAMEFEEL_SPEC.md
## §2 lists full-screen flash ColorRects). No shake, no strobe: one pulse.
func _flash_heal() -> void:
	if _heal_flash == null or not is_instance_valid(_heal_flash):
		return
	if bool(SettingsManager.get_setting("reduce_flash", false)):
		return
	_heal_flash.visible = true
	# Same one-owner rule as the vignette: two medkits in quick succession used to
	# leave two tweens on color:a, and the older one's completion callback hid the
	# rect in the middle of the newer pulse.
	if _heal_tween != null and _heal_tween.is_valid():
		_heal_tween.kill()
	_heal_tween = create_tween()
	_heal_tween.tween_property(_heal_flash, "color:a", 0.28, 0.05)
	_heal_tween.tween_property(_heal_flash, "color:a", 0.0, 0.07)
	_heal_tween.tween_callback(func() -> void:
		if is_instance_valid(_heal_flash):
			_heal_flash.visible = false)

## GAMEFEEL_SPEC.md (`district_blackout` / `light_disrupted`): "screen flash to
## black transition", "flash <= 120ms per pulse, no repeated strobe", and the
## spec marks reduce_flash on this row as a *hard* requirement - it is the one
## beat in the table called out as a real photosensitivity risk. So with the
## toggle on the flash is skipped outright, never shortened into something that
## still pulses. The blackout event names a district and the player only sees
## their own lights die, so the beat filters on where they are standing
## (DistrictManager.current_district is the authoritative field).
var _blackout_flash: ColorRect = null
var _blackout_tween: Tween

func _setup_blackout_flash() -> void:
	_blackout_flash = ColorRect.new()
	_blackout_flash.name = "BlackoutFlash"
	_blackout_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blackout_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blackout_flash.color = Color(0.0, 0.0, 0.0, 0.0)
	_blackout_flash.visible = false
	add_child(_blackout_flash)
	EventBus.district_blackout.connect(_on_district_blackout)
	EventBus.light_disrupted.connect(_pulse_blackout_flash)

func _on_district_blackout(district_id: StringName) -> void:
	if StringName(DistrictManager.current_district) != district_id:
		return
	_pulse_blackout_flash()
	_hint_light_source()

## 50 + 70 ms = the 120 ms the spec allows, one pulse per event, and a full-rect
## tint, so it goes through the same reduce_flash gate as the damage and heal
## beats above.
func _pulse_blackout_flash() -> void:
	if _blackout_flash == null or not is_instance_valid(_blackout_flash):
		return
	if bool(SettingsManager.get_setting("reduce_flash", false)):
		return
	_blackout_flash.visible = true
	if _blackout_tween != null and _blackout_tween.is_valid():
		_blackout_tween.kill()
	_blackout_tween = create_tween()
	_blackout_tween.tween_property(_blackout_flash, "color:a", 0.55, 0.05)
	_blackout_tween.tween_property(_blackout_flash, "color:a", 0.0, 0.07)
	_blackout_tween.tween_callback(func() -> void:
		if is_instance_valid(_blackout_flash):
			_blackout_flash.visible = false)

## GDD V.1 3.8: contextual hints. The sheet's example line is exactly the
## situation this covers - the player is in the dark with no light of their own,
## either because the district they stand in just lost power or because they
## walked into one that already has none. The "hints" toggle from
## settings_screen.gd (and the NG+ Keeper's Pact knob built on the same setting)
## is the switch such a hint is expected to honour, and the notice label the
## tracker already uses for messages is the surface for it.
var _flashlight_on: bool = true

func _setup_context_hints() -> void:
	EventBus.flashlight_state_changed.connect(func(on: bool) -> void:
		_flashlight_on = on)
	EventBus.district_entered.connect(func(id: StringName) -> void:
		if PowerGrid.get_stage(id) == DistrictData.Stage.DARK:
			_hint_light_source())
	# A load can restore a run that already had the flashlight switched off, and
	# no state_changed fires for it - read the field once so the hint is not
	# skipped for someone who is genuinely standing in the dark.
	var player := get_tree().get_first_node_in_group("player")
	if player != null and "flashlight_enabled" in player:
		_flashlight_on = bool(player.flashlight_enabled)

func _hint_light_source() -> void:
	if not bool(SettingsManager.get_setting("hints", true)):
		return
	if _flashlight_on:
		return
	_show_notice(LocalizationManager.t("HUD_HINT_DARK"))

## Peak of the screen-wide ember beat, and the HP below which the vignette stays
## dense. Named because docs/GAMEFEEL_SPEC.md §1 measures full-screen beats by
## alpha and ramp length - this is the documented exceedance the lead still has
## to rule on (see the PR).
const _VIGNETTE_BEAT_PEAK: float = 0.8
const _LOW_HP: float = 0.3

## Vignette ownership: one handler, one tween.
##
## The ember beat used to be a *second* handler on this same signal, connected
## after _on_hp and guarded by `ratio < _hp` - but _on_hp had already written _hp
## by the time it ran, so that comparison was never true and the beat never
## played at all. The sustained low-HP state had the mirror problem: it animated
## only downward, so healing back above the threshold left the dense tint on
## screen for the rest of the run. Both are driven from here now, with the
## previous value in hand, and the alpha they settle on is always recomputed from
## the current HP.
func _on_hp(ratio: float) -> void:
	var took_damage: bool = ratio < _hp
	_hp = ratio
	_tween_fill(hp_fill, ratio)
	hp_val.text = str(int(ratio * 100))
	# This is a full-screen beat (VignetteOverlay is a full-rect ColorRect), so it
	# honours reduce_flash - the same toggle that already silences the noise
	# vignette pulse below, and the one GAMEFEEL_SPEC.md §2 lists for full-screen
	# flash ColorRects. The sustained low-HP state below stays: legibility, not a
	# flash.
	if took_damage and not bool(SettingsManager.get_setting("reduce_flash", false)):
		_animate_vignette(_VIGNETTE_BEAT_PEAK, 0.25)
	_refresh_low_hp_vignette()

func _sustained_vignette_alpha() -> float:
	return maxf(_vignette_default_color.a, 0.6) if _hp < _LOW_HP else _vignette_default_color.a

## The single tween for both animations on vignette.color:a - a newer beat kills
## the older one instead of the two racing to write the same property.
func _animate_vignette(peak: float, settle_time: float) -> void:
	var v := vignette
	if v == null:
		return
	if _vignette_tween != null and _vignette_tween.is_valid():
		_vignette_tween.kill()
	_vignette_tween = create_tween()
	_vignette_tween.tween_property(v, "color:a", peak, 0.15)
	_vignette_tween.tween_property(v, "color:a", _sustained_vignette_alpha(), settle_time)

## Entering the dense state pulses once; leaving it relaxes without a spike.
func _refresh_low_hp_vignette() -> void:
	var low: bool = _hp < _LOW_HP
	if low == _vignette_low:
		return
	_vignette_low = low
	_animate_vignette(_VIGNETTE_BEAT_PEAK if low else _vignette_default_color.a, 0.15)

func _on_stam(ratio: float) -> void:
	_stam = ratio
	_tween_fill(stam_fill, ratio)
	stam_val.text = str(int(ratio * 100))

func _on_bat(ratio: float) -> void:
	_bat = ratio
	_tween_fill(bat_fill, ratio)
	bat_val.text = str(int(ratio * 100))
	if _battery_ad_button != null and is_instance_valid(_battery_ad_button) and not _battery_ad_button.disabled:
		_battery_ad_button.visible = ratio < 0.3

## FINAL PERFECTION P5: extra_battery reward was wired end-to-end in
## GameManager._on_ad_reward() (adds 50 charge) but had no UI trigger -
## AdService.show_rewarded(&"extra_battery") was never called from
## anywhere. Same pattern as death_screen.gd's _add_revive_button().
## FINAL HARDENING PASS (BLOCKER 3): one-time touch calibration on first
## touch-device launch - drag the joystick, tap interact, feel the haptic
## pulse. has_touch_ui() already gates every other touch-only setup here.
func _maybe_show_touch_calibration() -> void:
	if not has_touch_ui():
		return
	if SettingsManager.get_setting("touch_calibration_done", false):
		return
	var overlay: Control = load("res://scripts/ui/touch_calibration_overlay.gd").new()
	get_tree().root.add_child(overlay)

func _add_battery_ad_button() -> void:
	if not AdService.can_show_reward(&"extra_battery"):
		return
	var bat_row: Control = get_node_or_null("TopLeft/Bat")
	if bat_row == null:
		return
	var btn := Button.new()
	btn.name = "BatteryAdButton"
	btn.text = LocalizationManager.t("AD_EXTRA_BATTERY")
	btn.visible = false
	# Long locales (ru/fr ~2x the EN length) overflow a fixed 150px button —
	# wrap to a second line instead of spilling past the edge.
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.custom_minimum_size = Vector2(150, 40)
	btn.position = Vector2(0, 22)
	btn.pressed.connect(func() -> void:
		btn.disabled = true
		btn.visible = false
		AdService.show_rewarded(&"extra_battery"))
	bat_row.add_child(btn)
	_battery_ad_button = btn

func _on_ammo_changed(current: int, max_ammo: int) -> void:
	ammo_val.text = "%d / %d" % [current, max_ammo]
	_ammo_current = current
	_apply_crosshair_state()

## V.1 3.13: this widget never had a live source. WeaponManager/WeaponBase are
## committed but no scene instantiates either (weapon_pickup.gd:31-34 says so
## itself) and GDD §5 is melee-only canon, so EventBus.ammo_changed never fires
## in a real run and the counter sat on the scene's default "0 / 0" - a number
## that was simply false. The HUD now does what weapon_compare_ui.gd already
## does for the same missing manager: look for it softly on the player. With a
## weapon attached the counter mirrors its live magazine; without one (the
## shipping build) it reports melee mode instead of inventing ammunition.
var _weapon_present: bool = false

func _poll_weapon_state() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var weapon: Node = _find_player_weapon(player)
	var present: bool = weapon != null and is_instance_valid(weapon)
	if present and "current_ammo" in weapon and "max_ammo" in weapon:
		_on_ammo_changed(int(weapon.get("current_ammo")), int(weapon.get("max_ammo")))
	elif _ammo_current >= 0:
		# The weapon went away mid-run; drop the stale reading rather than
		# leaving the crosshair greyed by an empty magazine that no longer exists.
		_ammo_current = -1
		_apply_crosshair_state()
	if present != _weapon_present:
		_weapon_present = present
		_apply_ammo_caption()

## Soft discovery, the same shape weapon_compare_ui.gd uses for the very same
## manager: a WeaponManager child that can name its current weapon, or a bare
## WeaponBase attached straight to the player.
func _find_player_weapon(player: Node) -> Node:
	if player == null or not is_instance_valid(player):
		return null
	var manager := player.get_node_or_null("WeaponManager")
	if manager != null and manager.has_method("get_current_weapon"):
		return manager.call("get_current_weapon")
	for child in player.get_children():
		if child is WeaponBase:
			return child
	return null

func _apply_ammo_caption() -> void:
	var caption := get_node_or_null("AmmoCounter/AmmoCaption") as Label
	if caption != null:
		caption.text = LocalizationManager.t("HUD_AMMO" if _weapon_present else "HUD_MELEE")
	if ammo_val != null:
		ammo_val.visible = _weapon_present

func _tween_fill(cr: ColorRect, ratio: float) -> void:
	var target: float = clampf(ratio, 0.0, 1.0) * BAR_W
	var tween := create_tween()
	tween.tween_property(cr, "offset_right", target, 0.15)
	tween.play()

func _on_pause() -> void:
	if UIManager and UIManager.has_method("toggle"):
		UIManager.toggle(&"pause")

func _setup_button_feedback() -> void:
	for b in [$BottomRight/BtnAttack, $BottomRight/BtnSprint, $BottomRight/BtnStealth, $BottomRight/BtnInteract]:
		if b:
			b.pressed.connect(_on_btn_pressed.bind(b))
	_wire_action_buttons()

func _wire_action_buttons() -> void:
	var isv := get_node_or_null("/root/InputService")
	if not isv:
		return
	var attack := $BottomRight/BtnAttack
	var sprint := $BottomRight/BtnSprint
	var stealth := $BottomRight/BtnStealth
	var interact := $BottomRight/BtnInteract
	if attack:
		attack.button_down.connect(func() -> void: isv.request_attack())
	if sprint:
		sprint.button_down.connect(func() -> void: isv.set_joy_run_held(true))
		sprint.button_up.connect(func() -> void: isv.set_joy_run_held(false))
	if stealth:
		stealth.button_down.connect(func() -> void:
			isv.set_joy_stealth_toggled(not isv.is_stealth_toggled()))
	if interact:
		interact.button_down.connect(func() -> void: isv.request_interact())
	_add_side_buttons(isv)

func _on_btn_pressed(btn: Button) -> void:
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.04)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.04)
	if OS.has_feature("mobile") and SettingsManager != null and SettingsManager.haptics_enabled():
		Input.vibrate_handheld(15)

## GOLD MASTER v4: BtnInteract gets a slow brass pulse while something is
## in reach — the touch-only equivalent of the PC prompt label appearing.
var _interact_pulse: Tween = null
func _pulse_interact_button(on: bool) -> void:
	var btn := get_node_or_null("BottomRight/BtnInteract") as Button
	if btn == null:
		return
	if _interact_pulse != null and _interact_pulse.is_valid():
		_interact_pulse.kill()
	if not on:
		btn.modulate = Color.WHITE
		return
	_interact_pulse = create_tween().set_loops()
	_interact_pulse.tween_property(btn, "modulate", Color(1.3, 1.15, 0.8), 0.5)
	_interact_pulse.tween_property(btn, "modulate", Color.WHITE, 0.5)

## Кнопки-«спутники» правого кластера. Раньше они позиционировались абсолютными
## пикселями от 1920x1080 и на телефоне уезжали за экран — теперь якорятся к
## правому нижнему углу, а размер берётся из TOUCH_BTN (палец ~48-64 px).
const TOUCH_BTN: Vector2 = Vector2(64, 64)

func _add_side_buttons(isv: Node) -> void:
	if not has_touch_ui():
		return
	var anchored := func(node: Control, from_right: float, from_bottom: float) -> void:
		node.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		node.offset_left = -from_right - node.custom_minimum_size.x
		node.offset_right = -from_right
		node.offset_top = -from_bottom - node.custom_minimum_size.y
		node.offset_bottom = -from_bottom
	var mk := func(nm: String, label: String, cb: Callable) -> Button:
		var b := Button.new()
		b.name = nm
		b.text = label
		b.custom_minimum_size = TOUCH_BTN
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 22)
		b.button_down.connect(cb)
		add_child(b)
		return b
	var jump := mk.call("BtnJump", "↑", func() -> void: isv.request_jump()) as Button
	anchored.call(jump, 20.0, 250.0)
	var flash := mk.call("BtnFlash", "☀", func() -> void: isv.request_flashlight()) as Button
	anchored.call(flash, 100.0, 250.0)
	# Стробоскоп (GDD §3.1) — отдельная кнопка, на ПК это клавиша C.
	# Приседание уже висит на BtnStealth в сцене — второй кнопки не нужно.
	var strobe := mk.call("BtnStrobe", "⚡", func() -> void: _request_strobe()) as Button
	anchored.call(strobe, 180.0, 250.0)
	# T15: колесо быстрых слотов — держать, вести пальцем, отпустить.
	var wheel := mk.call("BtnWheel", "◎", func() -> void: if _quick_wheel: _quick_wheel.open()) as Button
	anchored.call(wheel, 260.0, 250.0)
	wheel.button_up.connect(func() -> void: if _quick_wheel: _quick_wheel.close(true))

func _request_strobe() -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p != null and p.has_method("trigger_strobe"):
		p.call("trigger_strobe")

func _setup_slot_placeholders() -> void:
	var item_icons := preload("res://scripts/ui/item_icons.gd")
	var order := _SLOT_ITEMS
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	for i in 6:
		var slot := get_node("BottomCenter/Slot" + str(i))
		if not slot:
			continue
		for child in slot.get_children():
			child.queue_free()
		# V2 SKIN WIRING P1: real slot chrome texture in place of the flat
		# color swatch; falls back to the old ColorRect if missing on disk.
		var chrome_path := "res://assets/textures/ui_v2/quickslot_v2_72.png"
		var border: Control
		if ResourceLoader.exists(chrome_path):
			var tex_border := TextureRect.new()
			tex_border.texture = load(chrome_path)
			tex_border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_border.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			border = tex_border
		else:
			border = ColorRect.new()
			(border as ColorRect).color = Color(0.165, 0.200, 0.251)
		border.name = "Border"
		border.size = Vector2(54, 54)
		border.position = Vector2(-1, -1)
		border.mouse_filter = Control.MOUSE_FILTER_PASS
		slot.add_child(border)
		var icon_parent := Control.new()
		icon_parent.name = "IconParent"
		icon_parent.size = Vector2(48, 48)
		icon_parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon_parent)
		var item_id: StringName = order[i] if i < order.size() else &""
		item_icons.draw_icon(icon_parent, item_id, 32.0)
		var badge := Label.new()
		badge.name = "Badge"
		badge.text = "0"
		badge.add_theme_color_override("font_color", Color(0.847, 0.824, 0.769))
		badge.add_theme_font_size_override("font_size", 11)
		badge.position = Vector2(34, 34)
		slot.add_child(badge)
		if inv and item_id != &"":
			var cnt: int = inv.count_of(item_id)
			if cnt > 0:
				badge.text = str(cnt)
		var si := i
		slot.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_use_quick_slot(si)
		)
	var slot0 := get_node("BottomCenter/Slot0")
	if slot0:
		var border := slot0.get_node_or_null("Border")
		if border is ColorRect:
			(border as ColorRect).color = Color(0.788, 0.635, 0.290)
		elif border is CanvasItem:
			(border as CanvasItem).modulate = Color(0.788, 0.635, 0.290)

func _on_quick_slot_key(index: int) -> void:
	_use_quick_slot(index)

func _use_quick_slot(index: int) -> void:
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	if not inv or not inv.has_method("use_item"):
		return
	inv.use_item(index)

func _refresh_slot_badges() -> void:
	var inv := get_tree().root.get_node_or_null("InventoryManager")
	if not inv:
		return
	for i in _SLOT_ITEMS.size():
		var slot := get_node_or_null("BottomCenter/Slot" + str(i))
		var badge: Label = slot.get_node_or_null("Badge") if slot else null
		if not badge:
			continue
		var item_id: StringName = _SLOT_ITEMS[i]
		badge.text = str(inv.count_of(item_id))

## docs/GAMEFEEL_SPEC.md, "New events to juice": item_picked_up -> a brief
## flash on the quick slot that received the item, opacity ramp only, <= 120 ms,
## skipped entirely under reduce_flash (that spec's toggle for HUD flash beats).
## The slot only holds one flash at a time, so a fast double pickup restarts the
## ramp instead of stacking overlays.
const _SLOT_FLASH_SEC: float = 0.12
const _SLOT_FLASH_ALPHA: float = 0.45
const _SLOT_FLASH_NAME: String = "PickupFlash"

func _on_item_picked_up(item_id: StringName) -> void:
	var index := _SLOT_ITEMS.find(item_id)
	if index < 0:
		return
	if bool(SettingsManager.get_setting("reduce_flash", false)):
		return
	var slot := get_node_or_null("BottomCenter/Slot" + str(index)) as Control
	if slot == null:
		return
	var flash := slot.get_node_or_null(_SLOT_FLASH_NAME) as ColorRect
	if flash == null:
		flash = ColorRect.new()
		flash.name = _SLOT_FLASH_NAME
		flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(flash)
	flash.color = Color(ThemeProvider.COLOR_AMBER, _SLOT_FLASH_ALPHA)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(flash, "color:a", 0.0, _SLOT_FLASH_SEC)
	tw.tween_callback(flash.queue_free)

## Below the 5th status row (VISIBILITY at y~190): at y=182 the button
## covered the caption ("...ILITY" in docs/stills/tzverify frames).
const _MAP_BUTTON_POS := Vector2(16, 216)

func _add_map_button() -> void:
	var btn := Button.new()
	btn.name = "MapButton"
	btn.position = _MAP_BUTTON_POS
	btn.size = Vector2(48, 48)
	btn.add_theme_color_override("font_color", Color(0.788, 0.635, 0.290))
	btn.add_theme_font_size_override("font_size", 20)
	btn.text = "🗺"
	btn.pressed.connect(_on_map_btn)
	add_child(btn)

func _on_map_btn() -> void:
	if UIManager and UIManager.has_method("open"):
		UIManager.open(&"city_map")

func _setup_radar() -> void:
	var frame := $TopRight/RadarFrame
	if not frame:
		return
	for c in frame.get_children():
		c.queue_free()
	var radar_script = load("res://scripts/ui/radar.gd")
	if not radar_script:
		return
	var radar := Control.new()
	radar.set_script(radar_script)
	radar.name = "Radar"
	frame.add_child(radar)
	radar.set_anchors_preset(Control.PRESET_FULL_RECT)

func _show_notice(msg: String) -> void:
	notice.text = msg
	await get_tree().create_timer(3.0).timeout
	# The HUD can be torn down (death -> scene reload) during the 3s wait —
	# don't touch `notice` on a freed instance.
	if not is_instance_valid(notice):
		return
	if notice.text == msg:
		notice.text = ""
