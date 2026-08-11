
extends Node

signal player_died

signal enemy_died(position: Vector3)

signal item_picked_up(item_data: Resource)

signal health_changed(new_health: int)

signal ammo_changed(current: int, max: int)

signal quest_updated(quest_id: String)