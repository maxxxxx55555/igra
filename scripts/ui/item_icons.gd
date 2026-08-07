extends Node

static func draw_icon(parent: Control, item_id: StringName, size: float) -> void:
	var tex_path: String = "res://assets/textures/items/%s.png" % String(item_id)
	if ResourceLoader.exists(tex_path):
		var tex: Texture2D = load(tex_path) as Texture2D
		if tex != null:
			var tr := TextureRect.new()
			tr.name = "IconTex_" + str(item_id)
			tr.texture = tex
			tr.size = Vector2(size, size)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(tr)
			return
	var draw := ColorRect.new()
	draw.name = "IconDraw_" + str(item_id)
	draw.size = Vector2(size, size)
	draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var c := Color(0.788, 0.635, 0.290)
	var dim := Color(0.541, 0.451, 0.220)
	match item_id:
		&"battery":
			draw.color = dim
			var inner := ColorRect.new()
			inner.size = Vector2(size * 0.5, size * 0.65)
			inner.position = Vector2(size * 0.25, size * 0.15)
			inner.color = c
			inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(inner)
			var cap := ColorRect.new()
			cap.size = Vector2(size * 0.3, size * 0.1)
			cap.position = Vector2(size * 0.35, size * 0.05)
			cap.color = Color(0.706, 0.271, 0.184)
			cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(cap)
			var contact := ColorRect.new()
			contact.size = Vector2(size * 0.15, size * 0.08)
			contact.position = Vector2(size * 0.425, size * 0.85)
			contact.color = c
			contact.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(contact)
		&"medkit":
			draw.color = dim
			var cross_h := ColorRect.new()
			cross_h.size = Vector2(size * 0.5, size * 0.18)
			cross_h.position = Vector2(size * 0.25, size * 0.41)
			cross_h.color = Color(0.706, 0.271, 0.184)
			cross_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(cross_h)
			var cross_v := ColorRect.new()
			cross_v.size = Vector2(size * 0.18, size * 0.5)
			cross_v.position = Vector2(size * 0.41, size * 0.25)
			cross_v.color = Color(0.706, 0.271, 0.184)
			cross_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(cross_v)
		&"key":
			draw.color = dim
			var shaft := ColorRect.new()
			shaft.size = Vector2(size * 0.15, size * 0.6)
			shaft.position = Vector2(size * 0.55, size * 0.2)
			shaft.color = Color(0.682, 0.714, 0.749)
			shaft.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(shaft)
			var head := ColorRect.new()
			head.size = Vector2(size * 0.35, size * 0.35)
			head.position = Vector2(size * 0.15, size * 0.25)
			head.color = Color(0.682, 0.714, 0.749)
			head.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(head)
			var hole := ColorRect.new()
			hole.size = Vector2(size * 0.12, size * 0.12)
			hole.position = Vector2(size * 0.265, size * 0.365)
			hole.color = Color(0.078, 0.106, 0.141)
			hole.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(hole)
		&"cable":
			draw.color = dim
			var body := ColorRect.new()
			body.size = Vector2(size * 0.6, size * 0.15)
			body.position = Vector2(size * 0.2, size * 0.425)
			body.color = Color(0.373, 0.541, 0.306)
			body.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(body)
			var end_l := ColorRect.new()
			end_l.size = Vector2(size * 0.1, size * 0.25)
			end_l.position = Vector2(size * 0.2, size * 0.375)
			end_l.color = Color(0.682, 0.714, 0.749)
			end_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(end_l)
			var end_r := ColorRect.new()
			end_r.size = Vector2(size * 0.1, size * 0.25)
			end_r.position = Vector2(size * 0.7, size * 0.375)
			end_r.color = Color(0.682, 0.714, 0.749)
			end_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(end_r)
		&"fuse":
			draw.color = dim
			var body := ColorRect.new()
			body.size = Vector2(size * 0.6, size * 0.25)
			body.position = Vector2(size * 0.2, size * 0.375)
			body.color = c
			body.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(body)
			var pin_l := ColorRect.new()
			pin_l.size = Vector2(size * 0.08, size * 0.15)
			pin_l.position = Vector2(size * 0.18, size * 0.425)
			pin_l.color = Color(0.682, 0.714, 0.749)
			pin_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(pin_l)
			var pin_r := ColorRect.new()
			pin_r.size = Vector2(size * 0.08, size * 0.15)
			pin_r.position = Vector2(size * 0.74, size * 0.425)
			pin_r.color = Color(0.682, 0.714, 0.749)
			pin_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(pin_r)
		&"scrap", &"tool":
			draw.color = dim
			var tri := ColorRect.new()
			tri.size = Vector2(size * 0.6, size * 0.6)
			tri.position = Vector2(size * 0.2, size * 0.2)
			tri.color = Color(0.541, 0.451, 0.220)
			tri.rotation = 0.785
			tri.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(tri)
		&"flashlight":
			draw.color = dim
			var body := ColorRect.new()
			body.size = Vector2(size * 0.25, size * 0.6)
			body.position = Vector2(size * 0.37, size * 0.2)
			body.color = Color(0.682, 0.714, 0.749)
			body.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(body)
			var head := ColorRect.new()
			head.size = Vector2(size * 0.45, size * 0.2)
			head.position = Vector2(size * 0.27, size * 0.15)
			head.color = c
			head.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(head)
			var beam := ColorRect.new()
			beam.size = Vector2(size * 0.08, size * 0.3)
			beam.position = Vector2(size * 0.46, size * 0.05)
			beam.color = Color(1.0, 0.851, 0.627)
			beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(beam)
		&"backpack":
			draw.color = dim
			var body := ColorRect.new()
			body.size = Vector2(size * 0.55, size * 0.5)
			body.position = Vector2(size * 0.225, size * 0.25)
			body.color = Color(0.078, 0.106, 0.141)
			body.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(body)
			var strap_l := ColorRect.new()
			strap_l.size = Vector2(size * 0.08, size * 0.25)
			strap_l.position = Vector2(size * 0.2, size * 0.35)
			strap_l.color = Color(0.541, 0.451, 0.220)
			strap_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(strap_l)
			var strap_r := ColorRect.new()
			strap_r.size = Vector2(size * 0.08, size * 0.25)
			strap_r.position = Vector2(size * 0.72, size * 0.35)
			strap_r.color = Color(0.541, 0.451, 0.220)
			strap_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(strap_r)
		&"coin_pack":
			draw.color = dim
			for p in 3:
				var coin := ColorRect.new()
				coin.size = Vector2(size * 0.5, size * 0.12)
				coin.position = Vector2(size * 0.25, size * 0.25 + p * size * 0.14)
				coin.color = c
				coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
				draw.add_child(coin)
		_:
			draw.color = Color(0.165, 0.200, 0.251)
			var q := ColorRect.new()
			q.size = Vector2(size * 0.4, size * 0.4)
			q.position = Vector2(size * 0.3, size * 0.3)
			q.color = dim
			q.mouse_filter = Control.MOUSE_FILTER_IGNORE
			draw.add_child(q)
	parent.add_child(draw)