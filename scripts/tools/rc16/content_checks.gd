extends RefCounted
## rc16 closeout checks of content: wired by the orchestrator into _closeout_check_runner.gd as `await <Preload>.run(self)`

const RIFLE: PackedScene = preload("res://scenes/weapons/weapon_rifle.tscn")
## A point high above the street: a shot straight up from here meets nothing that can take damage.
const SKY_SHOT_FROM := Vector3(480.0, 60.0, 480.0)

static func run(r: Node) -> void:
	await _fire1_cooldown_ticks_with_physics(r)

## FIRE1: the cooldown and the reload count on the physics tick that polls the trigger, not on the frame.
static func _fire1_cooldown_ticks_with_physics(r: Node) -> void:
	var rifle := RIFLE.instantiate() as WeaponBase
	r.add_child(rifle)
	rifle.set_process(false)
	r._ok(rifle.fire(SKY_SHOT_FROM, Vector3.UP) and not rifle.can_fire(), "FIRE1 a shot starts the cooldown")
	await r.get_tree().create_timer(0.5).timeout
	r._ok(rifle.can_fire(), "FIRE1 the cooldown runs on the physics tick: the rifle is ready 0.5 s after a shot with _process off")
	rifle.queue_free()
