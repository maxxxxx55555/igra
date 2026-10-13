extends RefCounted
## Session 23 (docs/AUDIO_CONSISTENCY.md, docs/VFX_BUDGET.md): the new audio and effects at run time. Wired into _closeout_check_runner.gd as
## `await Rc23Fx.run(self)`; CLOSEOUT_ONLY=s23 runs it with the accessibility checks. Every setting, node and weather a check touches is put back.

const FAR := Vector3(900.0, 0.0, 900.0)
const _Shells := preload("res://scripts/effects/shell_eject.gd")
const _Motes := preload("res://scripts/effects/dust_motes.gd")
const _Manhole := preload("res://scripts/world/manhole.gd")
const _Zone := preload("res://scripts/world/reverb_zone.gd")
const _Pool := preload("res://scripts/effects/vfx_pool.gd")
const BLOOD_HIT := preload("res://scenes/vfx/vfx_blood_hit.tscn")
const BLOOD := preload("res://scenes/vfx/vfx_blood.tscn")
const SPARK := preload("res://scenes/vfx/vfx_hit_spark.tscn")
const MUZZLE := preload("res://scenes/vfx/vfx_muzzle_flash.tscn")
const LAMP := preload("res://scenes/props/streetlight_3d.tscn")
const PARTICLE_BUDGET: int = 500  # PRODUCTION_BIBLE.md section 4: particles, concurrent

static func run(r: Node) -> void:
	r._playing()
	await _ducking(r)
	await _reverb_zone(r)
	await _surfaces(r)
	await _shells(r)
	_blood_direction(r)
	await _dust_motes(r)
	_manhole(r)
	await _rain_lens(r)
	await _particle_budget(r)
	r._playing()

## AUD1: a cue the player must hear dips Music and Ambient by 12 dB, holds, and comes back; it is the Amplify effect of each bus, not the slider.
static func _ducking(r: Node) -> void:
	var ducker: Node = AudioManager.get_node_or_null("Ducker")
	var amps: Array[AudioEffectAmplify] = []
	for bus: StringName in [&"Music", &"Ambient"]:
		var index: int = AudioServer.get_bus_index(bus)
		for slot in AudioServer.get_bus_effect_count(index):
			var effect: AudioEffect = AudioServer.get_bus_effect(index, slot)
			if effect is AudioEffectAmplify:
				amps.append(effect as AudioEffectAmplify)
	var slider0: float = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music"))
	EventBus.voice_line.emit("A line the player must hear.")
	await r.get_tree().create_timer(0.5).timeout
	var down: float = float(ducker.get("_db"))
	var amp_down: bool = amps.size() == 2 and is_equal_approx(amps[0].volume_db, -12.0) and is_equal_approx(amps[1].volume_db, -12.0)
	var slider_kept: bool = is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music")), slider0)
	await r.get_tree().create_timer(3.0).timeout
	var back: float = float(ducker.get("_db"))
	r._ok(is_equal_approx(down, -12.0) and amp_down and slider_kept and absf(back) < 0.01, "AUD1 ducking: a voice line dips the Music and Ambient buses by %.1f dB (their Amplify effects %s), the volume slider is not touched (%s), 3.5 s later the dip is %.2f dB" % [down, amp_down, slider_kept, back])

## AUD2: a reverb zone replaces what the rays sense (a tunnel is long and wet), the rays do not undo it, and leaving hands the reverb back.
static func _reverb_zone(r: Node) -> void:
	var reverb: AudioEffectReverb = AudioServer.get_bus_effect(AudioServer.get_bus_index(&"Combat"), 0) as AudioEffectReverb
	AudioManager.enter_reverb_zone(&"tunnel")
	await r.get_tree().create_timer(0.9).timeout
	var tunnel: bool = AudioManager.get("_zone") == &"tunnel" and is_equal_approx(reverb.room_size, 0.95) and is_equal_approx(reverb.wet, 0.45)
	var tunnel_room: float = reverb.room_size
	var tunnel_wet: float = reverb.wet
	AudioManager.call("_sense_reverb")
	await r.get_tree().create_timer(0.7).timeout
	var held: bool = is_equal_approx(reverb.room_size, 0.95)
	AudioManager.exit_reverb_zone(&"room")  # another zone's exit does not release this one
	var stays: bool = AudioManager.get("_zone") == &"tunnel"
	AudioManager.exit_reverb_zone(&"tunnel")
	AudioManager.call("_sense_reverb")
	await r.get_tree().create_timer(0.9).timeout
	var released: bool = AudioManager.get("_zone") == &"" and not is_equal_approx(reverb.room_size, 0.95)
	var player: Node3D = r._player
	var zone: Area3D = _Zone.new()
	zone.set("preset", &"room")
	zone.set("size", Vector3(6.0, 6.0, 6.0))
	r.add_child(zone)
	zone.global_position = player.global_position
	for i in 6:
		await r.get_tree().physics_frame
	var entered: bool = AudioManager.get("_zone") == &"room"
	zone.queue_free()
	AudioManager.exit_reverb_zone(&"room")
	r._ok(tunnel and held and stays and released and entered, "AUD2 reverb zones: a tunnel zone sets room %.2f wet %.2f (%s), the rays do not undo it (%s), another zone's exit does not release it (%s), its own exit does (%s), a zone box around the player enters by itself (%s)" % [tunnel_room, tunnel_wet, tunnel, held, stays, released, entered])

## AUD3: footsteps read the surface from the shape's metadata (concrete, metal, grass, wood, water), the street's strips are tagged, rain wets the road.
static func _surfaces(r: Node) -> void:
	var steps := FootstepSystem.new()
	r.add_child(steps)
	var wanted: Array[String] = ["concrete", "metal", "grass", "wood", "puddle"]
	var read: Array[String] = []
	var samples: Array[String] = []
	for i in wanted.size():
		var floor_body := StaticBody3D.new()
		var floor_shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(4.0, 0.2, 4.0)
		floor_shape.shape = box
		floor_shape.set_meta(&"surface", wanted[i])
		floor_body.add_child(floor_shape)
		r.add_child(floor_body)
		floor_body.global_position = FAR + Vector3(float(i) * 10.0, 0.0, 0.0)
		var ray := RayCast3D.new()
		ray.target_position = Vector3(0.0, -2.0, 0.0)
		ray.collision_mask = 1
		r.add_child(ray)
		ray.global_position = FAR + Vector3(float(i) * 10.0, 1.0, 0.0)
		await r.get_tree().physics_frame
		ray.force_raycast_update()
		steps.set("_raycast", ray)
		read.append(String(steps.call("_detect_material")))
		samples.append(String(steps.call("_step_sample", wanted[i], FootstepSystem.STATE_WALK)))
		ray.queue_free()
		floor_body.queue_free()
	var weather: Node = r.get_node("/root/WeatherSystem")
	var kinds: Array[String] = []
	var weather0: int = int(weather.get("current"))
	for state: int in [0, 1, 3]:  # WeatherSystem.Weather: CLEAR, RAIN, STORM
		weather.set("current", state)
		kinds.append(String(steps.call("_wetted", "asphalt_dry")))
	weather.set("current", weather0)
	var strips: Node = r._main.find_child("StreetCollision", true, false)
	var tags: Dictionary = {}
	for shape: Node in strips.get_children():
		if shape.has_meta(&"surface"):
			tags[String(shape.get_meta(&"surface"))] = true
	steps.queue_free()
	var tagged: bool = tags.has("asphalt_dry") and tags.has("concrete")
	r._ok(read == wanted and kinds == ["asphalt_dry", "asphalt_wet", "puddle"] and tagged, "AUD3 surfaces: the shape metadata gives %s for %s (steps %s), the road is dry, wet in a shower and a puddle in a storm (%s), the street strips are tagged %s" % [read, wanted, samples.slice(0, 2), kinds, tags.keys()])

## VFX1: a shot throws a case that falls, bounces on the street and goes back to the pool; the Effects setting at Low throws none.
static func _shells(r: Node) -> void:
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 0.2, 20.0)
	floor_shape.shape = box
	floor_body.add_child(floor_shape)
	r.add_child(floor_body)
	floor_body.global_position = FAR + Vector3(0.0, -0.1, 40.0)
	var effects0: Variant = SettingsManager.get_setting("effects", 2)
	SettingsManager.set_setting("effects", 2)
	var shell: RigidBody3D = null
	var thrown: bool = false
	var lowest: float = 99.0
	var rose_again: bool = false
	for attempt in 6:  # the throw is random, and one case in six bouncing is what the check asks
		shell = _Shells.eject(r.get_tree(), FAR + Vector3(0.0, 1.2, 40.0), Vector3.FORWARD)
		thrown = thrown or (shell != null and shell.visible)
		var last: float = 99.0
		var low: float = 99.0
		for i in 120:
			await r.get_tree().physics_frame
			var y: float = shell.global_position.y - (FAR.y)
			if y > last + 0.004 and low < 0.1:
				rose_again = true
			low = minf(low, y)
			last = y
		lowest = minf(lowest, low)
		if rose_again:
			break
	var on_street: bool = lowest > -0.05 and lowest < 0.08
	await r.get_tree().create_timer(1.0).timeout
	var pooled: bool = not shell.visible
	SettingsManager.set_setting("effects", 0)
	var low: bool = _Shells.eject(r.get_tree(), FAR, Vector3.FORWARD) == null
	SettingsManager.set_setting("effects", effects0)
	floor_body.queue_free()
	r._ok(thrown and on_street and rose_again and pooled and low, "VFX1 shell ejection: a case is thrown (%s), falls to the street (lowest %.3f m) and bounces (%s), goes back to the pool after its life (%s), none at Effects Low (%s)" % [thrown, lowest, rose_again, pooled, low])

## VFX2: blood leaves a hit along the direction it is given; a burst reused without one gets its own direction back.
static func _blood_direction(r: Node) -> void:
	for old: Node in _Pool._bursts.get(BLOOD_HIT, []):  # earlier checks leave parked bursts: the second spawn must find this one
		if is_instance_valid(old):
			old.queue_free()
	_Pool._bursts.erase(BLOOD_HIT)
	var first: VFXBurst = _Pool.spawn(BLOOD_HIT, FAR, r.get_tree(), Vector3.RIGHT) as VFXBurst
	var aimed: bool = (first.process_material as ParticleProcessMaterial).direction.is_equal_approx(Vector3.RIGHT)
	first.parked = true
	var again: VFXBurst = _Pool.spawn(BLOOD_HIT, FAR, r.get_tree()) as VFXBurst
	var restored: bool = again == first and (again.process_material as ParticleProcessMaterial).direction.is_equal_approx(first.emit_direction.normalized())
	again.queue_free()
	r._ok(aimed and restored, "VFX2 directional blood: a new burst flies along +X (%s), the same burst reused without a direction flies along its own %s (%s)" % [aimed, first.emit_direction, restored])

## VFX3: dust motes drift under the lit lamps near the player and under none that are far or out.
static func _dust_motes(r: Node) -> void:
	var player: Node3D = r._player
	var motes: Node = _Motes.new()
	r.add_child(motes)
	var near: Node3D = LAMP.instantiate() as Node3D
	near.set("force_on", true)
	r.add_child(near)
	near.global_position = player.global_position + Vector3(4.0, 0.0, 0.0)
	var out: Node3D = LAMP.instantiate() as Node3D
	r.add_child(out)
	out.global_position = player.global_position + Vector3(3.0, 0.0, 3.0)
	var far: Node3D = LAMP.instantiate() as Node3D
	far.set("force_on", true)
	r.add_child(far)
	far.global_position = player.global_position + Vector3(60.0, 0.0, 0.0)
	await r.get_tree().process_frame
	var spots: Array[Vector3] = motes.call("beams")
	motes.call("refresh")
	var first: GPUParticles3D = motes.get_child(0) as GPUParticles3D
	var under_near: bool = spots.size() >= 1 and first.emitting and first.global_position.distance_to(near.global_position) < 6.0
	var only_lit_near: bool = true
	for spot: Vector3 in spots:
		if spot.distance_to(out.global_position) < 1.0 or spot.distance_to(far.global_position) < 1.0:
			only_lit_near = false
	var effects0: Variant = SettingsManager.get_setting("effects", 2)
	SettingsManager.set_setting("effects", 0)
	var none_at_low: bool = (motes.call("beams") as Array).is_empty()
	SettingsManager.set_setting("effects", effects0)
	for node: Node in [motes, near, out, far]:
		node.queue_free()
	r._ok(under_near and only_lit_near and none_at_low, "VFX3 dust motes: an emitter under the lit lamp 4 m away (%s, beams %d), none under the lamp that is out or the one 60 m away (%s), none at Effects Low (%s)" % [under_near, spots.size(), only_lit_near, none_at_low])

## VFX4: a manhole is an iron cover flush with the road (its top where the road's top is, a lift above it), tagged metal, with a steam loop.
static func _manhole(r: Node) -> void:
	var cover: Node3D = _Manhole.new()
	r.add_child(cover)
	cover.global_position = FAR
	var shape: Node = cover.get_node("Cover").get_child(0)
	var steam: GPUParticles3D = cover.get_node("Steam") as GPUParticles3D
	var strips: Node = r._main.find_child("StreetCollision", true, false)
	var road: CollisionShape3D = strips.get_child(0) as CollisionShape3D
	var road_top: float = road.global_position.y + (road.shape as BoxShape3D).size.y * 0.5
	var cover_top: float = (shape as CollisionShape3D).global_position.y + ((shape as CollisionShape3D).shape as CylinderShape3D).height * 0.5
	var flush: bool = absf(cover_top - road_top - _Manhole.COVER_LIFT) < 0.001
	cover.queue_free()
	r._ok(String(shape.get_meta(&"surface", "")) == "metal" and steam.amount == 14 and steam.process_material != null and flush, "VFX4 manhole: surface %s, steam %d particles, cover top %.3f against road top %.3f (+%.2f lift: %s)" % [shape.get_meta(&"surface", ""), steam.amount, cover_top, road_top, _Manhole.COVER_LIFT, flush])

## VFX5: rain on the lens shows from the Ultra tier in a shower or worse, and not with Motion Comfort.
static func _rain_lens(r: Node) -> void:
	var lens: ColorRect = r._main.get_node("PostProcessOverlay/RainLens") as ColorRect
	var tier0: Variant = SettingsManager.get_setting("graphics_tier", 2)
	var results: Array[bool] = []
	SettingsManager.set_setting("graphics_tier", 3)
	EventBus.weather_changed.emit(1, "rain", 0.2, 0.7)
	results.append(lens.visible)
	EventBus.weather_changed.emit(0, "clear", 0.0, 0.0)
	results.append(not lens.visible)
	EventBus.weather_changed.emit(3, "storm", 0.5, 1.0)
	SettingsManager.set_setting("graphics_tier", 2)
	results.append(not lens.visible)
	SettingsManager.set_setting("graphics_tier", 3)
	results.append(lens.visible)
	SettingsManager.set_setting("reduce_camera_motion", true)
	results.append(not lens.visible)
	SettingsManager.set_setting("reduce_camera_motion", false)
	SettingsManager.set_setting("graphics_tier", tier0)
	r.get_node("/root/WeatherSystem").call("_emit")
	await r.get_tree().process_frame
	r._ok(results == [true, true, true, true, true], "VFX5 rain lens: shown in a shower at Ultra, hidden in clear weather, hidden below Ultra, shown in a storm at Ultra, hidden with Motion Comfort (%s)" % [results])

## VFX6: the particles alive at once stay under the budget, in a shower with the pooled bursts all in flight, and the pool's worst case does too.
static func _particle_budget(r: Node) -> void:
	EventBus.weather_changed.emit(0, "clear", 0.0, 0.0)
	await r.get_tree().process_frame
	var world: int = _alive_particles(r)
	for scene: PackedScene in [BLOOD, BLOOD_HIT, SPARK, MUZZLE]:
		for i in _Pool.MAX_PER_SCENE:
			_Pool.spawn(scene, FAR + Vector3(float(i), 0.0, 0.0), r.get_tree())
	await r.get_tree().process_frame
	var alive: int = _alive_particles(r)
	EventBus.weather_changed.emit(3, "storm", 0.5, 1.0)
	for scene: PackedScene in [BLOOD, BLOOD_HIT, SPARK, MUZZLE]:
		for i in 6:
			_Pool.spawn(scene, FAR + Vector3(float(i), 0.0, 0.0), r.get_tree())
	await r.get_tree().create_timer(0.3).timeout
	var stormy: int = _alive_particles(r)
	r.get_node("/root/WeatherSystem").call("_emit")
	var worst: int = 0
	for scene: PackedScene in [BLOOD, BLOOD_HIT, SPARK, MUZZLE]:
		var burst := scene.instantiate() as GPUParticles3D
		worst += burst.amount * _Pool.MAX_PER_SCENE
		burst.free()
	r._ok(alive < PARTICLE_BUDGET and stormy < 2 * PARTICLE_BUDGET and world + worst < PARTICLE_BUDGET, "VFX6 particle budget: the world's own emitters draw %d, with every pooled burst in flight (%d of each scene) %d (budget %d), %d in a storm (limit %d), the pool's worst case %d plus the world %d" % [world, _Pool.MAX_PER_SCENE, alive, PARTICLE_BUDGET, stormy, 2 * PARTICLE_BUDGET, worst, world + worst])

## Particles that are drawing now: amount scaled by the tier's ratio, over every emitter in the tree.
static func _alive_particles(r: Node) -> int:
	var alive: int = 0
	for node: Node in r.get_tree().root.find_children("*", "GPUParticles3D", true, false):
		var emitter := node as GPUParticles3D
		if emitter.emitting and emitter.is_visible_in_tree():
			alive += int(round(float(emitter.amount) * emitter.amount_ratio))
	return alive
