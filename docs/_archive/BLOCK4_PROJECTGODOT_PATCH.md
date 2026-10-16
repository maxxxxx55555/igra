# БЛОК 4 — Патч project.godot (выполни вручную)

Открой `project.godot` в текстовом редакторе и добавь/измени следующие строки:

## В секцию [application] добавь:
```
run/max_fps=60
```

## Итоговый вид секции [application]:
```
[application]

config/name="The Last Streetlight"
run/main_scene="res://scenes/ui/boot_loading.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")
config/icon="res://assets/ui/icon.png"
run/max_fps=60
```

Или через редактор Godot:
Project → Project Settings → Application → Run → Max FPS → 60
