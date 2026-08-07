class_name LoadingScreen
extends CanvasLayer

@onready var progress_bar: TextureProgressBar = %ProgressBar
@onready var tip_label: Label = %TipLabel

var tips: Array[String] = [
	"Stay in the light. The darkness hides more than shadows.",
	"Listen carefully — every sound tells a story.",
	"Not all doors are meant to be opened.",
	"Your flashlight is your best friend. Guard it well.",
	"Some secrets are better left buried.",
	"The streetlight is watching.",
	"Running attracts attention. So does silence."
]


func _ready() -> void:
	visible = false
	progress_bar.value = 0
	tip_label.text = tips.pick_random()


func show_loading(target_scene: String) -> void:
	visible = true
	progress_bar.value = 0
	tip_label.text = tips.pick_random()
	_simulate_loading(target_scene)


func _simulate_loading(target_scene: String) -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_method(_set_progress, 0.0, 0.9, 1.5)
	await get_tree().create_timer(1.5).timeout
	tween.kill()
	progress_bar.value = 1.0
	await get_tree().create_timer(0.3).timeout
	var result: Error = get_tree().change_scene_to_file(target_scene)
	if result != OK:
		push_error("LoadingScreen: Failed to load scene: ", target_scene)
	visible = false


func _set_progress(value: float) -> void:
	progress_bar.value = value
