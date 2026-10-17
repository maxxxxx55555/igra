extends RefCounted
## The signs of a district (the Soviet canon of Session 27): stencilled Russian words on the ground floor of the skyline's blocks, diegetic and the same in every locale; the interface is never touched.
## The bundled fonts hold no Cyrillic, so the words are drawn once by a Label in a SubViewport with the engine's own font (Open Sans, which holds it), baked to a texture with mipmaps, and every sign of
## the district is one quad of one MultiMesh (assets/shaders/soviet_sign.gdshader). Nothing is drawn headless or at the Low tier (a block without windows has no storeys to hang a sign on either).

const _SHADER := preload("res://assets/shaders/soviet_sign.gdshader")
const ATLAS_W: int = 1024
const ROW_PX: int = 128
const FONT_PX: int = 96
## A sign is 1 m tall (the letters about 0.55 m) and hangs between the pavement and the first row of windows (the windows start at 1.95 m).
const SIGN_H: float = 1.0
const SIGN_Y: float = 1.2
const SIGNS: int = 5
## How much of its own glow the paint shows, by power stage (DARK, PARTIAL, STREETS, FULL); at DARK the signs are all but gone.
const LIT_BY_STAGE: Array[float] = [0.45, 0.6, 0.8, 1.0]
const HAZARD: Array[String] = ["ОПАСНО", "ВЫСОКОЕ НАПРЯЖЕНИЕ", "ВХОД ВОСПРЕЩЁН", "ПРОХОД ЗАПРЕЩЁН", "НЕ ВХОДИТЬ"]
const YELLOW: Array[String] = ["АЗС", "БЕНЗИН", "ХЛЕБ"]
const WORDS := {
	&"suburbs": ["ПРОДУКТЫ", "ХЛЕБ", "АПТЕКА"],
	&"residential": ["ГАСТРОНОМ", "ПАРИКМАХЕРСКАЯ", "АПТЕКА", "ПРОДУКТЫ"],
	&"park": ["ПАРК КУЛЬТУРЫ", "КАРУСЕЛИ", "ВХОД"],
	&"school": ["ШКОЛА 7", "ВХОД"],
	&"hospital": ["БОЛЬНИЦА", "ПРИЁМНОЕ ОТДЕЛЕНИЕ"],
	&"gas_station": ["АЗС", "БЕНЗИН", "ВЫЕЗД"],
	&"police": ["МИЛИЦИЯ", "ДЕЖУРНАЯ ЧАСТЬ"],
	&"warehouses": ["СКЛАД 3", "ОПАСНО", "ПОГРУЗКА"],
	&"industrial": ["ЦЕХ 2", "ОПАСНО", "ВХОД ВОСПРЕЩЁН"],
	&"substation": ["ПОДСТАНЦИЯ", "ВЫСОКОЕ НАПРЯЖЕНИЕ", "НЕ ВХОДИТЬ"],
	&"power_station": ["ЭЛЕКТРОСТАНЦИЯ", "ОПАСНО", "ПРОХОД ЗАПРЕЩЁН"],
}

static func words_of(district_id: StringName) -> Array[String]:
	var found: Array[String] = []
	found.assign(WORDS.get(district_id, WORDS[&"suburbs"]))
	return found

## The size a word is drawn at: FONT_PX, smaller for a word that would not fit the row of the atlas (the end of "ВЫСОКОЕ НАПРЯЖЕНИЕ" and of "ПРИЁМНОЕ ОТДЕЛЕНИЕ" was cut off at 96 px).
static func font_px(word: String, font: Font) -> int:
	var wide: float = font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_PX).x
	return mini(FONT_PX, int(FONT_PX * ATLAS_W / (wide * 1.06)))

## `fronts` are the front faces of the skyline's blocks at the ground (z toward the street) and `widths` their widths; the signs are laid on them from a stream of the district's own.
static func build(parent: Node3D, district_id: StringName, fronts: Array[Transform3D], widths: Array[float]) -> void:
	if DisplayServer.get_name() == "headless" or fronts.is_empty():
		return
	var words: Array[String] = words_of(district_id)
	var font: Font = ThemeDB.fallback_font
	var viewport := SubViewport.new()
	viewport.size = Vector2i(ATLAS_W, ROW_PX * words.size())
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	var fills: Array[float] = []
	for i in words.size():
		var px: int = font_px(words[i], font)
		var label := Label.new()
		label.text = words[i]
		label.position = Vector2(0.0, i * ROW_PX)
		label.size = Vector2(ATLAS_W, ROW_PX)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", px)
		label.add_theme_color_override("font_color", Color.WHITE)
		viewport.add_child(label)
		fills.append(clampf(font.get_string_size(words[i], HORIZONTAL_ALIGNMENT_LEFT, -1, px).x / ATLAS_W * 1.06, 0.05, 1.0))
	parent.add_child(viewport)
	await parent.get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not is_instance_valid(parent):
		return
	var image: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	if image == null or image.is_empty():
		return
	image.generate_mipmaps()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = QuadMesh.new()
	mm.instance_count = SIGNS
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("signs_" + String(district_id))
	for i in SIGNS:
		var row: int = i % words.size()
		var width: float = fills[row] * ATLAS_W / ROW_PX * SIGN_H
		var k: int = rng.randi() % fronts.size()
		for _try in 6:
			if widths[k] >= width + 1.4:
				break
			k = rng.randi() % fronts.size()
		var span: float = maxf(0.0, widths[k] * 0.5 - width * 0.5 - 0.6)
		mm.set_instance_transform(i, fronts[k] * Transform3D(Basis.from_scale(Vector3(width, SIGN_H, 1.0)), Vector3(rng.randf_range(-span, span), SIGN_Y, 0.07)))
		mm.set_instance_custom_data(i, Color(float(row), fills[row], rng.randf(), _paint(words[row])))
	var mat := ShaderMaterial.new()
	mat.shader = _SHADER
	mat.set_shader_parameter("atlas", ImageTexture.create_from_image(image))
	mat.set_shader_parameter("rows", float(words.size()))
	mat.set_shader_parameter("detail", float(clampi(int(SettingsManager.get_setting("graphics_tier", 2)), 0, 2)))
	var signs := MultiMeshInstance3D.new()
	signs.name = "Signs"
	signs.multimesh = mm
	signs.material_override = mat
	signs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_stage(signs, PowerGrid.get_stage(district_id))
	parent.add_child(signs)

static func set_stage(signs: MultiMeshInstance3D, stage: int) -> void:
	(signs.material_override as ShaderMaterial).set_shader_parameter("lit", LIT_BY_STAGE[clampi(stage, 0, LIT_BY_STAGE.size() - 1)])

## The paint of a word: 2 faded red for a warning, 1 faded yellow for the road and the bread, 0 bone for the rest.
static func _paint(word: String) -> float:
	if HAZARD.has(word):
		return 2.0
	return 1.0 if YELLOW.has(word) else 0.0
