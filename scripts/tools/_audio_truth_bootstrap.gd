extends Node
## Bootstrap for the audio truth gate. Same pattern as
## _capture_stills_bootstrap.gd: the probe (tools/qa_sim/audio_truth_gate.gd)
## must outlive the Routes.start_game() scene swap it triggers, so it is
## parented to get_tree().root instead of living as this scene's own root.

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start")

func _start() -> void:
	var r := Node.new()
	r.name = "AudioTruthGate"
	r.set_script(load("res://tools/qa_sim/audio_truth_gate.gd"))
	get_tree().root.add_child(r)
