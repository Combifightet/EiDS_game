# File: mesh_generator.gd
extends Node3D
class_name MeshGenerator

# We will create and store these in code
# to avoid all scene-linking errors.
var mesh_instance: MeshInstance3D
var static_body: StaticBody3D
var collision_shape: CollisionShape3D

# This function is the ONLY thing this script does.
func generate_floor_mesh(grid: FloorPlanGrid):
	
	var image: Image = grid.to_texture()
	var img_err = image.save_png("res://generated_floor_image.png")
	if img_err != OK:
		printerr("!!! FAILED TO SAVE PNG IMAGE: ", img_err)

	
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	
	texture.set_path("res://generated_floor_texture.tres")

	# --- 2. Create Material ---
	var material = StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = Color.WHITE
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# --- 3. Create Visual Mesh ---
	var plane_mesh = PlaneMesh.new()
	
	var world_width = float(grid.width) / grid.grid_resolution
	var world_height = float(grid.height) / grid.grid_resolution
	
	plane_mesh.size = Vector2(world_width, world_height)
	
	# Create the MeshInstance node
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = plane_mesh
	mesh_instance.set_surface_override_material(0, material)
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh_instance.layers = 1 # Force it to be on visual layer 1

	# --- 4. Create Physics Collision ---
	static_body = StaticBody3D.new()
	static_body.collision_layer = 1 # Set physics layer
	
	collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(world_width, 0.1, world_height)
	collision_shape.shape = box_shape
	
	# Set local position (relative to static_body)
	collision_shape.position = Vector3(0, 0, 0) 
	
	# Add collision_shape as a child of static_body
	static_body.add_child(collision_shape)

	# --- 5. Assemble and Position ---
	
	# Add the nodes as children of this "MeshGenerator" node
	add_child(mesh_instance)
	add_child(static_body)
	
	# Set the local positions of the children
	# (StaticBody is slightly below the visual mesh)
	mesh_instance.position = Vector3.ZERO
	static_body.position = Vector3(0, -0.05, 0)
	
	# Now, calculate the final position
	var world_center_x = grid.origin.x + (world_width / 2.0)
	var world_center_z = grid.origin.y + (world_height / 2.0)
	
	# Finally, move this entire node (self) to the correct spot.
	# Both children (visuals and physics) will move with it.
	self.global_position = Vector3(world_center_x, 0, world_center_z)
	
	print("MeshGenerator: Created and moved to ", self.global_position)
