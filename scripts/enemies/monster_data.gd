class_name MonsterData
extends Resource
@export var id: StringName
@export var display_name: String
@export var description: String
@export var move_speed: float = 70.0
@export var chase_speed: float = 120.0
@export var collision_radius: float = 12.0
@export var detect_radius: float = 220.0
@export var vision_cone_deg: float = 360.0
@export var vision_range: float = 260.0
@export var noise_sensitivity: float = 1.0
@export var lose_time: float = 3.0
@export var light_vulnerable: bool = false
@export var light_damage_per_sec: float = 0.0
@export var fears_lit_district: bool = false
@export var max_hp: float = 40.0
@export var melee_damage: float = 10.0
@export var melee_range: float = 26.0
@export var can_break_lights: bool = false
@export var body_color: Color = Color("5a2a2a")