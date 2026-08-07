extends Node

var _solved: Dictionary = {}

func start_puzzle(id: String) -> bool:
    if _solved.get(id, false):
        return false
    # Сигнал слушает обучение (tutorial_system), но эмитить его было некому.
    EventBus.puzzle_started.emit(StringName(id))
    var screens := get_tree().root.find_child("Screens", true, false)
    if screens and screens.has_method("show_screen"):
        screens.show_screen("PuzzleCables")
    return true

func is_solved(id: String) -> bool:
    return _solved.get(id, false)

func mark_solved(id: String) -> void:
    _solved[id] = true
