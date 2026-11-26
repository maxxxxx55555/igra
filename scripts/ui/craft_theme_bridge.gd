class_name CraftThemeBridge
extends RefCounted
## Keeps the canonical ThemeProvider type scale and bundled fonts while laying
## the owner-supplied sodium 9-slice craft skins over the ordinary controls.

static func build() -> Theme:
	var theme := ThemeProvider.build_theme()
	var craft := AntiSlopThemeDirector.build_theme()
	for node_type: StringName in [&"Panel", &"PanelContainer", &"Button"]:
		var states: Array[StringName]
		if node_type == &"Button":
			states = [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]
		else:
			states = [&"panel"]
		for state: StringName in states:
			var sb: StyleBox = craft.get_stylebox(state, node_type)
			if sb != null:
				theme.set_stylebox(state, node_type, sb)
	# OptionButton/tabs inherit the Button look through ThemeProvider._scale;
	# refresh their styleboxes explicitly so the craft skin reaches every screen.
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled", &"focus"]:
		var sb: StyleBox = theme.get_stylebox(state, &"Button")
		if sb != null:
			theme.set_stylebox(state, &"OptionButton", sb)
	return theme
