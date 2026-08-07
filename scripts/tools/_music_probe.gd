extends Node
## Диагностика импорта музыки: реальные loop_mode/format/размер после импорта.

func _ready() -> void:
	var d := DirAccess.open("res://assets/audio/music")
	if d == null:
		print("[m] нет папки")
		get_tree().quit()
		return
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if f.ends_with(".wav"):
			var st := load("res://assets/audio/music/" + f) as AudioStreamWAV
			if st == null:
				print("[m] %s -> NULL" % f)
			else:
				print("[m] %-26s loop=%d begin=%d end=%d fmt=%d rate=%d bytes=%d len=%.1fs" % [
					f, st.loop_mode, st.loop_begin, st.loop_end, st.format,
					st.mix_rate, st.data.size(), st.get_length()])
		f = d.get_next()
	d.list_dir_end()
	get_tree().quit()
