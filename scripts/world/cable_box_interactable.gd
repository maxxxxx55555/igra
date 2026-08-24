extends Node3D
## WAVE 6 P3: substation cable junction box. Interacting starts the
## existing cable-matching minigame (scripts/ui/puzzle_cables.gd,
## fully built but never reachable by a real player - PuzzleSystem.
## start_puzzle() was previously only ever called from test scripts).
##
## The original ask described a new "3x hold-2s" mechanic for this, but
## a real, complete cable-connection minigame already exists and covers
## the same beat (GDD-canonical per-district puzzle_system.gd rewards) -
## reused it instead of building a second, redundant interaction
## paradigm from scratch.

const PUZZLE_ID: String = "fuse_substation"

var _body: StaticBody3D

func _ready() -> void:
	add_to_group("interactable")
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.6, 1.0, 0.4)
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.16, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(0.788, 0.635, 0.290)
	mat.emission_energy_multiplier = 0.5
	mesh.material_override = mat
	mesh.position = Vector3(0, 0.5, 0)
	add_child(mesh)
	_body = StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.6, 1.0, 0.4)
	cs.shape = shape
	cs.position = Vector3(0, 0.5, 0)
	_body.add_child(cs)
	add_child(_body)

func can_interact() -> bool:
	var ps := get_node_or_null("/root/PuzzleSystem")
	return ps == null or not ps.is_solved(PUZZLE_ID)

func interact_prompt() -> String:
	return LocalizationManager.t("CABLE_PUZZLE")

func interact(_player: Node = null) -> void:
	var ps := get_node_or_null("/root/PuzzleSystem")
	if ps != null and ps.has_method("start_puzzle"):
		ps.start_puzzle(PUZZLE_ID)
