extends Node3D

@export var camera_deadzone: float = 1.0
@export var camera_follow_speed: float = 5.0
@export var camera_rotation_duration: float = 0.3

@onready var player: Node3D = %Player

var _current_angle: float = 0.0
var _target_angle: float = 0.0
var _is_rotating_camera: bool = false


func _process(delta: float) -> void:
	global_position = lerp(global_position, player.global_position, camera_follow_speed * delta)
	rotation.y = _current_angle

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
	_target_angle = _current_angle + deg_to_rad(degrees)
	
	var tween = create_tween()
	tween.tween_property(self, "_current_angle", _target_angle, camera_rotation_duration)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.finished.connect(_finish_rotation)

func _finish_rotation() -> void:
	_is_rotating_camera = false
	# Normalize the angle to prevent it from growing infinitely
	_current_angle = fposmod(_current_angle, TAU)
	_target_angle = _current_angle
