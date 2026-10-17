extends Node
## VisibilityEnabler - a child of an enemy or a prop. A VisibleOnScreenNotifier3D switches the AI and the physics of its parent on while the camera sees it and off outside the view
## (the frame time of the three heavy kinds, TZ_DECISIONS VIS-enabler). Inside wake_m of the player the parent stays awake whatever the camera sees, so a pursuit from behind is real.

@export var aabb_size: Vector3 = Vector3(2.0, 2.5, 2.0)
@export var disable_physics: bool = true
@export var disable_process: bool = true
## Inside this many metres of the player the parent is never switched off.
@export var wake_m: float = 10.0
## How often the distance to the player is read, in seconds.
const REFRESH_SEC: float = 0.5

var _notifier: VisibleOnScreenNotifier3D
var _seen: bool = false

func _ready() -> void:
	# The parent is switched off with everything under it: this node and its timer keep running to switch it on again.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_notifier = VisibleOnScreenNotifier3D.new()
	_notifier.aabb = AABB(-aabb_size * 0.5, aabb_size)
	add_child(_notifier)
	_notifier.screen_entered.connect(_set_seen.bind(true))
	_notifier.screen_exited.connect(_set_seen.bind(false))
	var timer := Timer.new()
	timer.wait_time = REFRESH_SEC
	timer.timeout.connect(_refresh)
	add_child(timer)
	timer.start()
	_refresh()

func _set_seen(seen: bool) -> void:
	_seen = seen
	_refresh()

## Awake while the camera sees the parent or the player is within wake_m of it.
func _refresh() -> void:
	var parent := get_parent() as Node3D
	if parent == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var near: bool = player != null and parent.global_position.distance_to(player.global_position) <= wake_m
	_set_active(_seen or near)

func _set_active(active: bool) -> void:
	var parent: Node = get_parent()
	if disable_process:
		parent.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if disable_physics and parent is PhysicsBody3D:
		(parent as PhysicsBody3D).set_physics_process(active)
