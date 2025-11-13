extends Node3D
class_name LevelGen

@onready var custom_grid_map: CustomGridMap = $CustomGridMap

@export var wall_height: float = 1
@export var grid_size: float = 2


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

func from_grid(floor_plan_grid: FloorPlanGrid) -> void:
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
			
			# debug printing
			var result: String = ""
			if neighbours[0]:
				if neighbours[1]:
					if neighbours[3]:
						if neighbours[4]:
							result += "█"
						else:
							result += "▛"
					else:
						if neighbours[4]:
							result += "▜"
						else:
							result += "▀"
				else:
					if neighbours[3]:
						if neighbours[4]:
							result += "▙"
						else:
							result += "▌"
					else:
						if neighbours[4]:
							result += "▚"
						else:
							result += "▘"
			else:
				if neighbours[1]:
					if neighbours[3]:
						if neighbours[4]:
							result += "▟"
						else:
							result += "▞"
					else:
						if neighbours[4]:
							result += "▐"
						else:
							result += "▝"
				else:
					if neighbours[3]:
						if neighbours[4]:
							result += "▄"
						else:
							result += "▖"
					else:
						if neighbours[4]:
							result += "▗"
						else:
							result += " "
			if neighbours[2]:
				if neighbours[5]:
					result += "▌\n"
				else:
					result += "▘\n"
			else:
				if neighbours[5]:
					result += "▖\n"
				else:
					result += " \n"
			if neighbours[6]:
				if neighbours[7]:
					result += "▀"
				else:
					result += "▘"
			else:
				if neighbours[7]:
					result += "▝"
				else:
					result += " "
			if neighbours[8]:
				result += "▘"
			else:
				result += " "
			print(neighbours)
			print("Tile(", x, ", ", y, ") -> ", peering_bits)
			print(result)
			
			
			
			@warning_ignore("integer_division")
			custom_grid_map.set_cell_item(
				# TODO: this offset is not correct
				Vector3i(x-floor_plan_grid.width/2, 0, y-floor_plan_grid.height/2),
				custom_grid_map.tiles[peering_bits]
			)
