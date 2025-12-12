extends Control


func _process(_delta: float) -> void:	
	if Input.is_action_just_pressed("back"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
