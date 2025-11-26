extends Control

@onready var _points_label = $Points

func _ready() -> void:
	_points_label.text = str("Points: ", %Player.points)


func _process(_delta: float) -> void:
	_points_label.text = str("Points: ", %Player.points)
	
	if Input.is_action_just_pressed("back"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
