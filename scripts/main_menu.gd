extends Control

func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_character_editor_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_editor.tscn")


func _on_quit_game_pressed() -> void:
	get_tree().quit()
