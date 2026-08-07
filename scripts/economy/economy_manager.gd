extends Node
## A5: Monety -> magazin -> uluchshenija + navyki s vidimym effektom

signal coins_changed(amount: int)
signal upgrade_purchased(upgrade_id: String)

var coins: int = 0:
    set(v):
        coins = v
        coins_changed.emit(coins)

var upgrades: Dictionary = {
    "flashlight_range": {"name": "Dalnost fonarja", "level": 0, "max_level": 5, "base_cost": 50, "effect": "+3m dalnost"},
    "flashlight_battery": {"name": "Batareja fonarja", "level": 0, "max_level": 5, "base_cost": 40, "effect": "+20% batareja"},
    "armor_light": {"name": "Legkaja bronja", "level": 0, "max_level": 3, "base_cost": 80, "effect": "-15% uron"},
    "armor_heavy": {"name": "Tjazhelaja bronja", "level": 0, "max_level": 3, "base_cost": 150, "effect": "-30% uron, -1 skorost"},
    "weapon_damage": {"name": "Uron oruzhija", "level": 0, "max_level": 5, "base_cost": 60, "effect": "+5 uron"},
    "weapon_reload": {"name": "Skorost perezyadki", "level": 0, "max_level": 3, "base_cost": 70, "effect": "-20% vremja"},
    "health_max": {"name": "Maks. zdorove", "level": 0, "max_level": 5, "base_cost": 55, "effect": "+20 HP"},
    "stamina_max": {"name": "Maks. stamina", "level": 0, "max_level": 3, "base_cost": 45, "effect": "+25 stamina"},
    "stealth_boots": {"name": "Tihie botinki", "level": 0, "max_level": 2, "base_cost": 100, "effect": "-40% shum"},
    "radar": {"name": "Radar", "level": 0, "max_level": 2, "base_cost": 120, "effect": "Vragi na karte"}
}

func add_coins(amount: int) -> void:
    coins += amount

func get_upgrade_cost(upgrade_id: String) -> int:
    if not upgrades.has(upgrade_id):
        return 999999
    var u = upgrades[upgrade_id]
    return int(u.base_cost * pow(1.5, u.level))

func can_buy(upgrade_id: String) -> bool:
    if not upgrades.has(upgrade_id):
        return false
    var u = upgrades[upgrade_id]
    return u.level < u.max_level and coins >= get_upgrade_cost(upgrade_id)

func buy_upgrade(upgrade_id: String) -> bool:
    if not can_buy(upgrade_id):
        return false
    var cost = get_upgrade_cost(upgrade_id)
    coins -= cost
    upgrades[upgrade_id].level += 1
    upgrade_purchased.emit(upgrade_id)
    _apply_upgrade(upgrade_id)
    return true

func _apply_upgrade(upgrade_id: String) -> void:
    if not GameManager.player:
        return
    var p = GameManager.player
    match upgrade_id:
        "health_max":
            if p.has_node("HealthComponent"):
                p.get_node("HealthComponent").max_health += 20
        "weapon_damage":
            if p.has_node("WeaponManager"):
                for w in p.get_node("WeaponManager").weapons:
                    w.damage += 5
        "weapon_reload":
            if p.has_node("WeaponManager"):
                for w in p.get_node("WeaponManager").weapons:
                    w.reload_time *= 0.8
        "stamina_max":
            if p.has_method("add_stamina"):
                p.add_stamina(25)

func get_total_spent() -> int:
    var total = 0
    for u in upgrades.values():
        total += int(u.base_cost * (pow(1.5, u.level) - 1) / 0.5)
    return total