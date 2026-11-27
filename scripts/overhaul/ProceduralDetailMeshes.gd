extends RefCounted
## One indexed surface per module. A profile ring can be round or square with
## clipped corners; successive rings form shoulders, bevels and rolled lips.
const IRON := Color("#51636a")
const BRASS := Color("#c9a24a")
const CERAMIC := Color("#919890")
const GATE_CLEAR_WIDTH_M := 6.0
const CONCRETE := Color("#596066")

static var _meshes := {}
static var _hardware: ORMMaterial3D

static func hardware() -> ORMMaterial3D:
	if _hardware == null:
		_hardware = ORMMaterial3D.new()
		_hardware.vertex_color_use_as_albedo = true
		_hardware.vertex_color_is_srgb = true
		_hardware.albedo_texture = preload("res://assets/textures/wave2/iron_brass_hardware_albedo.png")
		_hardware.normal_enabled = true
		_hardware.normal_scale = 0.55
		_hardware.normal_texture = preload("res://assets/textures/wave2/iron_brass_hardware_normal.png")
		_hardware.orm_texture = preload("res://assets/textures/wave2/iron_brass_hardware_orm.png")
	return _hardware

var _frame := Transform3D.IDENTITY
var _surface := SurfaceTool.new()

func _triangle(a: Vector3, b: Vector3, c: Vector3, tint: Color, normal: Vector3, uv: Array[Vector2]) -> void:
	var index := 0
	for point: Vector3 in [a, b, c]:
		_surface.set_color(tint)
		_surface.set_normal(_frame.basis * normal)
		_surface.set_uv(uv[index])
		_surface.add_vertex(_frame * point)
		index += 1

func _rim(n: int, i: int, square: bool) -> Vector2:
	if square:
		const CORNERS := [Vector2(1,-0.84), Vector2(1,0.84), Vector2(0.84,1), Vector2(-0.84,1),
			Vector2(-1,0.84), Vector2(-1,-0.84), Vector2(-0.84,-1), Vector2(0.84,-1)]
		return CORNERS[i % n]
	return Vector2.from_angle(TAU * i / n)

func _profile(at: Vector3, width: Vector2, rings: Array[Vector2], tint: Color, square := false) -> void:
	var n := 8 if square else 12
	for i in n:
		var u := float(i) / n
		var v := float(i + 1) / n
		var p := _rim(n, i, square) * width
		var q := _rim(n, i + 1, square) * width
		for j in rings.size() - 1:
			var lo := rings[j]
			var hi := rings[j+1]
			var a := at + Vector3(p.x * lo.y, lo.x, p.y * lo.y)
			var b := at + Vector3(q.x * lo.y, lo.x, q.y * lo.y)
			var c := at + Vector3(q.x * hi.y, hi.x, q.y * hi.y)
			var d := at + Vector3(p.x * hi.y, hi.x, p.y * hi.y)
			var normal := (d-a).cross(b-a).normalized()
			_triangle(a,b,c,tint,normal,[Vector2(u,lo.x),Vector2(v,lo.x),Vector2(v,hi.x)])
			_triangle(a,c,d,tint,normal,[Vector2(u,lo.x),Vector2(v,hi.x),Vector2(u,hi.x)])
		for end in [0, rings.size()-1]:
			var r := rings[int(end)]
			var ctr := at + Vector3.UP * r.x
			var a := ctr + Vector3(p.x,0,p.y) * r.y
			var b := ctr + Vector3(q.x,0,q.y) * r.y
			var uv_a := _rim(n,i,square)*0.5 + Vector2(0.5,0.5)
			var uv_b := _rim(n,i+1,square)*0.5 + Vector2(0.5,0.5)
			if end == 0:
				_triangle(ctr,b,a,tint,Vector3.DOWN,[Vector2(0.5,0.5),uv_b,uv_a])
			else:
				_triangle(ctr,a,b,tint,Vector3.UP,[Vector2(0.5,0.5),uv_a,uv_b])

func _piece(at: Vector3, size: Vector3, tint: Color, square := true) -> void:
	var h := size.y * 0.5
	var lip := minf(h*0.24, minf(size.x,size.z)*0.08)
	_profile(at, Vector2(size.x,size.z)*0.5, [Vector2(-h,0.94),Vector2(-h+lip,1),
		Vector2(h-lip,1),Vector2(h,0.94)], tint, square)

func _relay() -> void:
	_piece(Vector3.ZERO, Vector3(0.32,0.07,0.23), BRASS)
	_piece(Vector3(0,0.105,0), Vector3(0.17,0.16,0.17), IRON,false)
	for i in 5:
		_piece(Vector3(0,0.05+i*0.028,0),Vector3(0.215,0.014,0.215),BRASS,false)
	for x: float in [-0.12,0.12]:
		_piece(Vector3(x,0.071,0),Vector3(0.045,0.093,0.045),CERAMIC,false)
		_piece(Vector3(x,0.13,0),Vector3(0.025,0.04,0.025),BRASS,false)

func _cabinet() -> void:
	_piece(Vector3.ZERO, Vector3(0.88,1.23,0.44), Color("#242c30"))
	_piece(Vector3(0,0.65,0.02),Vector3(1.02,0.09,0.57),IRON.lightened(0.13))
	_piece(Vector3(0,0,0.235),Vector3(0.77,1.08,0.045),IRON.lightened(0.12))
	_piece(Vector3(0.24,-0.07,0.293),Vector3(0.06,0.19,0.075),BRASS)
	for x: float in [-0.26,-0.13]:
		_piece(Vector3(x,-0.79,0),Vector3(0.064,0.5,0.064),IRON,false)
	for i in 4:
		_piece(Vector3(0,-0.29+i*0.05,0.274),Vector3(0.4,0.018,0.03),IRON)

func _gate_post() -> void:
	_profile(Vector3.ZERO,Vector2(0.55,0.55),[Vector2(0,1),Vector2(0.23,1),
		Vector2(0.34,0.84),Vector2(0.49,0.84),Vector2(0.54,0.9),Vector2(0.61,0.82),
		Vector2(3.9,0.82),Vector2(4.05,0.95),Vector2(4.25,0.95),Vector2(4.4,1)],CONCRETE,true)
	for x: float in [-0.29,0.29]:
		_piece(Vector3(x,2.2,-0.456),Vector3(0.073,2.95,0.046),IRON)

func _arch() -> void:
	for side: float in [-1,1]:
		_frame = Transform3D(Basis(Vector3.BACK, -side*0.14),Vector3(side*1.9,4.48,0))
		_piece(Vector3.ZERO,Vector3(3.99,0.43,0.9),CONCRETE)
	_frame = Transform3D.IDENTITY
	_piece(Vector3(0,4.72,0),Vector3(0.52,0.63,1.00),IRON)
	_piece(Vector3(0,3.96,-0.48),Vector3(2.8,0.55,0.12),IRON)
	for x: float in [-1.28,1.28]:
		_piece(Vector3(x,4.24,-0.45),Vector3(0.05,0.3,0.07),BRASS)

func _seat() -> void:
	for x: float in [-0.6,0.6]:
		_piece(Vector3(x,0.19,0),Vector3(0.09,0.36,0.41),IRON)
		_piece(Vector3(x,0.52,0.18),Vector3(0.07,0.5,0.07),IRON)
	for i in 3:
		_piece(Vector3(0,0.39,-0.16+i*0.16),Vector3(1.65,0.08,0.135),BRASS.darkened(0.38))
	for h: float in [0.62,0.76]:
		_piece(Vector3(0,h,0.18),Vector3(1.65,0.1,0.07),BRASS.darkened(0.38))
	_profile(Vector3(1.2,0,0),Vector2(0.19,0.19),[Vector2(0,0.73),Vector2(0.09,0.83),
		Vector2(0.48,1),Vector2(0.53,1.08),Vector2(0.55,0.8),Vector2(0.43,0.7)],IRON)

static func module(kind: StringName) -> ArrayMesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var builder := new()
	builder._surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	match kind:
		&"relay": builder._relay()
		&"cabinet": builder._cabinet()
		&"gate":
			for side: float in [-1,1]:
				builder._frame.origin = Vector3(side*(GATE_CLEAR_WIDTH_M*0.5+0.55),0,0)
				builder._gate_post()
			builder._arch()
		&"bench_bin": builder._seat()
		&"bollard":
			builder._profile(Vector3.ZERO,Vector2(0.13,0.13),[Vector2(0,1),Vector2(0.12,1),Vector2(0.18,0.68),Vector2(0.61,0.68),Vector2(0.64,0.8),Vector2(0.69,0.75),Vector2(0.72,0.4)],IRON)
		&"lens":
			builder._profile(Vector3.ZERO,Vector2(0.17,0.17),[Vector2(-0.055,0.56),Vector2(-0.034,0.92),Vector2(0,1),Vector2(0.025,0.88)],Color.WHITE)
		&"slab":
			builder._piece(Vector3.ZERO,Vector3.ONE,Color.WHITE)
		&"pavement":
			for x: float in [-0.25,0.25]:
				for z: float in [-0.25,0.25]:
					builder._piece(Vector3(x,0,z),Vector3(0.496,1,0.496),Color.WHITE)
		_:
			push_error("Unknown detail mesh: %s" % kind)
			return null
	builder._surface.index()
	builder._surface.generate_tangents()
	var mesh: ArrayMesh = builder._surface.commit()
	_meshes[kind] = mesh
	return mesh

static func place(parent: Node3D, kind: StringName, node_name: String, at: Vector3, size := Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = module(kind)
	instance.material_override = hardware()
	instance.position = at
	instance.scale = size
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance
