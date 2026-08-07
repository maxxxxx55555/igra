extends Node
## Autoload "EventBus".  Signal hub.  No order deps; no _ready work.

signal district_entered(district_id: StringName)
signal district_powered(district_id: StringName)
signal coin_changed(amount: int)
signal lives_changed(amount: int)
signal flashlight_toggled(on: bool)
signal player_caught
signal game_saved
signal game_loaded
signal shop_purchased(item: StringName)
signal remote_player_state(peer_id: int, pos: Vector3, yaw: float, district: StringName)
signal remote_power_changed(district: StringName, powered: bool)
signal lan_hosted(port: int)
signal lan_joined(peer_id: int)
signal lan_disconnected

func emit_district_entered(d: StringName) -> void:
	district_entered.emit(d)

func emit_district_powered(d: StringName) -> void:
	district_powered.emit(d)

func emit_coin(c: int) -> void:
	coin_changed.emit(c)

func emit_lives(l: int) -> void:
	lives_changed.emit(l)
signal ammo_changed(current: int, max: int)
signal enemy_attack(damage: int)
signal enemy_died(position: Vector3)
signal enemy_killed(monster_id: StringName)
signal enemy_spawned(enemy: Node3D)
signal item_picked_up(item_data: Resource)
signal player_died

signal achievement_unlocked(achievement_id: String)
signal boss_defeated(boss_id: String)
signal coins_changed(amount: int)
signal district_blackout(district_id: StringName)
signal district_restored(district_id: StringName)
signal district_stage_changed(district_id: StringName, stage: int)
signal document_unlocked(document_id: String)
signal encyclopedia_unlocked(entry_id: String)
signal enemy_hp_updated(monster_id: StringName, hp: float)
signal examine_text(text: String)
signal final_night_started
signal flashlight_changed(state: bool)
signal flashlight_depleted
signal flashlight_state_changed(on: bool)
signal game_over
signal game_started
signal game_state_changed(state: String)
signal game_won
signal hud_visibility_changed(visible: bool)
signal interaction_done(object_id: String)
signal inventory_changed
signal inventory_notice(message: String)
signal inventory_toggle_requested
signal inventory_weight_changed(weight: float)
signal item_consumed(item_id: String)
signal level_completed(level_id: String)
signal light_disrupted
signal light_level_changed(level: float)
signal monster_spotted(monster_id: StringName)
signal noise_emitted(position: Vector3, intensity: float)
signal player_battery_changed(level: float)
signal player_damaged(amount: float)
signal player_detected
signal player_health_changed(health: float)
signal player_hiding_changed(hiding: bool)
signal player_interact_available(available: bool)
signal player_stamina_changed(stamina: float)
signal player_state_changed(state: String)
signal player_stealth_changed(stealth: float)
signal power_grid_updated
signal purchase_done(item_id: String)
signal purchase_failed(item_id: String, reason: String)
signal purchase_success(item_id: String)
signal puzzle_solved(puzzle_id: String)
signal puzzle_started(puzzle_id: String)
signal quest_completed(quest_id: String)
signal radar_marker_added(marker_id: String, position: Vector3)
signal secret_found(secret_id: String)
signal settings_changed
signal shop_toggle_requested
signal skin_unlocked(skin_id: String)
signal streetlight_activated(streetlight_id: String)
signal ui_screen_closed(screen_id: String)
signal ui_screen_opened(screen_id: String)
signal wave_completed(wave_number: int)
signal weather_changed(weather_id: String)
signal xp_gained(amount: int)
signal zone_reached(zone_id: String)
signal boss_phase_changed(phase: int)
signal toast_requested(text: String, type: String)
signal player_healed(amount: int)
