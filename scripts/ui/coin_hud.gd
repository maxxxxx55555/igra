extends CanvasLayer

@onready var label: Label = $CoinLabel

func _ready() -> void:
	EventBus.coins_changed.connect(_upd)
	_upd(CoinWallet.get_coins())

func _upd(v: int) -> void:
	label.text = str(v) + " mon"
