extends Control

signal color_changed(color: Color)
signal height_changed(height: float)
signal radius_changed(radius: float)

@export var color_picker_button: ColorPickerButton
@export var height_slider: HSlider
@export var height_value_label: Label
@export var radius_slider: HSlider
@export var radius_value_label: Label
@export var character_preview_mesh: MeshInstance3D

const SAVE_FILE_PATH = "user://character_data.json"
var _preview_material: StandardMaterial3D
var _is_loading: bool = false

func _ready() -> void:
	await ready
	
	if character_preview_mesh:
		# Ensure the mesh has a unique material to modify.
		# This avoids changing the material on all capsules in your game.
		var mesh_res: CapsuleMesh = character_preview_mesh.mesh
		if mesh_res:
			_preview_material = StandardMaterial3D.new()
			_preview_material.albedo_color = color_picker_button.color
			character_preview_mesh.set_surface_override_material(0, _preview_material)
		else:
			print("Error: CharacterPreviewMesh does not have a CapsuleMesh resource.")
	
	_load_data()
	
func _on_color_picker_button_color_changed(new_color: Color) -> void:
	# Update the preview mesh's material color
	if _preview_material:
		_preview_material.albedo_color = new_color
	
	# Emit the signal
	color_changed.emit(new_color)
	
	_save_data()


func _on_height_slider_value_changed(new_height: float) -> void:
	# Update the preview mesh's height
	if character_preview_mesh and character_preview_mesh.mesh is CapsuleMesh:
		# A CapsuleMesh's "height" is the total height.
		# A CapsuleShape3D's "height" is just the cylinder part.
		# We'll assume the slider controls the *total* height.
		var capsule_mesh: CapsuleMesh = character_preview_mesh.mesh
		capsule_mesh.height = new_height
	
	# Update the label
	if height_value_label:
		# Format to 2 decimal places
		height_value_label.text = "%.2f" % new_height
	
	# Emit the signal
	height_changed.emit(new_height)
	
	_save_data()


func _on_radius_slider_value_changed(new_radius: float) -> void:
	# Update the preview mesh's radius
	if character_preview_mesh and character_preview_mesh.mesh is CapsuleMesh:
		var capsule_mesh: CapsuleMesh = character_preview_mesh.mesh
		capsule_mesh.radius = new_radius

	# Update the label
	if radius_value_label:
		# Format to 2 decimal places
		radius_value_label.text = "%.2f" % new_radius
	
	# Emit the signal
	radius_changed.emit(new_radius)
	
	_save_data()


func _on_back_buton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	

func _save_data() -> void:
	# Don't save if we are in the process of loading
	if _is_loading:
		return

	# 1. Create a dictionary with the data
	var data_to_save = {
		"color": color_picker_button.color.to_html(), # Save color as text e.g., "#ff00ff"
		"height": height_slider.value,
		"radius": radius_slider.value
	}
	
	# 2. Convert dictionary to a JSON text string (with tabs for readability)
	var json_string = JSON.stringify(data_to_save, "\t")
	
	# 3. Open/create the file and store the text
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close() # Important: close the file when done
	else:
		push_error("Failed to open save file for writing: %s" % SAVE_FILE_PATH)


func _load_data() -> void:
	# Set a flag so the _on...changed functions don't trigger a save
	_is_loading = true
	
	# 1. Check if the save file exists
	if FileAccess.file_exists(SAVE_FILE_PATH):
		# 2. Open and read the file content
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var file_content = file.get_as_text()
		file.close()
		
		# 3. Parse the JSON text
		var json = JSON.new()
		var error = json.parse(file_content)
		
		if error == OK:
			var loaded_data = json.data
			if loaded_data is Dictionary:
				# 4. Apply the loaded data to the UI controls
				height_slider.value = loaded_data.get("height", 2.0) # Use 2.0 as default
				radius_slider.value = loaded_data.get("radius", 0.5) # Use 0.5 as default
				color_picker_button.color = Color(loaded_data.get("color", "#ffffff"))
		else:
			push_error("Error parsing save file: %s" % json.get_error_message())
	
	# 5. Now, update the UI (labels, mesh) from the loaded values (or defaults)
	_on_color_picker_button_color_changed(color_picker_button.color)
	_on_height_slider_value_changed(height_slider.value)
	_on_radius_slider_value_changed(radius_slider.value)
	
	# We are done loading, so now we can allow saving again
	_is_loading = false
