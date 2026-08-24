extends Node
## THEME UNIFICATION P0: this used to build its own separate Theme (from
## theme_tls.tres, with its own duplicated color tokens and StyleBoxFlat
## button/panel styles) and set it window-wide - completely independent of
## ThemeProvider.build_theme(), which 12 screens already call locally and
## which owns the real chrome-kit textures. Any screen that never opted
## into ThemeProvider (main_menu chief among them) silently inherited THIS
## theme instead, so last wave's button chrome was invisible there.
##
## ThemeProvider is now the single canonical source everywhere: this
## autoload just applies it window-wide so screens that don't set a local
## theme override still get the real one, not a second, drifted copy.

func _ready() -> void:
	get_tree().root.theme = ThemeProvider.build_theme()
