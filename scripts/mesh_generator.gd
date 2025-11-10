extends Node3D
class_name MeshGenerator

@export var mesh_instance: MeshInstance3D
@export var static_body: StaticBody3D
@export var collision_shape: CollisionShape3D

func generate_floor_mesh(grid: FloorPlanGrid):
	
	# Create Texture
	var image: Image = grid.to_texture()
	var texture: ImageTexture = ImageTexture.create_from_image(image)

	# Create Material
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = Color.WHITE
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.4
	
	# Create Visual Mesh
	var plane_mesh = PlaneMesh.new()
	
	var world_width = float(grid.width) / grid.grid_resolution
	var world_height = float(grid.height) / grid.grid_resolution
	
	plane_mesh.size = Vector2(world_width, world_height)
	
	mesh_instance.mesh = plane_mesh
	mesh_instance.set_surface_override_material(0, material)
	
	# Create Physics Collision
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(world_width, 0.1, world_height)
	
	# Assign the shape to the exported node
	collision_shape.shape = box_shape

	# --- 6. Assemble and Position ---
	
	# Set the LOCAL positions of the children
	mesh_instance.position = Vector3.ZERO
	static_body.position = Vector3(0, -0.05, 0)
	
	# Set the physics layer on the exported node
	static_body.collision_layer = 1
	
	# Calculate the final position
	var world_center_x = grid.origin.x + (world_width / 2.0)
	var world_center_z = grid.origin.y + (world_height / 2.0)
	
	# Move this entire node (self) to the correct spot
	self.global_position = Vector3(world_center_x, 0, world_center_z)
