extends RefCounted
## The texture hook of the material factory (queue item B6): district_dressing.gd _plain() builds the material
## of every prop the dressing places, and names a texture set for it. Supports both .webp (compressed mobile build)
## and .png fallbacks so all 24 shipped PBR textures in assets/textures/pbr/ load reliably.

const DIR: String = "res://assets/textures/pbr/"
const TRIPLANAR_SCALE: float = 0.5

static func _resolve_tex(base_no_ext: String) -> String:
	var wp: String = base_no_ext + ".webp"
	if ResourceLoader.exists(wp):
		return wp
	var pp: String = base_no_ext + ".png"
	if ResourceLoader.exists(pp):
		return pp
	return ""

static func apply(mat: StandardMaterial3D, set_name: String) -> StandardMaterial3D:
	if set_name.is_empty():
		return mat
	var alb_path: String = _resolve_tex(DIR + set_name + "_albedo")
	if alb_path.is_empty():
		return mat
	mat.albedo_texture = load(alb_path)
	if not mat.vertex_color_use_as_albedo:
		mat.albedo_color = Color.WHITE
	var nrm_path: String = _resolve_tex(DIR + set_name + "_normal")
	if not nrm_path.is_empty():
		mat.normal_enabled = true
		mat.normal_texture = load(nrm_path)
	var rgh_path: String = _resolve_tex(DIR + set_name + "_rough")
	if not rgh_path.is_empty():
		mat.roughness = 1.0
		mat.roughness_texture = load(rgh_path)
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * TRIPLANAR_SCALE
	return mat
