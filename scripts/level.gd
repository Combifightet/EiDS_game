extends Node3D

@onready var custom_grid_map: CustomGridMap = $CustomGridMap

@export var wall_height: float = 1
@export var grid_size: float = 2

func _ready() -> void:
	custom_grid_map.clear()
	custom_grid_map.scale = Vector3(1/grid_size, wall_height, 1/grid_size)
	
	#var tile_id: int = custom_grid_map.tiles[0b000_010_000]
	#custom_grid_map.set_cell_item(Vector3(0,0,0), tile_id)
func from_grid(floor_plan_grid: FloorPlanGrid) -> void:
	custom_grid_map.clear()
	
	for y in range(floor_plan_grid.height):
		for x in range(floor_plan_grid.width):
			# TODO: calculate peering bits, by checking cell id's
			#       also check for doors
			var id: int = floor_plan_grid.get_cell(x, y).room_id
