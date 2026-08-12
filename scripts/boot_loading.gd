extends Control

@onready var bar: ProgressBar = $Panel/VBox/Bar
@onready var tip: Label = $Panel/VBox/Tip

const TIPS = [
	"Фонарь — твой единственный союзник.",
	"Слушай тишину — она лжёт реже людей.",
	"Каждый район имеет свой ритм.",
	"Документы раскрывают правду мира.",
	"Финальная ночь требует подготовки.",
]

var progress: float = 0.0
var target: float = 0.0
var _left: bool = false

func _ready() -> void:
	add_to_group("ui_root")
	tip.text = TIPS[randi() % TIPS.size()]
	tip.add_theme_color_override("font_color", Color("#CFC9B8"))

func _process(delta: float) -> void:
	target = min(target + delta * 30.0, 100.0)
	progress = lerp(progress, target, delta * 2.0)
	bar.value = progress
	# Без флага _left это срабатывало каждый кадр после 99% и спамило переходы.
	if progress > 99.0 and not _left:
		_left = true
		Routes.to_menu()