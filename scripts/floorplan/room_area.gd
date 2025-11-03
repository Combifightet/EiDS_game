extends RefCounted
class_name RoomArea

enum HouseZone {PUBLIC, PRIVATE, HALLWAY}

var id: int = 0
var zone: HouseZone = HouseZone.PUBLIC
var rel_size: float = 1 # size ratio
var connectivity: Array[int] = []

@warning_ignore("shadowed_variable")
func _init(id: int, zone: HouseZone, rel_size: float, connectivity: Array[int]) -> void:
	self.id = id
	self.zone = zone
	self.rel_size = rel_size
	self.connectivity = connectivity

static func from_graph(graph: Graph, randomness:float = 1, _seed:int = -1) -> Array[RoomArea]:
	if _seed == -1:
		randomize()
	else:
		seed(_seed)
	
	var sizes: Array[float] = []
	var total_size: float = 0
	for i in range(graph.nodes.size()):
		sizes.append(FloorPlanGen.randf_min(randomness))
		total_size += sizes[-1]
	
	var result: Array[RoomArea] = []
	var random_zone: HouseZone
	var generated_hallway: bool = false # to ensure generation of maxiumum one hallway
	for i in range(graph.nodes.size()):
		if not generated_hallway:
			random_zone = randi()%HouseZone.size() as HouseZone
		else:
			random_zone = randi()%(HouseZone.size()-1) as HouseZone
			# this won't be needed, since `HALLWAY` is the last enum value
			#if random_zone == HouseZone.HALLWAY:
				#random_zone = random_zone+1 as HouseZone
		result.append(RoomArea.new(
			graph.nodes[i],
			random_zone,
			sizes[i]/total_size,
			graph.get_connections_from(graph.nodes[i])
		))
	
	return result
