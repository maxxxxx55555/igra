extends Node
@export var enable_proc_audio: bool = true
func _ready() -> void:

    for bus in ["Master","Music","SFX","Ambient","UI"]:
        var asp := AudioStreamPlayer.new()
        asp.name = bus + "Bus"
        asp.bus = bus
        add_child(asp)
    var asp3d := AudioStreamPlayer3D.new()
    asp3d.name = "Ambient3D"
    asp3d.bus = "Ambient"
    add_child(asp3d)


