extends Node
## Terminal music must release ownership when the player returns to the menu.

var _fails: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	(MusicManager as Node).set_process(false)
	MusicManager._unlock_audio()
	GameManager._change_state(GameManager.GameState.WIN)
	MusicManager._on_game_won()
	_ok(MusicManager.mood == MusicDirector.Mood.VICTORY, "victory starts its musical state")
	_ok(MusicManager._wow_cue.playing, "victory starts its one-shot cue")
	GameManager.return_to_menu()
	MusicManager._evaluate()
	_ok(MusicManager.mood == MusicDirector.Mood.MENU, "return from victory resumes menu music")
	_ok(MusicManager._active.stream.resource_path == MusicManager.TRACKS[MusicDirector.Mood.MENU], "menu uses its own theme after victory")
	_ok(not MusicManager._wow_cue.playing, "victory cue cannot overlap the menu theme")
	GameManager._change_state(GameManager.GameState.WIN)
	MusicManager._on_game_won()
	MusicManager._on_game_started()
	_ok(not MusicManager._wow_cue.playing, "victory cue cannot overlap a new run")
	_ok(MusicManager.mood == MusicDirector.Mood.AMBIENT, "new run resumes district ambience")
	print("[audio-lifecycle] DONE fails=%d" % _fails)
	get_tree().quit(0 if _fails == 0 else 1)

func _ok(condition: bool, label: String) -> void:
	if not condition:
		_fails += 1
	print("[audio-lifecycle] %s %s" % ["OK" if condition else "FAIL", label])
