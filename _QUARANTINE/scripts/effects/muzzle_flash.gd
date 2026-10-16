extends Node3D
## MuzzleFlash — спавнится на точке дула, живёт 0.06 с.
## Добавь как дочерний узел AttackComponent или Weapon.
## Вызов: muzzle_flash.flash()

@export var flash_duration: float = 0.06
@export var flash_color: Color = Color(1.0, 0.85, 0.4, 1.0)
@export var flash_energy: float = 3.0

var _light: OmniLight3D
var _mesh: MeshInstance3D

func _ready() -> void:
	_light = OmniLight3D.new()
	_light.light_color = flash_color
	_light.light_energy = flash_energy
	_light.omni_range = 3.0
	_light.visible = false
	add_child(_light)
	var sm := SphereMesh.new()
	sm.radius = 0.08
	sm.height = 0.16
	_mesh = MeshInstance3D.new()
	_mesh.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = flash_color
	mat.emission_enabled = true
	mat.emission = flash_color
	mat.emission_energy_multiplier = flash_energy
	_mesh.material_override = mat
	_mesh.visible = false
	add_child(_mesh)

func flash() -> void:
	_light.visible = true
	_mesh.visible = true
	var tw := create_tween()
	tw.tween_interval(flash_duration)
	tw.tween_callback(func() -> void:
		_light.visible = false
		_mesh.visible = false
	)
