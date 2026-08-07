extends Node
## A3: EnemyPool - limit odnovremennyh vragov (mobajl)

@export var max_active: int = 8

var _active: int = 0

func try_spawn(scene: PackedScene, pos: Vector3, parent: Node) -> Node3D:
    if _active >= max_active:
        return null
    var e = scene.instantiate()
    parent.add_child(e)
    e.global_position = pos
    _active += 1
    if e.has_signal("died") or (e.has_node("HealthComponent") and e.get_node("HealthComponent").has_signal("died")):
        var h = e.get_node_or_null("HealthComponent")
        if h: h.died.connect(_on_dead)
    return e

func _on_dead() -> void:
    _active = max(0, _active - 1)

func active_count() -> int:
    return _active
