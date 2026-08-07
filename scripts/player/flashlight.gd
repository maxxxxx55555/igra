extends PointLight2D
@export var stats: FlashlightStats
var flashlight_enabled: bool = true
var _cone_dirty: bool = true
var _blackout_timer: float = 0.0
var _in_blackout: bool = false
const CONE_TEX_SIZE: int = 256
const CONE_COLOR := Color(1.0, 0.86, 0.55)
func _ready() -> void:
    if stats == null:
        # push_error("Flashlight: не назначен FlashlightStats (data/balance/flashlight_stats.tres)")
        return
    add_to_group("flashlight")
    shadow_enabled = true
    _rebuild_cone_texture()
    _apply_enabled()
    _emit_state()
func _process(delta: float) -> void:
    if stats == null:
        return
    if _cone_dirty:
        _rebuild_cone_texture()
        _cone_dirty = false
    var p := get_parent()
    if p and "look_dir" in p:
        rotation = atan2(p.look_dir.y, p.look_dir.x)
    if flashlight_enabled:
        _drain_battery(delta)
    _update_energy(delta)
func toggle() -> void:
    set_is_enabled(not flashlight_enabled)
func set_is_enabled(value: bool) -> void:
    if value and _battery() <= 0.0:
        value = false
    flashlight_enabled = value
    _apply_enabled()
    _emit_state()
func get_flashlight_enabled() -> bool:
    return flashlight_enabled
func is_point_lit(global_pos: Vector2) -> bool:
    if not flashlight_enabled or stats == null or _in_blackout:
        return false
    var rel: Vector2 = global_pos - global_position
    var dist: float = rel.length()
    if dist > stats.cone_length_px:
        return false
    var forward := Vector2(cos(rotation), sin(rotation))
    var ang: float = absf(wrapf(rel.angle_to(forward), -PI, PI))
    return ang <= deg_to_rad(stats.cone_angle_deg * 0.5)
func _battery() -> float:
    var p := get_parent()
    if p and p.has_method("get_battery"):
        return p.get_battery()
    return 0.0
func _drain_battery(delta: float) -> void:
    var p := get_parent()
    if p and p.has_method("consume_battery"):
        p.consume_battery(stats.drain_per_sec * delta)
func _apply_enabled() -> void:
    visible = flashlight_enabled
    if not flashlight_enabled:
        energy = stats.energy_ambient
func _update_energy(delta: float) -> void:
    if not flashlight_enabled:
        return
    var bat: float = _battery()
    var base: float = stats.energy_on
    var flicker: float = 0.0
    if bat < stats.flicker_battery_threshold:
        var low_factor: float = 1.0 - (bat / maxf(0.001, stats.flicker_battery_threshold))
        var instability: float = (1.0 - clampf(stats.stability, 0.0, 1.0))
        flicker = (randf() * 2.0 - 1.0) * stats.flicker_intensity * (0.4 + low_factor + instability)
    _blackout_timer -= delta
    if _blackout_timer <= 0.0:
        _blackout_timer = 1.0
        _in_blackout = randf() < (stats.blackout_chance_per_sec * (1.0 - clampf(stats.stability, 0.0, 1.0)) * (1.0 - bat / 100.0))
    if _in_blackout or bat <= 0.0:
        energy = stats.energy_ambient
    else:
        energy = maxf(stats.energy_ambient, base + flicker)
    var lvl: float = 0.0 if _in_blackout else clampf(energy / maxf(0.001, stats.energy_on), 0.0, 1.0)
    EventBus.light_level_changed.emit(lvl)
func _emit_state() -> void:
    EventBus.flashlight_state_changed.emit(flashlight_enabled)
    EventBus.flashlight_changed.emit()
func _rebuild_cone_texture() -> void:
    if stats == null:
        return
    var size: int = CONE_TEX_SIZE
    var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
    var center := Vector2(size * 0.5, size * 0.5)
    var max_len: float = size * 0.5
    var half_ang: float = deg_to_rad(stats.cone_angle_deg * 0.5)
    var feather: float = maxf(0.001, stats.edge_feather)
    for y in size:
        for x in size:
            var p := Vector2(x, y) - center
            var dist: float = p.length()
            var len_norm: float = dist / max_len
            if len_norm > 1.0:
                continue
            var ang: float = absf(atan2(p.y, p.x))
            if ang > half_ang:
                continue
            var radial: float = lerpf(1.0, stats.radial_falloff, len_norm)
            var edge: float = 1.0 - smoothstep(half_ang * (1.0 - feather), half_ang, ang)
            var a: float = clampf(radial * edge, 0.0, 1.0)
            img.set_pixel(x, y, Color(CONE_COLOR.r, CONE_COLOR.g, CONE_COLOR.b, a))
    texture = ImageTexture.create_from_image(img)
    texture_scale = stats.cone_length_px / max_len
func mark_cone_dirty() -> void:
    _cone_dirty = true
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.is_action_pressed("flashlight_toggle"):
            toggle()