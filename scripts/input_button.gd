extends Button

@export var input_action: String


func _ready() -> void:
	# Connect button signals to our handler functions
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _on_button_down() -> void:
	if input_action.is_empty():
		push_warning("No input action assigned to button: " + name)
		return
	
	# Create and dispatch a pressed input event
	var event := InputEventAction.new()
	event.action = input_action
	event.pressed = true
	Input.parse_input_event(event)


func _on_button_up() -> void:
	if input_action.is_empty():
		return
	
	# Create and dispatch a released input event
	var event := InputEventAction.new()
	event.action = input_action
	event.pressed = false
	Input.parse_input_event(event)
