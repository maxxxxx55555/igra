extends Node
## Autoload "DayNight": the in-world clock (starts at 20:00, day_duration_sec
## per full 24 h cycle, scaled by the NG+ "cycle" knob).
##
## It used to also repaint the WorldEnvironment toward a daytime sky (ambient
## up to 0.60, blue sky) between 06:00 and 18:00. GDD.md:261 is explicit -
## "Дня нет" (there is no day) - and the live environment writer is
## world_env_setup.gd. That painter only stayed harmless because its one-shot
## lookup in _ready() ran before any scene existed and always found nothing,
## so it was removed rather than left as a latent canon violation (TZ V01).

@export var day_duration_sec: float = 1440.0
@export var start_hour: float = 20.0

var _t: float = 0.0

func _ready() -> void:
	# Ручка NG+ "cycle" (Sprint): множитель длины цикла, напр. 0.85 = короче.
	# call_deferred: автозагрузка DayNight идёт в project.godot раньше
	# NewGamePlus, и на её _ready() модификаторы ещё не загружены
	# (_load_save() выполнится позже) — прямой вызов тут всегда читал бы 1.0.
	call_deferred(&"_apply_cycle_multiplier")

func _apply_cycle_multiplier() -> void:
	day_duration_sec *= NewGamePlus.get_night_cycle_multiplier()

func _process(delta: float) -> void:
	_t += delta

func get_hour() -> float:
	return fmod(start_hour + _t / day_duration_sec * 24.0, 24.0)
