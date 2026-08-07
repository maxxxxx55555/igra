extends Node
# NoiseSystem — фонарь добавляет шум, враги реагируют по detect_range
signal noise_emitted(position: Vector3, level: float)

var flashlight_noise: float = 0.6  # уровень шума от фонаря

func emit_noise(origin: Vector3, level: float) -> void:
    emit_signal("noise_emitted", origin, level)

func flashlight_on(origin: Vector3) -> void:
    emit_noise(origin, flashlight_noise)
