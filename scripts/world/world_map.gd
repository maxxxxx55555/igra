extends Node2D
const TS: int = 32
const SW: int = 12
const SH: int = 9
const LOOT_MAP: Dictionary = {"b": &"battery", "m": &"medkit", "k": &"key", "c": &"cable", "f": &"fuse", "s": &"scrap"}
const ENEMY_MAP: Dictionary = {
	"S": "res://scenes/enemies/shadow_3d.tscn", "C": "res://scenes/enemies/crawler_3d.tscn",
	"W": "res://scenes/enemies/watcher_3d.tscn", "H": "res://scenes/enemies/hunter_3d.tscn",
	"D": "res://scenes/enemies/destroyer_3d.tscn", "B": "res://scenes/enemies/boss_architect_3d.tscn",
}
const BLUEPRINT_SPAWNS: Array = [
	{"district": &"residential", "cell": Vector2i(6,4), "item": &"blueprint_flashlight_brightness"},
	{"district": &"park", "cell": Vector2i(5,5), "item": &"blueprint_flashlight_battery"},
	{"district": &"police", "cell": Vector2i(5,5), "item": &"blueprint_backpack_capacity"},
	{"district": &"warehouses", "cell": Vector2i(5,5), "item": &"blueprint_backpack_slots"},
]
@onready var floor_layer: TileMapLayer = $Floor
@onready var wall_layer: TileMapLayer = $Walls
@onready var decor_layer: TileMapLayer = $Decor
@onready var nav_region: NavigationRegion2D = $Navigation
@onready var walls_body: StaticBody2D = $WallsBody
@onready var spawns: Node2D = $Spawns
@onready var triggers: Node2D = $DistrictTriggers
var _player_scene: PackedScene = preload("res://scenes/player/player.tscn")
var _puzzle_scene: PackedScene = preload("res://scenes/props/puzzle.tscn")
var _light_scene: PackedScene = preload("res://scenes/props/streetlight.tscn")
var _pickup_scene: PackedScene = preload("res://scenes/props/pickup.tscn")
var _secret_scene: PackedScene = preload("res://scenes/props/secret.tscn")
var _examine_scene: PackedScene = preload("res://scenes/props/examine.tscn")
var _tileset: TileSet
var _source_id: int = 0
var _nav_poly: NavigationPolygon
func _ready() -> void:
	_tileset = _build_tileset()
	floor_layer.tile_set = _tileset
	wall_layer.tile_set = _tileset
	decor_layer.tile_set = _tileset
	_source_id = _tileset.get_source_id(0)
	_nav_poly = NavigationPolygon.new()
	var district_ids: Array = [
		&"suburbs", &"residential", &"park", &"school", &"hospital", &"gas_station",
		&"police", &"warehouses", &"industrial", &"substation", &"power_station"
	]
	for district_id in district_ids:
		_build_district_visual(district_id)
		_build_district_walls(district_id)
	nav_region.navigation_polygon = _nav_poly
	for district_id in district_ids:
		_build_district_objects(district_id)
		_build_district_trigger(district_id)
	if GameManager.is_playing():
		_spawn_blueprints()
		_spawn_player_at_layout()
		_restore_player_pos()
	EventBus.district_stage_changed.connect(_on_district_stage_changed)
var DISTRICT_OFFSETS: Dictionary = {
	&"suburbs": Vector2i(0, 0), &"residential": Vector2i(1, 0), &"park": Vector2i(2, 0), &"school": Vector2i(3, 0),
	&"hospital": Vector2i(0, 1), &"gas_station": Vector2i(1, 1), &"police": Vector2i(2, 1), &"warehouses": Vector2i(3, 1),
	&"industrial": Vector2i(0, 2), &"substation": Vector2i(1, 2), &"power_station": Vector2i(2, 2),
}
var DISTRICT_LAYOUTS: Dictionary = {
	&"suburbs": PackedStringArray(["............", ".##......##.", ".##..P...##.", "....GG......", ".##......##.", "...KL..b.c..", ".##..L...##.", ".?o........S", "............"]),
	&"residential": PackedStringArray(["............", ".##.m....##.", ".##......##.", "...GG..f....", ".##......##.", ".o.KL..b.##.", ".##..T...##.", ".S.......C..", "............"]),
	&"park": PackedStringArray(["............", ".dd......dd.", "....GG......", ".dd..L...dd.", "....K....m..", ".dd..T...dd.", "....L..b....", ".?........W.", "............"]),
	&"school": PackedStringArray(["............", ".####..####.", ".#GG#..#oo#.", ".#..#..#..#.", ".#KL####..#.", ".#..#m.#b.#.", ".#T.#..#..#.", ".####..####.", ".....C......"]),
	&"hospital": PackedStringArray(["............", ".####..####.", ".#GG#..#m.#.", ".#..#..#..#.", ".#KL####b.#.", ".#..#f.#..#.", ".#T.#..#o.#.", ".####..####.", "..S........."]),
	&"gas_station": PackedStringArray(["............", ".##......##.", "....GG...b..", ".##..L...##.", "....K....f..", ".##..T...##.", ".s.......s..", ".?o.......C.", "............"]),
	&"police": PackedStringArray(["............", ".####..####.", ".#GG#..#k.#.", ".#..#..#..#.", ".#KL####b.#.", ".#..#m.#..#.", ".#T.#..#o.#.", ".####..####.", ".....H......"]),
	&"warehouses": PackedStringArray(["............", ".###....###.", ".#GG#..#s.#.", ".#..#..#..#.", ".#KL####c.#.", ".#..#f.#..#.", ".#T.#..#b.#.", ".###....###.", "..D....?...."]),
	&"industrial": PackedStringArray(["............", ".###....###.", ".#GG#..#s.#.", ".#L.#..#..#.", ".#KL####c.#.", ".#..#f.#o.#.", ".#T.#..#b.#.", ".###....###.", "..D....H...."]),
	&"substation": PackedStringArray(["............", ".####..####.", ".#GG#..#f.#.", ".#L.#..#..#.", ".#KL####c.#.", ".#..#m.#..#.", ".#T.#..#o.#.", ".####..####.", "..D....?...."]),
	&"power_station": PackedStringArray(["............", ".####..####.", ".#GG#..#f.#.", ".#L.#..#..#.", ".#KL####c.#.", ".#..#m.#..#.", ".#T.#..#o.#.", ".####..####.", "..D....B...."]),
}
func _offset_px(district_id: StringName) -> Vector2:
	var off: Vector2i = DISTRICT_OFFSETS[district_id]
	return Vector2(off.x * SW * TS, off.y * SH * TS)
func _cell_world(district_id: StringName, x: int, y: int) -> Vector2:
	return _offset_px(district_id) + Vector2(x * TS + TS * 0.5, y * TS + TS * 0.5)
func _layout_of(district_id: StringName) -> PackedStringArray:
	return DISTRICT_LAYOUTS[district_id] as PackedStringArray
func _build_district_visual(district_id: StringName) -> void:
	var layout := _layout_of(district_id)
	var off: Vector2i = DISTRICT_OFFSETS[district_id]
	for y in layout.size():
		var row: String = layout[y]
		var x := 0
		var run_start := -1
		while x <= row.length():
			var ch := row[x] if x < row.length() else "#"
			var is_floor := ch != "#"
			if is_floor:
				floor_layer.set_cell(Vector2i(off.x * SW + x, off.y * SH + y), _source_id, Vector2i(0, 0))
				if ch == "d":
					decor_layer.set_cell(Vector2i(off.x * SW + x, off.y * SH + y), _source_id, Vector2i(2, 0))
				if run_start == -1:
					run_start = x
			else:
				if run_start != -1:
					_add_nav_rect(district_id, run_start, x - 1, y)
					run_start = -1
				wall_layer.set_cell(Vector2i(off.x * SW + x, off.y * SH + y), _source_id, Vector2i(1, 0))
			x += 1
		if run_start != -1:
			_add_nav_rect(district_id, run_start, row.length() - 1, y)
func _add_nav_rect(district_id: StringName, x0: int, x1: int, y: int) -> void:
	var base := _offset_px(district_id)
	var p0 := base + Vector2(x0 * TS, y * TS)
	var p1 := base + Vector2((x1 + 1) * TS, y * TS)
	var p2 := base + Vector2((x1 + 1) * TS, (y + 1) * TS)
	var p3 := base + Vector2(x0 * TS, (y + 1) * TS)
	var i := _nav_poly.vertices.size()
	_nav_poly.vertices.append_array([p0, p1, p2, p3])
	_nav_poly.add_polygon(PackedInt32Array([i, i + 1, i + 2, i + 3]))
func _build_district_walls(district_id: StringName) -> void:
	var layout := _layout_of(district_id)
	for y in layout.size():
		var row: String = layout[y]
		var x := 0
		while x < row.length():
			if row[x] == "#":
				var x0 := x
				while x < row.length() and row[x] == "#":
					x += 1
				var rect := RectangleShape2D.new()
				rect.size = Vector2((x - x0) * TS, TS)
				var sh := CollisionShape2D.new()
				sh.shape = rect
				sh.position = _cell_world(district_id, x0 + (x - x0) * 0.5, y)
				walls_body.add_child(sh)
			else:
				x += 1
func _build_district_objects(district_id: StringName) -> void:
	var layout := _layout_of(district_id)
	var stage: int = PowerGrid.get_stage(district_id)
	var playing: bool = GameManager.is_playing()
	for y in layout.size():
		var row: String = layout[y]
		for x in row.length():
			var ch := row[x]
			var pos := _cell_world(district_id, x, y)
			match ch:
				"G": _spawn_puzzle(pos, district_id, &"", false, 1, "Запустить генератор")
				"K": _spawn_puzzle(pos, district_id, &"cable", true, 2, "Подключить кабель")
				"T": _spawn_puzzle(pos, district_id, &"fuse", true, 3, "Починить трансформатор")
				"L": _spawn_light(pos, district_id)
			if LOOT_MAP.has(ch):
				_spawn_pickup(pos, LOOT_MAP[ch])
			elif ch == "?":
				_spawn_secret(pos)
			elif ch == "o":
				_spawn_examine(pos)
			elif ENEMY_MAP.has(ch) and playing and _should_spawn_enemy(ch, stage):
				_spawn_enemy(pos, ENEMY_MAP[ch])
func _should_spawn_enemy(ch: String, stage: int) -> bool:
	if stage >= DistrictData.Stage.FULL and ch != "B":
		return false
	if ch == "S" and stage >= DistrictData.Stage.STREETS:
		return false
	return true
func _spawn_blueprints() -> void:
	for b in BLUEPRINT_SPAWNS:
		var district_id: StringName = b["district"]
		var cell: Vector2i = b["cell"]
		_spawn_pickup(_cell_world(district_id, cell.x, cell.y), b["item"])
func _spawn_player_at_layout() -> void:
	for district_id in DISTRICT_LAYOUTS.keys():
		var layout := _layout_of(district_id)
		for y in layout.size():
			var row: String = layout[y]
			var x := row.find("P")
			if x >= 0:
				var p := _player_scene.instantiate()
				add_child(p)
				p.global_position = _cell_world(district_id, x, y)
				return
func _restore_player_pos() -> void:
	var pp := SaveSystem.consume_pending_player_pos()
	if pp == Vector3.INF:
		return
	var p := get_tree().get_first_node_in_group("player")
	if is_instance_valid(p):
		p.global_position = pp
func _spawn_puzzle(pos: Vector2, district_id: StringName, item: StringName, consume: bool, stage: int, label: String) -> void:
	var pz := _puzzle_scene.instantiate()
	pz.global_position = pos
	pz.district_id = district_id
	pz.required_item = item
	pz.consume_item = consume
	pz.result_stage = stage
	pz.action_name = label
	pz.puzzle_id = StringName("%s_%s_%d" % [district_id, label, stage])
	spawns.add_child(pz)
func _spawn_light(pos: Vector2, district_id: StringName) -> void:
	var l := _light_scene.instantiate()
	l.global_position = pos
	l.district_id = district_id
	spawns.add_child(l)
func _spawn_pickup(pos: Vector2, item_id: StringName) -> void:
	var pk := _pickup_scene.instantiate()
	pk.global_position = pos
	pk.item_id = item_id
	spawns.add_child(pk)
func _spawn_secret(pos: Vector2) -> void:
	var s := _secret_scene.instantiate()
	spawns.add_child(s)
	s.global_position = pos
func _spawn_examine(pos: Vector2) -> void:
	var e := _examine_scene.instantiate()
	spawns.add_child(e)
	e.global_position = pos
func _spawn_enemy(pos: Vector2, scene_path: String) -> void:
	var sc: PackedScene = load(scene_path)
	if sc == null:
		return
	var en := sc.instantiate()
	spawns.add_child(en)
	en.global_position = pos
func _build_district_trigger(district_id: StringName) -> void:
	var area := Area2D.new()
	area.monitorable = false
	var sh := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(SW * TS, SH * TS)
	sh.shape = rect
	area.add_child(sh)
	area.global_position = _offset_px(district_id) + Vector2(SW * TS * 0.5, SH * TS * 0.5)
	area.body_entered.connect(func(b: Node) -> void:
		if b.is_in_group("player"):
			EventBus.district_entered.emit(district_id)
	)
	triggers.add_child(area)
# Текстурный тайлсет: PNG из assets/art/ если есть, иначе программные тайлы VisualStyle.
func _tile_image(kind: int, png_name: String) -> Image:
	var img: Image = null
	if AssetRegistry.has(png_name):
		var t: Texture2D = AssetRegistry.get_tex(png_name)
		if t != null:
			img = t.get_image()
			if img != null and img.get_width() > 0:
				img.resize(TS, TS)
			else:
				img = null
	if img == null:
		img = VisualStyle.make_tile_texture(kind, TS).get_image()
	return img
func _build_tileset() -> TileSet:
	var imgs: Array = [_tile_image(0, "tile_floor.png"), _tile_image(1, "tile_wall.png"), _tile_image(2, "tile_decor.png")]
	var atlas := Image.create(TS * 3, TS, false, Image.FORMAT_RGBA8)
	for kind in 3:
		atlas.blit_rect(imgs[kind], Rect2i(0, 0, TS, TS), Vector2i(kind * TS, 0))
	var tex := ImageTexture.create_from_image(atlas)
	var ts := TileSet.new()
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TS, TS)
	ts.add_source(src, 0)
	src.create_tile(Vector2i(0, 0))
	src.create_tile(Vector2i(1, 0))
	src.create_tile(Vector2i(2, 0))
	return ts
func _on_district_stage_changed(district_id: StringName, stage: int) -> void:
	if stage < DistrictData.Stage.STREETS:
		return
	for en in spawns.get_children():
		if en.is_in_group("enemies") and en.get("monster_id") == &"shadow":
			if _enemy_in_district(en, district_id):
				en.queue_free()
func _enemy_in_district(en: Node, district_id: StringName) -> bool:
	var off: Vector2 = _offset_px(district_id)
	var lp: Vector2 = en.global_position - off
	return lp.x >= 0.0 and lp.y >= 0.0 and lp.x < SW * TS and lp.y < SH * TS
