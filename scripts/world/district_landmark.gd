extends RefCounted
## The landmark of each district (docs/DISTRICT_SIGNATURES.md): a tall silhouette of primitive meshes behind the skyline ring, north of the street grid, so the
## horizon of every district has a shape of its own. Visual only: no collision, no navigation. All its geometry is merged into two meshes, the body and the
## glowing parts, and a soft halo of light stands behind it, so a landmark costs three draw calls. The glow, the halo and the body follow the power stage of
## the district like the windows of the skyline do: dark at DARK, a silhouette against the halo at FULL.
## A part is [kind, size, position, tilt in degrees, glows]; kind "box": size is the extent; "cyl": size is (top radius, bottom radius, height);
## "ball": size.x is the radius; "ring": size is (inner radius, outer radius, 0) of a ring that stands in the XY plane.

const BODY_COLOR := Color("#2a3340")
const GLOW_COLOR := Color("#c9a24a")
const BODY_SELF_GLOW := Color(0.08, 0.10, 0.14)
## Per power stage (DARK, PARTIAL, STREETS, FULL): the emission energy of the glowing parts, the share of the body's self-glow, the opacity of the halo.
const GLOW_BY_STAGE: Array[float] = [0.0, 0.6, 1.3, 2.4]
const BODY_BY_STAGE: Array[float] = [0.15, 0.5, 0.8, 1.1]
const HALO_BY_STAGE: Array[float] = [0.0, 0.05, 0.10, 0.17]
## A halo that hugs the silhouette: the 110 m quad of the first version filled a third of the sky with flat brass (decision HALO-27).
const HALO_SIZE := Vector2(64.0, 52.0)
const HALO_BEHIND_M: float = 16.0

static var _glow_texture: GradientTexture2D = null
## Metres north of the street grid's centre; the skyline ring ends 44 m out.
const NORTH_M: float = 58.0

const PARTS := {
	&"suburbs": [  # a water tower
		["box", Vector3(0.5, 14.0, 0.5), Vector3(-2.2, 7.0, -2.2), Vector3.ZERO, false],
		["box", Vector3(0.5, 14.0, 0.5), Vector3(2.2, 7.0, -2.2), Vector3.ZERO, false],
		["box", Vector3(0.5, 14.0, 0.5), Vector3(-2.2, 7.0, 2.2), Vector3.ZERO, false],
		["box", Vector3(0.5, 14.0, 0.5), Vector3(2.2, 7.0, 2.2), Vector3.ZERO, false],
		["box", Vector3(6.2, 0.25, 0.25), Vector3(0.0, 4.0, 2.2), Vector3.ZERO, false],
		["box", Vector3(0.25, 0.25, 6.2), Vector3(2.2, 7.0, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(3.3, 3.3, 4.2), Vector3(0.0, 16.1, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(0.0, 3.5, 1.6), Vector3(0.0, 19.0, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(3.38, 3.38, 0.9), Vector3(0.0, 16.0, 0.0), Vector3.ZERO, true],
		["ball", Vector3(0.6, 0.0, 0.0), Vector3(0.0, 20.4, 0.0), Vector3.ZERO, true],
	],
	&"residential": [  # an apartment tower with lit floors and a mast
		["box", Vector3(12.0, 34.0, 10.0), Vector3(0.0, 17.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(8.0, 3.0, 7.0), Vector3(0.0, 35.5, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(0.12, 0.2, 9.0), Vector3(0.0, 41.5, 0.0), Vector3.ZERO, false],
		["ball", Vector3(0.4, 0.0, 0.0), Vector3(0.0, 46.2, 0.0), Vector3.ZERO, true],
		["box", Vector3(10.0, 0.35, 0.2), Vector3(0.0, 12.0, 5.05), Vector3.ZERO, true],
		["box", Vector3(10.0, 0.35, 0.2), Vector3(0.0, 20.0, 5.05), Vector3.ZERO, true],
		["box", Vector3(10.0, 0.35, 0.2), Vector3(0.0, 28.0, 5.05), Vector3.ZERO, true],
	],
	&"park": [  # a ferris wheel
		["ring", Vector3(8.7, 9.3, 0.0), Vector3(0.0, 11.0, 0.0), Vector3.ZERO, true],
		["ring", Vector3(4.4, 4.6, 0.0), Vector3(0.0, 11.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(18.2, 0.2, 0.2), Vector3(0.0, 11.0, 0.0), Vector3(0.0, 0.0, 0.0), false],
		["box", Vector3(18.2, 0.2, 0.2), Vector3(0.0, 11.0, 0.0), Vector3(0.0, 0.0, 60.0), false],
		["box", Vector3(18.2, 0.2, 0.2), Vector3(0.0, 11.0, 0.0), Vector3(0.0, 0.0, 120.0), false],
		["cyl", Vector3(0.7, 0.7, 1.2), Vector3(0.0, 11.0, 0.0), Vector3(90.0, 0.0, 0.0), false],
		["box", Vector3(0.5, 12.0, 0.5), Vector3(-3.4, 5.6, 1.5), Vector3(0.0, 0.0, -16.0), false],
		["box", Vector3(0.5, 12.0, 0.5), Vector3(3.4, 5.6, 1.5), Vector3(0.0, 0.0, 16.0), false],
		["box", Vector3(0.5, 12.0, 0.5), Vector3(-3.4, 5.6, -1.5), Vector3(0.0, 0.0, -16.0), false],
		["box", Vector3(0.5, 12.0, 0.5), Vector3(3.4, 5.6, -1.5), Vector3(0.0, 0.0, 16.0), false],
		["box", Vector3(1.2, 1.0, 1.0), Vector3(9.0, 11.0, 0.0), Vector3.ZERO, true],
		["box", Vector3(1.2, 1.0, 1.0), Vector3(-9.0, 11.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(1.2, 1.0, 1.0), Vector3(0.0, 20.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(1.2, 1.0, 1.0), Vector3(0.0, 2.0, 0.0), Vector3.ZERO, true],
		["box", Vector3(1.2, 1.0, 1.0), Vector3(6.4, 17.4, 0.0), Vector3.ZERO, false],
		["box", Vector3(1.2, 1.0, 1.0), Vector3(-6.4, 17.4, 0.0), Vector3.ZERO, true],
		["box", Vector3(1.2, 1.0, 1.0), Vector3(6.4, 4.6, 0.0), Vector3.ZERO, false],
		["box", Vector3(1.2, 1.0, 1.0), Vector3(-6.4, 4.6, 0.0), Vector3.ZERO, false],
	],
	&"school": [  # a clock tower
		["box", Vector3(5.0, 22.0, 5.0), Vector3(0.0, 11.0, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(0.0, 3.6, 4.0), Vector3(0.0, 24.0, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(1.4, 1.4, 0.2), Vector3(0.0, 18.0, 2.55), Vector3(90.0, 0.0, 0.0), true],
		["box", Vector3(0.12, 1.0, 0.1), Vector3(0.0, 18.4, 2.7), Vector3.ZERO, false],
		["box", Vector3(0.7, 0.12, 0.1), Vector3(0.35, 18.0, 2.7), Vector3.ZERO, false],
		["box", Vector3(16.0, 8.0, 9.0), Vector3(-11.0, 4.0, 0.0), Vector3.ZERO, false],
	],
	&"hospital": [  # a tower with a lit cross and a helipad
		["box", Vector3(14.0, 28.0, 11.0), Vector3(0.0, 14.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(8.0, 18.0, 9.0), Vector3(-11.0, 9.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(1.6, 7.0, 0.3), Vector3(0.0, 21.0, 5.65), Vector3.ZERO, true],
		["box", Vector3(7.0, 1.6, 0.3), Vector3(0.0, 21.0, 5.65), Vector3.ZERO, true],
		["cyl", Vector3(3.0, 3.0, 0.15), Vector3(0.0, 28.1, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(2.7, 2.7, 0.2), Vector3(0.0, 28.15, 0.0), Vector3.ZERO, true],
		["cyl", Vector3(0.1, 0.16, 6.0), Vector3(4.0, 31.0, 0.0), Vector3.ZERO, false],
	],
	&"gas_station": [  # a price pylon and a canopy
		["box", Vector3(0.9, 14.0, 0.9), Vector3(0.0, 7.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(4.2, 5.2, 0.7), Vector3(0.0, 15.5, 0.0), Vector3.ZERO, false],
		["box", Vector3(3.4, 1.0, 0.1), Vector3(0.0, 17.2, 0.4), Vector3.ZERO, true],
		["box", Vector3(3.4, 1.0, 0.1), Vector3(0.0, 15.5, 0.4), Vector3.ZERO, true],
		["box", Vector3(3.4, 1.0, 0.1), Vector3(0.0, 13.8, 0.4), Vector3.ZERO, true],
		["box", Vector3(16.0, 0.6, 9.0), Vector3(-14.0, 6.0, 6.0), Vector3.ZERO, false],
		["box", Vector3(0.5, 6.0, 0.5), Vector3(-20.5, 3.0, 2.5), Vector3.ZERO, false],
		["box", Vector3(0.5, 6.0, 0.5), Vector3(-7.5, 3.0, 2.5), Vector3.ZERO, false],
		["box", Vector3(0.5, 6.0, 0.5), Vector3(-20.5, 3.0, 9.5), Vector3.ZERO, false],
		["box", Vector3(0.5, 6.0, 0.5), Vector3(-7.5, 3.0, 9.5), Vector3.ZERO, false],
		["box", Vector3(14.0, 0.15, 0.4), Vector3(-14.0, 5.6, 6.0), Vector3.ZERO, true],
	],
	&"police": [  # a radio mast and the station
		["cyl", Vector3(0.12, 0.5, 30.0), Vector3(0.0, 15.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(3.0, 0.15, 0.15), Vector3(0.0, 8.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(0.15, 0.15, 3.0), Vector3(0.0, 14.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(3.0, 0.15, 0.15), Vector3(0.0, 20.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(0.15, 0.15, 3.0), Vector3(0.0, 25.0, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(1.2, 1.2, 0.2), Vector3(1.6, 22.0, 0.0), Vector3(90.0, 0.0, 0.0), false],
		["cyl", Vector3(1.2, 1.2, 0.2), Vector3(-1.4, 17.0, 0.6), Vector3(90.0, 0.0, 0.0), false],
		["ball", Vector3(0.45, 0.0, 0.0), Vector3(0.0, 30.4, 0.0), Vector3.ZERO, true],
		["box", Vector3(14.0, 12.0, 10.0), Vector3(-14.0, 6.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(3.0, 0.4, 0.3), Vector3(-14.0, 4.5, 5.2), Vector3.ZERO, true],
	],
	&"warehouses": [  # a gantry crane
		["box", Vector3(1.0, 16.0, 1.0), Vector3(-10.0, 8.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(1.0, 16.0, 1.0), Vector3(10.0, 8.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(22.0, 1.2, 1.6), Vector3(0.0, 16.6, 0.0), Vector3.ZERO, false],
		["box", Vector3(3.0, 1.4, 2.0), Vector3(3.0, 15.3, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(0.05, 0.05, 9.0), Vector3(3.0, 10.4, 0.0), Vector3.ZERO, false],
		["box", Vector3(2.6, 1.6, 2.6), Vector3(3.0, 5.2, 0.0), Vector3.ZERO, false],
		["ball", Vector3(0.3, 0.0, 0.0), Vector3(-10.0, 17.3, 0.0), Vector3.ZERO, true],
		["ball", Vector3(0.3, 0.0, 0.0), Vector3(10.0, 17.3, 0.0), Vector3.ZERO, true],
	],
	&"industrial": [  # smokestacks
		["cyl", Vector3(1.1, 1.7, 34.0), Vector3(-7.0, 17.0, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(1.0, 1.5, 29.0), Vector3(0.0, 14.5, 3.0), Vector3.ZERO, false],
		["cyl", Vector3(0.9, 1.3, 24.0), Vector3(7.0, 12.0, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(1.14, 1.14, 0.5), Vector3(-7.0, 32.0, 0.0), Vector3.ZERO, true],
		["cyl", Vector3(1.04, 1.04, 0.5), Vector3(0.0, 27.0, 3.0), Vector3.ZERO, true],
		["cyl", Vector3(0.94, 0.94, 0.5), Vector3(7.0, 22.0, 0.0), Vector3.ZERO, true],
		["ball", Vector3(0.35, 0.0, 0.0), Vector3(-7.0, 34.3, 0.0), Vector3.ZERO, true],
		["box", Vector3(14.0, 0.8, 0.8), Vector3(0.0, 9.0, -2.0), Vector3.ZERO, false],
	],
	&"substation": [  # a pylon and two transformers
		["box", Vector3(0.35, 20.0, 0.35), Vector3(2.2, 10.0, 2.0), Vector3(0.0, 0.0, 6.3), false],
		["box", Vector3(0.35, 20.0, 0.35), Vector3(-2.2, 10.0, 2.0), Vector3(0.0, 0.0, -6.3), false],
		["box", Vector3(0.35, 20.0, 0.35), Vector3(2.2, 10.0, -2.0), Vector3(0.0, 0.0, 6.3), false],
		["box", Vector3(0.35, 20.0, 0.35), Vector3(-2.2, 10.0, -2.0), Vector3(0.0, 0.0, -6.3), false],
		["box", Vector3(14.0, 0.4, 0.4), Vector3(0.0, 17.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(11.0, 0.4, 0.4), Vector3(0.0, 13.0, 0.0), Vector3.ZERO, false],
		["box", Vector3(8.0, 0.4, 0.4), Vector3(0.0, 9.5, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(0.12, 0.12, 2.2), Vector3(-6.0, 15.8, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(0.12, 0.12, 2.2), Vector3(0.0, 15.8, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(0.12, 0.12, 2.2), Vector3(6.0, 15.8, 0.0), Vector3.ZERO, false],
		["ball", Vector3(0.35, 0.0, 0.0), Vector3(0.0, 20.4, 0.0), Vector3.ZERO, true],
		["box", Vector3(3.0, 3.0, 2.4), Vector3(-9.0, 1.5, 6.0), Vector3.ZERO, false],
		["box", Vector3(3.0, 3.0, 2.4), Vector3(9.0, 1.5, 6.0), Vector3.ZERO, false],
	],
	&"power_station": [  # two cooling towers and a stack
		["cyl", Vector3(6.0, 9.5, 36.0), Vector3(0.0, 18.0, 0.0), Vector3.ZERO, false],
		["cyl", Vector3(6.15, 6.15, 0.5), Vector3(0.0, 36.2, 0.0), Vector3.ZERO, true],
		["cyl", Vector3(4.6, 7.2, 27.0), Vector3(-20.0, 13.5, 4.0), Vector3.ZERO, false],
		["cyl", Vector3(4.7, 4.7, 0.4), Vector3(-20.0, 27.1, 4.0), Vector3.ZERO, true],
		["cyl", Vector3(1.3, 2.0, 44.0), Vector3(18.0, 22.0, -2.0), Vector3.ZERO, false],
		["ball", Vector3(0.5, 0.0, 0.0), Vector3(18.0, 44.6, -2.0), Vector3.ZERO, true],
	],
}

## The landmark of `district_id`: a Node3D of two meshes (body, glow) at `at`; its glow material is kept in the meta "glow" for apply_stage().
static func build(district_id: StringName, at: Vector3) -> Node3D:
	var body := SurfaceTool.new()
	var glow := SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	glow.begin(Mesh.PRIMITIVE_TRIANGLES)
	var parts: Array = PARTS.get(district_id, PARTS[&"suburbs"])
	for part: Array in parts:
		var tilt: Vector3 = part[3]
		var basis := Basis.from_euler(Vector3(deg_to_rad(tilt.x), deg_to_rad(tilt.y), deg_to_rad(tilt.z)))
		var xform := Transform3D(basis, part[2])
		var piece: Mesh = _mesh(String(part[0]), part[1])
		if bool(part[4]):
			glow.append_from(piece, 0, xform)
		else:
			body.append_from(piece, 0, xform)
	var root := Node3D.new()
	root.name = "Landmark"
	root.position = at
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = BODY_COLOR
	body_mat.roughness = 1.0
	body_mat.emission_enabled = true
	body_mat.emission = BODY_SELF_GLOW
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = GLOW_COLOR
	glow_mat.emission_enabled = true
	glow_mat.emission = GLOW_COLOR
	var halo_mat := StandardMaterial3D.new()
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_mat.albedo_texture = glow_texture()
	halo_mat.albedo_color = Color(GLOW_COLOR, 0.0)
	root.set_meta(&"glow", glow_mat)
	root.set_meta(&"body", body_mat)
	root.set_meta(&"halo", halo_mat)
	_add(root, "Body", body.commit(), body_mat)
	_add(root, "Glow", glow.commit(), glow_mat)
	var halo := QuadMesh.new()
	halo.size = HALO_SIZE
	_add(root, "Halo", halo, halo_mat).position = Vector3(0.0, HALO_SIZE.y * 0.38, -HALO_BEHIND_M)
	return root

## A soft round gradient, white at the middle and clear at the edge: the pool of light under a lamp and the halo behind a landmark are quads that carry it.
static func glow_texture() -> GradientTexture2D:
	if _glow_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		gradient.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0, 0.3), Color(1.0, 1.0, 1.0, 0.0)])
		_glow_texture = GradientTexture2D.new()
		_glow_texture.gradient = gradient
		_glow_texture.fill = GradientTexture2D.FILL_RADIAL
		_glow_texture.fill_from = Vector2(0.5, 0.5)
		_glow_texture.fill_to = Vector2(1.0, 0.5)
		_glow_texture.width = 64
		_glow_texture.height = 64
	return _glow_texture

## The glow, the body and the halo for a power stage (DARK, PARTIAL, STREETS, FULL).
static func apply_stage(root: Node3D, stage: int) -> void:
	var i: int = clampi(stage, 0, GLOW_BY_STAGE.size() - 1)
	(root.get_meta(&"glow") as StandardMaterial3D).emission_energy_multiplier = GLOW_BY_STAGE[i]
	(root.get_meta(&"body") as StandardMaterial3D).emission_energy_multiplier = BODY_BY_STAGE[i]
	var halo_mat := root.get_meta(&"halo") as StandardMaterial3D
	halo_mat.albedo_color = Color(GLOW_COLOR, HALO_BY_STAGE[i])
	var halo := root.get_node_or_null("Halo") as Node3D
	if halo != null:
		halo.visible = HALO_BY_STAGE[i] > 0.0

static func _add(root: Node3D, node_name: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	if mesh == null or mesh.get_surface_count() == 0:
		return null
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(instance)
	return instance

static func _mesh(kind: String, size: Vector3) -> Mesh:
	match kind:
		"cyl":
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = size.x
			cylinder.bottom_radius = size.y
			cylinder.height = size.z
			cylinder.radial_segments = 16
			cylinder.rings = 1
			return cylinder
		"ball":
			var ball := SphereMesh.new()
			ball.radius = size.x
			ball.height = size.x * 2.0
			ball.radial_segments = 8
			ball.rings = 4
			return ball
		"ring":
			var ring := TorusMesh.new()
			ring.inner_radius = size.x
			ring.outer_radius = size.y
			ring.rings = 24
			ring.ring_segments = 6
			return _stood_up(ring)
		_:
			var box := BoxMesh.new()
			box.size = size
			return box

## A torus lies in the XZ plane; the ring of a wheel stands in the XY plane.
static func _stood_up(torus: TorusMesh) -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.append_from(torus, 0, Transform3D(Basis(Vector3.RIGHT, deg_to_rad(90.0)), Vector3.ZERO))
	return tool.commit()
