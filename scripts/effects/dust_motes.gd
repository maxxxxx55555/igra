extends Node
## Dust in the light (docs/VFX_BUDGET.md): a few motes drift in the beams of the lit streetlights nearest to the player. EMITTERS pooled
## emitters of EMITTER_AMOUNT motes each are moved under the nearest lit lamps every SCAN_SEC; a lamp that is out (a dark district) or farther than
## RANGE_M has none. A child of the district's StreetProps, so a rebuilt district takes it with it. The Effects setting at Low draws none.

const EMITTERS: int = 4
const EMITTER_AMOUNT: int = 14
const RANGE_M: float = 28.0
const SCAN_SEC: float = 1.0
const BEAM_DROP_M: float = 2.2  # the middle of the beam under the lamp head
const BEAM_BOX := Vector3(1.3, 2.2, 1.3)  # half sizes
const MOTE_TEXTURE := preload("res://assets/textures/fx/dust.png")
const MOTE_COLOR := Color(0.95, 0.86, 0.62, 0.45)

var _emitters: Array[GPUParticles3D] = []
var _timer: float = 0.0

func _ready() -> void:
	for i in EMITTERS:
		var emitter := GPUParticles3D.new()
		emitter.name = "Motes%d" % i
		emitter.amount = EMITTER_AMOUNT
		emitter.lifetime = 6.0
		emitter.preprocess = 3.0
		emitter.emitting = false
		emitter.local_coords = false
		emitter.visibility_aabb = AABB(Vector3(-4.0, -4.0, -4.0), Vector3(8.0, 8.0, 8.0))
		var mat := ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		mat.emission_box_extents = BEAM_BOX
		mat.direction = Vector3.UP
		mat.spread = 180.0
		mat.initial_velocity_min = 0.02
		mat.initial_velocity_max = 0.09
		mat.gravity = Vector3.ZERO
		mat.scale_min = 0.025
		mat.scale_max = 0.06
		mat.color = MOTE_COLOR
		emitter.process_material = mat
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE
		var quad_mat := StandardMaterial3D.new()
		quad_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		quad_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		quad_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		quad_mat.vertex_color_use_as_albedo = true
		quad_mat.albedo_texture = MOTE_TEXTURE
		quad_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		quad_mat.billboard_keep_scale = true  # a billboard drops the scale of a particle unless it keeps it: the motes were the 1 m of their quad, smudges about a lamp
		quad.material = quad_mat
		emitter.draw_pass_1 = quad
		add_child(emitter)
		_emitters.append(emitter)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = SCAN_SEC
		refresh()

## The lit lamps within RANGE_M, nearest first, at most EMITTERS of them: their beam centres.
func beams() -> Array[Vector3]:
	var found: Array[Vector3] = []
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or int(SettingsManager.get_setting("effects", 2)) < 1:
		return found
	var lit: Array[Node3D] = []
	for lamp: Node in get_tree().get_nodes_in_group("streetlights"):
		var node := lamp as Node3D
		if node != null and bool(node.get("_on")) and node.global_position.distance_to(player.global_position) <= RANGE_M:
			lit.append(node)
	lit.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(player.global_position) < b.global_position.distance_squared_to(player.global_position))
	for lamp: Node3D in lit.slice(0, EMITTERS):
		var head := lamp.get_node_or_null("SpotLight") as Node3D
		found.append((head.global_position if head != null else lamp.global_position + Vector3.UP * 4.2) - Vector3.UP * BEAM_DROP_M)
	return found

func refresh() -> void:
	var spots: Array[Vector3] = beams()
	for i in _emitters.size():
		var emitter: GPUParticles3D = _emitters[i]
		emitter.emitting = i < spots.size()
		if i < spots.size():
			emitter.global_position = spots[i]
