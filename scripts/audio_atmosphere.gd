extends Node

const MIX: int = 22050

var _ambient: AudioStreamPlayer
var _district_ambient: Dictionary = {}
var _current_district: String = ""
var _monster_alert_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ambient = _make_player()
	_ambient.name = "AtmoAmbient"
	_ambient.volume_db = -16.0
	_ambient.stream = _gen_drone(2.0)
	_ambient.play()
	for i in 4:
		var p := _make_player()
		p.name = "MonsterAlert" + str(i)
		p.volume_db = -10.0
		_monster_alert_players.append(p)
	EventBus.district_entered.connect(_on_district_entered)
	EventBus.enemy_attack.connect(_on_enemy_attack)
	EventBus.monster_spotted.connect(_on_monster_spotted)


func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
	add_child(p)
	return p

func _on_district_entered(district_id: StringName) -> void:
	_current_district = str(district_id)
	var freq := 55.0 + _district_pitch_offset(_current_district)
	_ambient.stream = _gen_drone(2.0, freq)
	_ambient.play()


func _district_pitch_offset(district: String) -> float:
	match district:
		"suburb": return 0.0
		"residential": return 8.0
		"park": return -5.0
		"school": return 12.0
		"hospital": return -8.0
		"policestation": return 15.0
		"gasstation": return 20.0
		"warehouse": return -12.0
		"industrial": return 10.0
		"substation": return 18.0
		"powerplant": return 25.0
	return 0.0

func _on_enemy_attack(_damage: int) -> void:
	_one_shot_monster(_gen_growl(), -8.0)

func _on_monster_spotted(_id: Variant) -> void:
	_one_shot_monster(_gen_growl(), -12.0)

func _one_shot_monster(stream: AudioStreamWAV, vol: float) -> void:
	for p in _monster_alert_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = vol
			p.play()
			return

func _buf(seconds: float) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(int(seconds * MIX))
	return b

func _wrap(b: PackedByteArray) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_8_BITS
	s.mix_rate = MIX
	s.stereo = false
	s.data = b
	return s

func _wrap_loop(b: PackedByteArray) -> AudioStreamWAV:
	var s := _wrap(b)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = b.size()
	return s

func _gen_drone(seconds: float, freq: float = 55.0) -> AudioStreamWAV:
	var b := _buf(seconds)
	for i in b.size():
		var t := float(i) / float(MIX)
		var v := sin(t * freq * TAU) * 0.4 + sin(t * freq * 1.5 * TAU) * 0.2
		v += (float(randi() % 100) / 100.0 - 0.5) * 0.08
		b[i] = clampi(int(128.0 + v * 90.0), 0, 255)
	return _wrap_loop(b)

func _gen_growl() -> AudioStreamWAV:
	var b := _buf(0.4)
	for i in b.size():
		var t := float(i) / float(MIX)
		var env := 1.0 - float(i) / float(b.size())
		var v := sin(t * (80.0 + sin(t * 10.0) * 25.0) * TAU) * env
		v += (float(randi() % 100) / 100.0 - 0.5) * 0.25 * env
		b[i] = clampi(int(128.0 + v * 110.0), 0, 255)
	return _wrap(b)
