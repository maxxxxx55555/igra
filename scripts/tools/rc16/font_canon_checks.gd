extends RefCounted
## Inspect real font bytes, variable weight and glyph chains, not a display name.

static func role(font: Font, weight: float) -> bool:
	var variation := font as FontVariation
	if variation == null or not is_equal_approx(float(variation.variation_opentype.get("wght", 0.0)), weight):
		return false
	var base := variation.base_font as FontFile
	var full := load("res://assets/fonts/RobotoCondensed-Full-VF.ttf") as FontFile
	return base != null and base.data == full.data and bundled_glyphs(font)

static func wordmark(font: Font) -> bool:
	var variation := font as FontVariation
	if variation == null or variation.variation_embolden <= 0.0:
		return false
	var base := variation.base_font as FontFile
	var display := load("res://assets/fonts/BebasNeue-Regular.ttf") as FontFile
	return base != null and base.data == display.data and bundled_glyphs(font)

static func bundled_glyphs(font: Font) -> bool:
	if not _bundled(font, {}):
		return false
	for letter: String in "Journal Продолжить Ёё Äß":
		if not font.has_char(letter.unicode_at(0)):
			return false
	return true

static func _bundled(font: Font, seen: Dictionary) -> bool:
	if font == null or font is SystemFont:
		return false
	if seen.has(font.get_instance_id()):
		return true
	seen[font.get_instance_id()] = true
	if font is FontFile and (font as FontFile).allow_system_fallback:
		return false
	if font is FontVariation and not _bundled((font as FontVariation).base_font, seen):
		return false
	for fallback: Font in font.fallbacks:
		if not _bundled(fallback, seen):
			return false
	return true
