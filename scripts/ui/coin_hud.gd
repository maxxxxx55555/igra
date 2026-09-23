extends CanvasLayer

@onready var label: Label = $CoinLabel

func _ready() -> void:
	# BREAK_REPORT B8: was EventBus's own (now-removed) coins_changed, a
	# different signal that only base_monster.gd's kill-reward roll ever
	# emitted - shop/quest/secret/achievement coins all go through
	# CoinWallet.add(), which only fires CoinWallet's own coins_changed, so
	# the HUD never updated for any of those and briefly showed a raw kill
	# roll as the total instead.
	CoinWallet.coins_changed.connect(_upd)
	_upd(CoinWallet.get_coins())

func _upd(v: int) -> void:
	label.text = str(v) + " mon"
