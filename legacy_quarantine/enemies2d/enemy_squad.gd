

extends "res://legacy_quarantine/enemies2d/enemy_fps.gd"

@export 

var squad_id: String = "squad_1"

@export 

var communicate_range: float = 15.0
var _squad_members: Array = []

func _ready() -> void:
	super._ready()
	_find_squad()

func _find_squad() -> void:
	for node in get_tree().get_nodes_in_group("enemy"):
		if node != self and node != self and node.squad_id == squad_id:
			_squad_members.append(node)

func _update_target() -> void:
	super._update_target()
	if _target:
		_alert_squad()

func _alert_squad() -> void:
	for member in _squad_members:
		if is_instance_valid(member) and global_position.distance_to(member.global_position) <= communicate_range:
			member._target = _target
			member._change_state(State.CHASE)

func _do_attack() -> void:
	# Flanking: esli v otrijade >1, obhodim s boka
	if _squad_members.size() > 0 and _target:
		

		var flank_dir = global_position.direction_to(_target.global_position).rotated(Vector3.UP, PI/4)
		velocity = flank_dir * speed
	else:
		super._do_attack()