extends Node

var items: Array[Dictionary] = [
    {id="skin_01", type="cosmetic", price_coins=500, real_usd=0.0, desc="Alternate skin - Urban"},
    {id="skin_02", type="cosmetic", price_coins=800, real_usd=1.99, desc="Alternate skin - Midnight"},
    {id="boost_battery", type="boost", price_coins=200, real_usd=0.0, desc="Battery boost +50%"},
    {id="boost_stamina", type="boost", price_coins=150, real_usd=0.0, desc="Stamina boost +30%"},
    {id="emblem_01", type="cosmetic", price_coins=300, real_usd=0.0, desc="Survivor emblem"},
    {id="remove_ads", type="boost", price_coins=0, real_usd=2.99, desc="Remove advertisements"},
]

func get_item(id: String) -> Dictionary:
    for it in items:
        if it.id == id:
            return it
    return {}
