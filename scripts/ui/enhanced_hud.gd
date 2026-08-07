

extends CanvasLayer

@onready 

var health_bar: ProgressBar = $HealthBar

@onready 

var health_label: Label = $HealthLabel

@onready 

var battery_bar: ProgressBar = $BatteryBar

@onready 

var battery_label: Label = $BatteryLabel

@onready 

var minimap: Control = $MiniMap

@onready 

var enemy_health_label: Label = $EnemyHealthLabel
var _current_health: float = 100.0
var _target_health: float = 100.0
var _battery: float = 100.0
var _nearest_enemy: Node3D = null
func _ready() -> void:
	if GameManager.player:
		if GameManager.player.has_node("HealthComponent"):
			GameManager.player.get_node("HealthComponent").health_changed.connect(_on_health_changed)
		if GameManager.player.has_node("Flashlight"):
			_update_battery()
		get_tree().create_timer(1.0).timeout.connect(_update_battery)
	EventBus.enemy_died.connect(_on_enemy_died)

func _process(delta: float) -> void:
	_current_health = lerp(_current_health, _target_health, delta * 3.0)
	if health_bar:
		health_bar.value = _current_health
		health_label.text = str(int(_current_health)) + " / 100"
	_update_battery()
	_find_nearest_enemy()
	if _nearest_enemy and _nearest_enemy.has_node("HealthComponent"):
		var enemy_health = _nearest_enemy.get_node("HealthComponent")
		enemy_health_label.text = "HUNTER"
		enemy_health_label.visible = true
	else:
		enemy_health_label.visible = false

func _on_health_changed(new_health: int) -> void:
	_target_health = new_health

func _update_battery() -> void:
	if GameManager.player and GameManager.player.has_node("Flashlight"):
		var flashlight = GameManager.player.get_node("Flashlight")
		if flashlight.has_method("get_battery"):
			_battery = flashlight.get_battery()
		else:
			_battery = max(0, _battery - 0.05)
		if battery_bar:
			battery_bar.value = _battery
			battery_label.text = str(int(_battery)) + "%"
			if _battery < 20:
				battery_bar.modulate = Color(1, 0.2, 0.2)
			elif _battery < 50:
				battery_bar.modulate = Color(1, 0.8, 0.2)
			else:
				battery_bar.modulate = Color(0.2, 1.0, 0.2)

func _find_nearest_enemy() -> void:
	if not GameManager.player:
		return
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node3D = null
	var nearest_dist: float = 10.0
	for enemy in enemies:
		if enemy.has_node("HealthComponent") and enemy.get_node("HealthComponent").current_health > 0:
			var dist = GameManager.player.global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest = enemy
				nearest_dist = dist
	_nearest_enemy = nearest
func _on_enemy_died(pos: Vector3) -> void:
	# Flash effect or notification
	pass