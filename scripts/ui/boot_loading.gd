extends Control
## Резервный контроллер загрузочного экрана: маршрут берём из Routes,
## раньше здесь был свой каскад из трёх «а вдруг эта сцена есть» проверок.

func _ready() -> void:
	await get_tree().create_timer(1.2).timeout
	Routes.to_menu()
