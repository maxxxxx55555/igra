extends Node
## MonsterTelegraph — добавляется как дочерний узел к любому врагу.
## Вызов: telegraph.warn(callback) — вспышка + звук за 0.4 с до удара.
## Подключи в base_monster.gd: _telegraph.warn(func() -> void: _deal_damage())

const WARN_DURATION: float = 0.4

@export var flash_color: Color = Color(1.0, 0.2, 0.1, 0.8)
@export var warn_sfx_path: String = "res://assets/audio/sfx/sfx_enemy_warn.wav"

var _mesh_owner: MeshInstance3D = null
var _original_modulate: Color = Color.WHITE

func _ready() -> void:
	# Ищем MeshInstance3D у родителя
	for child in get_parent().get_children():
		if child is MeshInstance3D:
			_mesh_owner = child
			break

func warn(attack_callback: Callable) -> void:
	_flash()
	_play_warn_sfx()
	var tw := create_tween()
	tw.tween_interval(WARN_DURATION)
	tw.tween_callback(attack_callback)

func _flash() -> void:
	if _mesh_owner == null:
		return
	_original_modulate = _mesh_owner.get_instance_shader_parameter("modulate") if false else Color.WHITE
	var tw := create_tween()
	tw.tween_property(_mesh_owner, "modulate", flash_color, 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mesh_owner, "modulate", Color.WHITE, 0.12).set_ease(Tween.EASE_IN)
	tw.tween_property(_mesh_owner, "modulate", flash_color, 0.08).set_ease(Tween.EASE_OUT)
	tw.tween_property(_mesh_owner, "modulate", Color.WHITE, 0.12).set_ease(Tween.EASE_IN)

func _play_warn_sfx() -> void:
	var sfx: AudioStream = load(warn_sfx_path)
	if sfx == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = sfx
	player.max_distance = 12.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	get_parent().add_child(player)
	player.play()
	var tw := create_tween()
	tw.tween_interval(sfx.get_length() + 0.1)
	tw.tween_callback(player.queue_free)
