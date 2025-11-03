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
	
	var connectivity: Dictionary[Vector2i, Array] = floorplan_gen.to_connectivity_dict()
	print("\n\nconnectivity:")
	print(connectivity)
	

# Updates the 'container_size' uniform whenever the ColorRect is resized
func _on_debug_rect_resized() -> void:
	if debug_rect.material: # Check if material exists
		debug_rect.material.set_shader_parameter('container_size', debug_rect.size)
