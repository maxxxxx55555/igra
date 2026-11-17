extends Node3D
## B10 zone set pieces (2026-11-16): the three content-plan zones the store
## recipes need, wired as visual-only world dressing (no collision, no
## navigation, no interactable): the residential playground (yard swing,
## sandbox, chalk sun), the park Keeper's shed (work bench, brass work lamp,
## shortwave radio, papers) and the industrial Workshop B bench under its
## impossible overhead lamp. The two prop lamps burn in every stage like the
## RestLantern: the Keeper's lamp is his own, and Workshop B's burned at 23:15
## with no feeder (industrial_note_02). Their throw is 3-8 m, so they light a
## bench, not the district's architecture.

const _PBR := preload("res://scripts/world/pbr_sets.gd")
const _PICKUP := preload("res://scripts/art/pickup_meshes.gd")
const BRASS := Color("#c9a24a")
const SODIUM := Color("#ffb36a")
const CHALK := Color(0.72, 0.72, 0.68)
const GROUND_Y: float = 0.06
const ALBEDO_SET_MEAN: float = 0.38

func build(district_id: StringName, clear: Array[Vector2], grid: float) -> void:
	var limit: float = grid * 1.5 + 8.0 - 0.5
	match district_id:
		&"residential":
			var at := _spot(Vector3(-grid * 1.7, 0.0, 0.0), clear, Rect2(-1.8, -0.8, 5.1, 4.8), limit)
			if at != Vector3.INF:
				_playground(at)
		&"park":
			var at := _spot(Vector3(grid * 1.7, 0.0, -grid), clear, Rect2(-2.2, -2.2, 4.4, 4.4), limit)
			if at != Vector3.INF:
				_keeper_shed(at)
		&"industrial":
			var at := _spot(Vector3(grid * 1.7, 0.0, 0.0), clear, Rect2(-1.6, -0.4, 3.2, 2.4), limit)
			if at != Vector3.INF:
				_workshop_b(at)

## The first bounded footprint at least 1.8 m from every clear point.
func _spot(base: Vector3, clear: Array[Vector2], footprint: Rect2, limit: float) -> Vector3:
	var offsets: Array[Vector3] = [Vector3.ZERO]
	for z in range(-6, 7, 3):
		for x in range(-6, 7, 3):
			if x != 0 or z != 0:
				offsets.append(Vector3(float(x), 0.0, float(z)))
	for off in offsets:
		var at: Vector3 = base + off
		var bounds := Rect2(Vector2(at.x, at.z) + footprint.position, footprint.size)
		if bounds.position.x < -limit or bounds.position.y < -limit or bounds.end.x > limit or bounds.end.y > limit:
			continue
		var free := true
		for c in clear:
			var closest := Vector2(clampf(c.x, bounds.position.x, bounds.end.x), clampf(c.y, bounds.position.y, bounds.end.y))
			if c.distance_to(closest) < 1.8:
				free = false
				break
		if free:
			return at
	return Vector3.INF

func _mat(set_name: String, tint: Color, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat = _PBR.apply(mat, set_name)
	if mat.albedo_texture != null:
		mat.albedo_color = Color(
			minf(tint.r / ALBEDO_SET_MEAN, 1.0),
			minf(tint.g / ALBEDO_SET_MEAN, 1.0),
			minf(tint.b / ALBEDO_SET_MEAN, 1.0),
			tint.a
		)
	else:
		mat.albedo_color = tint
	mat.roughness = rough
	mat.metallic = 0.0
	return mat

func _plain(tint: Color, rough: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = rough
	mat.metallic = 0.0
	return mat

func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.material_override = mat
	mi.position = at
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func _tube(parent: Node3D, node_name: String, r: float, h: float, at: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var m := CylinderMesh.new()
	m.top_radius = r
	m.bottom_radius = r
	m.height = h
	m.radial_segments = 8
	m.rings = 1
	mi.mesh = m
	mi.material_override = mat
	mi.position = at
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

func _bulb(parent: Node3D, at: Vector3, glow: Color, energy: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Bulb"
	var m := SphereMesh.new()
	m.radius = 0.05
	m.height = 0.1
	m.radial_segments = 8
	m.rings = 4
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = glow
	mat.emission_enabled = true
	mat.emission = glow
	mat.emission_energy_multiplier = energy
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
	return mi

# ---------------- residential: the playground ----------------

func _playground(at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "Playground"
	root.position = at
	add_child(root)
	var iron := _mat("rusted_metal", Color(0.30, 0.28, 0.26), 0.6)
	var plank := _mat("plywood", Color(0.42, 0.34, 0.24), 0.85)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(root, "SwingLeg", Vector3(0.07, 2.3, 0.07), Vector3(sx * 1.15, 1.1, sz * 0.55), iron, Vector3(sz * 0.24, 0.0, -sx * 0.24))
	_tube(root, "SwingBar", 0.045, 2.6, Vector3(0.0, 2.2, 0.0), iron, Vector3(0.0, 0.0, PI * 0.5))
	for i in 2:
		var x: float = -0.55 + float(i) * 1.1
		var sway: float = 0.10 if i == 0 else -0.06
		var swing := Node3D.new()
		swing.name = "Swing%d" % i
		swing.position = Vector3(x, 2.2, 0.0)
		swing.rotation.x = sway
		root.add_child(swing)
		for sz in [-1.0, 1.0]:
			_tube(swing, "Rope", 0.012, 1.7, Vector3(0.0, -0.85, sz * 0.16), iron)
		_box(swing, "Seat", Vector3(0.42, 0.04, 0.20), Vector3(0.0, -1.72, 0.0), plank)
	var sand := Node3D.new()
	sand.name = "Sandbox"
	sand.position = Vector3(2.3, 0.0, 1.5)
	root.add_child(sand)
	for sz in [-1.0, 1.0]:
		_box(sand, "SandboxWall", Vector3(1.7, 0.26, 0.09), Vector3(0.0, GROUND_Y + 0.13, sz * 0.85), plank)
		_box(sand, "SandboxWall", Vector3(0.09, 0.26, 1.7), Vector3(sz * 0.85, GROUND_Y + 0.13, 0.0), plank)
	_box(sand, "Sand", Vector3(1.62, 0.05, 1.62), Vector3(0.0, GROUND_Y + 0.16, 0.0), _plain(Color(0.34, 0.31, 0.25), 1.0))
	# the chalk sun of suburbs_note_06 answered: a circle and eight rays
	var chalk := _plain(CHALK, 0.95)
	var sun := Node3D.new()
	sun.name = "ChalkSun"
	sun.position = Vector3(0.4, GROUND_Y + 0.015, 3.1)
	root.add_child(sun)
	for i in 16:
		var a: float = TAU * float(i) / 16.0
		_box(sun, "ChalkRing", Vector3(0.22, 0.006, 0.05), Vector3(cos(a) * 0.55, 0.0, sin(a) * 0.55), chalk, Vector3(0.0, -a, 0.0))
	for i in 8:
		var a2: float = TAU * float(i) / 8.0 + 0.2
		_box(sun, "ChalkRay", Vector3(0.26, 0.006, 0.045), Vector3(cos(a2) * 0.82, 0.0, sin(a2) * 0.82), chalk, Vector3(0.0, -a2, 0.0))

# ---------------- park: the Keeper's shed ----------------

func _keeper_shed(at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "KeeperShed"
	root.position = at
	root.rotation.y = 0.6
	add_child(root)
	var wood := _mat("plywood", Color(0.32, 0.27, 0.20), 0.88)
	var dark := _mat("plywood", Color(0.22, 0.19, 0.15), 0.9)
	_box(root, "ShedFloor", Vector3(3.0, 0.10, 2.4), Vector3(0.0, GROUND_Y + 0.05, 0.0), dark)
	_box(root, "ShedBack", Vector3(3.0, 2.3, 0.10), Vector3(0.0, GROUND_Y + 1.2, -1.15), wood)
	for sx in [-1.0, 1.0]:
		_box(root, "ShedSide", Vector3(0.10, 2.3, 2.4), Vector3(sx * 1.45, GROUND_Y + 1.2, 0.0), wood)
	_box(root, "ShedRoof", Vector3(3.3, 0.08, 2.7), Vector3(0.0, GROUND_Y + 2.42, -0.1), dark, Vector3(0.10, 0.0, 0.0))
	var bench := Node3D.new()
	bench.name = "WorkBench"
	bench.position = Vector3(0.0, 0.0, -0.75)
	root.add_child(bench)
	_box(bench, "BenchTop", Vector3(1.9, 0.08, 0.65), Vector3(0.0, GROUND_Y + 0.86, 0.0), wood)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(bench, "BenchLeg", Vector3(0.08, 0.82, 0.08), Vector3(sx * 0.85, GROUND_Y + 0.41, sz * 0.24), dark)
	# the brass work lamp: the single warm source of the shot
	var lamp := Node3D.new()
	lamp.name = "WorkLamp"
	lamp.position = Vector3(-0.35, GROUND_Y + 0.90, 0.25)
	bench.add_child(lamp)
	_tube(lamp, "LampStem", 0.02, 0.34, Vector3(0.0, 0.17, 0.0), _mat("rusted_metal", Color(0.4, 0.35, 0.25), 0.5))
	var shade := MeshInstance3D.new()
	shade.name = "LampShade"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.03
	cone.bottom_radius = 0.14
	cone.height = 0.12
	cone.radial_segments = 10
	shade.mesh = cone
	shade.material_override = _mat("rusted_metal", Color(0.45, 0.38, 0.22), 0.45)
	shade.position = Vector3(0.0, 0.38, 0.0)
	lamp.add_child(shade)
	_bulb(lamp, Vector3(0.0, 0.33, 0.0), BRASS, 2.5)
	var light := OmniLight3D.new()
	light.name = "WorkLampLight"
	light.light_color = BRASS
	light.light_energy = 1.6
	light.omni_range = 3.2
	light.position = Vector3(0.0, 0.30, 0.0)
	lamp.add_child(light)
	# the shortwave radio and the work orders
	var radio := Node3D.new()
	radio.name = "ShortwaveRadio"
	radio.position = Vector3(0.20, GROUND_Y + 0.96, 0.02)
	radio.rotation.y = -0.15
	bench.add_child(radio)
	var casing := _mat("rusted_metal", Color(0.22, 0.23, 0.21), 0.65)
	var speaker := _plain(Color(0.075, 0.08, 0.07), 0.95)
	var grille := _plain(Color(0.11, 0.12, 0.11), 0.7)
	grille.metallic = 0.3
	var glass := _plain(Color(0.12, 0.16, 0.15), 0.18)
	var dial_brass := _plain(Color(0.47, 0.38, 0.20), 0.6)
	var knob := _plain(Color(0.16, 0.17, 0.15), 0.55)
	_box(radio, "Casing", Vector3(0.46, 0.24, 0.20), Vector3(0.0, 0.12, 0.0), casing)
	_box(radio, "SpeakerFace", Vector3(0.25, 0.16, 0.014), Vector3(-0.085, 0.12, 0.107), speaker)
	for i in 8:
		_box(radio, "GrilleBar%d" % i, Vector3(0.004, 0.142, 0.003), Vector3(-0.19 + float(i) * 0.03, 0.12, 0.1155), grille)
	_box(radio, "TuningGlass", Vector3(0.12, 0.045, 0.014), Vector3(0.135, 0.17, 0.109), glass)
	_box(radio, "TuningMark", Vector3(0.002, 0.026, 0.002), Vector3(0.135, 0.17, 0.118), dial_brass)
	_box(radio, "TuningNeedle", Vector3(0.033, 0.002, 0.002), Vector3(0.13, 0.166, 0.12), dial_brass)
	_tube(radio, "VolumeKnob", 0.021, 0.024, Vector3(0.095, 0.075, 0.12), knob, Vector3(PI * 0.5, 0.0, 0.0))
	_tube(radio, "TuningKnob", 0.021, 0.024, Vector3(0.175, 0.075, 0.12), knob, Vector3(PI * 0.5, 0.0, 0.0))
	_tube(radio, "Antenna", 0.006, 0.34, Vector3(-0.16, 0.37, -0.04), grille)
	var paper := _plain(Color(0.60, 0.58, 0.52), 0.95)
	for i in 3:
		_box(bench, "Paper%d" % i, Vector3(0.21, 0.004, 0.29), Vector3(-0.15 + float(i) * 0.22, GROUND_Y + 0.905 + float(i) * 0.004, 0.12 - float(i) * 0.06), paper, Vector3(0.0, 0.4 * float(i) - 0.3, 0.0))
	for i in 2:
		_box(root, "PartsShelf", Vector3(0.9, 0.05, 0.3), Vector3(1.3, GROUND_Y + 1.1 + float(i) * 0.5, -0.6), wood)
		_box(root, "PartsBox", Vector3(0.22, 0.16, 0.18), Vector3(1.25, GROUND_Y + 1.21 + float(i) * 0.5, -0.6), dark)

# ---------------- industrial: Workshop B, the 23:15 room ----------------

func _workshop_b(at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "WorkshopB"
	root.position = at
	add_child(root)
	var steel := _mat("rusted_metal", Color(0.30, 0.30, 0.32), 0.55)
	var wood := _mat("plywood", Color(0.36, 0.30, 0.22), 0.85)
	_box(root, "BenchTop", Vector3(2.0, 0.09, 0.7), Vector3(0.0, GROUND_Y + 0.9, 0.0), wood)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(root, "BenchLeg", Vector3(0.09, 0.86, 0.09), Vector3(sx * 0.9, GROUND_Y + 0.43, sz * 0.26), steel)
	# the impossible overhead: it burns with no feeder, full and warm
	_tube(root, "LampCord", 0.018, 0.9, Vector3(0.0, GROUND_Y + 3.85, 0.0), steel)
	var shade := MeshInstance3D.new()
	shade.name = "LampShade"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 0.34
	cone.height = 0.26
	cone.radial_segments = 12
	shade.mesh = cone
	shade.material_override = steel
	shade.position = Vector3(0.0, GROUND_Y + 3.35, 0.0)
	root.add_child(shade)
	# The lit lens under the shade: from below the lamp has to read as a lamp
	# and not as a white speck in the dark, so the burning part is a warm disc.
	var lens := MeshInstance3D.new()
	lens.name = "LampLens"
	var disc := CylinderMesh.new()
	disc.top_radius = 0.30
	disc.bottom_radius = 0.30
	disc.height = 0.015
	disc.radial_segments = 16
	lens.mesh = disc
	var lens_mat := StandardMaterial3D.new()
	lens_mat.albedo_color = SODIUM
	lens_mat.emission_enabled = true
	lens_mat.emission = SODIUM
	lens_mat.emission_energy_multiplier = 1.4
	lens_mat.roughness = 0.4
	lens.material_override = lens_mat
	lens.position = Vector3(0.0, GROUND_Y + 3.22, 0.0)
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(lens)
	_bulb(root, Vector3(0.0, GROUND_Y + 3.28, 0.0), SODIUM, 3.0)
	var spot := SpotLight3D.new()
	spot.name = "BenchLight"
	spot.light_color = SODIUM
	spot.light_energy = 4.0
	spot.spot_range = 8.0
	spot.spot_angle = 55.0
	spot.spot_angle_attenuation = 1.2
	spot.position = Vector3(0.0, GROUND_Y + 3.25, 0.0)
	spot.rotation.x = -PI * 0.5
	root.add_child(spot)
	# the conveyor tail sorting brass lamp shells
	var conv := Node3D.new()
	conv.name = "ConveyorTail"
	conv.position = Vector3(0.0, 0.0, 1.7)
	root.add_child(conv)
	_box(conv, "ConveyorFrame", Vector3(3.0, 0.12, 0.5), Vector3(0.0, GROUND_Y + 0.72, 0.0), steel)
	for i in 6:
		_tube(conv, "Roller", 0.05, 0.46, Vector3(-1.25 + float(i) * 0.5, GROUND_Y + 0.82, 0.0), steel, Vector3(PI * 0.5, 0.0, 0.0))
	for sx in [-1.0, 1.0]:
		_box(conv, "ConveyorLeg", Vector3(0.08, 0.7, 0.08), Vector3(sx * 1.3, GROUND_Y + 0.35, 0.0), steel)
	for i in 3:
		_tube(conv, "LampShell", 0.09, 0.1, Vector3(-0.8 + float(i) * 0.7, GROUND_Y + 0.92, 0.0), _mat("rusted_metal", Color(0.5, 0.4, 0.2), 0.4))
	var toolbox := MeshInstance3D.new()
	toolbox.name = "Toolbox"
	toolbox.mesh = _PICKUP.mesh_for(&"repair_kit")
	var tmats: Array[Material] = _PICKUP.materials_for(&"repair_kit")
	if tmats.size() > 0:
		toolbox.material_override = tmats[0]
	toolbox.position = Vector3(0.7, GROUND_Y + 1.0, 0.1)
	root.add_child(toolbox)