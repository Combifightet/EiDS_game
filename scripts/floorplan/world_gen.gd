extends RefCounted
class_name WorldGen

const BORDER_DIST: float = 10 ##average distance of the border (affected by `NOISE_STRENGTH`)
const NOISE_STRENGTH: float = 2 ## will be in the range of `± n`
const NOISE_SCALE: float = 10
const SEED: int = -1

const _EPSILON = 0.0001 ## to make float comparison be more forgiving

var grid: FloorPlanGrid
var doors: Array[FloorPlanGen.Door] = []

var _padding: int = 0

#const characters: Array[String] = [
	#"  ",
	#"░░",
	#"▒▒",
	#"▓▓",
	#"██",
#]

func _init(floorplan: FloorPlanGrid, door_list: Array[FloorPlanGen.Door], outline: Array[Vector2]) -> void:
	grid = _generate_map(floorplan, outline)
	doors = _padd_doors(door_list)

func _generate_map(floorplan: FloorPlanGrid, outline: Array[Vector2]) -> FloorPlanGrid:
	_padding = ceili(BORDER_DIST + abs(NOISE_STRENGTH) + 1)
	
	## Generate empty floor plan grid based on the convex hull
	var temp_floor_plan: FloorPlanGrid = FloorPlanGrid.from_points(
		convex_hull(outline, false),
		floorplan.grid_resolution
	)
	var temp_grid: Array[Array] = temp_floor_plan.grid
	
	## Setup empty distance map
	var queue: Array[Vector2i] = []
	var dist_grid: Array[Array] # should be Array[Array[float]
	dist_grid = []
	for y in range(-_padding, len(temp_grid) + _padding):
		dist_grid.append([])
		for x in range(-_padding, len(temp_grid[0]) + _padding):
			if (y >= 0 and y < len(temp_grid)) and (x>=0 and x < len(temp_grid[y])):
				dist_grid[y+_padding].append(0)
				queue.append(Vector2i(x+_padding, y+_padding))
			else:
				dist_grid[y+_padding].append(INF)
	
	
	#print("\nDistance Grid: (before)")
	#FloorPlanGrid.debug_print_mat2(dist_grid)
	
	## Filll distance map using BFS (might also be Daikstra (I have no idea anymore .-.))
	var directions: Array[Vector2i] = [
		Vector2i( 0,  1),   # top
		Vector2i( 1,  1),   # top-right
		Vector2i( 1,  0),   # right
		Vector2i( 1, -1),   # bottom-right
		Vector2i( 0, -1),   # bottom
		Vector2i(-1, -1),   # bottom-left
		Vector2i(-1,  0),   # left
		Vector2i(-1,  1)    # top-left
	]
	var height: int = len(dist_grid)
	var width: int  = len(dist_grid[0])
	# BFS to calculate distances
	while not queue.is_empty():
		var pos: Vector2i = queue.pop_front()
		var current_dist: float = dist_grid[pos.y][pos.x]
		
		# Check all neighbors
		for dir in directions:
			var nx: int = pos.x + dir.x
			var ny: int = pos.y + dir.y
			
			var dist: float = dir.length()
			
			# Skip if out of bounds
			if nx < 0 or nx >= width or ny < 0 or ny >= height:
				continue
			# Skip if already has a shorter path
			if dist_grid[ny][nx] <= current_dist+dist + _EPSILON:
				continue
			
			# Set distance and add to queue
			dist_grid[ny][nx] = current_dist + dist
			queue.append(Vector2i(nx, ny))
	
	#print("\nDistance Grid:")
	#FloorPlanGrid.debug_print_mat2(dist_grid)
	
	
	## Offset using 2d Symplex Noise to make the look more natural 
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	if SEED >= 0:
		noise.seed = SEED
	else:
		randomize()
		noise.seed = randi()
	
	for y in range(height):
		for x in range(width):
			var value: float = noise.get_noise_2d((x)*NOISE_SCALE, (y)*NOISE_SCALE)
			value *= NOISE_STRENGTH
			
			if dist_grid[y][x] + value < BORDER_DIST:
				dist_grid[y][x] = FloorPlanCell.OUTSIDE
			else:
				dist_grid[y][x] = FloorPlanCell.NO_ROOM
			
	#print("\nWorld Grid: (after)")
	#FloorPlanGrid.debug_print_mat2(dist_grid)
	
	
	## convert 2D dist Array to 2D FloorPlanCell Array
	## And place original romms in the center again
	var final_height: int = len(dist_grid)
	var final_width: int  = len(dist_grid[0])
	var result: FloorPlanGrid = FloorPlanGrid.new(
		final_width,
		final_height,
		floorplan.grid_resolution
	) # grid will be initialized with empty cells
	result.origin = floorplan.origin
	for key: Vector2i in floorplan._room_dict:
		result._room_dict[key+Vector2i.ONE*_padding] = floorplan._room_dict[key]
	for key: int in floorplan._room_bounds:
		result._room_bounds[key] = floorplan._room_bounds[key]
		result._room_bounds[key].position += Vector2i.ONE*_padding

	for y in range(final_height):
		for x in range(final_width):
			# coordinate is outside the orinial map
			if (y<_padding or y>=final_height-_padding) or (x<_padding or x>=final_width-_padding):
				result.grid[y][x].room_id = dist_grid[y][x]
			else:
				result.grid[y][x].room_id = floorplan.grid[y-_padding][x-_padding].room_id
			
	#print("\nWorld Grid: (final)")
	#FloorPlanGrid.print_grid(result)
	
	
	## Finaly return a result
	return result



func _padd_doors(door_list: Array[FloorPlanGen.Door]) -> Array[FloorPlanGen.Door]:
	for door in door_list:
		door.from += Vector2i.ONE*_padding
		door.to   += Vector2i.ONE*_padding
	return door_list
	
	
	
## This only works reliable for a non intersecting wound polygon
##  could be more efficient, but should be alright
static func convex_hull(points: Array[Vector2], clockwies: bool = true) -> Array[Vector2]:
	if len(points) <= 3:
		return points
	
	if not clockwies:
		points.reverse()
	
	var smth_changed: bool = false
	while not smth_changed:
		smth_changed = false
	
		var hull: Array[Vector2] = []
		
		var point = points[-1]
		var incoming_vec: Vector2 = point-points[-2]
		var outgoing_vec: Vector2
		for next_point in points:
			outgoing_vec = next_point-point
			
			var angle: float = angle_difference(incoming_vec.angle(), outgoing_vec.angle())
			# TODO: not really sure if this works as intended
			print("incoming_vec: ", incoming_vec)
			print("outgoing_vec: ", outgoing_vec)
			print("  angle: ", angle)
			
			if angle < 0:
				hull.append(point)
			else:
				smth_changed = true
			
			point = next_point
			incoming_vec = outgoing_vec
		
		points = hull
		
	return points
