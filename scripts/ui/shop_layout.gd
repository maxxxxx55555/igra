extends RefCounted
## The shop uses a reading-width panel and keeps its close action outside the catalog.

const ROW := 190.0
const GAP := 12.0
## Header, the coin line above the grid and the Close row below it (screens.gd SHOP_TOP, SHOP_CLOSE_ZONE, card chrome).
const CHROME := 180.0

static func extent(viewport: Vector2) -> Vector2:
	var width: float = minf(1100.0, viewport.x - 48.0)
	var count: int = 0
	for kind in [ShopItem.Kind.UPGRADE, ShopItem.Kind.SKIN, ShopItem.Kind.BUNDLE]:
		count += ShopService.catalog_by_kind(kind).size()
	var rows: int = maxi(1, ceili(count / (2.0 if width - 40.0 >= 600.0 else 1.0)))
	var height: float = rows * ROW + (rows - 1) * GAP + CHROME
	return Vector2(width, minf(height, minf(820.0, viewport.y - 48.0)))

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
	close_button.size = Vector2(220.0, UiScale.min_touch())
	close_button.position = Vector2((size.x - close_button.size.x) * 0.5, size.y - 48.0)
	close_button.add_theme_font_size_override("font_size", 22)
