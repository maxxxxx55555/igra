extends Node
## The procedural body of a monster. It builds the look of monster_looks.gd and moves it: gait from the speed, breathing, head tracking, the windup of an attack, a flinch on a hit and the
## collapse of a death. BaseMonster._update_anim is the hook ANIMATION_GUIDE.md section 4 names. It writes the transforms of the nodes it made and reads what the monster hands in: no
## stat, hitbox or AI state depends on it, and the hit flash (MonsterTelegraph, BaseMonster._hit_flash) keeps working because the parts share one StandardMaterial3D.

const _Looks := preload("res://scripts/enemies/monster_looks.gd")
const WINDUP: float = 0.4
const STRIKE: float = 0.1
const RECOVER: float = 0.3
const COLLAPSE_SEC: float = 0.75
const FLINCH_OUT: float = 0.07
const FLINCH_BACK: float = 0.12
const FLINCH_M: float = 0.08
const HEAD_RATE: float = 6.0
const HEAD_CLAMP: float = 0.7

## One roughened mesh per shape, shared by every monster: the vertices of a low-poly primitive are pushed by a hash of their place so that no part reads as a smooth capsule.
static var _meshes: Dictionary = {}

var _look: Dictionary
var _g: Dictionary
var _mat: StandardMaterial3D
var _root: Node3D
var _torso: Node3D
var _head: MeshInstance3D
var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _feet_y: float = -0.9
var _leg_len: float = 0.8
var _hip_y: float = 0.8
var _rest_h: float = 0.3
var _gait_phase: float = 0.0
var _moving: float = 0.0
var _clock: float = 0.0
var _seed: float = -1.0
var _head_yaw: float = 0.0
var _cue_seen: int = -1
var _atk: float = -1.0
## The windup of the attack being played (s): WINDUP, or the length of the telegraph's windup less the strike when the monster winds up for longer, so the arm comes down when the hit lands.
var _windup: float = WINDUP
var _flinch_t: float = -1.0
var _flinch_dir: Vector3 = Vector3.BACK
var _flinch_k: float = 0.0
var _fall_t: float = -1.0
var _fall_dir: float = 1.0
var _alt_synced: bool = false

static func _hash(v: Vector3) -> float:
	return fposmod(sin(v.dot(Vector3(12.9898, 78.233, 37.719))) * 43758.5453, 1.0)

static func _rough(src: PrimitiveMesh, amount: float) -> ArrayMesh:
	var arrays: Array = src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		var cell: Vector3 = (verts[i] * 8.0).round()
		verts[i] += (Vector3(_hash(cell), _hash(cell + Vector3.ONE * 17.0), _hash(cell + Vector3.ONE * 31.0)) - Vector3.ONE * 0.5) * amount
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out

static func _mesh(spec: Array) -> Mesh:
	var key: String = str(spec.slice(0, 4))
	if _meshes.has(key):
		return _meshes[key]
	var a: float = spec[1]
	var b: float = spec[2]
	var c: float = spec[3]
	var src: PrimitiveMesh
	if spec[0] == "cyl":
		var cyl := CylinderMesh.new()
		cyl.top_radius = a
		cyl.bottom_radius = b
		cyl.height = c
		cyl.radial_segments = 8
		cyl.rings = 2
		src = cyl
	elif spec[0] == "box":
		var box := BoxMesh.new()
		box.size = Vector3(a, b, c)
		box.subdivide_width = 1
		box.subdivide_height = 2
		box.subdivide_depth = 1
		src = box
	else:
		var sph := SphereMesh.new()
		sph.radius = a
		sph.height = a * 2.0
		sph.radial_segments = 10
		sph.rings = 5
		src = sph
	_meshes[key] = _rough(src, clampf((a + b + c) / 3.0 * 0.1, 0.008, 0.05))
	return _meshes[key]

func build(monster: Node3D, id: StringName) -> void:
	name = "MonsterRig"
	monster.add_child(self)
	_look = _Looks.look(id)
	_g = _Looks.gait(id)
	var cap := monster.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cap and cap.shape is CapsuleShape3D:
		_feet_y = -0.5 * (cap.shape as CapsuleShape3D).height
	_root = Node3D.new()
	_root.name = "VisualRoot"
	_root.position.y = _feet_y
	monster.add_child(_root)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _look["tint"]
	_mat.roughness = 0.9
	if _look.has("emit"):
		_mat.emission_enabled = true
		_mat.emission = _look["emit"]
		_mat.emission_energy_multiplier = 0.6
	var legs: Array = _look["legs"]
	var body: Array = _look["body"]
	_leg_len = float(legs[2])
	_hip_y = float(legs[4]) if int(legs[0]) > 0 else float(body[4])
	_rest_h = float(body[2]) if body[0] == "cyl" else float(body[3]) * 0.5
	_torso = Node3D.new()
	_torso.name = "Torso"
	_torso.position.y = _hip_y
	_root.add_child(_torso)
	_part("BodyMesh", body, _torso, -_hip_y, _mat)
	_head = _part("HeadMesh", _look["head"], _torso, -_hip_y, _mat)
	_legs = _limbs(legs, _root, 0.0, "Leg")
	_arms = _limbs(_look["arms"], _torso, -_hip_y, "Arm")
	if id == &"crawler":
		_alt(monster)

func _part(part_name: String, spec: Array, parent: Node3D, dy: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = _mesh(spec)
	mi.material_override = mat
	mi.position = Vector3(0.0, float(spec[4]) + dy, float(spec[5]))
	parent.add_child(mi)
	return mi

## Each limb hangs from a pivot node at its joint, so a rotation about x swings it; positive x swings the free end forward (-Z).
func _limbs(spec: Array, parent: Node3D, dy: float, tag: String) -> Array[Node3D]:
	var out: Array[Node3D] = []
	var count: int = spec[0]
	var length: float = spec[2]
	for i in count:
		var pivot := Node3D.new()
		pivot.name = "%s%d" % [tag, i]
		var z: float = float(spec[5]) * (-1.0 if i < 2 else 1.0) if count == 4 else float(spec[5])
		pivot.position = Vector3((-1.0 if i % 2 == 0 else 1.0) * float(spec[3]), float(spec[4]) + dy, z)
		parent.add_child(pivot)
		var limb := _part("%sMesh" % tag, ["box", spec[1], length, spec[1], -length * 0.5, 0.0], pivot, 0.0, _mat)
		limb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		out.append(pivot)
	return out

## The arachnophobia mode swaps a crawler for this plain blob (SettingsManager._apply_arachnophobia hides VisualRoot and shows AltMesh).
func _alt(monster: Node3D) -> void:
	var blob := MeshInstance3D.new()
	blob.name = "AltMesh"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.26
	mesh.height = 0.7
	blob.mesh = mesh
	blob.material_override = _mat
	blob.rotation.x = PI * 0.5
	blob.position.y = _feet_y + 0.28
	blob.visible = false
	monster.add_child(blob)

## One call per physics frame. speed is the horizontal speed in m/s, heading the vector to the player while the monster is aware of it and not chasing (else zero), cue_msec the
## start of the last telegraph cue (MonsterTelegraph.last_cue_msec) and windup the time from that cue to the hit (MonsterTelegraph.last_cue_windup).
func update(delta: float, dead: bool, speed: float, heading: Vector3, cue_msec: int, windup: float = WINDUP) -> void:
	if _root == null:
		return
	if _seed < 0.0:
		_seed = _hash(_root.global_position)
	if not _alt_synced:
		_alt_synced = true
		_sync_alt()
	if dead:
		_lie_down(delta)
		return
	_clock += delta
	if cue_msec >= 0 and cue_msec != _cue_seen:
		_cue_seen = cue_msec
		_atk = 0.0
		_windup = maxf(WINDUP, windup - STRIKE)
	var strike: Vector2 = _attack(delta)
	_moving = move_toward(_moving, smoothstep(0.12, 0.6, speed), 6.0 * delta)
	var moving: float = _moving
	_gait_phase += speed / float(_g["s"]) * delta
	var ph: float = _gait_phase * TAU + float(_g["jit"]) * sin(_clock * 17.0)
	_swing(ph, moving, strike.x)
	var flinch: Vector2 = _flinch(delta)
	var lean: float = float(_g["pitch"]) * (0.5 + 0.5 * moving) + strike.y
	var stumble: float = 0.0
	if float(_g["stagger"]) > 0.0 and moving > 0.3 and fposmod(_clock, float(_g["stagger"])) < 0.3:
		stumble = 0.15 * sin(fposmod(_clock, float(_g["stagger"])) / 0.3 * PI)
	_torso.rotation.x = -(lean + stumble)
	_torso.rotation.z = float(_g["list"]) + float(_g["roll"]) * sin(ph) * moving
	_torso.rotation.y = flinch.y
	var breath: float = 1.0 + 0.015 * sin(_clock * TAU * (0.8 + 0.6 * fposmod(_seed * 7.13, 1.0)) + _seed * TAU)
	_torso.scale.y = breath
	_torso.position = Vector3(0.0, _hip_y - float(_g["bob"]) * moving * (0.5 - 0.5 * cos(2.0 * ph)), flinch.x)
	_look_at_player(delta, heading)

func _swing(ph: float, moving: float, arm_add: float) -> void:
	var amp: float = clampf(float(_g["s"]) / (TAU * maxf(_leg_len, 0.2)), 0.0, 0.9) * float(_g["kl"])
	var hold: float = float(_g["hold"])
	var tuck: float = float(_g["air"]) * maxf(0.0, sin(2.0 * ph)) * moving
	for i in _legs.size():
		var off: float = PI if i % 2 == 1 else 0.0
		if _legs.size() == 4 and i >= 2:
			off += PI
		var s: float = sin(ph + off)
		s = signf(s) * pow(absf(s), 1.0 - hold)
		var share: float = float(_g["asym"]) if i == 1 else 1.0
		_legs[i].rotation.x = amp * s * share * moving - tuck
	for i in _arms.size():
		var s: float = sin(ph + (0.0 if i % 2 == 1 else PI))
		_arms[i].rotation.x = float(_g["rest"]) + float(_g["ka"]) * s * moving + arm_add

## The windup, the strike and the recovery of an attack as a curve: x is the arm angle (rad, negative = drawn back), y the lean of the body (rad, positive = forward).
func _attack(delta: float) -> Vector2:
	if _atk < 0.0:
		return Vector2.ZERO
	_atk += delta
	if _atk >= _windup + STRIKE + RECOVER:
		_atk = -1.0
		return Vector2.ZERO
	if _atk < _windup:
		var k: float = _atk / _windup
		return Vector2(-1.5, -0.18) * k * k
	if _atk < _windup + STRIKE:
		return Vector2(-1.5, -0.18).lerp(Vector2(1.2, 0.25), (_atk - _windup) / STRIKE)
	return Vector2(1.2, 0.25).lerp(Vector2.ZERO, smoothstep(0.0, 1.0, (_atk - _windup - STRIKE) / RECOVER))

## A directional flinch: the body is knocked back along the hit by up to FLINCH_M and returns, with a small yaw kick. x is the push along the torso's z (rad-free metres), y the yaw.
func flinch(from: Vector3, strength: float) -> void:
	if _root == null:
		return
	var away: Vector3 = _root.global_position - from
	away.y = 0.0
	_flinch_dir = (_root.global_transform.basis.inverse() * away).normalized() if from != Vector3.ZERO and away.length_squared() > 0.0001 else Vector3.BACK
	_flinch_k = clampf(strength * 4.0, 0.3, 1.0)
	_flinch_t = 0.0

func _flinch(delta: float) -> Vector2:
	if _flinch_t < 0.0:
		return Vector2.ZERO
	_flinch_t += delta
	if _flinch_t >= FLINCH_OUT + FLINCH_BACK:
		_flinch_t = -1.0
		return Vector2.ZERO
	var k: float = _flinch_t / FLINCH_OUT if _flinch_t < FLINCH_OUT else 1.0 - (_flinch_t - FLINCH_OUT) / FLINCH_BACK
	return Vector2(_flinch_dir.z * FLINCH_M * _flinch_k * k, 0.05 * _flinch_k * k * signf(_flinch_dir.x + 0.0001))

func _look_at_player(delta: float, heading: Vector3) -> void:
	var want: float = 0.0
	if heading != Vector3.ZERO:
		var local: Vector3 = _root.global_transform.basis.inverse() * heading
		want = clampf(atan2(-local.x, -local.z), -HEAD_CLAMP, HEAD_CLAMP)
	_head_yaw = move_toward(_head_yaw, want, HEAD_RATE * delta)
	_head.rotation.y = _head_yaw

## A death: the body falls about its feet over COLLAPSE_SEC, lifted by half its thickness so that it lies on the floor, the limbs pulled in and the emission faded.
func collapse() -> void:
	if _root == null or _fall_t >= 0.0:
		return
	_fall_t = 0.0
	_fall_dir = 1.0 if _seed < 0.5 else -1.0

func _lie_down(delta: float) -> void:
	if _fall_t < 0.0:
		collapse()
	_fall_t = minf(_fall_t + delta, COLLAPSE_SEC)
	var k: float = pow(_fall_t / COLLAPSE_SEC, 2.0)
	_root.rotation.x = _fall_dir * k * PI * 0.5
	_root.position.y = _feet_y + sin(k * PI * 0.5) * _rest_h
	for leg in _legs:
		leg.rotation.x = lerpf(leg.rotation.x, -0.5, k)
	for arm in _arms:
		arm.rotation.x = lerpf(arm.rotation.x, 0.4, k)
	if _mat.emission_enabled:
		_mat.emission_energy_multiplier = 0.6 * (1.0 - k)

## A crawler that spawns while the arachnophobia mode is on starts as the blob.
func _sync_alt() -> void:
	var alt := get_parent().get_node_or_null("AltMesh") as MeshInstance3D
	if alt and SettingsManager.get_setting("arachnophobia", false):
		_root.visible = false
		alt.visible = true
