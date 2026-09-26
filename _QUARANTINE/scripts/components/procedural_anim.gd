extends Node
## Procedural animation helper: builds AnimationLibrary in code for simple states.
## Attach to a node with AnimationPlayer child, call _setup_animations() in _ready.

@export var auto_play: StringName = &"idle"

var _player: AnimationPlayer
var _lib: AnimationLibrary

func _ready() -> void:
	_setup_animations()
	if auto_play != &"":
		_player.play(auto_play)

func _setup_animations() -> void:
	_player = get_node_or_null("AnimationPlayer")
	if not _player:
		_player = AnimationPlayer.new()
		_player.name = "AnimationPlayer"
		add_child(_player)
	_lib = AnimationLibrary.new()
	_player.add_animation_library("", _lib)
	_build_idle()
	_build_run()
	_build_attack()
	_build_dodge()

func _build_idle() -> void:
	var anim := Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	var tr := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr, "../Mesh:rotation_degrees:y")
	anim.track_insert_key(tr, 0.0, 0.0)
	anim.track_insert_key(tr, 1.0, 0.0)
	var tr2 := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr2, "../Mesh:position:y")
	anim.track_insert_key(tr2, 0.0, 0.0)
	anim.track_insert_key(tr2, 0.5, 0.05)
	anim.track_insert_key(tr2, 1.0, 0.0)
	_lib.add_animation("idle", anim)

func _build_run() -> void:
	var anim := Animation.new()
	anim.length = 0.6
	anim.loop_mode = Animation.LOOP_LINEAR
	var tr := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr, "../Mesh:rotation_degrees:z")
	anim.track_insert_key(tr, 0.0, -5.0)
	anim.track_insert_key(tr, 0.3, 5.0)
	anim.track_insert_key(tr, 0.6, -5.0)
	var tr2 := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr2, "../Mesh:position:y")
	anim.track_insert_key(tr2, 0.0, 0.0)
	anim.track_insert_key(tr2, 0.15, 0.08)
	anim.track_insert_key(tr2, 0.3, 0.0)
	anim.track_insert_key(tr2, 0.45, 0.08)
	anim.track_insert_key(tr2, 0.6, 0.0)
	_lib.add_animation("run", anim)

func _build_attack() -> void:
	var anim := Animation.new()
	anim.length = 0.4
	anim.loop_mode = Animation.LOOP_NONE
	var tr := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr, "../Mesh:rotation_degrees:x")
	anim.track_insert_key(tr, 0.0, 0.0)
	anim.track_insert_key(tr, 0.15, -15.0)
	anim.track_insert_key(tr, 0.3, 10.0)
	anim.track_insert_key(tr, 0.4, 0.0)
	_lib.add_animation("attack", anim)

func _build_dodge() -> void:
	var anim := Animation.new()
	anim.length = 0.5
	anim.loop_mode = Animation.LOOP_NONE
	var tr := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(tr, "../Mesh:position:z")
	anim.track_insert_key(tr, 0.0, 0.0)
	anim.track_insert_key(tr, 0.25, 0.5)
	anim.track_insert_key(tr, 0.5, 0.0)
	_lib.add_animation("dodge", anim)

func play(name: StringName) -> void:
	if _player:
		_player.play(name)
