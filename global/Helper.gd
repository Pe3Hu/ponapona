extends Node


var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	#region init
	rng.randomize()
	#endregion


func clear_children(parent_: Node) -> void:
	while parent_.get_child_count() > 0:
		var child: Node = parent_.get_child(0)
		parent_.remove_child(child)
		child.queue_free()


func axial_to_world(coord_: Vector2i) -> Vector2:
	var q := float(coord_.x)
	var r := float(coord_.y)
	return Vector2(
		Catalog.HEX_SIZE * (q + r * 0.5),
		Catalog.HEX_SIZE * (sqrt(3.0) * 0.5 * r)
	)


func opposite_direction(direction_: int) -> int:
	return posmod(direction_ + Catalog.EDGE_COUNT / 2, Catalog.EDGE_COUNT)


func direction_index(delta_: Vector2i) -> int:
	var index_ := 0
	for offset_ in Digest.direction_to_offset.values():
		if offset_ == delta_:
			return index_
		index_ += 1
	return Catalog.EDGE_COUNT


func hex_neighbors(coord_: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for offset_ in Digest.direction_to_offset.values():
		neighbors.append(coord_ + offset_)
	return neighbors
