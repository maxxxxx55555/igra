extends Node
## VisibilityEnabler — добавляется к врагу или пропсу.
## Использует VisibleOnScreenNotifier3D для включения/выключения AI и физики.
## Добавь как дочерний узел к CharacterBody3D / StaticBody3D.

@export var aabb_size: Vector3 = Vector3(2.0, 2.5, 2.0)
@export var disable_physics: bool = true
@export var disable_process: bool = true

var _notifier: VisibleOnScreenNotifier3D

func _ready() -> void:
	_notifier = VisibleOnScreenNotifier3D.new()
	_notifier.aabb = AABB(-aabb_size * 0.5, aabb_size)
	add_child(_notifier)
	_notifier.screen_entered.connect(_on_visible)
	_notifier.screen_exited.connect(_on_hidden)
	# Начинаем выключенными — notifier сам включит при появлении на экране
	_set_active(false)

func _on_visible() -> void:
	_set_active(true)

func _on_hidden() -> void:
	_set_active(false)

func _set_active(active: bool) -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	if disable_process:
		parent.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if disable_physics and parent is PhysicsBody3D:
		(parent as PhysicsBody3D).set_physics_process(active)
