extends Node
## Windowed QA turntable for the seven B9 production meshes: lays them out on a
## lit plane and saves one contact frame to .qa_logs/b9_turntable.png. A mesh is
## not accepted on a log line alone; this frame is read by eye.
##
##   bash tools/qa_sim/guarded_windowed res://scenes/tools/b9_turntable_scene.tscn 120

const NAMES: Array[String] = [
	"mesh_car", "mesh_cabinet", "mesh_fence", "mesh_cart",
	"mesh_crate", "mesh_barrel", "mesh_debris",
]
const OUT := ("res://" + ".qa_logs/b9_turntable.png")

func _ready() -> void:
	_build.call_deferred()

func _build() -> void:
	var world := Node3D.new()
	get_tree().root.add_child(world)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#060f13")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.40, 0.46)
	env.ambient_light_energy = 0.85
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#ffb36a")
	sun.light_energy = 1.5
	sun.rotation_degrees = Vector3(-42, 34, 0)
	world.add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(22, 9)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.12, 0.14, 0.15)
	gm.roughness = 0.95
	ground.material_override = gm
	ground.position.y = -0.02
	world.add_child(ground)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 6.4, 13.5)
	cam.fov = 58.0
	world.add_child(cam)
	cam.look_at(Vector3(0, 0.7, 0))
	cam.make_current()

	var xs: Array[float] = [-8.4, -5.2, -2.7, -0.4, 2.1, 4.2, 6.6]
	for i in NAMES.size():
		var path := "res://assets/mesh/%s.res" % NAMES[i]
		var mesh: ArrayMesh = load(path)
		if mesh == null:
			printerr("[b9-turntable] missing ", path)
			get_tree().quit(1)
			return
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.position = Vector3(xs[i], 0, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.42, 0.44, 0.46) if i < 4 else Color(0.50, 0.44, 0.34)
		mat.roughness = 0.7
		mat.metallic = 0.2
		mi.material_override = mat
		world.add_child(mi)
		print("[b9-turntable] ", NAMES[i], " tris=", _tris(mesh), " aabb=", mesh.get_aabb().size.snappedf(0.01))

	# The game's boot autoloads put the main menu (a full-rect CanvasItem) over
	# the root viewport; hide every canvas layer that is not this turntable's 3D
	# world so the captured bytes really are the meshes, not the menu artwork.
	for layer in get_tree().root.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = false
	for item in get_tree().root.find_children("*", "CanvasItem", true, false):
		(item as CanvasItem).visible = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var err := img.save_png(ProjectSettings.globalize_path(OUT))
	print("[b9-turntable] saved ", OUT, " result=", err, " size=", img.get_size())
	get_tree().quit(0 if err == OK else 1)

func _tris(mesh: Mesh) -> int:
	var total: int = 0
	for s in mesh.get_surface_count():
		var arr: Array = mesh.surface_get_arrays(s)
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		total += ix.size() / 3 if ix != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total
