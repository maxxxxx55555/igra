extends SceneTree

var _failures: Array[String] = []
var _total: int = 0

func _initialize() -> void:
	_scan_dir("res://scripts")
	_scan_dir("res://scenes")
	print("PROBE: scanned ", _total, " .gd files, failures: ", _failures.size())
	for f in _failures:
		print("PROBE_FAIL: ", f)
	quit(0)

func _scan_dir(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var fname := d.get_next()
	while fname != "":
		if not fname.begins_with(".") and fname != ".uid":
			var full := dir + "/" + fname
			if d.current_is_dir():
				_scan_dir(full)
			elif fname.ends_with(".gd"):
				_total += 1
				var script := load(full)
				if script == null:
					_failures.append(full)
		fname = d.get_next()
	d.list_dir_end()
