extends Node3D

@export var camera_deadzone: float = 1.0  # This variable is unused in your active code
@export var camera_follow_speed: float = 5.0 # Higher = smoother camera
@export var camera_rotation_duration: float = 0.3  # Duration of 90-degree rotation

#@onready var camera: Camera3D = $Camera3D 
@onready var player: Node3D = %Player

var _target_camera_rotation: float = 0.0
var _is_rotating_camera: bool = false


func _process(delta: float) -> void:
	global_position = lerp(global_position, player.global_position, camera_follow_speed * delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_camera_left"):
		rotate_camera(-90)
	elif event.is_action_pressed("rotate_camera_right"):
		rotate_camera(90)

func rotate_camera(degrees: float) -> void:
	print("rotate_camera: ", degrees)
	if _is_rotating_camera:
		return
		
	_is_rotating_camera = true
	_target_camera_rotation += deg_to_rad(degrees)
	
	var tween = create_tween()

	tween.tween_property(self, "rotation:y", _target_camera_rotation, camera_rotation_duration)

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.finished.connect(func(): _is_rotating_camera = false)
