extends PointLight2D
@export var district_id: StringName
@export var lit_energy: float = 0.9
@export var lit_color: Color = Color("f2c879")
var _blackout: float = 0.0
func _ready() -> void:
    shadow_enabled = true
    color = lit_color
    EventBus.power_grid_updated.connect(_refresh)
    EventBus.district_blackout.connect(_on_blackout)
    _refresh()
func _process(delta: float) -> void:
    if _blackout > 0.0:
        _blackout -= delta
        energy = 0.0
        if _blackout <= 0.0:
            _refresh()
func _on_blackout(id: StringName) -> void:
    if id == district_id and PowerGrid.get_stage(district_id) >= DistrictData.Stage.STREETS:
        _blackout = 15.0
func _refresh() -> void:
    var lit: bool = PowerGrid.get_stage(district_id) >= DistrictData.Stage.STREETS
    energy = lit_energy if (lit and _blackout <= 0.0) else 0.0