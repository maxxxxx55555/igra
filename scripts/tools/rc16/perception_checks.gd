extends RefCounted
## Light-truth wave gates: perception (frustum + rendered light + clear eye line), the damage-number gate, cartography's
## rendered-light survey with its per-lamp cursor, the rain overlay's Low-tier guard and the export/boot config.
## Wired into _closeout_check_runner.gd as `await RcPerception.run(self)`; CLOSEOUT_ONLY=perception runs it alone.
## Fixtures stand 900 m off the district origin: no district geometry or lamp reaches them, and the check camera is current
## so the LightLimiter keeps the fixture glow among the nearest rendered lights.

const _Weather := preload("res://scripts/ui/weather_overlay.gd")
const _Lamp := preload("res://scripts/world/streetlight_3d.gd")
const LAMP_HEIGHT: float = 4.2

static func run(r: Node) -> void:
	r._playing()
	await _visibility(r)
	await _cartography(r)
	await _weather_tier(r)
	_config_static(r)

static func _make_camera(r: Node, at: Vector3, target: Vector3) -> Camera3D:
	var cam := Camera3D.new()
	cam.fov = 90.0
	r.add_child(cam)
	cam.look_at_from_position(at, target)
	cam.make_current()
	return cam

static func _restore_camera(prev: Camera3D, cam: Camera3D) -> void:
	if is_instance_valid(prev):
		prev.make_current()
	cam.queue_free()

## VIS1..VIS6 and DN1: one monster on an empty flat, one pool light above it, one camera looking at its chest.
static func _visibility(r: Node) -> void:
	var base: Vector3 = Cartography.district_origin() + Vector3(900.0, 0.0, 900.0)
	var prev_cam: Camera3D = r.get_viewport().get_camera_3d()
	var cam := _make_camera(r, base + Vector3(0.0, 1.6, 8.0), base + Vector3(0.0, 1.0, 0.0))
	var monster: Node3D = r._monster("crawler_3d", base)
	monster.set("_seen_in_beam", false)
	var flash0: bool = bool(r._player.get("flashlight_enabled"))
	r._player.set("flashlight_enabled", false)
	await r.get_tree().physics_frame
	var dark: bool = not monster.is_perceptible()
	r._ok(dark, "VIS1 a monster in darkness with no beam is not perceptible, even on camera (%s)" % dark)
	var pool := OmniLight3D.new()
	pool.omni_range = 8.0
	pool.light_energy = 2.0
	r.add_child(pool)
	pool.global_position = base + Vector3(0.0, 3.0, 0.0)
	LightGrid.register_light(pool)
	await r.get_tree().physics_frame
	var listed: bool = LightGrid.visible_lights_at(base, BaseMonster.LIT_POOL).has(pool)
	var lit: bool = monster.is_perceptible()
	r._ok(listed and lit, "VIS2 a monster in an unoccluded lit pool within the frustum is perceptible and the pool light is listed (listed %s, perceptible %s)" % [listed, lit])
	pool.visible = false
	var hidden: bool = not monster.is_perceptible() and not LightGrid.visible_lights_at(base, BaseMonster.LIT_POOL).has(pool)
	pool.visible = true
	r._ok(hidden, "VIS3 a glow the limiter hides (visible=false, energy kept) neither lists nor makes the monster perceptible (%s)" % hidden)
	monster.set("_seen_in_beam", true)
	var beam: bool = monster.is_perceptible()
	monster.set("_seen_in_beam", false)
	r._ok(beam, "VIS4 the flashlight beam alone makes an on-camera monster with a clear eye line perceptible (%s)" % beam)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(6.0, 3.0, 0.4)
	shape.shape = box
	wall.add_child(shape)
	r.add_child(wall)
	wall.global_position = base + Vector3(0.0, 1.5, 4.0)
	await r.get_tree().physics_frame
	var walled_pool: bool = not monster.is_perceptible()
	monster.set("_seen_in_beam", true)
	var walled_beam: bool = not monster.is_perceptible()
	monster.set("_seen_in_beam", false)
	wall.queue_free()
	r._ok(walled_pool and walled_beam, "VIS5 a monster in a lit pool BEHIND a wall is not perceptible, beam or pool: the eye line decides (pool %s, beam %s)" % [walled_pool, walled_beam])
	cam.look_at_from_position(cam.global_position, base + Vector3(0.0, 1.0, 20.0))
	await r.get_tree().physics_frame
	var off_camera: bool = not monster.is_perceptible()
	r._ok(off_camera, "VIS6 a lit monster outside the camera frustum is not perceptible (%s)" % off_camera)
	# DN1: the HUD handler itself gates the number on perception, so a blind hit leaks no position.
	cam.look_at_from_position(cam.global_position, base + Vector3(0.0, 1.0, 0.0))
	await r.get_tree().physics_frame
	var hud: Node = r._main.get_node_or_null("HUD")
	var numbers: Node = hud.get_node_or_null("DamageNumbers") if hud != null else null
	var shown_dark := true
	var shown_lit := false
	if numbers != null:
		for label: Node in numbers.get_children():
			(label as CanvasItem).visible = false
		pool.visible = false
		hud.call("_on_enemy_damaged", monster, 7.0)
		shown_dark = _any_number_visible(numbers)
		pool.visible = true
		hud.call("_on_enemy_damaged", monster, 7.0)
		shown_lit = _any_number_visible(numbers)
		for label: Node in numbers.get_children():
			(label as CanvasItem).visible = false
	r._ok(numbers != null and not shown_dark and shown_lit,
		"DN1 the HUD gives a damage number only to a perceptible monster: a blind hit shows none (%s), a lit hit shows one (%s)" % [not shown_dark, shown_lit])
	LightGrid.unregister_light(pool)
	pool.queue_free()
	monster.queue_free()
	r._player.set("flashlight_enabled", flash0)
	_restore_camera(prev_cam, cam)

static func _any_number_visible(numbers: Node) -> bool:
	for label: Node in numbers.get_children():
		if (label as CanvasItem).visible:
			return true
	return false

## A restored lamp of the real streetlight script: flicker off, powered by hand after its unknown-district stage left it dark.
static func _make_lamp(r: Node, at: Vector3, omni_range: float, spot_angle: float) -> Node3D:
	var lamp: Node3D = _Lamp.new()
	lamp.name = "QaLamp"
	lamp.set("lamp_flicker", false)
	lamp.set("district_id", &"qa_fixture")
	lamp.set("mesh_visible", false)
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.position = Vector3(0.0, LAMP_HEIGHT, 0.0)
	glow.omni_range = omni_range
	glow.light_energy = 1.0
	lamp.add_child(glow)
	var spot := SpotLight3D.new()
	spot.name = "SpotLight"
	spot.position = Vector3(0.0, LAMP_HEIGHT, 0.0)
	spot.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	spot.spot_range = 16.0
	spot.spot_angle = spot_angle
	spot.light_energy = 2.0
	lamp.add_child(spot)
	r.add_child(lamp)
	lamp.global_position = at
	# _ready ran _apply_stage for the unknown district and left the lamp dark: power it by hand as a restored lamp.
	lamp.set("_on", true)
	glow.visible = true
	glow.light_energy = 1.0
	spot.visible = true
	spot.light_energy = 2.0
	LightGrid.register_light(glow)
	return lamp

static func _free_lamp(lamp: Node) -> void:
	var glow := lamp.get_node_or_null("Glow") as OmniLight3D
	if glow != null:
		LightGrid.unregister_light(glow)
	lamp.queue_free()

static func _cell_ground(origin: Vector3, cell: Vector2i) -> Vector3:
	return origin + Vector3((cell.x + 0.5) * Cartography.CELL, Cartography.GROUND_LIFT, (cell.y + 0.5) * Cartography.CELL)

## CART1..CART5: each scenario charts into its own district id, so the passes never mix; the real memory is restored after.
static func _cartography(r: Node) -> void:
	var dm := r.get_node_or_null("/root/DistrictManager")
	if dm == null:
		r._ok(false, "CART the DistrictManager autoload is missing")
		return
	var district0: String = dm.current_district
	var saved: Dictionary = Cartography.to_dict()
	var held: Array[Node] = []
	# GDScript loop variables share the enclosing function scope: `lamp` is the
	# fixture created below, so the two sweeps use their own distinct names.
	for street_lamp: Node in r.get_tree().get_nodes_in_group(&"streetlights"):
		if bool(street_lamp.get("_on")):
			street_lamp.set("_on", false)
			held.append(street_lamp)
	var origin: Vector3 = Cartography.district_origin()
	var foot: Vector3 = origin + Vector3(-900.0, 0.0, -900.0)
	var prev_cam: Camera3D = r.get_viewport().get_camera_3d()
	var cam := _make_camera(r, foot + Vector3(10.0, 1.6, 0.0), foot)
	# CART1: the positive path charts cells only inside the rendered glow's ground reach and the frustum.
	dm.current_district = "qa_cart_positive"
	var lamp := _make_lamp(r, foot, 8.0, 55.0)
	for i: int in 6:
		Cartography.survey()
	var cells: Dictionary = Cartography.charted_cells("qa_cart_positive")
	var reach: float = sqrt(64.0 - LAMP_HEIGHT * LAMP_HEIGHT)
	var bounded := true
	var in_frustum := true
	var beyond_spot := false
	for cell: Vector2i in cells:
		var ground := _cell_ground(origin, cell)
		var d: float = Vector2(ground.x - foot.x, ground.z - foot.z).length()
		bounded = bounded and d <= reach + 0.01
		in_frustum = in_frustum and cam.is_position_in_frustum(ground)
		beyond_spot = beyond_spot or d > 4.0
	var far_cell: Vector2i = Cartography.cell_of(foot - origin + Vector3(20.0, 0.0, 0.0))
	r._ok(not cells.is_empty() and bounded and in_frustum and beyond_spot and not cells.has(far_cell),
		"CART1 a restored lamp charts cells only within its rendered reach and the frustum (%d cells, bounded %s, on camera %s, past the spot pool %s, no far cell %s)" % [cells.size(), bounded, in_frustum, beyond_spot, not cells.has(far_cell)])
	_free_lamp(lamp)
	await r.get_tree().process_frame
	# CART2: flashlight on, no powered lamp: nothing charts.
	dm.current_district = "qa_cart_dark"
	var lamp2 := _make_lamp(r, foot, 8.0, 55.0)
	lamp2.set("_on", false)
	var flash0: bool = bool(r._player.get("flashlight_enabled"))
	r._player.set("flashlight_enabled", true)
	for i: int in 4:
		Cartography.survey()
	var unpowered: bool = Cartography.charted_cells("qa_cart_dark").is_empty()
	r._player.set("flashlight_enabled", flash0)
	_free_lamp(lamp2)
	await r.get_tree().process_frame
	r._ok(unpowered, "CART2 the flashlight on and walking with no powered lamp charts nothing (%s)" % unpowered)
	# CART3: an authored always-on lamp is not the player's doing.
	dm.current_district = "qa_cart_force"
	var lamp3 := _make_lamp(r, foot, 8.0, 55.0)
	lamp3.set("force_on", true)
	for i: int in 4:
		Cartography.survey()
	var forced: bool = Cartography.charted_cells("qa_cart_force").is_empty()
	_free_lamp(lamp3)
	await r.get_tree().process_frame
	r._ok(forced, "CART3 a force_on lamp charts nothing (%s)" % forced)
	# CART4: the limiter hid the glow (visible=false, energy kept): only the still-rendered spot pool charts.
	# No await between hiding and the passes, so the limiter cannot restore the glow mid-scenario.
	dm.current_district = "qa_cart_spot"
	var lamp4 := _make_lamp(r, foot, 14.0, 30.0)
	var glow4 := lamp4.get_node("Glow") as OmniLight3D
	glow4.visible = false
	var spot_pool: float = LAMP_HEIGHT * tan(deg_to_rad(30.0))
	for i: int in 6:
		Cartography.survey()
	var cells4: Dictionary = Cartography.charted_cells("qa_cart_spot")
	var only_spot := not cells4.is_empty()
	for cell: Vector2i in cells4:
		var ground := _cell_ground(origin, cell)
		only_spot = only_spot and Vector2(ground.x - foot.x, ground.z - foot.z).length() <= spot_pool + 0.01
	_free_lamp(lamp4)
	await r.get_tree().process_frame
	r._ok(only_spot, "CART4 a limiter-hidden glow charts only the spot pool (%d cells, all within %.2f m: %s)" % [cells4.size(), spot_pool, only_spot])
	# CART5: a wall hides the whole prefix of the cell scan; the per-lamp cursor must still reach the cells after it.
	# The reach of 19.55 m puts more than CELLS_PER_TICK blocked candidates before the first visible one.
	dm.current_district = "qa_cart_fair"
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.4, 3.0, 44.0)
	shape.shape = box
	wall.add_child(shape)
	r.add_child(wall)
	wall.global_position = foot + Vector3(-1.0, 1.5, 0.0)
	var lamp5 := _make_lamp(r, foot, 20.0, 55.0)
	await r.get_tree().physics_frame
	for i: int in 30:
		Cartography.survey()
	var cells5: Dictionary = Cartography.charted_cells("qa_cart_fair")
	var reached_later := false
	var leaked := false
	for cell: Vector2i in cells5:
		var gx: float = origin.x + (cell.x + 0.5) * Cartography.CELL
		reached_later = reached_later or gx > foot.x
		leaked = leaked or gx < foot.x - 1.2
	_free_lamp(lamp5)
	wall.queue_free()
	await r.get_tree().process_frame
	r._ok(reached_later and not leaked,
		"CART5 blocked prefix cells do not starve the later ones: the cursor charts past the wall (%d cells, reached %s, nothing leaked behind the wall %s)" % [cells5.size(), reached_later, not leaked])
	dm.current_district = district0
	Cartography.reset()
	Cartography.from_dict(saved)
	for held_lamp: Node in held:
		held_lamp.set("_on", true)
	_restore_camera(prev_cam, cam)

## WX1: the rain overlay hides and stops its draw/tick work on the Low tier, live on settings_changed.
static func _weather_tier(r: Node) -> void:
	r._playing()
	var tier0: int = int(SettingsManager.get_setting("graphics_tier", 2))
	var overlay: Control = _Weather.new()
	r.add_child(overlay)
	await r.get_tree().process_frame
	EventBus.weather_changed.emit(1, "rain", 0.0, 0.8)
	SettingsManager.set_graphics_tier(0)
	await r.get_tree().process_frame
	var low_hidden: bool = not overlay.visible
	var low_still: bool = not overlay.is_processing()
	SettingsManager.set_graphics_tier(2)
	await r.get_tree().process_frame
	var high_shown: bool = overlay.visible and overlay.is_processing()
	SettingsManager.set_graphics_tier(tier0)
	var ws := r.get_node_or_null("/root/WeatherSystem")
	if ws != null:
		ws.call("_emit")  # the scenario's rain emit is undone with the real weather state
	overlay.queue_free()
	r._ok(low_hidden and low_still and high_shown,
		"WX1 the rain overlay is hidden and still on Low, live on the tier change, and draws again above Low (hidden %s, still %s, shown %s)" % [low_hidden, low_still, high_shown])

## CFG1..CFG3: the export refuses the internet permission, the boot splash points at a real file, and the rain guard is in the source.
static func _config_static(r: Node) -> void:
	var presets := ConfigFile.new()
	var net_ok: bool = presets.load("res://export_presets.cfg") == OK
	var has_key := false
	if net_ok:
		for section: String in presets.get_sections():
			if presets.has_section_key(section, "permissions/internet"):
				has_key = true
				net_ok = net_ok and presets.get_value(section, "permissions/internet") == false
	r._ok(net_ok and has_key, "CFG1 every export preset that carries the internet permission refuses it (permissions/internet=false)")
	var project := ConfigFile.new()
	var splash: String = str(project.get_value("application", "boot_splash/image", "")) if project.load("res://project.godot") == OK else ""
	r._ok(splash != "" and FileAccess.file_exists(splash), "CFG2 the boot splash image is set to an existing file (%s)" % splash)
	var weather_src: String = FileAccess.get_file_as_string("res://scripts/ui/weather_overlay.gd")
	r._ok(weather_src.contains("graphics_tier") and weather_src.contains("settings_changed"),
		"CFG3 the rain overlay source carries the Low-tier guard wired to settings_changed (supplement to WX1)")