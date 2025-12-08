extends Node3D
class_name LevelGen

@export var wall_height: float = 1.5
@export var grid_size: float = 2

@onready var custom_grid_map: CustomGridMap = $CustomGridMap

var _collectible: PackedScene = preload('res://scenes/collectible.tscn')
var _guard_scene: PackedScene = preload("res://scenes/guard.tscn")


func _ready() -> void:
	custom_grid_map.clear()
	custom_grid_map.scale = Vector3(1/grid_size, wall_height, 1/grid_size)
	
	#var tile_id: int = custom_grid_map.tiles[0b000_010_000]
	#custom_grid_map.set_cell_item(Vector3(0,0,0), tile_id)

func _cell_equals(a: FloorPlanCell, b: FloorPlanCell) -> bool:
	if a == null or a.is_empty():
		return false
	return b == null or not (
		b.is_empty() or
		a.room_id != b.room_id
	)

func from_grid(floor_plan_grid: FloorPlanGrid, doors: Array[FloorPlanGen.Door] = [], subdivisions: int = 0) -> Array[Vector2i]:
	custom_grid_map.clear()
		
	for y in range(floor_plan_grid.height):
		for x in range(floor_plan_grid.width):
			# TODO: calculate peering bits, by checking cell id's
			#       also check for doors
			var cell = floor_plan_grid.get_cell(x, y)
			var neighbours: Array[bool] = [
				false, false, false,
				false, false, false,
				false, false, false
			]
			if cell != null and not cell.is_empty():
				neighbours[4] = true
				
				for door in doors:
					if door.from == Vector2i(x,y) or door.to == Vector2i(x,y):
						var dir: Vector2i
						if door.from == Vector2i(x,y):
							dir = door.to-door.from
						else:
							dir = door.from-door.to
						if dir == Vector2i( 0, -1):
							neighbours[1] = true # top
						elif dir == Vector2i(-1, 0):
							neighbours[3] = true # left
						elif dir == Vector2i( 1, 0):
							neighbours[5] = true # right
						elif dir == Vector2i( 0, 1):
							neighbours[7] = true # bottom
							
				
				if _cell_equals(cell, floor_plan_grid.get_cell(x, y-1)):
					neighbours[1] = true # top
				if _cell_equals(cell, floor_plan_grid.get_cell(x-1, y)):
					neighbours[3] = true # left
				if _cell_equals(cell, floor_plan_grid.get_cell(x+1, y)):
					neighbours[5] = true # right
				if _cell_equals(cell, floor_plan_grid.get_cell(x, y+1)):
					neighbours[7] = true # bottom
				
				if _cell_equals(cell, floor_plan_grid.get_cell(x-1, y-1)) and (neighbours[3] and neighbours[1]):
					neighbours[0] = true # top left
				if _cell_equals(cell, floor_plan_grid.get_cell(x+1, y-1)) and (neighbours[1] and neighbours[5]):
					neighbours[2] = true # top right
				if _cell_equals(cell, floor_plan_grid.get_cell(x-1, y+1)) and (neighbours[3] and neighbours[7]):
					neighbours[6] = true # bottom left
				if _cell_equals(cell, floor_plan_grid.get_cell(x+1, y+1)) and (neighbours[7] and neighbours[5]):
					neighbours[8] = true # bottom right
			
			# artificialy rotate neighbour array 180° due to 2d / 3d descrepancy
			neighbours.reverse()
			
			var peering_bits: int = 0b000_000_000
			for i in range(neighbours.size()):
				if neighbours[i]:
					peering_bits += 2**i
			
			
			@warning_ignore("integer_division")
			custom_grid_map.set_cell_item(
				# TODO: this offset is not correct
				#Vector3i(x-floor_plan_grid.width/2, 0, y-floor_plan_grid.height/2),
				Vector3i(x, 0, y),
				custom_grid_map.tiles[peering_bits]
			)

			var subd_scale: float = pow(2, max(0, subdivisions))

			custom_grid_map.scale = Vector3(1/grid_size, wall_height, 1/grid_size)
			custom_grid_map.scale *= Vector3(subd_scale, 1, subd_scale)
	
	_place_collectibles(floor_plan_grid, doors)
	
	_extend_top()
	
	return _place_collectibles(floor_plan_grid, doors)



func _place_collectibles(floor_plan_grid: FloorPlanGrid, doors: Array[FloorPlanGen.Door]) -> Array[Vector2i]:
	var rooms: Dictionary[int, Vector2i] = {}
	for room_pos in floor_plan_grid._room_dict.keys():
		rooms[floor_plan_grid._room_dict[room_pos].id] = room_pos
	
	
	var graph: Graph = Graph.new()
	graph.nodes = [-1]
	graph.nodes.append_array(rooms.keys())
	for door in doors:
		var dist: float = 1_000_000_000
		if door.from_id != FloorPlanCell.OUTSIDE and door.to_id != FloorPlanCell.OUTSIDE:
			dist = (rooms[door.from_id]-rooms[door.to_id]).length()
		graph.edges.append(
			Graph.Edge.new(door.from_id, door.to_id, dist)
		)
	
	# ensure that each room is reachable
	var mst_graph: Graph = graph.get_mst()

	# Sort nodes by distance from node -1 using BFS
	var sorted_room_ids: Array[int] = []
	var distance: Dictionary[int, int] = {}
	var queue: Array[int] = []

	# Start from outside  (id == -1)
	var start_node: int = mst_graph.nodes.min()
	queue.append(start_node)
	distance[start_node] = 0
	sorted_room_ids.append(start_node)

	# BFS traversal
	while not queue.is_empty():
		var current: int = queue.pop_front()
		var connections: Array[int] = mst_graph.get_connections_from(current)
		
		for neighbor in connections:
			if not distance.has(neighbor):
				distance[neighbor] = distance[current] + 1
				queue.append(neighbor)
				sorted_room_ids.append(neighbor)
	
	# remove outside "room" if it exists
	print(sorted_room_ids)
	if sorted_room_ids[0] == FloorPlanCell.OUTSIDE:
		sorted_room_ids.remove_at(0)
	var furthest_room: int = sorted_room_ids.pop_back()
	var middle_index: int = floor((len(sorted_room_ids))/2.0)
	var far_middle_room: int = sorted_room_ids[middle_index]
	var near_middle_room: int = sorted_room_ids[middle_index-1]
	
	var collectible_pos: Array[Vector2i] = [
		floor_plan_grid.get_room_center(furthest_room),
		floor_plan_grid.get_room_center(far_middle_room),
		floor_plan_grid.get_room_center(near_middle_room),
	]
	
	for i in range(len(collectible_pos)):
		var collectible: Collectible = _collectible.instantiate()
		# 2 x^(2)-10 x+30
		collectible.value = 2*i*i -10*i +30
		add_child(collectible)
		var pos: Vector2i = collectible_pos[i]
		collectible.position = Vector3(pos.x, 0, pos.y)
	
	return collectible_pos


func place_single_guard(floor_plan_grid: FloorPlanGrid, target_player: Node3D, 
						nav_data: Dictionary, grid_origin: Vector3, 
						grid_res: float, patrol_path: Array[Vector2i]) -> void:
	# Get all available rooms from the grid data
	var room_positions = floor_plan_grid._room_dict.keys()
	if room_positions.is_empty():
		return

	# Pick a random room. 
	var random_room_pos = room_positions.pick_random()
	var room_id = floor_plan_grid._room_dict[random_room_pos].id
	
	# Get the center coordinate of that room
	var grid_pos: Vector2i = floor_plan_grid.get_room_center(room_id)
	
	# Instantiate the guard
	var guard_instance = _guard_scene.instantiate()
	add_child(guard_instance)
	
	# Position the guard
	guard_instance.global_position = Vector3(grid_pos.x, 1.0, grid_pos.y)
	
	# Rotate guard randomly (0, 90, 180, or 270 degrees)
	var random_rot = (randi() % 4) * 90.0
	guard_instance.rotation_degrees.y = random_rot
	
	# 3. Assign the player reference required by guard.gd 
	guard_instance.target_player = target_player
	
	guard_instance.setup_navigation(grid_origin, grid_res, nav_data)
	guard_instance.set_patrol_path(patrol_path)


func _extend_top() -> void:
	var min_cell: Vector2i = Vector2i(INF, INF)
	var max_cell: Vector2i = Vector2i(-INF, -INF)
	for cell in custom_grid_map.get_used_cells():
		if cell.x < min_cell.x:
			min_cell.x = cell.x
		if cell.x > max_cell.x:
			max_cell.x = cell.x
		if cell.y < min_cell.y:
			min_cell.y = cell.y
		if cell.y > max_cell.y:
			max_cell.y = cell.y
	
	#custom_grid_map.global_position
	custom_grid_map.map_to_local(Vector3i(min_cell.x, 0, min_cell.y))
	# TODO: does nothing yet
		
	
