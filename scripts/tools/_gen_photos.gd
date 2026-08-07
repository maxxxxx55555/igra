extends Node
## Procedural "old city photo" generator: grain, vignette, sepia.
## Run: godot --headless --path <proj> res://scenes/tools/gen_photos_scene.tscn

const OUT: String = "res://assets/photos/"
const SIZE: int = 256

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 20260807
	DirAccess.make_dir_recursive_absolute(OUT)
	var themes := [
		{"name": "abandoned_street", "hue": 0.08, "sat": 0.35, "bright": 0.45},
		{"name": "dark_alley", "hue": 0.10, "sat": 0.25, "bright": 0.30},
		{"name": "old_park", "hue": 0.25, "sat": 0.30, "bright": 0.50},
		{"name": "broken_lamp", "hue": 0.05, "sat": 0.40, "bright": 0.40},
		{"name": "foggy_avenue", "hue": 0.60, "sat": 0.15, "bright": 0.55},
		{"name": "ruined_school", "hue": 0.07, "sat": 0.30, "bright": 0.38},
		{"name": "empty_hospital", "hue": 0.55, "sat": 0.20, "bright": 0.42},
		{"name": "night_substation", "hue": 0.65, "sat": 0.25, "bright": 0.28},
		{"name": "warehouse_shadow", "hue": 0.08, "sat": 0.20, "bright": 0.32},
		{"name": "last_streetlight", "hue": 0.10, "sat": 0.45, "bright": 0.48},
	]
	for t in themes:
		_generate(t["name"], t["hue"], t["sat"], t["bright"])
	print("[photos] DONE generated=", themes.size())
	get_tree().quit()

func _generate(name: String, hue: float, sat: float, bright: float) -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.05, 0.07))
	for y in range(SIZE):
		for x in range(SIZE):
			var uv := Vector2(float(x) / float(SIZE), float(y) / float(SIZE))
			var n := _fbm(uv * 4.0)
			var v := bright * (0.6 + 0.4 * n)
			var col := Color.from_hsv(hue, sat, clampf(v, 0.0, 1.0))
			var vig := _vignette(uv)
			col.v *= vig
			col = col.lightened(0.05)
			img.set_pixel(x, y, col)
	_grain(img)
	_save(name, img)

func _vignette(uv: Vector2) -> float:
	var d := (uv - Vector2(0.5, 0.5)).length()
	return clampf(1.0 - d * 1.4, 0.0, 1.0)

func _fbm(p: Vector2) -> float:
	var v := 0.0
	var amp := 0.5
	for i in 4:
		v += amp * _noise(p)
		p *= 2.0
		amp *= 0.5
	return v

func _noise(p: Vector2) -> float:
	var i := Vector2i(int(floor(p.x)), int(floor(p.y)))
	var f := Vector2(p.x - floor(p.x), p.y - floor(p.y))
	var a := _hash(i)
	var b := _hash(i + Vector2i(1, 0))
	var c := _hash(i + Vector2i(0, 1))
	var d := _hash(i + Vector2i(1, 1))
	var u := f * f * (Vector2.ONE * 3.0 - 2.0 * f)
	return lerpf(lerpf(a, b, u.x), lerpf(c, d, u.x), u.y)

func _hash(i: Vector2i) -> float:
	var h := i.x * 374761393 + i.y * 668265263
	return float(h % 1000) / 1000.0

func _grain(img: Image) -> void:
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			var c := img.get_pixel(x, y)
			var g := _rng.randf_range(-0.04, 0.04)
			c.r = clampf(c.r + g, 0.0, 1.0)
			c.g = clampf(c.g + g, 0.0, 1.0)
			c.b = clampf(c.b + g, 0.0, 1.0)
			img.set_pixel(x, y, c)

func _save(name: String, img: Image) -> void:
	var path := OUT + name + ".png"
	img.save_png(path)
	print("[photos] ", path)
