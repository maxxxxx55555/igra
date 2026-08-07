extends Control
@onready var coins_label: Label = $Panel/VBox/TopRow/CoinsLabel
@onready var btn_plus: Button = $Panel/VBox/TopRow/BtnPlus
@onready var sec_packs: HBoxContainer = $Panel/VBox/SecPacks/Row
@onready var sec_upgrades: HBoxContainer = $Panel/VBox/SecUpgrades/Row
@onready var sec_skins: HBoxContainer = $Panel/VBox/SecSkins/Row
@onready var sec_bundles: HBoxContainer = $Panel/VBox/SecBundles/Row
var _cards: Dictionary = {}
class CoinIcon extends Control:
    func _ready() -> void:
        custom_minimum_size = Vector2(16, 16)
    func _draw() -> void:
        draw_circle(Vector2(8, 8), 7.0, ThemeProvider.COLOR_AMBER)
        draw_arc(Vector2(8, 8), 7.0, 0.0, TAU, 16, ThemeProvider.COLOR_AMBER_DIM, 1.5)
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    theme = ThemeProvider.build_theme()
    visible = false
    btn_plus.focus_mode = Control.FOCUS_NONE
    btn_plus.visible = false  # Донат отключён
    btn_plus.pressed.connect(func() -> void: EventBus.inventory_notice.emit("ДОНАТ ОТКЛЮЧЁН — МОНЕТЫ ТОЛЬКО В ИГРЕ"))
    _build_section(sec_packs, ShopItem.Kind.COIN_PACK)
    _build_section(sec_upgrades, ShopItem.Kind.UPGRADE)
    _build_section(sec_skins, ShopItem.Kind.SKIN)
    _build_section(sec_bundles, ShopItem.Kind.BUNDLE)
    EventBus.coins_changed.connect(_on_coins)
    EventBus.purchase_success.connect(func(_id: StringName) -> void: _refresh())
    EventBus.skin_unlocked.connect(func(_id: StringName) -> void: _refresh())
    EventBus.shop_toggle_requested.connect(toggle)
    _on_coins(CoinWallet.get_coins())
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.is_action_pressed("shop_toggle"):
            toggle()
            get_viewport().set_input_as_handled()
func toggle() -> void:
    visible = not visible
    if visible:
        _refresh()
        EventBus.ui_screen_opened.emit(&"shop")
    else:
        EventBus.ui_screen_closed.emit(&"shop")
func _build_section(row: HBoxContainer, kind: int) -> void:
    for c in row.get_children():
        c.queue_free()
    for it in ShopService.catalog_by_kind(kind):
        var card := _make_card(it)
        row.add_child(card.root)
        _cards[it.id] = card
func _coin_node() -> Control:
    if AssetRegistry.has("coin_icon.png"):
        var tr := TextureRect.new()
        tr.texture = AssetRegistry.get_tex("coin_icon.png")
        tr.custom_minimum_size = Vector2(16, 16)
        tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        return tr
    return CoinIcon.new()
func _make_card(it: ShopItem) -> Dictionary:
    var root := PanelContainer.new()
    root.custom_minimum_size = Vector2(150, 96)
    root.mouse_filter = Control.MOUSE_FILTER_STOP
    var vb := VBoxContainer.new()
    vb.add_theme_constant_override("separation", 4)
    root.add_child(vb)
    var name_l := Label.new()
    name_l.text = it.display_name
    name_l.add_theme_font_size_override("font_size", 12)
    name_l.autowrap_mode = TextServer.AUTOWRAP_WORD
    vb.add_child(name_l)
    var price_row := HBoxContainer.new()
    price_row.add_theme_constant_override("separation", 4)
    vb.add_child(price_row)
    price_row.add_child(_coin_node())
    var price_l := Label.new()
    price_row.add_child(price_l)
    var ribbon := Label.new()
    ribbon.visible = it.discount_percent > 0
    ribbon.text = "-%d%%" % it.discount_percent
    ribbon.add_theme_color_override("font_color", Color.WHITE)
    var rsb := StyleBoxFlat.new()
    rsb.bg_color = ThemeProvider.COLOR_DANGER
    rsb.set_corner_radius_all(3)
    rsb.set_content_margin_all(3)
    ribbon.add_theme_stylebox_override("normal", rsb)
    ribbon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vb.add_child(ribbon)
    var id := it.id
    root.gui_input.connect(func(ev: InputEvent) -> void:
        if ev is InputEventMouseButton and ev.pressed:
            ShopService.buy(id))
    return {"root": root, "price": price_l, "ribbon": ribbon, "name": name_l, "item": it}
func _on_coins(a: int) -> void:
    coins_label.text = "%d" % a
    _refresh()
func _refresh() -> void:
    var coins := CoinWallet.get_coins()
    for id in _cards.keys():
        var c: Dictionary = _cards[id]
        var it: ShopItem = c.item
        var owned := ShopService.is_owned(id)
        if it.kind == ShopItem.Kind.COIN_PACK:
            c.price.text = "+%d монет (недоступно)" % it.coins_granted
            c.root.modulate = Color(0.5, 0.5, 0.5)
        else:
            c.price.text = "%d" % it.final_price_coins()
            c.root.modulate = Color(0.5, 0.5, 0.5) if owned else Color.WHITE
            if owned:
                c.name.text = it.display_name + " [+]"
        if it.kind == ShopItem.Kind.COIN_PACK:
            c.root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        elif owned:
            c.root.mouse_filter = Control.MOUSE_FILTER_IGNORE
        else:
            c.root.mouse_filter = Control.MOUSE_FILTER_STOP if coins >= it.final_price_coins() else Control.MOUSE_FILTER_IGNORE