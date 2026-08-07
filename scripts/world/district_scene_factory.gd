class_name DistrictSceneFactory
extends Node
const DISTRICTS: Array[StringName] = [
    &"suburbs", &"residential", &"park", &"school", &"hospital",
    &"gas_station", &"police", &"warehouses", &"industrial",
    &"substation", &"power_station",
]
static func build(parent: Node, district_id: StringName) -> Node3D:
    var root := Node3D.new()
    root.name = StringName("District_" + String(district_id))
    parent.add_child(root)
    var theme: Dictionary = DistrictThemes.get_theme(district_id)
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    DistrictThemes.apply_to_environment(env, district_id)
    world_env.environment = env
    world_env.name = "WorldEnvironment"
    root.add_child(world_env)
    var sb_script: Script = load("res://scripts/world/street_builder.gd")
    if sb_script != null:
        var sb := Node3D.new()
        sb.set_script(sb_script)
        sb.name = "StreetBuilder3D"
        sb.set("district_id", String(district_id))
        sb.set("theme", theme)
        root.add_child(sb)
    var wx_script: Script = load("res://scripts/effects/weather_vfx.gd")
    if wx_script != null:
        var wx := Node3D.new()
        wx.set_script(wx_script)
        wx.name = "WeatherVFX"
        wx.set("weather_kind", String(theme.get("weather", "fog_light")))
        root.add_child(wx)
    if EventBus.has_signal("district_entered"):
        EventBus.district_entered.emit(district_id)
    return root
static func district_count() -> int:
    return DISTRICTS.size()
static func district_id_at(index: int) -> StringName:
    if index < 0 or index >= DISTRICTS.size(): return &"suburbs"
    return DISTRICTS[index]
