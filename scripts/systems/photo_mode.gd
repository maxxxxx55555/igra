extends Node
## E41: Fotorezhim - kadr, filtry, ramki, sohranenie

var _active: bool = false
var _filter_index: int = 0
var _filters: Array = ["none", "noir", "sepia", "cold", "warm", "vhs"]

## Клавишу photo_mode обрабатывает UIManager для своего оверлея
## (scripts/ui/photo_mode.gd). Этот режим — тот, что открывается из галереи
## экранов, и раньше он ловил ту же клавишу сам: после одного захода в
## галерею нажатие переключало сразу оба оверлея. Здесь переключение
## только явное, через toggle().
func _toggle() -> void:
	_active = !_active
	if _active:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_apply_filter()
	else:
		InputService.refresh_mouse_mode()
		_remove_filter()

func toggle() -> void:
	_toggle()

func _apply_filter() -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return
	var env = cam.get_world_3d().environment if cam.get_world_3d() else null
	if not env:
		return
	match _filters[_filter_index]:
		"noir":
			env.adjustment_saturation = 0.0
			env.adjustment_contrast = 1.5
		"sepia":
			env.adjustment_saturation = 0.3
		"cold":
			env.fog_light_color = Color(0.1, 0.15, 0.3)
		"warm":
			env.fog_light_color = Color(0.3, 0.2, 0.1)
		"vhs":
			env.glow_intensity = 1.5

func _remove_filter() -> void:
	pass

func cycle_filter() -> void:
	_filter_index = (_filter_index + 1) % _filters.size()
	_apply_filter()

func take_photo() -> void:
	var img = get_viewport().get_texture().get_image()
	var path = "user://screenshots/photo_%d.png" % Time.get_unix_time_from_system()
	DirAccess.make_dir_recursive_absolute("user://screenshots")
	img.save_png(path)
	print("[photo] saved: ", path)
	if AchievementManager:
		AchievementManager.unlock("photographer")