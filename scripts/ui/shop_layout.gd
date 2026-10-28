extends RefCounted
## The shop uses a reading-width panel and keeps its close action outside the catalog.

static func extent(viewport: Vector2) -> Vector2:
	return Vector2(minf(1100.0, viewport.x - 48.0), minf(820.0, viewport.y - 48.0))

static func fit(data: Dictionary, viewport: Vector2) -> void:
	var size: Vector2 = extent(viewport)
	var card: ColorRect = data.card
	data.underlay.size = viewport
	card.size = size
	card.position = (viewport - size) * 0.5
	data.border.size = size + Vector2(4.0, 4.0)
	data.inner.size = size - Vector2(2.0, 2.0)
	data.header_line.size.x = size.x - 4.0
	data.title_lbl.size.x = size.x - 40.0
	data.title_lbl.add_theme_font_size_override("font_size", 28)
	data.content.size = size - Vector2(40.0, 100.0)
	var close_button: Button = data.close_btn
	close_button.size = Vector2(220.0, 44.0)
	close_button.position = Vector2((size.x - close_button.size.x) * 0.5, size.y - 48.0)
	close_button.add_theme_font_size_override("font_size", 22)
