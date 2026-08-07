extends Node

var coins: int = 100:
    set(v):
        coins = v
        coins_changed.emit(coins)

signal coins_changed(new_amount: int)

func add_coins(n: int) -> void:
    coins += n

func spend_coins(n: int) -> bool:
    if coins >= n:
        coins -= n
        return true
    return false

func can_afford(n: int) -> bool:
    return coins >= n
