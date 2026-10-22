extends Node
## MonsterTelegraph - a child node of any enemy.
## Call telegraph.warn(callback): a flash and a sound 0.4 s before the hit.
## base_monster.gd wires it as _telegraph.warn(_deal_damage); tools/qa_sim/telegraph_audit.py holds every hit to it.

const WARN_DURATION: float = 0.4

## The ember of the style guide (danger only), not a neon red.
@export var flash_color: Color = Color("#b4452f")
@export var warn_sfx_path: String = "res://assets/audio/sfx/sfx_enemy_warn.wav"
## How far the warning sound carries: a sniper's shot is announced from its own range, not from 12 m.
@export var cue_range: float = 12.0
## When the last cue began (Time.get_ticks_msec), so a check can tell the cue from the hit that follows it.
var last_cue_msec: int = -1
## How long the windup that cue opened lasts (s): the body winds up for as long (monster_rig.gd), so the arm comes down when the hit lands (v10 N033: the Hunter and the Brute hit 1.0 s after the cue, the arm was back at rest at 0.8 s).
var last_cue_windup: float = WARN_DURATION

## GAME_AUDIT/arena design audit P8: _mesh_owner used to be resolved once in
## _ready() by scanning only direct children - too early (base_monster.gd
## adds this node before _build_visual() creates any mesh) and too shallow
## (base monsters nest it at VisualRoot/BodyMesh, not a direct child), so
## _mesh_owner stayed null forever and the warning was invisible. Resolved
## lazily at warn() time instead, once visuals are guaranteed to exist.
var _mesh_owner: MeshInstance3D = null

func warn(attack_callback: Callable) -> void:
	cue()
	var tw := create_tween()
	tw.tween_interval(WARN_DURATION)
	tw.tween_callback(attack_callback)

## The sight and the sound of an attack that is about to land, without the attack: the windups of the Crawler, the Hunter and the Brute call it, and warn() is a cue and a callback.
func cue(windup: float = WARN_DURATION) -> void:
	last_cue_msec = Time.get_ticks_msec()
	last_cue_windup = windup
	if _mesh_owner == null or not is_instance_valid(_mesh_owner):
		_mesh_owner = _find_mesh(get_parent())
	_flash()
	_play_warn_sfx()

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
	var base_glow: Color = sm.emission
	var base_lit: bool = sm.emission_enabled
	sm.albedo_color = flash_color
	sm.emission_enabled = true
	sm.emission = flash_color
	var tw := create_tween()
	tw.tween_interval(WARN_DURATION)
	tw.tween_callback(func() -> void:
		sm.albedo_color = base_color
		sm.emission = base_glow
		sm.emission_enabled = base_lit)

func _play_warn_sfx() -> void:
	var sfx: AudioStream = load(warn_sfx_path)
	if sfx == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.stream = sfx
	player.bus = &"Combat"
	player.max_distance = cue_range
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	get_parent().add_child(player)
	player.play()
	var tw := create_tween()
	tw.tween_interval(sfx.get_length() + 0.1)
	tw.tween_callback(player.queue_free)
