# AssetRegistry — опциональный подхват PNG-арта в стиле референса. БЕЗОПАСНО:
# если файла нет в assets/art/ — НЕ падает, отдаёт процедурный плейсхолдер.
# Сохрани PNG (правый клик по картинке в чате) как: tile_floor.png, tile_wall.png,
# player_top.png, coin_icon.png, menu_bg.png в THE_LAST_STREETLIGHT/assets/art/.
class_name AssetRegistry
extends RefCounted

const ART: String = "res://assets/art/"

static var _cache: Dictionary = {}

static func get_tex(rel: String) -> Texture2D:
    var path: String = ART + rel
    if _cache.has(path):
        return _cache[path]
    var tex: Texture2D = null
    if ResourceLoader.exists(path):
        var res: Variant = load(path)
        if res is Texture2D:
            tex = res
    if tex == null:
        tex = _placeholder(rel)
    _cache[path] = tex
    return tex

static func has(rel: String) -> bool:
    return ResourceLoader.exists(ART + rel)

static func _placeholder(rel: String) -> Texture2D:
    var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
    img.fill(_color_for(rel))
    return ImageTexture.create_from_image(img)

static func _color_for(rel: String) -> Color:
    if rel.find("floor") >= 0: return Color("20242b")
    if rel.find("wall")  >= 0: return Color("3a2a22")
    if rel.find("coin")  >= 0: return Color("e8a13a")
    if rel.find("menu")  >= 0: return Color("0d0f12")
    if rel.find("monster") >= 0: return Color("5a2a2a")
    if rel.find("light") >= 0 or rel.find("flash") >= 0: return Color("f2c879")
    if rel.find("bag")   >= 0: return Color("7a5a23")
    if rel.find("power") >= 0: return Color("c98a2e")
    if rel.find("lore")  >= 0 or rel.find("book") >= 0: return Color("8c8a82")
    return Color("15181d")