extends Node
## Edge Highlight (Accessibility): every interactable thing and pickup near the player gets a bright rim on its meshes, drawn as a material
## overlay so the object's own materials stay as they are; out of range, or with the setting off, the overlay is gone. A child of the Interactor.

const GROUPS: Array[StringName] = [&"interactable", &"pickups"]
const RANGE_M: float = 9.0
const TICK_SEC: float = 0.25
const RIM_CODE := "shader_type spatial;\n" \
	+ "render_mode unshaded, blend_add, depth_draw_never;\n" \
	+ "uniform vec3 rim_color : source_color = vec3(0.90, 0.81, 0.43);\n" \
	+ "void fragment() {\n" \
	+ "\tfloat rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.5);\n" \
	+ "\tALBEDO = rim_color;\n" \
	+ "\tALPHA = rim * 0.9;\n" \
	+ "}\n"

static var _rim: ShaderMaterial = null

var player: Node3D = null
var _lit: Array[MeshInstance3D] = []
var _timer: float = 0.0

func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = TICK_SEC
		refresh()

## The meshes of the interactables within RANGE_M of the player, or none with the setting off.
func wanted() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if not bool(SettingsManager.get_setting("edge_highlight", false)) or not is_instance_valid(player):
		return out
	for group: StringName in GROUPS:
		for node: Node in get_tree().get_nodes_in_group(group):
			var near := node as Node3D
			if near == null or near.global_position.distance_to(player.global_position) > RANGE_M:
				continue
			for mesh: Node in near.find_children("*", "MeshInstance3D", true, false):
				out.append(mesh as MeshInstance3D)
	return out

func refresh() -> void:
	var now: Array[MeshInstance3D] = wanted()
	for mesh: MeshInstance3D in _lit:
		if is_instance_valid(mesh) and not now.has(mesh):
			mesh.material_overlay = null
	for mesh: MeshInstance3D in now:
		mesh.material_overlay = _material()
	_lit = now

static func _material() -> ShaderMaterial:
	if _rim == null:
		var shader := Shader.new()
		shader.code = RIM_CODE
		_rim = ShaderMaterial.new()
		_rim.shader = shader
	return _rim
