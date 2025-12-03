extends Node3D
class_name VisionCone

@export var color: Color = Color(0xff7a883e):
	set(value):
		color = value
		_update_visuals()
@export_range(0, 10, 0.01, "or_greater") var view_distance: float = 5:
	set(value):
		view_distance = value
		_update_visuals()
@export_range(0, 180, 1, "radians_as_degrees") var angle: float = deg_to_rad(40):
	set(value):
		angle = value
		_update_visuals()
## Must be a unique value, for vision cones to work while overlapping each other
@export_range(0, 1, 1, "or_greater", "hide_slider") var id: int = 0:
	set(value):
		id = max(0, value)
		_update_visuals()


@onready var cone: SpotLight3D = $Cone
@onready var plane: MeshInstance3D = $Cone/Plane


func _update_visuals() -> void:
	if not is_node_ready():
		return
		
	plane.scale = Vector3.ONE * view_distance
	plane.get_active_material(0).set_shader_parameter("angle", angle)
	plane.get_active_material(0).set_shader_parameter("color", color)
	plane.get_active_material(0).set_shader_parameter("id", id)
	cone.spot_angle = rad_to_deg(angle/2)+1
	cone.spot_range = view_distance+1
	cone.light_energy = id


func _ready() -> void:
	cone.light_color = Color(0xffffff)
	_update_visuals()
