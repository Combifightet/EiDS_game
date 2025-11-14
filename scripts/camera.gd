extends Node3D

@export var camera_deadzone: float = 1.0
@export var camera_follow_speed: float = 5.0
@export var camera_rotation_duration: float = 0.3

@onready var player: Node3D = %Player
@onready var camera: Camera3D = $Camera3D
@onready var viewport_container: SubViewportContainer = %PixelViewportContainer

@onready var _prev_rotation = camera.global_rotation
@onready var _snap_space = camera.global_transform

@onready var _container_position = viewport_container.position


var _current_angle: float = 0.0
var _target_angle: float = 0.0
var _is_rotating_camera: bool = false


func _process(delta: float) -> void:
	# smooth camera folowing
	global_position = lerp(global_position, player.global_position, camera_follow_speed * delta)
	rotation.y = _current_angle
	
	# texel snapping (credit to: https://www.youtube.com/watch?v=LQfAGAj9oNQ)
	# rotation changes the snap space
	if camera.global_rotation != _prev_rotation:
		_prev_rotation = camera.global_rotation
		_snap_space = camera.global_transform
	var texel_size: float = camera.size/180.0
	# camera position in snap space
	var snap_space_pos: Vector3 = camera.global_position * _snap_space
	# snap!
	var snapped_snap_spapce_pos: Vector3 = snap_space_pos.snapped(Vector3.ONE * texel_size)
	# how much we snapped (in snap space)
	var snap_error: Vector3 = snapped_snap_spapce_pos-snap_space_pos
	# apply camera offset as to not affect the actual transform
	camera.h_offset = snap_error.x
	camera.v_offset = snap_error.y
	# apply invverse offset to viewport
	var texel_error: Vector2 = Vector2(snap_error.x, -snap_error.y) / texel_size
	viewport_container.position = _container_position + texel_error*viewport_container.stretch_shrink


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_camera_left"):
		rotate_camera(-90)
	elif event.is_action_pressed("rotate_camera_right"):
		rotate_camera(90)

func rotate_camera(degrees: float) -> void:
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
