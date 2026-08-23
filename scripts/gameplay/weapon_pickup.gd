
extends Area3D

@export 
var weapon_name: String = "rifle"  # pistol, rifle, shotgun

@export 
var ammo_amount: int = 30

@onready 
var mesh: MeshInstance3D = $MeshInstance3D

@onready 
var particles: GPUParticles3D = $GPUParticles3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_animate_float()

func _animate_float() -> void:
	
	var tween := create_tween().set_loops()
	tween.tween_property(mesh, "position:y", 0.3, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(mesh, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	# GDD §5 (БОЕВАЯ СИСТЕМА) is melee-only canon — no ranged weapon appears
	# anywhere in the combat design. WeaponManager/WeaponBase exist as
	# scaffolding but this scene (and WeaponManager itself) are never
	# instantiated in any live level, so `unlock_weapon()` — which
	# WeaponManager never actually defined — was a no-op call to a method
	# that doesn't exist, guarded by has_method() into silence. Removed
	# rather than implemented: adding ranged combat would be a real design
	# change beyond what GDD specifies, not a bug fix.
	if body.has_method("add_ammo"):
		body.add_ammo(weapon_name, ammo_amount)
	_play_pickup()
	queue_free()

func _play_pickup() -> void:
	if particles:
		particles.emitting = true
		await get_tree().create_timer(0.5).timeout
