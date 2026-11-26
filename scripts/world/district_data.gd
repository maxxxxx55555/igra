class_name DistrictData
extends Resource
enum Stage { DARK = 0, PARTIAL = 1, STREETS = 2, FULL = 3 }
@export var id: StringName
@export var display_name: String
@export var stage: Stage = Stage.DARK
@export var powered_by: Array[StringName] = []
@export var map_position: Vector2 = Vector2.ZERO
## Per-district tactical profile (authored in data/districts/*.tres and applied
## by Wave2GameBridge + HorrorTensionDirector's 11 district mutators).
@export var fog_density: float = 0.02
@export var cold_mult: float = 1.0
@export var enemy_count: int = 6