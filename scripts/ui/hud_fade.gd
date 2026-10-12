extends RefCounted
## Contextual HUD (docs/HUD_PLAN.md): a control shows while its value matters and fades out once it stops mattering. The fade runs on one
## alpha property and nothing else, so `visible` and the layout stay as the scene made them. `prop` is "modulate:a" for a row that holds
## other controls and "self_modulate:a" for a leaf the HUD's opacity setting already owns the `modulate` of. One tween per control, kept in
## its meta: a new state replaces the old one. Reduce UI Motion makes the transitions instant; the hold stays.

const FADE_IN_SEC: float = 0.15
const FADE_OUT_SEC: float = 0.6

## Brings every item to full alpha at once; unless `keep`, fades them to `rest` after `hold` seconds.
static func show_for(items: Array, hold: float, rest: float = 0.0, keep: bool = false, prop: String = "modulate:a") -> void:
	var calm: bool = bool(SettingsManager.get_setting("reduce_ui_motion", false))
	for item: CanvasItem in items:
		if not is_instance_valid(item):
			continue
		_stop(item)
		var tween := item.create_tween()
		item.set_meta(&"hud_fade", tween)
		tween.tween_property(item, prop, 1.0, 0.0 if calm else FADE_IN_SEC)
		if not keep:
			tween.tween_interval(hold)
			tween.tween_property(item, prop, rest, 0.0 if calm else FADE_OUT_SEC)

## Puts every item at `rest` now: the first frame of a scene that starts calm.
static func settle(items: Array, rest: float = 0.0, prop: String = "modulate:a") -> void:
	for item: CanvasItem in items:
		if not is_instance_valid(item):
			continue
		_stop(item)
		item.set_indexed(NodePath(prop), rest)

static func _stop(item: CanvasItem) -> void:
	var old: Variant = item.get_meta(&"hud_fade", null)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
