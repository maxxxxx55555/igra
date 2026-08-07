extends Node
## D10: Vibracija na mobajle

func pulse(weak: bool = true) -> void:
    if OS.has_feature("mobile"):
        if weak:
            Input.vibrate_handheld(40)
        else:
            Input.vibrate_handheld(120)

func shoot() -> void: pulse(true)
func hurt() -> void: pulse(false)
func explode() -> void: pulse(false)