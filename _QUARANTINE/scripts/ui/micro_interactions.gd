extends Node
## D22: MicroInteractions - hover/press dlya vseh knopok

func apply_to_all(root: Node) -> void:
	for b in root.find_children("*", "Button", true, false):
		_bind(b)

func _bind(b: Button) -> void:
	if b.mouse_entered.is_connected(_enter): return
	b.mouse_entered.connect(_enter.bind(b))
	b.mouse_exited.connect(_exit.bind(b))
	b.button_down.connect(_down.bind(b))
	b.button_up.connect(_up.bind(b))

func _enter(b: Button) -> void:
	var tw = b.create_tween()
	tw.tween_property(b, "modulate", Color(1.2, 1.1, 0.8), 0.12)

func _exit(b: Button) -> void:
	var tw = b.create_tween()
	tw.tween_property(b, "modulate", Color.WHITE, 0.12)

func _down(b: Button) -> void:
	var tw = b.create_tween()
	tw.tween_property(b, "scale", Vector2(0.96, 0.96), 0.06)

func _up(b: Button) -> void:
	var tw = b.create_tween()
	tw.tween_property(b, "scale", Vector2.ONE, 0.06)