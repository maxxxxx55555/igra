extends Node
## P4 (CONTENT UX wave): each lit streetlight_3d.gd instance used to own its
## own always-playing AudioStreamPlayer3D ("Hum") - up to 24 simultaneous 3D
## audio streams per district once a street is fully powered, most of them
## far enough from the player to be inaudible under max_distance=14.0 but
## still mixed every frame. streetlight_3d.gd's own comment already
## establishes Hum was never a draw-call contributor (confirmed again below,
## re-measured fresh) - this is a CPU/audio-mixing lever, a different metric
## than perf_check_scene measures, not a guess at the same one.
##
## Pool of MAX_POOL real AudioStreamPlayer3D nodes, shared globally. Lit
## streetlights register/unregister here instead of playing their own Hum
## node; every REASSIGN_INTERVAL the pool re-sorts registered streetlights
## by distance to the player and repositions its players onto the nearest
## MAX_POOL of them ("nearest-lit priority" - farther ones go silent, exactly
## as if their own Hum had stopped, since beyond max_distance they were
## inaudible anyway).

const MAX_POOL: int = 8
const REASSIGN_INTERVAL: float = 0.3
const HUM_STREAM: AudioStream = preload("res://assets/audio/sfx/amb_lamp_hum.wav")

var _players: Array[AudioStreamPlayer3D] = []
var _registered: Array[Node3D] = []
var _timer: float = 0.0
var _hum_bus: String = "Master"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pick the right bus once at boot (defensive: SFX bus may not exist yet
	# during very early autoload order — SettingsManager._ensure_bus creates
	# it later; re-resolve lazily on first _reassign if still Master).
	_hum_bus = _resolve_bus()
	# Force-loop the hum stream the same way audio_manager.gd and
	# music_manager.gd do — .import loop settings aren't committed so on a
	# fresh checkout the imported stream defaults to one-shot and each pool
	# slot would fall silent 0.6s into district entry.
	_force_loop(HUM_STREAM)
	for i in MAX_POOL:
		var p := AudioStreamPlayer3D.new()
		p.name = "HumSlot%d" % i
		p.stream = HUM_STREAM
		p.bus = _hum_bus
		p.volume_db = -22.0
		p.unit_size = 4.0
		p.max_distance = 14.0
		add_child(p)
		_players.append(p)

static func _resolve_bus() -> String:
	return "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"

static func _force_loop(s: AudioStream) -> void:
	if s is AudioStreamWAV:
		(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true

func register(streetlight: Node3D) -> void:
	if not _registered.has(streetlight):
		_registered.append(streetlight)
		if not streetlight.tree_exiting.is_connected(_on_streetlight_freed):
			streetlight.tree_exiting.connect(_on_streetlight_freed.bind(streetlight))

func unregister(streetlight: Node3D) -> void:
	_registered.erase(streetlight)

func _on_streetlight_freed(streetlight: Node3D) -> void:
	_registered.erase(streetlight)

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = REASSIGN_INTERVAL
	_reassign()

func _reassign() -> void:
	# Late bus reconnect: SettingsManager._ensure_bus("SFX") runs deferred
	# after settings load; if we booted before that existed and fell back
	# to Master, migrate every slot to SFX the moment it appears.
	if _hum_bus == "Master" and AudioServer.get_bus_index("SFX") >= 0:
		_hum_bus = "SFX"
		for p in _players:
			p.bus = _hum_bus
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not (player is Node3D):
		for p in _players:
			if p.playing:
				p.stop()
		return
	var ppos: Vector3 = (player as Node3D).global_position
	_registered = _registered.filter(func(s: Node3D) -> bool: return is_instance_valid(s))
	_registered.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_squared_to(ppos) < b.global_position.distance_squared_to(ppos))
	for i in _players.size():
		var slot := _players[i]
		if i < _registered.size():
			slot.global_position = _registered[i].global_position
			if not slot.playing:
				slot.play()
		elif slot.playing:
			slot.stop()

## Headless-probe hook: how many pool slots are actively assigned right now.
func active_count() -> int:
	var n := 0
	for p in _players:
		if p.playing:
			n += 1
	return n
