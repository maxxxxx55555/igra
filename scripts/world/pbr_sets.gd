extends RefCounted
## The texture hook of the material factory (queue item B6): district_dressing.gd _plain() builds the material of every prop the dressing places, and names a texture set for it. A set is a name; its files are
## assets/textures/pbr/<name>_albedo.png, _normal.png and _rough.png (tools/gen_pbr_textures.py). A set whose albedo does not exist leaves the material exactly as it was, so a prop may name its set before the
## files exist, and one edit of this file textures every prop of the world. The textures tile, so the mapping is triplanar in the prop's own space: a crate and a 4 m container take the same grain.

const DIR: String = "res://assets/textures/pbr/"
const TRIPLANAR_SCALE: float = 0.5

static func apply(mat: StandardMaterial3D, set_name: String) -> StandardMaterial3D:
	if set_name.is_empty() or not ResourceLoader.exists(DIR + set_name + "_albedo.png"):
		return mat
	mat.albedo_texture = load(DIR + set_name + "_albedo.png")
	if not mat.vertex_color_use_as_albedo:
		mat.albedo_color = Color.WHITE
	if ResourceLoader.exists(DIR + set_name + "_normal.png"):
		mat.normal_enabled = true
		mat.normal_texture = load(DIR + set_name + "_normal.png")
	if ResourceLoader.exists(DIR + set_name + "_rough.png"):
		mat.roughness = 1.0
		mat.roughness_texture = load(DIR + set_name + "_rough.png")
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3.ONE * TRIPLANAR_SCALE
	return mat
