extends RefCounted
## Session 29 (the v10.0.0-ship pass), R6 the exit leaks, F19 the brightness drift and R2 the light limiter. LEAK1 every close button a screen keeps is in the tree or null: the six screens without a close button each held a
## `Button.new()` that never entered it, and at exit those six Buttons kept their theme styles, shaped texts and two fonts alive (12 ShapedTextData and 2 Font RIDs, 37 ObjectDB instances in a short run). LAMP2 the lamps do
## not flicker in step: all 48 lamps of a district started their sine at 0, so the street pulsed by 15 % and fell to a fifth of its light six times a second together (two frames of one view differed by up to 20 %).
## LIMIT1 to LIMIT3 the LightLimiter shows the eight nearest LIT omni lights: it set `visible` of every omni light by its rank, so the glow of the six nearest unlit lamps came back on in a dark district and held six of the
## eight slots (5 ms of a frame at the High tier). Wired into _closeout_check_runner.gd.

const _LAMP := preload("res://scenes/props/streetlight_3d.tscn")

static func run(r: Node) -> void:
	_screens(r)
	await _lamps(r)
	await _limiter(r)

static func _screens(r: Node) -> void:
	var screens: Node = r._main.get_node_or_null("Screens")
	var data: Dictionary = screens.get("_screen_data") if screens != null else {}
	var bare: int = 0
	var orphans: int = 0
	for entry: Dictionary in data.values():
		var button: Button = entry.get("close_btn")
		bare += 1 if button == null else 0
		orphans += 1 if button != null and not button.is_inside_tree() else 0
	r._ok(not data.is_empty() and bare > 0 and orphans == 0, "LEAK1 no screen holds a close button outside the tree (%d screens, %d without a close button, %d orphans)" % [data.size(), bare, orphans])

## Twelve lit lamps 11 m apart stand on their own phases of the flicker (buckets of half a radian over the 12 rad/s sine): lamps that start together stand in one.
static func _lamps(r: Node) -> void:
	var holder := Node3D.new()
	r._main.add_child(holder)
	var lamps: Array[Node3D] = []
	for i in 12:
		var lamp := _LAMP.instantiate() as Node3D
		lamp.set("force_on", true)
		lamp.position = Vector3(float(i) * 11.0, 0.0, float(i % 3) * 7.0)
		holder.add_child(lamp)
		lamps.append(lamp)
	for _frame in 3:
		await r.get_tree().process_frame
	var phases: Dictionary = {}
	for lamp in lamps:
		phases[int(fposmod(float(lamp.get("_t")) * 12.0, TAU) / 0.5)] = true
	holder.queue_free()
	r._ok(phases.size() >= 5, "LAMP2 twelve lit lamps stand on %d of 13 phases of the flicker (one when they flicker in step)" % phases.size())

## Nine lit lights in a row from the camera, one light of no energy nearest of all and a lamp that is out: after a pass the eight nearest lit lights are shown and the ninth is hidden (LIMIT1), the light of no energy and
## the glow of the lamp are off (LIMIT2), and the light that is lit again comes back while the eighth of the others gives its slot (LIMIT3). Every other omni light of the scene is put out while the check runs.
static func _limiter(r: Node) -> void:
	var limiter: Node = r.get_tree().root.get_node_or_null("LightLimiter")
	var camera: Camera3D = r.get_viewport().get_camera_3d()
	if limiter == null or camera == null:
		r._ok(false, "LIMIT1 the LightLimiter and a camera exist")
		return
	var others: Dictionary = {}
	for node: Node in r.get_tree().get_nodes_in_group(&"omni_lights"):
		others[node] = (node as OmniLight3D).visible
		(node as OmniLight3D).visible = false
	var holder := Node3D.new()
	r._main.add_child(holder)
	var at: Vector3 = camera.global_position
	var lit: Array[OmniLight3D] = []
	for i in 9:
		var light := OmniLight3D.new()
		light.light_energy = 1.0
		holder.add_child(light)
		light.global_position = at + Vector3(0.0, 0.0, -2.0 - float(i))
		lit.append(light)
	var idle := OmniLight3D.new()
	idle.light_energy = 0.0
	holder.add_child(idle)
	idle.global_position = at + Vector3(0.0, 0.0, -1.0)
	var lamp := _LAMP.instantiate() as Node3D
	holder.add_child(lamp)
	lamp.global_position = at + Vector3(1.0, 0.0, -1.5)
	var glow := lamp.get_node("Glow") as OmniLight3D
	await r.get_tree().process_frame
	limiter.call("_update_lights")
	var shown: int = 0
	for i in 8:
		shown += 1 if lit[i].visible else 0
	r._ok(shown == 8 and not lit[8].visible, "LIMIT1 of nine lit lights the eight nearest are shown and the ninth is hidden (%d of the eight shown, ninth %s)" % [shown, lit[8].visible])
	r._ok(not idle.visible and not glow.visible, "LIMIT2 a light of no energy and the glow of a lamp that is out stay off (idle %s, glow %s)" % [idle.visible, glow.visible])
	idle.light_energy = 1.0
	limiter.call("_update_lights")
	r._ok(idle.visible and not lit[7].visible, "LIMIT3 the light that was hidden for want of energy comes back when it is lit, the eighth of the others gives its slot (idle %s, eighth %s)" % [idle.visible, lit[7].visible])
	holder.queue_free()
	for node in others:  # untyped: a light freed meanwhile (a pickup, a lamp of a district that was left) cannot be assigned to a typed variable
		if is_instance_valid(node):
			(node as OmniLight3D).visible = others[node]
