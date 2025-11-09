extends CharacterBody3D

class_name PlayerMovement

## How fast the player moves from one cell to the next (in seconds)
@export var move_duration: float = 0.2

# This will hold our pathfinding graph
var astar_graph = AStar2D.new()

var _grid_origin := Vector3.ZERO
var _grid_resolution: float = 1.0

# These maps let us convert between Vector2i grid coords and AStar's integer IDs
var cell_to_id: Dictionary = {}
var id_to_cell: Dictionary = {}

# This holds the path we are currently following
var current_path: PackedVector2Array = []
var is_moving: bool = false
var active_tween: Tween

## Node to hold the debug path markers.
## Assign this in the Inspector!
@export var path_markers_container: Node3D

# A simple mesh to re-use for our markers
var debug_sphere = SphereMesh.new()

# --- 1. Setup Function ---

func setup_grid_transform(origin: Vector2, resolution: float) -> void:
	_grid_origin = Vector3(origin.x, global_position.y, origin.y)
	_grid_resolution = resolution

func setup_pathfinding_graph(grid_data: Dictionary) -> void:
	# Clear any old data
	astar_graph.clear()
	cell_to_id.clear()
	id_to_cell.clear()
	
	var point_id_counter: int = 0
	
	# 1. Add all cells as "points" (nodes) to the graph
	for cell_coord: Vector2i in grid_data:
		astar_graph.add_point(point_id_counter, cell_coord)
		cell_to_id[cell_coord] = point_id_counter
		id_to_cell[point_id_counter] = cell_coord
		point_id_counter += 1
		
	# 2. Add all "connections" (edges)
	for from_cell: Vector2i in grid_data:
		var from_id: int = cell_to_id[from_cell]
		
		# Get the list of neighbors this cell can move to
		var neighbors_array: Array = grid_data[from_cell]
		
		for to_cell: Vector2i in neighbors_array:
			# Make sure the destination cell is also a valid point in our graph
			if cell_to_id.has(to_cell):
				var to_id: int = cell_to_id[to_cell]
				
				# Connect them (one-way). Since we iterate all cells,
				# the reverse connection will be added when we get to that cell.

				astar_graph.connect_points(from_id, to_id, false)

# We will check for clicks every frame
func _process(_delta):
	

	# 1. Check for a left mouse click
	if Input.is_action_just_pressed("LeftClick"):
		
		# 2. Get the mouse position and camera
		var mouse_pos = get_viewport().get_mouse_position()
		var camera = get_viewport().get_camera_3d()
		var space_state = get_world_3d().direct_space_state
		
		# Make sure we have everything we need (safer than before)
		if not camera or not space_state:
			return
		
		# 3. Project a ray from the camera to the mouse position
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000.0
		
		# 4. Create and cast the ray
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collision_mask = 1 # Only hit the "ground"
		
		var result = space_state.intersect_ray(query)
		
		# 5. If the ray hit something...
		if result:
			# Clear old path markers
			if path_markers_container:
				for marker in path_markers_container.get_children():
					marker.queue_free()
			
			# Find start and end cells
			var start_cell = _world_to_grid(global_position)
			var end_cell = _world_to_grid(result.position)
			
			# Make sure cells are valid before pathfinding
			if not cell_to_id.has(start_cell) or not cell_to_id.has(end_cell):
				print("Clicked on an invalid or unmapped cell.")
				return

			# Get the integer IDs for AStar
			var start_id: int = cell_to_id[start_cell]
			var end_id: int = cell_to_id[end_cell]
			
			# Calculate the path
			var new_path: PackedVector2Array = astar_graph.get_point_path(start_id, end_id)
			
			# Draw new path markers
			if path_markers_container:
				for i in range(1, new_path.size()):
					var cell_pos: Vector2i = Vector2i(new_path[i])
					var world_pos = _grid_to_world(cell_pos)
					
					var marker_instance = MeshInstance3D.new()
					marker_instance.mesh = debug_sphere
					marker_instance.scale = Vector3(0.2, 0.2, 0.2)
					path_markers_container.add_child(marker_instance) 
					marker_instance.global_position = world_pos
			
			# Stop all current movement
			if active_tween and active_tween.is_running():
				active_tween.kill()
				is_moving = false
			
			# If the path is just our start, do nothing
			if new_path.size() <= 1:
				current_path.clear()
				return
			
			# Remove the first cell (our current position)
			new_path.remove_at(0)
			
			# Store the new path and start moving
			current_path = new_path
			# is_moving is already false, so we don't need to set it
			
			# Kick off the movement chain
			move_to_next_cell()

func move_to_next_cell() -> void:
	# If we are already moving, or the path is empty, stop.
	if is_moving or current_path.is_empty():
		is_moving = false
		return
		
	is_moving = true
	
	# Get the first cell from the path (as Vector2) and cast it to Vector2i
	var next_cell: Vector2i = Vector2i(current_path[0])
	
# 	Remove that cell from the path
	current_path.remove_at(0)
	
	# Convert it to a 3D world position
	var target_position = _grid_to_world(next_cell)
	
	# Create a tween to move there
	active_tween = create_tween()
	active_tween.tween_property(self, "global_position", target_position, move_duration)
	active_tween.set_trans(Tween.TRANS_SINE)
	
	# When this tween finishes, it will call this function again
	# to move to the *next* cell in the path.
	# When the tween finishes, first set is_moving to false,
	# *then* call move_to_next_cell() to start the next step.
	active_tween.finished.connect(func():
		is_moving = false
		move_to_next_cell()
	)


# --- 4. Helper (Utility) Functions ---

# Converts a 3D world position to a 2D grid coordinate
func _world_to_grid(world_pos: Vector3) -> Vector2i:
	var grid_x = roundi((world_pos.x - _grid_origin.x) * _grid_resolution)
	var grid_z = roundi((world_pos.z - _grid_origin.z) * _grid_resolution)
	return Vector2i(grid_x, grid_z)

# Converts a 2D grid coordinate to a 3D world position
func _grid_to_world(grid_pos: Vector2i) -> Vector3:
	var world_x = (float(grid_pos.x) / _grid_resolution) + _grid_origin.x
	var world_z = (float(grid_pos.y) / _grid_resolution) + _grid_origin.z
	# Return at the player's current height
	return Vector3(world_x, 0.7, world_z)
