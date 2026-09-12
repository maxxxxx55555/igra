# tools/texture_psnr_check.gd — PSNR of a reimported (VRAM Compressed)
# texture against its original Lossless PNG, one line per file, CSV-ish.
#
#   godot --headless --path . --script tools/texture_psnr_check.gd -- \
#       assets/textures/tiles assets/textures/surfaces
#
# Prints "PSNR <path> <db>" per file ("inf" = pixel-identical) and a
# final "PSNR_SUMMARY min=<x> mean=<y> n=<n>" line.
extends SceneTree

func _init() -> void:
	var dirs: PackedStringArray = OS.get_cmdline_user_args()
	if dirs.is_empty():
		dirs = ["assets/textures/tiles", "assets/textures/surfaces"]
	var paths: Array[String] = []
	for d in dirs:
		_collect_pngs(d, paths)
	var vals: Array[float] = []
	for p in paths:
		var db := _psnr(p)
		if db == INF:
			print("PSNR ", p, " inf")
		else:
			print("PSNR ", p, " %.2f" % db)
			vals.append(db)
	if vals.is_empty():
		print("PSNR_SUMMARY min=inf mean=inf n=", paths.size())
	else:
		var mn: float = vals[0]
		var sum := 0.0
		for v in vals:
			mn = minf(mn, v)
			sum += v
		print("PSNR_SUMMARY min=%.2f mean=%.2f n=%d" % [mn, sum / vals.size(), paths.size()])
	quit(0)

func _collect_pngs(dir: String, out: Array[String]) -> void:
	var da := DirAccess.open(dir)
	if da == null:
		return
	da.list_dir_begin()
	var f := da.get_next()
	while f != "":
		if f.ends_with(".png"):
			out.append(dir.path_join(f))
		f = da.get_next()
	da.list_dir_end()

## Loads the ORIGINAL file bytes straight off disk (bypassing the .import
## cache entirely) so this is a true before/after, not import-vs-import.
func _load_original(path: String) -> Image:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var bytes := f.get_buffer(f.get_length())
	f.close()
	var img := Image.new()
	return img if img.load_png_from_buffer(bytes) == OK else null

func _psnr(path: String) -> float:
	var orig := _load_original(path)
	var tex := load("res://" + path) as Texture2D
	if orig == null or tex == null:
		return -1.0
	var comp := tex.get_image()
	if comp == null:
		return -1.0
	if comp.is_compressed():
		comp.decompress()
	if comp.get_format() != orig.get_format():
		comp = comp.duplicate()
		comp.convert(orig.get_format())
	if comp.get_size() != orig.get_size():
		comp.resize(orig.get_size().x, orig.get_size().y)
	var w := orig.get_width()
	var h := orig.get_height()
	var sq_err := 0.0
	var n := 0
	for y in h:
		for x in w:
			var a := orig.get_pixel(x, y)
			var b := comp.get_pixel(x, y)
			sq_err += (a.r - b.r) ** 2 + (a.g - b.g) ** 2 + (a.b - b.b) ** 2 + (a.a - b.a) ** 2
			n += 4
	var mse := sq_err / n
	if mse <= 0.0000001:
		return INF
	# Colors are float 0..1 here (Image.get_pixel returns normalized Color);
	# MAX^2/MSE with MAX=1.0, in dB.
	return -10.0 * log(mse) / log(10.0)
