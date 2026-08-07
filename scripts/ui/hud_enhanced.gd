extends CanvasLayer

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/AmmoLabel
@onready var crosshair: TextureRect = $Crosshair
@onready var damage_overlay: ColorRect = $DamageOverlay

var _target_health: float = 100.0
var _current_health: float = 100.0

func _ready() -> void:
	damage_overlay.visible = false
	if GameManager.player and GameManager.player.health:
		GameManager.player.health.health_changed.connect(_on_health_changed)
	EventBus.ammo_changed.connect(_on_ammo_changed)

func _process(delta: float) -> void:
	_current_health = lerp(_current_health, _target_health, delta * 5.0)
	if health_bar:
		health_bar.value = _current_health
		health_label.text = str(int(_current_health)) + " / 100"
	if damage_overlay.visible:
		damage_overlay.modulate.a -= delta * 2.0
		if damage_overlay.modulate.a <= 0.0:
			damage_overlay.visible = false

func _on_health_changed(new_health: int) -> void:
	var old_health := _target_health
	_target_health = float(new_health)
	if new_health < old_health:
		damage_overlay.visible = true
		damage_overlay.modulate.a = 0.5

func _on_ammo_changed(current: int, max_ammo: int) -> void:
	if ammo_label:
		ammo_label.text = str(current) + " / " + str(max_ammo)