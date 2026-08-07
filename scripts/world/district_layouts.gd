class_name DistrictLayouts
extends RefCounted

const TILE_SIZE: int = 32
const SLOT_W: int = 12
const SLOT_H: int = 9

var OFFSETS: Dictionary = {
	&"suburbs": Vector2i(0,0), &"residential": Vector2i(1,0), &"park": Vector2i(2,0), &"school": Vector2i(3,0),
	&"hospital": Vector2i(0,1), &"gas_station": Vector2i(1,1), &"police": Vector2i(2,1), &"warehouses": Vector2i(3,1),
	&"industrial": Vector2i(0,2), &"substation": Vector2i(1,2), &"power_station": Vector2i(2,2),
}

var LAYOUTS: Dictionary = {
&"suburbs": PackedStringArray(["............",".##......##.",".##..P...##.","....GG......",".##......##.","...KL..b.c..",".##..L...##.",".?o........S","............"]),
&"residential": PackedStringArray(["............",".##.m....##.",".##......##.","...GG..f....",".##......##.",".o.KL..b.##.",".##..T...##.",".S.......C..","............"]),
&"park": PackedStringArray(["............",".dd......dd.","....GG......",".dd..L...dd.","....K....m..",".dd..T...dd.","....L..b....",".?........W.","............"]),
&"school": PackedStringArray(["............",".####..####.",".#GG#..#oo#.",".#..#..#..#.",".#KL####..#.",".#..#m.#b.#.",".#T.#..#..#.",".####..####.",".....C......"]),
&"hospital": PackedStringArray(["............",".####..####.",".#GG#..#m.#.",".#..#..#..#.",".#KL####b.#.",".#..#f.#..#.",".#T.#..#o.#.",".####..####.","..S........."]),
&"gas_station": PackedStringArray(["............",".##......##.","....GG...b..",".##..L...##.","....K....f..",".##..T...##.",".s.......s..",".?o.......C.","............"]),
&"police": PackedStringArray(["............",".####..####.",".#GG#..#k.#.",".#..#..#..#.",".#KL####b.#.",".#..#m.#..#.",".#T.#..#o.#.",".####..####.",".....H......"]),
&"warehouses": PackedStringArray(["............",".###....###.",".#GG#..#s.#.",".#..#..#..#.",".#KL####c.#.",".#..#f.#..#.",".#T.#..#b.#.",".###....###.","..D....?...."]),
&"industrial": PackedStringArray(["............",".###....###.",".#GG#..#s.#.",".#L.#..#..#.",".#KL####c.#.",".#..#f.#o.#.",".#T.#..#b.#.",".###....###.","..D....H...."]),
&"substation": PackedStringArray(["............",".####..####.",".#GG#..#f.#.",".#L.#..#..#.",".#KL####c.#.",".#..#m.#..#.",".#T.#..#o.#.",".####..####.","..D....?...."]),
&"power_station": PackedStringArray(["............",".####..####.",".#GG#..#f.#.",".#L.#..#..#.",".#KL####c.#.",".#..#m.#..#.",".#T.#..#o.#.",".####..####.","..D....B...."]),
}

func symbol_at(district_id: StringName, x: int, y: int) -> String:
	var layout: PackedStringArray = LAYOUTS.get(district_id, PackedStringArray())
	if y < 0 or y >= layout.size():
		return "."
	var row: String = layout[y]
	if x < 0 or x >= row.length():
		return "."
	return row.substr(x, 1)

func for_each_cell(district_id: StringName, cb: Callable) -> void:
	var layout: PackedStringArray = LAYOUTS.get(district_id, PackedStringArray())
	for y in layout.size():
		var row: String = layout[y]
		for x in row.length():
			var s: String = row.substr(x, 1)
			if s == ".":
				continue
			var wp := Vector3(x * TILE_SIZE, 0.0, y * TILE_SIZE)
			cb.call(s, x, y, wp)
