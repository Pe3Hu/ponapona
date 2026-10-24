extends Node


var rng := RandomNumberGenerator.new()


#region init
func _ready() -> void:
	rng.randomize()
#endregion


func get_neighbor_coord(coord_: Vector2i, direction_index_: int) -> Vector2i:
	return coord_ + Digest.hex_directions[direction_index_]

func hex_to_pixel(coord_: Vector2i, size_: float) -> Vector2:
	var x: float = size_ * (sqrt(3.0) * coord_.x + sqrt(3.0) / 2.0 * coord_.y)
	var y: float = size_ * (3.0 / 2.0 * coord_.y)
	return Vector2(x, y)

func pixel_to_hex(pos_: Vector2, size_: float) -> Vector2i:
	var q: float = (sqrt(3.0) / 3.0 * pos_.x - 1.0 / 3.0 * pos_.y) / size_
	var r: float = (2.0 / 3.0 * pos_.y) / size_
	return _round_axial(q, r)

func _round_axial(q_: float, r_: float) -> Vector2i:
	var s_: float = -q_ - r_
	var rq: int = int(round(q_))
	var rr: int = int(round(r_))
	var rs: int = int(round(s_))
	var dq: float = abs(float(rq) - q_)
	var dr: float = abs(float(rr) - r_)
	var ds: float = abs(float(rs) - s_)
	if dq > dr and dq > ds:
		rq = -rr - rs
	elif dr > ds:
		rr = -rq - rs
	return Vector2i(rq, rr)

func get_reverse_direction_index(direction_index_: int) -> int:
	return (direction_index_ + int(Catalog.CHUNK_N * 0.5)) % Catalog.CHUNK_N

func get_direction_index(coord_: Vector2i, direction_: Vector2i) -> int:
	var parity := coord_.x % 2
	return Digest.direction_differences[parity].find(direction_)

func shuffle(values_: Array) -> void:
	for index in range(values_.size() - 1, 0, -1):
		var swap := rng.randi_range(0, index)
		var value = values_[index]
		values_[index] = values_[swap]
		values_[swap] = value

func clear_children(node_: Node) -> void:
	while node_.get_child_count() > 0:
		var child := node_.get_child(0)
		node_.remove_child(child)
		child.queue_free()
