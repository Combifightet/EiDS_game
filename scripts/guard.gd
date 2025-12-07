extends CharacterBody3D

# --- Configuration ---
@export var vision_angle: float = 60.0 # Total angle of the cone (pie slice)
@export var detection_time: float = 2.0 # Seconds before game over
@export var eyes_height: float = 0.5 # Offset to cast ray from eyes, not feet

# --- References ---
@onready var vision_area: Area3D = $VisionArea
@onready var ray_cast: RayCast3D = $RayCast3D
@onready var spot_indicator: Label3D = $SpotIndicator
@onready var vision_cone_mesh: MeshInstance3D = $VisionArea/VisionCone

# --- State ---
var target_player: PlayerMovement = null
var detection_timer: float = 0.0
var is_alert: bool = false

func _ready() -> void:
	# Set up the raycast to ignore the guard itself so it doesn't intersect with its own body
	ray_cast.add_exception(self)
	ray_cast.enabled = false # Save performance, only enable when player is close
	
	spot_indicator.text = ""
	
	if vision_cone_mesh:
		var mat = vision_cone_mesh.get_surface_override_material(0)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("vision_angle_deg", vision_angle)

func _physics_process(delta: float) -> void:
	if target_player:
		check_vision(delta)
	else:
		# Cooldown if player leaves the area completely
		if detection_timer > 0:
			detection_timer = max(0.0, detection_timer - delta)
			update_indicator()

func check_vision(delta: float) -> void:
	var can_see = false
	
	# 1. Direction Calculation
	var guard_eyes = global_position + Vector3(0, eyes_height, 0)
	var player_center = target_player.global_position + Vector3(0, 0.5, 0) 
	
	# Calculate direction on the 2D plane (XZ) only to ignore height differences
	var direction_to_player_2d = (player_center - guard_eyes)
	direction_to_player_2d.y = 0 # Flatten the vector
	direction_to_player_2d = direction_to_player_2d.normalized()
	
	var forward_vector_2d = -global_transform.basis.z
	forward_vector_2d.y = 0 # Flatten the forward vector
	forward_vector_2d = forward_vector_2d.normalized()
	
	var angle_to_player = forward_vector_2d.angle_to(direction_to_player_2d)
	
	# 2. Angle Check (The "Pie Slice")
	if angle_to_player < deg_to_rad(vision_angle / 2.0):
		
		# 3. RayCast Check (Line of Sight)
		# We still use the full 3D positions for the RayCast to ensure walls block view
		ray_cast.global_position = guard_eyes
		ray_cast.target_position = ray_cast.to_local(player_center)
		ray_cast.force_raycast_update()
		
		if ray_cast.is_colliding():
			var collider = ray_cast.get_collider()
			if collider == target_player:
				can_see = true
	
	# 4. Timer Logic
	if can_see:
		print("in vision")
		detection_timer += delta
		is_alert = true
		if detection_timer >= detection_time:
			game_over()
		_set_cone_color(Color(1.0, 0.0, 0.0, 0.5)) # Red
	else:
		# Cooldown logic (player hid behind wall or left cone)
		detection_timer = max(0.0, detection_timer - delta)
		is_alert = false
		_set_cone_color(Color(0.0, 0.5, 1.0, 0.3)) # Blue
	
	update_indicator()

func update_indicator() -> void:
	if detection_timer > 0:
		# Show an exclamation mark or countdown
		var progress = int((detection_timer / detection_time) * 100)
		spot_indicator.text = str(progress) + "%"
		spot_indicator.modulate = Color.WHITE.lerp(Color.RED, detection_timer / detection_time)
	else:
		spot_indicator.text = ""

func game_over() -> void:
	print("GAME OVER - CAUGHT BY GUARD")
	spot_indicator.text = "CAUGHT!"
	set_physics_process(false) # Stop checking
	# Add your scene reload or game over UI logic here:
	# get_tree().reload_current_scene()

func _set_cone_color(col: Color) -> void:
	if vision_cone_mesh:
		var mat = vision_cone_mesh.get_surface_override_material(0)
		if mat:
			mat.set_shader_parameter("color", col)

# --- Signal Callbacks ---

func _on_vision_area_body_entered(body: Node3D) -> void:
	# We strictly check for the class_name defined in player_movement.gd [cite: 124]
	if body is PlayerMovement:
		target_player = body
		ray_cast.enabled = true
		print("enter")

func _on_vision_area_body_exited(body: Node3D) -> void:
	if body == target_player:
		target_player = null
		ray_cast.enabled = false
		print("exit")
