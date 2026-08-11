extends Node

const SCENES: Array[String] = [
	"res://scenes/player/player.tscn",
	"res://scenes/player/player_3d.tscn",
	"res://scenes/player_fps.tscn",
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/legacy_2d/boss_arena.tscn",
	"res://scenes/enemies/shadow_3d.tscn",
	"res://scenes/enemies/crawler_3d.tscn",
	"res://scenes/enemies/watcher_3d.tscn",
	"res://scenes/enemies/hunter_3d.tscn",
	"res://scenes/enemies/destroyer_3d.tscn",
	"res://scenes/enemies/boss_architect_3d.tscn",
	"res://scenes/enemies/enemy_base.tscn",
	"res://scenes/gameplay/door.tscn",
	"res://scenes/gameplay/exploding_barrel.tscn",
	"res://scenes/gameplay/checkpoint.tscn",
	"res://scenes/gameplay/craft_station.tscn",
	"res://scenes/gameplay/zone_trigger.tscn",
	"res://scenes/pickups/health_pickup.tscn",
	"res://scenes/pickups/ammo_pickup.tscn",
	"res://scenes/pickups/weapon_pickup.tscn",
	"res://scenes/pickups/key_item.tscn",
	"res://scenes/pickups/document_pickup.tscn",
	"res://scenes/props/streetlight_3d.tscn",
	"res://scenes/props/puzzle_3d.tscn",
	"res://scenes/props/examine.tscn",
	"res://scenes/props/secret.tscn",
	"res://scenes/weapons/weapon_pistol.tscn",
	"res://scenes/weapons/weapon_rifle.tscn",
	"res://scenes/weapons/weapon_shotgun.tscn",
	"res://scenes/weapons/weapon_model.tscn",
	"res://scenes/legacy_2d/hud.tscn",
	"res://scenes/ui/hud_3d.tscn",
	"res://scenes/ui/hud_enhanced.tscn",
	"res://scenes/ui/main_menu.tscn",
	"res://scenes/legacy_2d/inventory_ui.tscn",
	"res://scenes/legacy_2d/shop_ui.tscn",
	"res://scenes/ui/skill_tree_ui.tscn",
	"res://scenes/ui/quest_tracker_hud.tscn",
	"res://scenes/ui/touch_controls.tscn",
	"res://scenes/legacy_2d/world.tscn",
	"res://scenes/world/test_zone.tscn",
]

var _bad: Array[String] = []
var _idx: int = 0

func _ready() -> void:
	_run()

func _run() -> void:
	if _idx >= SCENES.size():
		if _bad.is_empty():
			print("[probe-scene] OK: all scenes instantiate")
		for b in _bad:
			print("[probe-scene] BAD: ", b)
		get_tree().quit(1 if not _bad.is_empty() else 0)
		return
	var p: PackedScene = ResourceLoader.load(SCENES[_idx])
	if p == null:
		_bad.append(SCENES[_idx] + " (not loaded)")
		_idx += 1
		_run()
		return
	var inst := p.instantiate()
	if inst == null:
		_bad.append(SCENES[_idx] + " (instantiate null)")
		_idx += 1
		_run()
		return
	add_child(inst)
	print("[probe-scene] ok: ", SCENES[_idx])
	await get_tree().process_frame
	inst.queue_free()
	_idx += 1
	_run()
