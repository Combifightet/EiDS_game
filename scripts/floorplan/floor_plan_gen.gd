extends RefCounted
class_name FloorPlanGen

enum HouseSize {SMALL, NORMAL, LARGE}
enum Direction {N=0, E=1, S=2, W=3}

const DIRECTION_VECTORS: Dictionary[Direction, Vector2] = {
	Direction.N: Vector2.UP,
	Direction.E: Vector2.RIGHT,
	Direction.S: Vector2.DOWN,
	Direction.W: Vector2.LEFT,
}
const VECTOR_DIRECTIONS: Dictionary[Vector2, Direction] = {
	Vector2.UP: Direction.N,
	Vector2.RIGHT: Direction.E,
	Vector2.DOWN: Direction.S,
	Vector2.LEFT: Direction.W
}

var building_outline: Array[Vector2] = []


var _seed: int = -1
var _last_seed: int = -1

# subdivision count of "standard" unit grid
var _outline_grid_resolution: int = 1
var _room_grid_resolution: int =  2

var _floorplan_grid: FloorPlanGrid

var _doors_list: Array[Door] = []

const _initial_vertecies: Dictionary[HouseSize, int] = {
	HouseSize.SMALL:  3,
	HouseSize.NORMAL: 6,
	HouseSize.LARGE:  11,
}
const _randomness: Dictionary[HouseSize, float] = {
	HouseSize.SMALL:  0.4,
	HouseSize.NORMAL: 0.6,
	HouseSize.LARGE:  0.9,
}
const _house_radius: Dictionary[HouseSize, float] = {
	HouseSize.SMALL:  4,
	HouseSize.NORMAL: 6,
	HouseSize.LARGE:  9,
}
const _min_rooms: Dictionary[HouseSize, int] = {
	HouseSize.SMALL:  3,
	HouseSize.NORMAL: 5,
	HouseSize.LARGE:  8,
}
const _max_rooms: Dictionary[HouseSize, int] = {
	HouseSize.SMALL:  5,
	HouseSize.NORMAL: 8,
	HouseSize.LARGE:  14,
}

func _init(grid_resolution: int = 1, grid_subdivisions: int = 2) -> void:
	assert(grid_resolution>0, "grid resolution must be a positive value")
	_outline_grid_resolution = grid_resolution
	_room_grid_resolution = grid_resolution*grid_subdivisions

## Returns a random floating point-value between `min_value` and `1.0` (inclusive) 
static func randf_min(min_value: float) -> float:
	min_value = clamp(min_value, 0, 1)
	return randf()*min_value+(1-min_value)

func _get_invalid_dir(vec: Vector2) -> Direction:
	var invalid_dir: Direction
	if abs(vec.x) >= abs(vec.y):
		if vec.x >= 0:
			invalid_dir = Direction.N
		else:
			invalid_dir = Direction.S
	else:
		if vec.y >= 0:
			invalid_dir = Direction.E
		else:
			invalid_dir = Direction.W
	return invalid_dir

func _get_rand_valid_travel_direction(vec: Vector2, incoming_dir: int = -1) -> Direction:
	var invalid_dir: Direction = _get_invalid_dir(vec)
	var invalid_dir_2: Direction = _get_invalid_dir(vec.rotated(2*PI/16))
	if invalid_dir_2==invalid_dir:
		invalid_dir_2 = _get_invalid_dir(vec.rotated(-2*PI/16))

	var output_dir: Direction
	if incoming_dir == -1:
		@warning_ignore("integer_division") 
		output_dir = (invalid_dir+len(Direction)/2)%len(Direction) as Direction
	else:
		output_dir = randi_range(0, len(Direction)-1) as Direction
	# flip direction if it is invalid
	if output_dir == invalid_dir:
		@warning_ignore("integer_division") 
		output_dir = (output_dir+len(Direction)/2)%len(Direction)  as Direction
	if invalid_dir_2!=invalid_dir and output_dir == invalid_dir_2:
		@warning_ignore("integer_division") 
		output_dir = (output_dir+len(Direction)/2)%len(Direction)  as Direction
		
	# if selected output direction is the input direction rotate input clockwise untill not inside the invalid_dir
	@warning_ignore("integer_division") 
	if incoming_dir != -1 and output_dir == (incoming_dir+len(Direction)/2)%len(Direction):
		# assert(len(Direction)>=3, "Need at least 3 directions or this might be a `while true:` loop")
		while true:
			output_dir = (output_dir+1)%len(Direction) as Direction
			@warning_ignore("integer_division") 
			if output_dir!=invalid_dir and output_dir!=invalid_dir_2 and output_dir!=(incoming_dir+len(Direction)/2)%len(Direction):
				break
	
	return output_dir

func _get_connection_points(point_a: Vector2, point_b: Vector2, start_direction: Vector2) -> Array[Vector2]:
	# cheack weather the connection needs zero, one or two intermediate points and return them
	if is_equal_approx(point_a.x, point_b.x) or is_equal_approx(point_a.y, point_b.y):
		return []
	elif start_direction.x*(point_b.x-point_a.x) > 0 or start_direction.y*(point_b.y-point_a.y) > 0:
		return [
			Vector2(
				point_a + Vector2((point_b.x-point_a.x) * abs(start_direction.x),
				(point_b.y-point_a.y) * abs(start_direction.y))
			)
		]
	else:
		var result: Array[Vector2] = [Vector2(point_a - Vector2((point_b.x-point_a.x) * abs(start_direction.x),
			(point_b.y-point_a.y) * abs(start_direction.y))
		)]
		result.append(2*result[0]+point_b-2*point_a	)
		return result

func _generate_building_outline(vertices: int = 7, randomness: float = 0.8, radius: float = 5) -> Array[Vector2]:
	var dists: Array[float] = [0]
	var total_dist: float = 0
	for i in range(1, vertices):
		dists.append(dists[-1]+randf_min(randomness))
	total_dist = dists[-1]+randf_min(randomness)
	
	var points: Array[Vector2] = []
	for point in dists:
		points.append((Vector2.from_angle(point/total_dist*2*PI) * radius).snapped(Vector2.ONE*_outline_grid_resolution))
	var result: Array[Vector2] = []
	var incoming_dir: int = -1
	
	for i in range(points.size()):
		var point_a = points[i]
		var point_b = points[(i + 1) % points.size()]
		
		result.append(point_a)
		
		# Base direction on vector to next point
		var vec_to_next = (point_b - point_a)
		if vec_to_next.is_zero_approx():
			print('ERROR POINTS ARE IDENTICAL')
			vec_to_next = Vector2.UP # Default if points are the same
			
		var travel_dir: Direction = _get_rand_valid_travel_direction(point_a, incoming_dir)
		var travel_vec: Vector2 = DIRECTION_VECTORS[travel_dir]
		
		result.append_array(_get_connection_points(point_a, point_b, travel_vec))
		
		var incoming_vec: Vector2 = points[(i+1)%len(points)]-result[-1]
		incoming_vec = incoming_vec.normalized()
		if incoming_vec.is_equal_approx(Vector2.ZERO):
			incoming_dir = -1
		else:
			incoming_dir = VECTOR_DIRECTIONS[incoming_vec]
	
	return result


func _generate_room_areas(room_count: int = 5, randomness: float = 1) -> Array[RoomArea]:
	var graph: Graph = Graph.get_connected(room_count, true, 1)
	var mst_graph: Graph = graph.get_mst()
	print(mst_graph.to_dot("MstGraph"))
	print(mst_graph.nodes)
	return RoomArea.from_graph(mst_graph, randomness, _seed)



## Sets the seed for the random number generator to `base`.
## A value of `-1` means no seed
func set_seed(base: int = -1) -> void:
	_seed = base
	seed(4)

func get_seed() -> int:
	return _seed

func get_last_seed() -> int:
	return _last_seed

func get_grid() -> FloorPlanGrid:
	return _floorplan_grid

## Generates a new floor plan for a predefined building size
func generate(size: HouseSize) -> void:
	if _seed == -1:
		randomize()
		_last_seed = randi()
		seed(_last_seed)
	else:
		_last_seed = _seed
		seed(_seed)
	
	generate_custom(
		_initial_vertecies[size],
		_randomness[size],
		_house_radius[size],
		randi_range(_min_rooms[size], _max_rooms[size])
	)

## Generates a new floor plan for a custom building.
func generate_custom(initial_vertecies: int = 6, randomness: float = 0.6, radius: float = 6, room_count: int = 6) -> void:
	print("############################## ", room_count)
	print("generating floorplan ...")
	if _seed == -1:
		randomize()
		_last_seed = randi()
		seed(_last_seed)
	else:
		_last_seed = _seed
		seed(_seed)
	
	print("  generating outline ...")
	building_outline = _generate_building_outline(
		initial_vertecies,
		randomness,
		radius,
	)
	
	print("  generating grid ...")
	_floorplan_grid = FloorPlanGrid.from_points(building_outline, _room_grid_resolution)
	print("    printing grid ...")
	FloorPlanGrid.print_grid(_floorplan_grid)
	
	print("  generating room set (", room_count, ") ...")
	var rooms: Array[RoomArea] = _generate_room_areas(room_count, randomness)
	print("    rooms: ", rooms)
	print("  generating intial room positions ...")
	_floorplan_grid.place_rooms(rooms)
	print("  growing rooms ...")
	_floorplan_grid.grow_rooms()
	print("  placing doors ...")
	_generate_doors()
	# print("  placing inner doors ...")
	# print("  placing windows") # optional
	# print("  placing entrance door")
	# FloorPlanGrid.print_grid(_floorplan_grid)

func _generate_doors():
	var connectivity_dict: Dictionary[int, Array] = {}
	var centers_dict: Dictionary[int, Vector2] = {}
	var cell_count_dict: Dictionary[int, int] = {}
	var grid: Array[Array] = _floorplan_grid.grid
	var directions: Array[Vector2i] = [
		Vector2i.LEFT,
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.DOWN,
	]
	
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var cell: FloorPlanCell = grid[y][x]
			if cell.is_empty():
				continue
			if connectivity_dict.keys().find(cell.room_id) < 0:
				connectivity_dict[cell.room_id] = []
				centers_dict[cell.room_id] = Vector2.ZERO
				cell_count_dict[cell.room_id] = 0
			
			centers_dict[cell.room_id] += Vector2(x, y)
			cell_count_dict[cell.room_id] += 1 

			for dir in directions:
				var n_x: int = x+dir.x
				var n_y: int = y+dir.y
				if n_x<0 or n_x>=grid[y].size() or n_y<0 or n_y>=grid.size():
					continue
				var n_cell: FloorPlanCell = grid[n_y][n_x]
				if n_cell.room_id == cell.room_id:
					continue
				if connectivity_dict[cell.room_id].find(n_cell.room_id) < 0:
					connectivity_dict[cell.room_id].append(n_cell.room_id)
	for key in centers_dict.keys():
		centers_dict[key] /= cell_count_dict[key]
	
	var doors_graph: Graph = Graph.new(true)
	doors_graph.nodes = connectivity_dict.keys()
	for node in doors_graph.nodes:
		print(connectivity_dict[node])
		for conn in connectivity_dict[node]:
			var dist: float = (centers_dict[conn]-centers_dict[node]).length()
			if conn==-1 or node==-1:
				dist = 1_000_000_000
			doors_graph.edges.append(Graph.Edge.new(node, conn, dist))
	
	# ensure that each room is reachable
	var doors_mst_graph: Graph = doors_graph.get_mst()
	print(doors_mst_graph.to_dot("doors_mst_graph"))
	for edge in doors_mst_graph.edges:
		var selected_door: Door = _select_door(edge.start, edge.end)
		if selected_door!=null:
			_doors_list.append(selected_door)
	
	# remove duplicate edges
	var i: int = 0
	while i<len(doors_graph.edges):
		var index: int = doors_graph.edges.rfind_custom(func(edge: Graph.Edge): return edge.start==doors_graph.edges[i].end and edge.end==doors_graph.edges[i].start)
		if index > i:
			doors_graph.edges.remove_at(index)
		i += 1
	
	# add some more random connections
	for _i in range(roundi(len(doors_mst_graph.edges)*2)):
		if len(doors_graph.edges)>=0:
			break
		doors_graph.edges.remove_at(randi()%len(doors_graph.edges))
	
	
	for edge in doors_graph.edges:
		if edge.start==FloorPlanCell.OUTSIDE or edge.end==FloorPlanCell.OUTSIDE:
			continue
		if edge.start==FloorPlanCell.NO_ROOM or edge.end==FloorPlanCell.NO_ROOM:
			continue
		if _doors_list.any(func(door): return (door.from_id==edge.start and door.to_id==edge.end) or (door.from_id==edge.end and door.to_id==edge.start)):
			continue
		var selected_door: Door = _select_door(edge.start, edge.end)
		if selected_door!=null:
			_doors_list.append(selected_door)
			print("added an extra door")


func _select_door(id_a: int, id_b: int) -> Door:
	var grid: Array[Array] = _floorplan_grid.grid
	var directions: Array[Vector2i] = [
		Vector2i.LEFT,
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.DOWN,
	]
	
	var possible_doors: Array[Door] = []
	
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var cell: FloorPlanCell = grid[y][x]
			if cell.is_empty():
				continue
			if cell.room_id==id_a or cell.room_id==id_b:
				for dir in directions:
					var n_x: int = x+dir.x
					var n_y: int = y+dir.y
					if n_x<0 or n_x>=grid[y].size() or n_y<0 or n_y>=grid.size():
						continue
					var n_cell: FloorPlanCell = grid[n_y][n_x]
					if n_cell.room_id!=cell.room_id and (n_cell.room_id==id_a or n_cell.room_id==id_b):
						possible_doors.append(Door.new(
							Vector2i(x, y),     # cell.room_id,
							Vector2i(n_x, n_y), # n_cell.room_id,
							id_a,
							id_b,
							cell.is_outside() or n_cell.is_outside()
						))
	
	return _select_best_door(possible_doors)


func _select_best_door(doors: Array[Door]) -> Door:
	var grid: Array[Array] = _floorplan_grid.grid
	doors.shuffle()
	var best_score: float = -1
	var best_door: Door
	for door in doors:
		var ab: Vector2i = door.to-door.from
		var ba: Vector2i = door.to-door.from
		var current_score: int = 0
		if grid[door.from.y][door.from.x].room_id == grid[door.from.y+ab.x][door.from.x-ab.y].room_id:
			current_score += 1 # from (left)
		if grid[door.from.y][door.from.x].room_id == grid[door.from.y-ab.x][door.from.x+ab.y].room_id:
			current_score += 1 # from (right)
		if grid[door.to.y][door.to.x].room_id == grid[door.to.y+ba.x][door.to.x-ba.y].room_id:
			current_score += 1 # to (left)
		if grid[door.to.y][door.to.x].room_id == grid[door.to.y-ba.x][door.to.x+ba.y].room_id:
			current_score += 1 # to (right)
		
		if current_score == 4: # already found an optimal door
			return door
		if current_score < best_score:
			best_score = current_score
			best_door = door
	return best_door

static func subdivide_doors(door_list: Array[Door]) -> Array[Door]:
	var new_doors: Array[Door] = []

	for door in door_list:
		
		if door.from.x == door.to.x:
			# vertical door
			new_doors.append(Door.new(
				door.from * 2 + (Vector2i(0,1) if door.from.y < door.to.y else Vector2i.ZERO),
				door.to   * 2 + (Vector2i.ZERO if door.from.y < door.to.y else Vector2i(0,1)),
				door.from_id,
				door.to_id,
				door.outside_door
			))
			new_doors.append(Door.new(
				door.from * 2 + (Vector2i.ONE if door.from.y < door.to.y else Vector2i(1,0)),
				door.to   * 2 + (Vector2i(1,0) if door.from.y < door.to.y else Vector2i.ONE),
				door.from_id,
				door.to_id,
				door.outside_door
			))
		else:
			# horizontal door
			new_doors.append(Door.new(
				door.from * 2 + (Vector2i(1,0) if door.from.x < door.to.x else Vector2i.ZERO),
				door.to   * 2 + (Vector2i.ZERO if door.from.x < door.to.x else Vector2i(1,0)),
				door.from_id,
				door.to_id,
				door.outside_door
			))
			new_doors.append(Door.new(
				door.from * 2 + (Vector2i.ONE if door.from.x < door.to.x else Vector2i(0,1)),
				door.to   * 2 + (Vector2i(0,1) if door.from.x < door.to.x else Vector2i.ONE),
				door.from_id,
				door.to_id,
				door.outside_door
			))
	
	return new_doors

static func get_connectivity_dict(floorplan_grid: FloorPlanGrid, doors: Array[Door], subdivisions: int = 0) -> Dictionary[Vector2i, Array]:
	var temp_grid: FloorPlanGrid = floorplan_grid

	# subdivide the grid if needed
	for _i in range(subdivisions):
		temp_grid = temp_grid.get_subdivided_grid()


	var connectivity_dict: Dictionary[Vector2i, Array] = {}
	# Test direction
	var directions: Array[Vector2i] = [
		Vector2i.LEFT+Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.UP+Vector2i.LEFT,
		Vector2i.UP,
		Vector2i.RIGHT+Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.DOWN+Vector2i.RIGHT,
		Vector2i.DOWN,
	]
	
	var grid: Array[Array] = temp_grid.grid
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			var cell: FloorPlanCell = grid[y][x]
			if cell.is_empty():
				continue
			
			connectivity_dict[Vector2i(x, y)] = []
			
			for dir in directions:
				var n_x: int = x+dir.x
				var n_y: int = y+dir.y
				if n_x<0 or n_x>=grid[y].size() or n_y<0 or n_y>=grid.size():
					continue
				if cell.room_id == grid[n_y][n_x].room_id:
					connectivity_dict[Vector2i(x,y)].append(Vector2i(n_x, n_y))
	
	# subdivide the doors if needed
	var temp_doors: Array[Door] = doors
	print()
	print(temp_doors)
	for _i in range(subdivisions):
		temp_doors = subdivide_doors(temp_doors)
		print()
		print(temp_doors)
	print()

	for door in temp_doors:
		connectivity_dict[door.from].append(door.to)
		connectivity_dict[door.to].append(door.from)

		# merge adjacent doors:
		if door.from.x == door.to.x:
			# vertical door
			# check if there is another door to the right
			if temp_doors.any(
				func(d: Door): return d.from == door.from + Vector2i(1,0) and \
									  d.to   == door.to   + Vector2i(1,0)):
				connectivity_dict[door.from].append(door.to + Vector2i(1,0))
				connectivity_dict[door.from + Vector2i(1,0)].append(door.to)
				connectivity_dict[door.to].append(door.from + Vector2i(1,0))
				connectivity_dict[door.to + Vector2i(1,0)].append(door.from)
		else:
			# horizontal door
			# chekc if there is another door below
			if temp_doors.any(
				func(d: Door): return d.from == door.from + Vector2i(0,1) and \
									  d.to   == door.to   + Vector2i(0,1)):
				connectivity_dict[door.from].append(door.to + Vector2i(0,1))
				connectivity_dict[door.from + Vector2i(0,1)].append(door.to)
				connectivity_dict[door.to].append(door.from + Vector2i(0,1))
				connectivity_dict[door.to + Vector2i(0,1)].append(door.from)
	
	return connectivity_dict



class Door extends RefCounted:
	var from: Vector2i ## outside cell
	var to: Vector2i   ## inside cell
	var from_id: int
	var to_id: int
	var outside_door: bool = false
	
	@warning_ignore("shadowed_variable")
	func _init(from: Vector2i, to: Vector2i, from_id: int, to_id: int, outside_door: bool = false) -> void:
		self.from = from
		self.to = to
		self.from_id = from_id
		self.to_id = to_id
		self.outside_door = outside_door
	
	func _to_string() -> String:
		return str("Door(from: ",from,"[", from_id ,"], to: ",to,"[", to_id ,"])")
