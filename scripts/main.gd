extends Node

var floorplan_gen: FloorPlanGen

@onready var debug_rect: ColorRect = $ColorRect

func _ready() -> void:
	
	floorplan_gen = FloorPlanGen.new()
	#floorplan_gen.set_seed(7)
	randomize()
	floorplan_gen.set_seed(randi())
	floorplan_gen.generate(FloorPlanGen.HouseSize.SMALL)
	print("last_seed: ", floorplan_gen.get_last_seed())

	# debug drawing (2d)
	print("displaying grid ...")
	var grid: FloorPlanGrid = floorplan_gen.get_grid()
	var texture: ImageTexture = ImageTexture.create_from_image(grid.to_texture())
	
	debug_rect.material.set_shader_parameter('data_texture', texture)
	debug_rect.material.set_shader_parameter('data_size', Vector2(grid.width, grid.height))
	debug_rect.material.set_shader_parameter('container_size', debug_rect.size)
	debug_rect.resized.connect(_on_debug_rect_resized)
	
	var _connectivity: Dictionary[Vector2i, Array] = floorplan_gen.to_connectivity_dict()
	print("\n\nconnectivity:")
	print(dict_connections_to_grid_string(_connectivity))
	

# Updates the 'container_size' uniform whenever the ColorRect is resized
func _on_debug_rect_resized() -> void:
	if debug_rect.material: # Check if material exists
		debug_rect.material.set_shader_parameter('container_size', debug_rect.size)

# ● ─ │ ╱ ╲ ╳


func dict_connections_to_grid_string(connections: Dictionary) -> String:
	if connections.is_empty():
		return "No connections"
	
	# Find grid bounds
	var max_x = 0
	var max_y = 0
	
	for pos in connections.keys():
		max_x = max(max_x, pos.x)
		max_y = max(max_y, pos.y)
	
	# Create grid (3x3 per cell: node + connection spaces)
	var width = max_x * 2 + 1
	var height = max_y * 2 + 1
	var grid = []
	for y in range(height + 1):
		var row = []
		for x in range(width + 1):
			row.append(" ")
		grid.append(row)
	
	# Place all nodes
	for pos in connections.keys():
		var gx = pos.x * 2
		var gy = pos.y * 2
		grid[gy][gx] = "●"
	
	# Draw connections
	for pos in connections.keys():
		var gx = pos.x * 2
		var gy = pos.y * 2
		
		for neighbor in connections[pos]:
			var diff = neighbor - pos
			
			# Right (1, 0)
			if diff.x == 1 and diff.y == 0:
				grid[gy][gx + 1] = "─"
			
			# Down (0, 1)
			elif diff.x == 0 and diff.y == 1:
				grid[gy + 1][gx] = "│"
			
			# Diagonal down-right (1, 1)
			elif diff.x == 1 and diff.y == 1:
				if grid[gy + 1][gx + 1] == "╱":
					grid[gy + 1][gx + 1] = "╳"
				elif grid[gy + 1][gx + 1] != "╳":
					grid[gy + 1][gx + 1] = "╲"
			
			# Diagonal up-right (1, -1)
			elif diff.x == 1 and diff.y == -1:
				if grid[gy - 1][gx + 1] == "╲":
					grid[gy - 1][gx + 1] = "╳"
				elif grid[gy - 1][gx + 1] != "╳":
					grid[gy - 1][gx + 1] = "╱"
			
			# Left (-1, 0)
			elif diff.x == -1 and diff.y == 0:
				grid[gy][gx - 1] = "─"
			
			# Up (0, -1)
			elif diff.x == 0 and diff.y == -1:
				grid[gy - 1][gx] = "│"
			
			# Diagonal down-left (-1, 1)
			elif diff.x == -1 and diff.y == 1:
				if grid[gy + 1][gx - 1] == "╲":
					grid[gy + 1][gx - 1] = "╳"
				elif grid[gy + 1][gx - 1] != "╳":
					grid[gy + 1][gx - 1] = "╱"
			
			# Diagonal up-left (-1, -1)
			elif diff.x == -1 and diff.y == -1:
				if grid[gy - 1][gx - 1] == "╱":
					grid[gy - 1][gx - 1] = "╳"
				elif grid[gy - 1][gx - 1] != "╳":
					grid[gy - 1][gx - 1] = "╲"
	
	# Convert grid to string
	var result = ""
	for y in range(height + 1):
		for x in range(width + 1):
			result += grid[y][x]
		result += "\n"
	
	return result
