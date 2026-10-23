extends RefCounted
## Session 30 (the v10.0.0-tag pass), Z4(b) N037: a damage-over-time tick on the player is not a monster hit.
## Before the fix a bleed/burn/poison tick went through take_damage like a monster hit: it played the hurt sound,
## reset the regen delay and opened the 0.8 s mercy window that then swallowed the next real hit in full, while a
## tick that fell inside an open window was lost the other way. DOT1 a tick opens no mercy window and the next
## real hit lands in full; DOT2 a tick inside an open window is not swallowed and still takes its health.
## Each check fails on the pre-fix code (AF2 both ways). Wired into _closeout_check_runner.gd as s30.

static func run(r: Node) -> void:
	_mercy(r)

static func _mercy(r: Node) -> void:
	var player: Node = r._player
	if not player.has_method("apply_dot"):
		r._ok(false, "DOT1 pre-fix: apply_dot missing - a tick goes through take_damage like a monster hit")
		r._ok(false, "DOT2 pre-fix: apply_dot missing - a tick inside the mercy window is swallowed")
		return
	var hp0: float = float(player.get("hp"))
	var max_hp: float = float((player.get("stats") as Resource).get("max_hp"))
	player.set("hp", max_hp)
	var grace: String = "_damage_grace_timer"
	player.set(grace, 0.0)
	player.call("take_damage", 10.0, Vector3.ZERO)
	var grace_open: bool = float(player.get(grace)) > 0.0
	var hp_after_hit: float = float(player.get("hp"))
	player.call("apply_dot", 4.0)
	var tick_in_window_lands: bool = float(player.get("hp")) < hp_after_hit
	player.set(grace, 0.0)
	player.call("apply_dot", 4.0)
	var tick_opens_no_grace: bool = float(player.get(grace)) == 0.0
	var hp_before_hit: float = float(player.get("hp"))
	player.call("take_damage", 10.0, Vector3.ZERO)
	var hit_after_tick_lands: bool = float(player.get("hp")) < hp_before_hit
	player.set("hp", hp0)
	player.set(grace, 0.0)
	r._ok(tick_opens_no_grace and hit_after_tick_lands, "DOT1 a tick opens no mercy window (%s) and the next real hit lands in full (%s)" % [tick_opens_no_grace, hit_after_tick_lands])
	r._ok(grace_open and tick_in_window_lands, "DOT2 a real hit opens the window (%s) and a tick inside it still takes its health (%s)" % [grace_open, tick_in_window_lands])
