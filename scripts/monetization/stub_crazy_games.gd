extends RefCounted
## Заглушка веб-поставщика CrazyGames.
##
## Настоящий SDK недоступен: репозиторий CrazyGames/SDK-Godot не клонируется
## анонимно (см. docs/BLOCKED.md). Пока его нет, веб-сборка не должна падать —
## она должна работать без рекламы.
##
## Контракт тот же, что у StubAdProvider: initialize / is_ready / show.
## Когда SDK появится, этот файл заменяется реализацией, игровой код не трогаем.

const LOG_PREFIX := "CrazyGames stub active"

var _service: Node
var _logged := false

func _init(service: Node) -> void:
	_service = service

func initialize() -> void:
	print(LOG_PREFIX, ": SDK не подключён, реклама отключена, игра продолжает работать")
	_logged = true

## Роликов нет. Игра обязана продолжать работать, поэтому это не ошибка,
## а честное «нечего показывать»: интерфейс просто не покажет кнопку.
func is_ready() -> bool:
	return false

func show(_reward_id: StringName) -> void:
	_service._on_provider_failed(LOG_PREFIX + ": показывать нечего")

func was_initialized() -> bool:
	return _logged
