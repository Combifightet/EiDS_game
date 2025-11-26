extends Node3D
class_name LevelGen

@export var wall_height: float = 1.5
@export var grid_size: float = 2

@onready var custom_grid_map: CustomGridMap = $CustomGridMap

var _collectible: PackedScene = preload('res://scenes/collectible.tscn')


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

func from_grid(floor_plan_grid: FloorPlanGrid, doors: Array[FloorPlanGen.Door] = [], subdivisions: int = 0) -> void:
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
			if cell != null:
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
	
	place_rooms(floor_plan_grid, doors, subdivisions)

func place_rooms(floor_plan_grid: FloorPlanGrid, doors: Array[FloorPlanGen.Door], subdivisions: int = 0) -> void:
	var rooms: Dictionary[int, Vector2i] = {}
	for room_pos in floor_plan_grid._room_dict.keys():
		rooms[floor_plan_grid._room_dict[room_pos].id] = room_pos
	
	
	var graph: Graph = Graph.new()
	graph.nodes = [-1]
	graph.nodes.append_array(rooms.keys())
	for door in doors:
		var dist: float = 1_000_000_000
		if door.from_id != -1 and door.to_id != -1:
			dist = (rooms[door.from_id]-rooms[door.to_id]).length()
			graph.edges.append(
				Graph.Edge.new(door.from_id, door.to_id, dist)
			)
			graph.edges.append(
				Graph.Edge.new(door.to_id, door.from_id, dist)
			)
		else:
			graph.edges.insert(
				0, 
				Graph.Edge.new(door.from_id, door.to_id, 1_000_000_000)
			)
	
	print()
	print(graph.to_dot("ConnectivityGraph"))
	print()
	
	# ensure that each room is reachable
	var mst_graph: Graph = graph.get_mst()
	print()
	print(mst_graph.to_dot("MstConnectivityGraph"))
	print()
	
	
	var sorted_room_ids: Array[int] = [mst_graph.edges[0].start]
	# TODO: this doesnt sort them in the right order
	for edge in mst_graph.edges:
		sorted_room_ids.append(edge.end)
	
	var outside_index: int = sorted_room_ids.find(-1)
	if outside_index >= 0:
		sorted_room_ids.remove_at(outside_index)
	var furthest_room: int = sorted_room_ids.pop_back()
	var middle_index: int = floor((len(sorted_room_ids)-1)/2.0)
	var far_middle_room: int = sorted_room_ids[middle_index+1]
	var near_middle_room: int = sorted_room_ids[middle_index]
	
	var collectible_pos: Array[Vector2i] = [
		rooms[furthest_room],
		rooms[far_middle_room],
		rooms[near_middle_room],
	]
	
	for i in range(len(collectible_pos)):
		var collectible: Collectible = _collectible.instantiate()
		# 2 x^(2)-10 x+30
		collectible.value = 2*i*i -10*i +30
		add_child(collectible)
		var pos: Vector2i = collectible_pos[i]
		collectible.position = Vector3(pos.x, 0, pos.y)
		
		print("Collectible(",i,"),  value: ", collectible.value, "  ->  ", collectible_pos[i])
		
