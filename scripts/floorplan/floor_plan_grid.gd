extends RefCounted
class_name FloorPlanGrid

## Implements the room expansion algorithm for floor plan generation

var grid: Array[Array] = [] ## should be of type `Array[Array[FloorPlanCell]]`
var width: int = 0
var height: int = 0
var grid_resolution: int = 1
var origin: Vector2 = Vector2.ZERO

var _room_dict: Dictionary[Vector2i, RoomArea] = {} ## Stores the initial room position
var _room_bounds: Dictionary[int, Rect2i] = {} ## Stores the current rectangular bounds of each room


func _init(w: int, h: int, resolution: int = 1) -> void:
	print("    width:  ", w)
	print("    height: ", h)
	width = w
	height = h
	grid_resolution = resolution
	_initialize_grid()


## Initialize the grid with empty cells
func _initialize_grid() -> void:
	grid.clear()
	for y in range(height):
		var row: Array[FloorPlanCell] = []
		for x in range(width):
			row.append(FloorPlanCell.new())
		grid.append(row)

func _create_int_grid(initial_value:int = 0) -> Array[Array]:
	var int_grid: Array[Array] = [] ## should be of type `Array[Array[int]]`
	for y in range(height):
		var row: Array[int] = []
		for x in range(width):
			row.append(initial_value)
		int_grid.append(row)
	return int_grid


## Create grid from a list of boundary points
static func from_points(points: Array[Vector2], resolution: int = 1) -> FloorPlanGrid:
	assert(resolution>=1, "resoltion must be a natual number (e.g >= 1)")
	if points.is_empty():
		return null
	const padding: int = 1
	
	var bounds: Rect2 = _get_bounds(points)
	assert(bounds.is_finite(), "bounding box can't be infinite")
	var grid_size: Vector2 = snap2(bounds.end, 1.0/resolution)-snap2(bounds.position, 1.0/resolution) # get min grid dimension
	grid_size *= resolution # scale with resolution
	grid_size += Vector2.ONE*2*padding # add padding around the building grid

	
	var floor_grid: FloorPlanGrid = FloorPlanGrid.new(floor(grid_size).x, floor(grid_size).y, resolution)
	
	# Mark cells inside the polygon as empty, outside as OUTSIDE
	floor_grid.origin = snap2(bounds.position, 1.0/resolution) - Vector2.ONE*padding/resolution
	var world_pos: Vector2
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			world_pos = floor_grid.origin + Vector2(x, y)/resolution
			if not _is_point_in_polygon(world_pos, points):
				floor_grid.get_cell(x,y).set_outside()
	
	return floor_grid


static func snap(value: float, increment: float = 1) -> float:
	return floor(value/increment)*increment
	
static func snap2(value: Vector2, increment: float = 1) -> Vector2:
	return Vector2(
		snap(value.x, increment),
		snap(value.y, increment)
	)


## Get cell at position, returns null if out of bounds
func get_cell(x: int, y: int) -> FloorPlanCell:
	if x < 0 or x >= width or y < 0 or y >= height:
		return null
	return grid[y][x]

func set_cell(x: int, y: int, cell: FloorPlanCell) -> void:
	if x < 0 or x >= width or y < 0 or y >= height:
		return
	grid[y][x] = cell


## Check if a point is inside a polygon using ray casting algorithm
static func _is_point_in_polygon(point: Vector2, polygon: Array[Vector2]) -> bool:
	if polygon.size()<=2:
		return false
	
	var inside = false
	const d: Vector2 = Vector2(cos(PI/42), sin(PI/42))
	var v1: Vector2
	var v2: Vector2
	const v3: Vector2 = Vector2(-d.y, d.x)
	var t1: float
	var t2: float
	
	var current_point: Vector2 = polygon[-1]
	for next_point in polygon:
		v1 = point-current_point
		v2 = next_point-current_point
		t1 = v2.cross(v1)/v2.dot(v3)
		if t1>0: # ray points in direction of line (segment)
			t2 = v1.dot(v3)/v2.dot(v3)
			if t2>=0 and t2<1: # ray hits inbetween current_point (inclusive) and next_point (exlusive)
				inside = not inside
		
		current_point = next_point
	
	return inside


## returns the axis aligned bounding box of a given point list
static func _get_bounds(points: Array[Vector2]) -> Rect2:
	if points.is_empty():
		return Rect2()
	
	var min_bounds: Vector2 = Vector2.INF
	var max_bounds: Vector2 = -Vector2.INF
	
	for point in points:
		if point.x < min_bounds.x:
			min_bounds.x = point.x
		if point.x > max_bounds.x:
			max_bounds.x = point.x
		if point.y < min_bounds.y:
			min_bounds.y = point.y
		if point.y > max_bounds.y:
			max_bounds.y = point.y
	
	return Rect2(min_bounds, max_bounds-min_bounds)


## generaterandom initial room placements
func place_rooms(rooms: Array[RoomArea]) -> void:
	_room_dict = {}
	print("rooms: ", rooms)

	var dist_grid: Array[Array] = _get_outside_dists() # should be Array[Array[int]]

	print("  dist_grid:")
	
	var free_cells: int = _get_empty_cells()
	
	print("free_cells: ", free_cells)
	
	var room_dist_entropy: Array[Array] = _create_int_grid(0)

	for room in rooms:
		var room_radius: int = floor(sqrt(room.rel_size*free_cells)/2)
		var entropy: Array[Array] = []
		
		# optimal wall distance
		for y in range(dist_grid.size()):
			var row: Array[int] = []
			for x in range(dist_grid[y].size()):
				if dist_grid[y][x]<=0:
					row.append(-1)
				else:
					var dist: int = room_radius-dist_grid[y][x]
					#row.append(min(0, dist))
					row.append(abs(dist))
			entropy.append(row)
		
		# make rooms not be too close together
		entropy = _combine_entropy(entropy, room_dist_entropy)
		
		# makes neighoring rooms be closer together
		for y in range(entropy.size()):
			for x in range(entropy[y].size()):
				entropy[y][x]*=4 # TODO: check here
		entropy = _combine_entropy(entropy, _get_room_dists(room.connectivity))
		
		
		# select random from minimum
		var entropy_flattend: Array[int] = []
		for row in entropy:
			entropy_flattend.append_array(row)
		entropy_flattend.sort()
		var min_entropy = entropy_flattend[entropy_flattend.find_custom(func (x): return x>=0)]
		
		var valid_cells: Array[Vector2i] = []
		for y in range(len(entropy)):
			for x in range(len(entropy[y])):
				if entropy[y][x] == min_entropy:
					valid_cells.append(Vector2i(x, y))
		assert(not valid_cells.is_empty(), "valid_cells shouldn't be empty")
		var random_cell: Vector2i = valid_cells[randi()%valid_cells.size()]
		var initial_room_cell: FloorPlanCell = get_cell(random_cell.x, random_cell.y)
		assert(initial_room_cell.is_empty(), "selected cell should be empty")
		initial_room_cell.grow(room.id)
		
		_room_dict[random_cell] = room
		_room_bounds[room.id] = Rect2i(random_cell, Vector2i.ONE)
		
		# Update room dist_grid
		var queue: Array[Vector2i] = [random_cell]
		room_dist_entropy[random_cell.y][random_cell.x] = room_radius*2
		
		const directions: Array[Vector2i] = [
			Vector2i.RIGHT,   # right
			Vector2i.LEFT,  # left
			Vector2i.DOWN,   # down
			Vector2i.UP   # up
		]
		# BFS to calculate distances
		while not queue.is_empty():
			var pos: Vector2i = queue.pop_front()
			var current_entropy: int = room_dist_entropy[pos.y][pos.x]
			
			# Check all neighbors
			if current_entropy>0:
				for dir in directions:
					var nx: int = pos.x + dir.x
					var ny: int = pos.y + dir.y
					
					if nx < 0 or nx >= width or ny < 0 or ny >= height:
						continue # out of bounds
					if room_dist_entropy[ny][nx] >= current_entropy or room_dist_entropy[ny][nx]==-1:
						continue # already has a closer room
					
					# Set distance and add to queue
					room_dist_entropy[ny][nx] = current_entropy - 1
					queue.append(Vector2i(nx, ny))
					
		room_dist_entropy[random_cell.y][random_cell.x] = -1


func _combine_entropy(e1: Array[Array], e2: Array[Array]) -> Array[Array]:
	var result: Array[Array] = []
	for y in range(e1.size()):
		var row: Array[int] = []
		for x in range(e1[y].size()):
			row.append(-1 if e1[y][x]<0 or e2[y][x]<0 else e1[y][x]+e2[y][x])
		result.append(row)
	return result

func grow_rooms() -> void:
	var room_areas: Array[RoomArea] = _room_dict.values()
	var free_cells: int = _get_inside_cells()
	var goal_size: Dictionary[int, int] = {} # Dictionary[room_id, target_cell_count]
	var growable_rooms: Array[RoomArea]
	
	# Pre-calculate target size in cells for each room
	for room in room_areas:
		goal_size[room.id] = int(floor(room.rel_size * free_cells))
		
	# ---- Rectangular Growth ----
	growable_rooms = room_areas.duplicate()
	
	while not growable_rooms.is_empty():
		var room_to_grow: RoomArea = _get_most_deviant_room(growable_rooms)

		# Ensure the room has bounds (it should have been set in place_rooms)
		if not _room_bounds.has(room_to_grow.id):
			printerr("Room ", room_to_grow.id, " has no bounds! Skipping.")
			growable_rooms.erase(room_to_grow)
			continue
			
		var current_bounds: Rect2i = _room_bounds[room_to_grow.id]	
		var did_grow: bool = false
		
		# Start from a random direction to avoid directional bias
		var start_direction: int = randi() % 4 
		
		for i in range(4):
			var direction: int = (start_direction + i) % 4
			var rect_to_check: Rect2i
			
			match direction:
				0:  # left
					rect_to_check = Rect2i(current_bounds.position.x - 1, current_bounds.position.y, 1, current_bounds.size.y)
					if _can_grow_rect(rect_to_check):
						_fill_rect(room_to_grow.id, rect_to_check)
						_room_bounds[room_to_grow.id] = current_bounds.grow_individual(1, 0, 0, 0)
						did_grow = true
						break
				1:  # top
					rect_to_check = Rect2i(current_bounds.position.x, current_bounds.position.y - 1, current_bounds.size.x, 1)
					if _can_grow_rect(rect_to_check):
						_fill_rect(room_to_grow.id, rect_to_check)
						_room_bounds[room_to_grow.id] = current_bounds.grow_individual(0, 1, 0, 0)
						did_grow = true
						break
				2:  # right
					rect_to_check = Rect2i(current_bounds.end.x, current_bounds.position.y, 1, current_bounds.size.y)
					if _can_grow_rect(rect_to_check):
						_fill_rect(room_to_grow.id, rect_to_check)
						_room_bounds[room_to_grow.id] = current_bounds.grow_individual(0, 0, 1, 0)
						did_grow = true
						break
				3:  # bottom
					rect_to_check = Rect2i(current_bounds.position.x, current_bounds.end.y, current_bounds.size.x, 1)
					if _can_grow_rect(rect_to_check):
						_fill_rect(room_to_grow.id, rect_to_check)
						_room_bounds[room_to_grow.id] = current_bounds.grow_individual(0, 0, 0, 1)
						did_grow = true
						break
		
		if not did_grow:
			growable_rooms.erase(room_to_grow)
			
	
	# ----- L Shaped Growth ------
	growable_rooms = room_areas.duplicate()
	
	const start_directions: Array[Vector2i] = [
		Vector2i.RIGHT,
		Vector2i.LEFT,
		Vector2i.DOWN,
		Vector2i.UP,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,
	]
	const check_directions: Array[Vector2i] = [
		Vector2i.DOWN,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.LEFT,
		Vector2i.UP,
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.RIGHT,
	]
	
	while not growable_rooms.is_empty():
		
		var grow_base: Vector2i = Vector2i.ZERO
		var grow_room: RoomArea
		var grow_start_pos: Vector2i
		var grow_direction: Vector2i
		for room in growable_rooms:
			if not _room_bounds.has(room.id):
				printerr("Room %d has no bounds! Skipping." % room.id)
				growable_rooms.erase(room)
				continue
			
			var room_bounds: Rect2i = _room_bounds[room.id]
			
			# check all directions			
			var start_points: Array[Vector2i] = [ #                reverse of check_direction
				Vector2i(room_bounds.position.x, room_bounds.position.y) + Vector2i.UP,    # top (left)
				Vector2i(room_bounds.end.x-1,    room_bounds.position.y) + Vector2i.UP,    # top (right)
				Vector2i(room_bounds.end.x-1,    room_bounds.position.y) + Vector2i.RIGHT, # right (top)
				Vector2i(room_bounds.end.x-1,    room_bounds.end.y-1)    + Vector2i.RIGHT, # right (bottom)
				Vector2i(room_bounds.end.x-1,    room_bounds.end.y-1)    + Vector2i.DOWN,  # bottom (right)
				Vector2i(room_bounds.position.x, room_bounds.end.y-1)    + Vector2i.DOWN,  # bottom (left)
				Vector2i(room_bounds.position.x, room_bounds.end.y-1)    + Vector2i.LEFT,  # left (bottom)
				Vector2i(room_bounds.position.x, room_bounds.position.y) + Vector2i.LEFT,  # left (top)
			]
			var growth_width: int = 0
			var side_index: int = -1
			for i in range(8):
				var current_width: int = 0
				var x: int = start_points[i].x
				var y: int = start_points[i].y
				# check if current cell is empty, and if still neighboring the room
				var current_cell = get_cell(x,y)
				var check_cell = get_cell(x+check_directions[i].x,y+check_directions[i].y)
				if room.id==2 and i==1 :
					print(current_cell.room_id)
					print(check_cell.room_id)
				while((current_cell!=null and current_cell.is_empty()) and (check_cell!=null and check_cell.room_id==room.id)):
					current_width += 1
					x += start_directions[i].x
					y += start_directions[i].y
					current_cell = get_cell(x,y)
					check_cell = get_cell(x+check_directions[i].x,y+check_directions[i].y)
				
				if current_width>growth_width:
					growth_width = current_width
					side_index = i
				
			if growth_width>grow_base.length():
				grow_base = start_directions[side_index]*growth_width
				grow_room = room
				grow_start_pos = start_points[side_index]
				grow_direction = -check_directions[side_index]
		
		if grow_base != Vector2i.ZERO:

			var grow_rect: Rect2i = Rect2i(grow_start_pos, grow_base)
			var next_grow_rect: Rect2i = grow_rect
			next_grow_rect.size += grow_direction
			while (_can_grow_rect(next_grow_rect)):
				grow_rect = next_grow_rect
				next_grow_rect.size += grow_direction
			_fill_rect(grow_room.id, grow_rect)
			growable_rooms.erase(grow_room)
			print(grow_rect)
		else:
			break
			
	
	# ----- Fill Empty Space -----
	# Find all connected components of empty cells (holes)
	var holes: Array[Array] = _find_empty_holes()  # Array of Array[Vector2i]
	
	for hole in holes:
		if hole.is_empty():
			continue
			
		# Count which room borders this hole the most
		var border_counts: Dictionary = {}  # Dictionary[int, int] - room_id -> border_cell_count
		
		for pos in hole:
			# Check all neighbors of this empty cell
			for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
				var neighbor_pos: Vector2i = pos + dir
				var neighbor_cell: FloorPlanCell = get_cell(neighbor_pos.x, neighbor_pos.y)
				
				# If neighbor is a room (not empty, not outside, not null)
				if neighbor_cell != null and not neighbor_cell.is_empty() and not neighbor_cell.is_outside():
					var room_id: int = neighbor_cell.room_id
					if not border_counts.has(room_id):
						border_counts[room_id] = 0
					border_counts[room_id] += 1
		
		# Find the room with the most border cells
		var max_border_count: int = 0
		var dominant_room_id: int = -1
		
		for room_id in border_counts.keys():
			if border_counts[room_id] > max_border_count:
				max_border_count = border_counts[room_id]
				dominant_room_id = room_id
		
		# Fill the hole with the dominant room
		if dominant_room_id != -1:
			for pos in hole:
				var cell: FloorPlanCell = get_cell(pos.x, pos.y)
				if cell != null and cell.is_empty():
					cell.grow(dominant_room_id)


## Find all connected components of empty cells using flood fill
func _find_empty_holes() -> Array[Array]:
	var visited: Array[Array] = _create_int_grid(0)  # 0 = not visited, 1 = visited
	var holes: Array[Array] = []  # Array of Array[Vector2i]
	
	for y in range(height):
		for x in range(width):
			var cell: FloorPlanCell = get_cell(x, y)
			
			# Start flood fill from unvisited empty cells
			if visited[y][x] == 0 and cell.is_empty():
				var hole: Array[Vector2i] = []
				var queue: Array[Vector2i] = [Vector2i(x, y)]
				visited[y][x] = 1
				
				# BFS to find all connected empty cells
				while not queue.is_empty():
					var pos: Vector2i = queue.pop_front()
					hole.append(pos)
					
					# Check all 4 neighbors
					for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
						var nx: int = pos.x + dir.x
						var ny: int = pos.y + dir.y
						
						# Skip if out of bounds or already visited
						if nx < 0 or nx >= width or ny < 0 or ny >= height:
							continue
						if visited[ny][nx] == 1:
							continue
						
						var neighbor_cell: FloorPlanCell = get_cell(nx, ny)
						
						# Only continue flood fill if neighbor is also empty
						if neighbor_cell.is_empty():
							visited[ny][nx] = 1
							queue.append(Vector2i(nx, ny))
				
				holes.append(hole)
	
	return holes


## Checks if all cells within a given rectangle are empty and growable
func _can_grow_rect(rect: Rect2i) -> bool:
	var x_dir: int = -1 if rect.size.x<0 else 1
	var y_dir: int = -1 if rect.size.y<0 else 1
	
	for y in range(rect.position.y, rect.end.y, y_dir):
		for x in range(rect.position.x, rect.end.x, x_dir):
			var cell: FloorPlanCell = get_cell(x, y)
			if cell == null or not cell.is_empty():
				return false
	return true


## Sets all cells within a given rectangle to a specific room ID
func _fill_rect(room_id: int, rect: Rect2i) -> void:
	var x_dir: int = -1 if rect.size.x<0 else 1
	var y_dir: int = -1 if rect.size.y<0 else 1
	
	for y in range(rect.position.y, rect.end.y, y_dir):
		for x in range(rect.position.x, rect.end.x, x_dir):
			var cell: FloorPlanCell = get_cell(x, y)
			if cell != null:
				cell.grow(room_id)


## returns cell count of this `RoomArea`
func _get_room_cells(room: RoomArea) -> int:
	var area: int = 0
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if get_cell(x,y).room_id == room.id:
				area += 1
	return area

## positive deviation means room is to small, and negative deviation means the opposite
func _compare_deviation(a: RoomArea, b: RoomArea, ) -> bool:
	var inside_cells: int = _get_inside_cells()
	var deviataion_a: float = a.rel_size - _get_room_cells(a)/float(inside_cells)
	var deviataion_b: float = b.rel_size - _get_room_cells(b)/float(inside_cells)
	return deviataion_a > deviataion_b
	


func _get_most_deviant_room(rooms: Array[RoomArea])-> RoomArea:
	rooms.sort_custom(_compare_deviation)
	return rooms[0]


func _get_inside_cells() -> int:
	var free_cells: int = 0
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if not get_cell(x,y).is_outside():
				free_cells += 1
	return free_cells


func _get_empty_cells() -> int:
	var free_cells: int = 0
	for y in range(grid.size()):
		for x in range(grid[y].size()):
			if get_cell(x,y).is_empty():
				free_cells += 1
	return free_cells


func _get_outside_dists() -> Array[Array]:
	var dist_grid: Array[Array] = _create_int_grid(-1)  # -1 means unvisited
	var queue: Array[Vector2i] = []
	
	# Initialize: add all outside cells to queue with distance 0
	for y in range(height):
		for x in range(width):
			if get_cell(x, y).is_outside():
				dist_grid[y][x] = 0
				queue.append(Vector2i(x, y))
	
	var directions: Array[Vector2i] = [
		Vector2i(1, 0),   # right
		Vector2i(-1, 0),  # left
		Vector2i(0, 1),   # down
		Vector2i(0, -1)   # up
	]
	# BFS to calculate distances
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_front()
		var current_dist: int = dist_grid[pos.y][pos.x]
		
		# Check all neighbors
		for dir in directions:
			var nx: int = pos.x + dir.x
			var ny: int = pos.y + dir.y
			
			# Skip if out of bounds or already visited
			if nx < 0 or nx >= width or ny < 0 or ny >= height:
				continue
			if dist_grid[ny][nx] != -1:
				continue
			
			# Set distance and add to queue
			dist_grid[ny][nx] = current_dist + 1
			queue.append(Vector2i(nx, ny))
	
	return dist_grid

func _get_room_dists(room_ids: Array[int]) -> Array[Array]:
	var dist_grid: Array[Array] = _create_int_grid(-1)  # -1 means unvisited
	var queue: Array[Vector2i] = []
	
	# Initialize: add all outside cells to queue with distance 0
	for y in range(height):
		for x in range(width):
			if room_ids.find(get_cell(x, y).room_id) >= 0:
				dist_grid[y][x] = 0
				queue.append(Vector2i(x, y))
	
	var directions: Array[Vector2i] = [
		Vector2i(1, 0),   # right
		Vector2i(-1, 0),  # left
		Vector2i(0, 1),   # down
		Vector2i(0, -1)   # up
	]
	
	# doesn't contain any room with id==room_-id
	if queue.is_empty():
		return _create_int_grid(0)
	
	# BFS to calculate distances
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_front()
		var current_dist: int = dist_grid[pos.y][pos.x]
		
		# Check all neighbors
		for dir in directions:
			var nx: int = pos.x + dir.x
			var ny: int = pos.y + dir.y
			
			# Skip if out of bounds or already visited
			if nx < 0 or nx >= width or ny < 0 or ny >= height:
				continue
			if dist_grid[ny][nx] != -1:
				continue
			
			# Set distance and add to queue
			dist_grid[ny][nx] = current_dist + 1
			queue.append(Vector2i(nx, ny))
	
	return dist_grid


func get_rooms() -> Array[int]:
	var rooms: Array[int] = []
	for y in range(height):
		for x in range(width):
			var cell: FloorPlanCell = get_cell(x, y)
			if not cell.is_empty() and not cell.is_outside() and cell.room_id not in rooms:
				rooms.append(cell.room_id)
	rooms.sort()
	return rooms


func get_subdivided_grid() -> FloorPlanGrid:
	var new_width: int = width * 2
	var new_height: int = height * 2
	var new_grid: FloorPlanGrid = FloorPlanGrid.new(new_width, new_height, grid_resolution)
	
	for y in range(height):
		for x in range(width):
			var old_cell: FloorPlanCell = get_cell(x, y)
			new_grid.set_cell(x*2,     y*2,     old_cell) # top-left
			new_grid.set_cell(x*2 + 1, y*2,     old_cell) # top-right
			new_grid.set_cell(x*2,     y*2 + 1, old_cell) # bottom-left
			new_grid.set_cell(x*2 + 1, y*2 + 1, old_cell) # bottom-right
	
	return new_grid


func to_texture() -> Image:
	var rooms: Array[int] = get_rooms()
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGB8)
	for y in range(height):
		for x in range(width):
			var cell: FloorPlanCell = get_cell(x, y)
			if cell.is_outside():
				image.set_pixel(x, y, Color.from_rgba8(35, 39, 46))
			elif cell.is_empty():
				image.set_pixel(x, y, Color.from_rgba8(255, 0, 255))
			else:
				var hue: float = rooms.find(cell.room_id)/float(rooms.size())
				image.set_pixel(x, y, Color.from_ok_hsl(hue, 66/100.0, 55/100.0))
	return image


## Debug: Print grid
func print_grid() -> void:
	for y: int in range(height):
		var row_str: String = ""
		for x: int in range(width):
			var cell: FloorPlanCell = get_cell(x,y)
			if cell.is_outside():
				row_str += " X "
			elif cell.is_empty():
				row_str += " . "
			else:
				row_str += "%2d " % cell.room_id
		print(row_str)

## Debug: Print grid
func debug_print_mat2(mat2: Array[Array]) -> void:
	for y: int in range(mat2.size()):
		var row_str: String = ""
		for x: int in range(mat2[y].size()):
			if mat2[y][x] == -1:
				row_str += "- "
			else:
				row_str += str(mat2[y][x]) + " "
		print(row_str)
