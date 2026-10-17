class_name LinkData
extends RefCounted


var edge_a: int
var edge_b: int
var color: int

var shape: int:
	get:
		return Digest.edge_pair_to_shape[Vector2i(min(edge_a, edge_b), max(edge_a, edge_b))]


func _init(edge_a_: int, edge_b_: int, color_: int) -> void:
	#region init
	edge_a = edge_a_
	edge_b = edge_b_
	color = color_
	#endregion
