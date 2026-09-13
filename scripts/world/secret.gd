extends Node3D
## Находимый секрет района (content/secrets.json, 26 штук на 11 районов).
##
## Раньше этот скрипт наследовал Area2D — наследие двухмерной версии игры.
## Interactor.gd отбирает цели строкой `not (node is Node3D): continue`, то
## есть секрет молча не попадал в список взаимодействуемых вообще нигде:
## сигнал secret_found не мог быть испущен в принципе, а на него завязаны
## квесты, достижение «secret_hunter», XP, награды и счётчик ProgressTracker.
## Двенадцать scenes/secrets/secret_room_*.tscn при этом стоят пустыми
## заглушками (75 байт, один голый Node3D).
##
## Теперь секрет — обычный 3D-интерактив: та же группа "interactable" и тот
## же контракт can_interact()/interact_prompt()/interact(player), что у щита
## района и пазлов.

@export var secret_id: StringName = &""
@export var item_id: StringName = &"battery"
@export var amount: int = 1
@export var district_id: StringName = &""
## Стадия района, ниже которой секрет ещё не найти (content: min_stage 0..3).
@export var min_stage: int = 0
@export var title_key: String = ""

var _taken: bool = false

func _ready() -> void:
	add_to_group("interactable")
	_refresh_gate()
	EventBus.district_stage_changed.connect(func(id: StringName, _stage: int) -> void:
		if id == district_id:
			_refresh_gate())

## Секрет со стадией выше текущей не виден и не берётся: район сначала надо
## починить. Гейт живёт в самом объекте, поэтому DistrictLoot раскладывает
## всё сразу и не обязан пересобирать район при каждой смене стадии.
func _refresh_gate() -> void:
	visible = can_interact()

func can_interact() -> bool:
	if _taken:
		return false
	if district_id == &"":
		return true
	return PowerGrid.get_stage(district_id) >= min_stage

func interact_prompt() -> String:
	return LocalizationManager.t("PROMPT_INTERACT")

func interact(_player: Node = null) -> void:
	if _taken or not can_interact():
		return
	_taken = true
	InventoryManager.try_add(item_id, amount)
	EventBus.secret_found.emit(String(secret_id))
	var title: String = LocalizationManager.t(title_key) if title_key != "" else ""
	var notice: String = LocalizationManager.t("SECRET_FOUND")
	EventBus.toast_requested.emit(notice if title == "" else "%s — %s" % [notice, title], "secret")
	queue_free()
