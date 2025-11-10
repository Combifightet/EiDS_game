extends RefCounted
class_name FloorPlanCell

## Represents a single cell in a floor plan grid

const OUTSIDE: int = -1
const NO_ROOM: int = -9223372036854775808 # min signed 64-bit integer (2^63 - 1)

var room_id: int = -1


func _init(initial_room_id: int = NO_ROOM) -> void:
	room_id = initial_room_id

func set_outside() -> void:
	room_id = OUTSIDE


## Grows this cell by assigning it to a room
## Returns true if the cell was successfully assigned, false if it already had a room
func grow(new_room_id: int) -> bool:
	if room_id != NO_ROOM:
		return false
	
	room_id = new_room_id
	return true


## Checks if this cell is empty (no room assigned)
func is_empty() -> bool:
	return room_id == NO_ROOM


## Checks if this cell is an outside cell
func is_outside() -> bool:
	return room_id == OUTSIDE


## Clears the cell, removing any room assignment
func clear() -> void:
	room_id = NO_ROOM


## Returns a string representation of the cell
func _to_string() -> String:
	if is_empty():
		return "FloorPlanCell(empty)"
	elif is_outside():
		return "FloorPlanCell(outside)" 
	else:
		return "FloorPlanCell(room_id=%d)" % room_id
