extends Node3D
## A real HUD and physics world; only enemy perception is controlled by the fixture.

class TargetFixture extends StaticBody3D:
	var monster_id: StringName = &"shadow"
	var hp: float = 25.0
	var max_hp: float = 100.0
	var perceptible: bool = true
	func is_perceptible() -> bool:
		return perceptible

var _fails: int = 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	GameManager._change_state(GameManager.GameState.PLAYING)
	UIManager.close_all_blocking()
	var camera := Camera3D.new()
	add_child(camera)
	camera.current = true
	var first: TargetFixture = _target(Vector3(8.0, 0.0, -8.0), 80.0)
	var aimed: TargetFixture = _target(Vector3(0.0, 0.0, -8.0), 25.0)
	var hud := preload("res://scenes/ui/hud_3d.tscn").instantiate() as CanvasLayer
	add_child(hud)
	await get_tree().physics_frame
	await get_tree().physics_frame
	hud.call("_poll_aim_target")
	_expect(hud.get("_enemy_bar_monster") == aimed,
		"Aim keeps the actual instance when another enemy shares its species")
	var bar: Control = hud.get("enemy_hp_bar") as Control
	_expect(bar.visible and is_equal_approx(bar.scale.x, 0.25), "Aimed instance health is shown")
	first.perceptible = false
	hud.call("_poll_aim_target")
	_expect(bar.visible and hud.get("_enemy_bar_monster") == aimed,
		"An unseen same-species enemy cannot suppress the visible aimed target")
	EventBus.enemy_hp_updated.emit(&"shadow", 0.8)
	_expect(hud.get("_enemy_bar_monster") == aimed and is_equal_approx(bar.scale.x, 0.25),
		"Ambiguous species-only damage cannot overwrite the aimed instance health")
	hud.call("_hide_enemy_bar")
	EventBus.player_detected.emit(&"shadow")
	_expect(not bar.visible, "Ambiguous species-only spotting cannot invent an instance")
	hud.call("_poll_aim_target")
	aimed.perceptible = false
	hud.call("_process_enemy_bar", 0.01)
	_expect(not bar.visible, "The actual target losing perception hides its readout")
	aimed.perceptible = true
	first.free()
	EventBus.enemy_hp_updated.emit(&"shadow", 0.4)
	_expect(bar.visible and hud.get("_enemy_bar_monster") == aimed and is_equal_approx(bar.scale.x, 0.4),
		"An unambiguous species-only health event still updates the unique instance")
	aimed.free()
	hud.call("_process_enemy_bar", 0.01)
	_expect(not bar.visible, "Freeing the actual target safely hides its readout")
	hud.queue_free()
	camera.queue_free()
	# The real player_detected signal starts a sting outside the fixture subtree.
	for player: Node in MusicManager.find_children("*", "AudioStreamPlayer", true, false):
		(player as AudioStreamPlayer).stop()
	# Drain deferred HUD construction and node-owned tweens before engine shutdown.
	await get_tree().process_frame
	await get_tree().process_frame
	print("[hud-target] DONE fails=", _fails)
	get_tree().quit(1 if _fails > 0 else 0)

func _target(at: Vector3, health: float) -> TargetFixture:
	var target := TargetFixture.new()
	target.position = at
	target.hp = health
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.0, 2.5, 1.0)
	collision.shape = shape
	target.add_child(collision)
	add_child(target)
	target.add_to_group("enemies")
	return target

func _expect(ok: bool, message: String) -> void:
	if not ok:
		_fails += 1
	print("[hud-target] ", "PASS " if ok else "FAIL ", message)
