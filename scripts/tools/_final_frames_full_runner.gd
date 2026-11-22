extends "res://scripts/tools/_final_frames_runner.gd"
## Full-resolution sign-off frames for the final visual tree (2026-11-22).
## The stock runner halves every frame; AF3 only needs >=400x200, but the
## docs/stills/store set is kept at 1920x1080 for the press kit.

func _shot(frame: String) -> void:
	await _capture(frame, false)
