extends Node2D
var look_dir: Vector2 = Vector2.DOWN
var _sprite: Texture2D = null
const BODY_COLOR := Color("2b2f36")
const RIM_COLOR := Color("e8a13a")
const SKIN_RIM := {
    &"skin_survivor_ashen": Color("9aa0a8"),
    &"skin_survivor_rust":  Color("b5532a"),
}
var _rim: Color = RIM_COLOR
var _body: Color = BODY_COLOR
func _ready() -> void:
    if AssetRegistry.has("player_top.png"):
        _sprite = AssetRegistry.get_tex("player_top.png")
    EventBus.skin_unlocked.connect(func(_id: StringName) -> void: _apply_active_skin())
    _apply_active_skin()
func _apply_active_skin() -> void:
    _rim = RIM_COLOR
    _body = BODY_COLOR
    for id in [&"skin_survivor_rust", &"skin_survivor_ashen"]:
        if ShopService.is_owned(id) and SKIN_RIM.has(id):
            _rim = SKIN_RIM[id]
            _body = BODY_COLOR.lerp(Color.BLACK, 0.2)
            break
    if is_inside_tree():
        queue_redraw()
func _draw() -> void:
    if _sprite != null:
        draw_texture_rect(_sprite, Rect2(-16, -16, 32, 32), false)
        return
    VisualStyle.draw_player(self, look_dir, _rim, _body)