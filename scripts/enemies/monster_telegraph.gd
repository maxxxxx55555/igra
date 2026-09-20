extends Node
## MonsterTelegraph — добавляется как дочерний узел к любому врагу.
## Вызов: telegraph.warn(callback) — вспышка + звук за 0.4 с до удара.
## Подключи в base_monster.gd: _telegraph.warn(func() -> void: _deal_damage())

const WARN_DURATION: float = 0.4

@export var flash_color: Color = Color(1.0, 0.2, 0.1, 0.8)
@export var warn_sfx_path: String = "res://assets/audio/sfx/sfx_enemy_warn.wav"

## GAME_AUDIT/arena design audit P8: _mesh_owner used to be resolved once in
## _ready() by scanning only direct children - too early (base_monster.gd
## adds this node before _build_visual() creates any mesh) and too shallow
## (base monsters nest it at VisualRoot/BodyMesh, not a direct child), so
## _mesh_owner stayed null forever and the warning was invisible. Resolved
## lazily at warn() time instead, once visuals are guaranteed to exist.
var _mesh_owner: MeshInstance3D = null

func warn(attack_callback: Callable) -> void:
	if _mesh_owner == null or not is_instance_valid(_mesh_owner):
		_mesh_owner = _find_mesh(get_parent())
	_flash()
	_play_warn_sfx()
	var tw := create_tween()
	tw.tween_interval(WARN_DURATION)
	tw.tween_callback(attack_callback)

func _find_mesh(n: Node) -> MeshInstance3D:
	for child in n.get_children():
		if child is MeshInstance3D:
			return child
		var found := _find_mesh(child)
		if found:
			return found
	return null

## Was tweening MeshInstance3D.modulate - a CanvasItem (2D) property that
## doesn't exist on a 3D mesh, so the tween silently did nothing. One
## steady, non-strobing highlight on the mesh's own material for the full
## warning window instead of the old 4-segment flash (also GAMEFEEL_SPEC's
## reduce_flash intent: a shape/material cue, not a strobe).
func _flash() -> void:
	if _mesh_owner == null:
		return
	var mat := _mesh_owner.material_override
	if not (mat is StandardMaterial3D):
		return
	var sm := mat as StandardMaterial3D
	var base_color: Color = sm.albedo_color
	sm.albedo_color = flash_color
	var tw := create_tween()
	tw.tween_interval(WARN_DURATION)
	tw.tween_callback(func() -> void: sm.albedo_color = base_color)

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
