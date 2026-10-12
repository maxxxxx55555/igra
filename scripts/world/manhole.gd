extends Node3D
## A manhole cover in the street (docs/DISTRICT_SIGNATURES.md): a round iron plate flush with the road that the footsteps ring on (surface
## "metal", read by footstep_system.gd from the shape's metadata) and a thin column of steam that rises from it in a loop. The cover stands
## COVER_LIFT above the road top, so a ray down from the player's foot meets it before the road.

const RADIUS: float = 0.5
const THICKNESS: float = 0.04
const ROAD_TOP: float = 0.06  # StreetBuilder.TILE_THICKNESS 0.1 around y 0.01
const COVER_LIFT: float = 0.01
const IRON := Color("#2a3340")
const STEAM_TEXTURE := preload("res://assets/textures/fx/smoke_puff.png")
const STEAM_AMOUNT: int = 14
const STEAM_COLOR := Color(0.72, 0.76, 0.80, 0.30)

func _ready() -> void:
	var body := StaticBody3D.new()
	body.name = "Cover"
	add_child(body)
	var shape := CollisionShape3D.new()
	var disc := CylinderShape3D.new()
	disc.radius = RADIUS
	disc.height = THICKNESS
	shape.shape = disc
	shape.position.y = ROAD_TOP + COVER_LIFT - THICKNESS * 0.5
	shape.set_meta(&"surface", &"metal")
	body.add_child(shape)
	var plate := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = RADIUS
	mesh.bottom_radius = RADIUS
	mesh.height = THICKNESS
	mesh.radial_segments = 16
	mesh.rings = 1
	var iron := StandardMaterial3D.new()
	iron.albedo_color = IRON
	iron.metallic = 0.6
	iron.roughness = 0.55
	mesh.material = iron
	plate.mesh = mesh
	plate.position.y = ROAD_TOP + COVER_LIFT - THICKNESS * 0.5
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(plate)
	add_child(_steam())

func _steam() -> GPUParticles3D:
	var steam := GPUParticles3D.new()
	steam.name = "Steam"
	steam.amount = STEAM_AMOUNT
	steam.lifetime = 3.0
	steam.preprocess = 3.0
	steam.position.y = ROAD_TOP + COVER_LIFT
	steam.visibility_aabb = AABB(Vector3(-2.0, 0.0, -2.0), Vector3(4.0, 5.0, 4.0))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3.UP
	mat.spread = 10.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 0.9
	mat.gravity = Vector3(0.0, 0.05, 0.0)
	mat.scale_min = 0.45
	mat.scale_max = 0.9
	mat.color = STEAM_COLOR
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	fade.add_point(0.25, Color(1.0, 1.0, 1.0, 1.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	mat.color_ramp = ramp
	steam.process_material = mat
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var quad_mat := StandardMaterial3D.new()
	quad_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	quad_mat.vertex_color_use_as_albedo = true
	quad_mat.albedo_texture = STEAM_TEXTURE
	quad_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = quad_mat
	steam.draw_pass_1 = quad
	return steam
