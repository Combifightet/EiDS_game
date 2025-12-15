extends GridMap
class_name CustomGridMap

## should be of type [Biome] (enum)
@export var room_ids: ImageTexture:
	set(value):
		room_ids = value
		_update_materials()
		
@export var grid_scale: float = 1.0:
	set(value):
		grid_scale = value
		_update_materials()
		
@export var grid_offset: Vector2 = Vector2(0, 0):
	set(value):
		grid_offset = value
		_update_materials()

# 240 = 16 + 
# 0b001_111_000

# bitmask (0b000010000):
#  1   2   4
#  8  16  32
# 64 128 256

# https://user-images.githubusercontent.com/47016402/87044533-f5e89f00-c1f6-11ea-9178-67b2e357ee8a.png

@onready var tiles: Dictionary[int, int] = {
	0b000_010_010: mesh_library.find_item_by_name("Tile 1-1"),
	0b000_011_010: mesh_library.find_item_by_name("Tile 1-2"),
	0b000_111_010: mesh_library.find_item_by_name("Tile 1-3"),
	0b000_110_010: mesh_library.find_item_by_name("Tile 1-4"),
	0b110_111_010: mesh_library.find_item_by_name("Tile 1-5"),
	0b000_111_011: mesh_library.find_item_by_name("Tile 1-6"),
	0b000_111_110: mesh_library.find_item_by_name("Tile 1-7"),
	0b011_111_010: mesh_library.find_item_by_name("Tile 1-8"),
	0b000_011_011: mesh_library.find_item_by_name("Tile 1-9"),
	0b010_111_111: mesh_library.find_item_by_name("Tile 1-10"),
	0b000_111_111: mesh_library.find_item_by_name("Tile 1-11"),
	0b000_110_110: mesh_library.find_item_by_name("Tile 1-12"),
	0b010_010_010: mesh_library.find_item_by_name("Tile 2-1"),
	0b010_011_010: mesh_library.find_item_by_name("Tile 2-2"),
	0b010_111_010: mesh_library.find_item_by_name("Tile 2-3"),
	0b010_110_010: mesh_library.find_item_by_name("Tile 2-4"),
	0b010_011_011: mesh_library.find_item_by_name("Tile 2-5"),
	0b011_111_111: mesh_library.find_item_by_name("Tile 2-6"),
	0b110_111_111: mesh_library.find_item_by_name("Tile 2-7"),
	0b010_110_110: mesh_library.find_item_by_name("Tile 2-8"),
	0b011_011_011: mesh_library.find_item_by_name("Tile 2-9"),
	0b011_111_110: mesh_library.find_item_by_name("Tile 2-10"),
	0b000_000_000: mesh_library.find_item_by_name("Tile 2-11"),
	0b110_111_110: mesh_library.find_item_by_name("Tile 2-12"),
	0b010_010_000: mesh_library.find_item_by_name("Tile 3-1"),
	0b010_011_000: mesh_library.find_item_by_name("Tile 3-2"),
	0b010_111_000: mesh_library.find_item_by_name("Tile 3-3"),
	0b010_110_000: mesh_library.find_item_by_name("Tile 3-4"),
	0b011_011_010: mesh_library.find_item_by_name("Tile 3-5"),
	0b111_111_011: mesh_library.find_item_by_name("Tile 3-6"),
	0b111_111_110: mesh_library.find_item_by_name("Tile 3-7"),
	0b110_110_010: mesh_library.find_item_by_name("Tile 3-8"),
	0b011_111_011: mesh_library.find_item_by_name("Tile 3-9"),
	0b111_111_111: mesh_library.find_item_by_name("Tile 3-10"),
	0b110_111_011: mesh_library.find_item_by_name("Tile 3-11"),
	0b110_110_110: mesh_library.find_item_by_name("Tile 3-12"),
	0b000_010_000: mesh_library.find_item_by_name("Tile 4-1"),
	0b000_011_000: mesh_library.find_item_by_name("Tile 4-2"),
	0b000_111_000: mesh_library.find_item_by_name("Tile 4-3"),
	0b000_110_000: mesh_library.find_item_by_name("Tile 4-4"),
	0b010_111_110: mesh_library.find_item_by_name("Tile 4-5"),
	0b011_111_000: mesh_library.find_item_by_name("Tile 4-6"),
	0b110_111_000: mesh_library.find_item_by_name("Tile 4-7"),
	0b010_111_011: mesh_library.find_item_by_name("Tile 4-8"),
	0b011_011_000: mesh_library.find_item_by_name("Tile 4-9"),
	0b111_111_000: mesh_library.find_item_by_name("Tile 4-10"),
	0b111_111_010: mesh_library.find_item_by_name("Tile 4-11"),
	0b110_110_000: mesh_library.find_item_by_name("Tile 4-12"),
}


func _update_materials() -> void:
	print("grid_scale:  ", grid_scale)
	print("grid_offset: ", grid_offset)
	for item_id: int in mesh_library.get_item_list():
		var item_mesh: Mesh = mesh_library.get_item_mesh(item_id)
		
		for i: int in range(item_mesh.get_surface_count()):
			var material = item_mesh.surface_get_material(i)
			material.set_shader_parameter("world_offset", -Vector2(global_position.x, global_position.z))
			material.set_shader_parameter("room_ids", room_ids)
			material.set_shader_parameter("grid_size", grid_scale)
			material.set_shader_parameter("grid_offset", grid_offset)
