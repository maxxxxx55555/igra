extends Control
## HUD: HP / Ammo / Battery / Flashlight — TextureRect icons + ProgressBar values.
## Values animate via Tween. Listens to EventBus signals.

const _TEX_HEALTH     := "res://assets/ui/ui_health.svg"
const _TEX_AMMO       := "res://assets/ui/ui_ammo.svg"
const _TEX_BATTERY    := "res://assets/ui/ui_battery.svg"
const _TEX_FLASHLIGHT := "res://assets/ui/ui_flashlight.svg"

@onready var _hp_bar:    ProgressBar = $Bars/HPRow/Bar
@onready var _ammo_bar:  ProgressBar = $Bars/AmmoRow/Bar
@onready var _bat_bar:   ProgressBar = $Bars/BatRow/Bar
@onready var _fl_bar:    ProgressBar = $Bars/FlRow/Bar

@onready var _hp_icon:   TextureRect = $Bars/HPRow/Icon
@onready var _ammo_icon: TextureRect = $Bars/AmmoRow/Icon
@onready var _bat_icon:  TextureRect = $Bars/BatRow/Icon
@onready var _fl_icon:   TextureRect = $Bars/FlRow/Icon

var _tween: Tween

func _ready() -> void:
	_load_icons()
	EventBus.player_health_changed.connect(_on_health)
	EventBus.ammo_changed.connect(_on_ammo)
	EventBus.player_battery_changed.connect(_on_battery)
	EventBus.flashlight_state_changed.connect(_on_flashlight)
	EventBus.hud_visibility_changed.connect(func(v: bool) -> void: visible = v)
	visible = false

func _load_icons() -> void:
	_set_icon(_hp_icon,   _TEX_HEALTH)
	_set_icon(_ammo_icon, _TEX_AMMO)
	_set_icon(_bat_icon,  _TEX_BATTERY)
	_set_icon(_fl_icon,   _TEX_FLASHLIGHT)

func _set_icon(tr: TextureRect, path: String) -> void:
	var tex: Texture2D = load(path)
	if tex:
		tr.texture = tex

func _tween_bar(bar: ProgressBar, target: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(bar, "value", target * 100.0, 0.25).set_ease(Tween.EASE_OUT)

func _on_health(ratio: float) -> void:
	_tween_bar(_hp_bar, ratio)

func _on_ammo(current: int, max_ammo: int) -> void:
	var ratio: float = float(current) / float(max(max_ammo, 1))
	_tween_bar(_ammo_bar, ratio)

func _on_battery(ratio: float) -> void:
	_tween_bar(_bat_bar, ratio)

func _on_flashlight(enabled: bool) -> void:
	_fl_icon.modulate = Color(1, 1, 1, 1.0) if enabled else Color(1, 1, 1, 0.35)
