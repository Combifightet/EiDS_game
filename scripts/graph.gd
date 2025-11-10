extends RefCounted
class_name Graph

var _is_dirceted: bool = false
var edges: Array[Edge] = []
var nodes: Array[int] = []

func _init(directed: bool = false) -> void:
	_is_dirceted = directed

# Convert the graph to its respective representaion in the DOT Language
func to_dot(graph_name: String = "GodotGraph") -> String:
	var dot = ("digraph " if _is_dirceted else "graph ") + graph_name + " {"
	var edge_connector: String = " -- "
	if _is_dirceted:
		edge_connector = " -> "
	
	# Add all edges
	for edge in edges:
		dot += "\n    " + str(edge.start) + edge_connector + str(edge.end)
		dot += " [weight=" + str(edge.weight) + "];"
	# Add missing orphan nodes
	for node in nodes:
		if not edges.any(func(edge: Edge): return edge.start==node or edge.end==node):
			dot += "\n    " + str(node) + ";"
	
	dot += "\n}"
	return dot

## Finds the minimum spanning tree (mst) for a given graph.
## It uses [Prim's Algorithm](https://en.wikipedia.org/wiki/Prim%27s_algorithm)
func get_mst() -> Graph:
	var min_weight: Dictionary[int, float] = {}
	var min_edge: Dictionary = {}
	for node in nodes:
		min_weight[node] = INF
	
	var explored: Array[int] = []
	var unexplored: Array[int] = nodes.duplicate()
	
	var start_node: int = unexplored[0]
	min_weight[start_node] = 0
	
	while not unexplored.is_empty():
		# Select vertex in unexplored with minimum cost
		# sort with descending weight
		unexplored.sort_custom(func(a, b): return min_weight[a] > min_weight[b])
		var current_node: int = unexplored.pop_back()
		explored.append(current_node)
		
		for edge in edges:
			var neighbor: int
			if edge.start == current_node:
				neighbor = edge.end
			elif _is_dirceted == false and edge.end == current_node:
				neighbor = edge.start
			else:
				continue
			
			# FIXED: Compare edge weight directly, not accumulated weight
			if unexplored.find(neighbor) >= 0 and edge.weight < min_weight[neighbor]:
				min_weight[neighbor] = edge.weight
				min_edge[neighbor] = edge
	
	var mst_edges: Array[Edge] = []
	var mst_nodes: Array[int] = []
	for node in nodes:
		if min_edge.keys().find(node) >= 0:
			mst_edges.append(min_edge[node])
	for edge in mst_edges:
		if mst_nodes.find(edge.start) < 0:
			mst_nodes.append(edge.start)
		if mst_nodes.find(edge.end) < 0:
			mst_nodes.append(edge.end)
	
	var mst = Graph.new(_is_dirceted)
	mst.edges = mst_edges
	mst.nodes = mst_nodes
	
	return mst

# Returns a fully connected (undirected) graph with random weights if needed
static func get_connected(node_count: int, random_weights: bool = true, _seed:int = -1) -> Graph:
	if _seed == -1:
		randomize()
	else:
		seed(_seed)
	
	if node_count<=0:
		return Graph.new()
	
	var weight: float = 1
	
	var result_nodes: Array[int] = []
	var result_edges: Array[Edge] = []
	for i in range(node_count):
		result_nodes.append((i))
		for j in range(i+1, node_count):
			if random_weights:
				weight = randf()
			result_edges.append(Edge.new(i, j, weight))
	
	var result: Graph = Graph.new()
	result.nodes = result_nodes
	result.edges = result_edges
	return result

## returns a list of all nodes connected to this node via outgoing edges
func get_connections_from(node: int) -> Array[int]:
	var result: Array[int] = []
	for edge in edges:
		if edge.start==node and result.find(edge.end)<0:
			result.append(edge.end)
		if _is_dirceted==false and edge.end==node and result.find(edge.start)<0:
			result.append(edge.start)
	return result

## returns a list of all nodes connected to this node via incoming edges
func get_connections_to(node: int) -> Array[int]:
	var result: Array[int] = []
	for edge in edges:
		if edge.end==node and result.find(edge.start)<0:
			result.append(edge.start)
		if _is_dirceted==false and edge.start==node and result.find(edge.end)<0:
			result.append(edge.end)
	return result

func _edges_to_nodes(edge_list: Array[Edge]) -> Array[int]:
	var result: Array[int] = []
	for edge in edge_list:
		if not result.find(edge.start) >= 0:
			result.append(edge.start)
		if not result.find(edge.end) >= 0:
			result.append(edge.end)
	return result

class Edge extends RefCounted:
	var start: int ## Start node id
	var end: int ## End node id
	var weight: float = 1.0
	
	@warning_ignore("shadowed_variable")
	func _init(start, end, weight) -> void:
		self.start = start
		self.end = end
		self.weight = weight
