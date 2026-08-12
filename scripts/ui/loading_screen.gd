extends CanvasLayer

@onready var bar: ProgressBar = $Panel/Bar
@onready var tip: Label = $Panel/TipLabel
@onready var status: Label = $Panel/StatusLabel

var tips: Array = ["tip1", "tip2", "tip3", "tip4"]
var _progress: float = 0.0
var _target: String = "res://scenes/main_3d.tscn"

func _ready() -> void:
	status.text = LocalizationManager.t("loading")
	tip.text = LocalizationManager.t(tips[randi() % tips.size()])
	_load_async()

func _process(d: float) -> void:
	_progress = min(_progress + d * 35.0, 100.0)
	bar.value = _progress

func _load_async() -> void:
	ResourceLoader.load_threaded_request(_target)
	while true:
		var prog: Array = []
		var st = ResourceLoader.load_threaded_get_status(_target, prog)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			var packed = ResourceLoader.load_threaded_get(_target)
			get_tree().change_scene_to_packed(packed)
			return
		elif st == ResourceLoader.THREAD_LOAD_FAILED:
			get_tree().change_scene_to_file(_target)
			return
		await get_tree().create_timer(0.1).timeout
