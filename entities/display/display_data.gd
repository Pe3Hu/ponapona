class_name DisplayData
extends RefCounted


signal display_changed

var chain_size: int = 0
var loop_red: int = 0
var loop_yellow: int = 0
var loop_green: int = 0
var loop_blue: int = 0
var gobble_count: int = 0
var forced_hint: bool = false
var phase: int = Bozo.Phase.NONE
var result: int = Bozo.Result.NONE


func recalc(field_: ChainFieldData, gobbles_: GobbleData, phase_: PhaseData) -> void:
	chain_size = field_.chain_size
	loop_red = _max_loop(field_, Bozo.Hue.RED)
	loop_yellow = _max_loop(field_, Bozo.Hue.YELLOW)
	loop_green = _max_loop(field_, Bozo.Hue.GREEN)
	loop_blue = _max_loop(field_, Bozo.Hue.BLUE)
	gobble_count = gobbles_.coords.size()
	forced_hint = gobbles_.is_forced
	phase = phase_.phase
	result = phase_.result
	display_changed.emit()


func _max_loop(field_: ChainFieldData, color_: int) -> int:
	var best_ := 0
	var visited_: Dictionary = {}
	for start_ in field_.cell_to_cell.keys():
		if visited_.has(start_):
			continue
		if not _has_color(field_, start_, color_):
			continue
		var length_ := 0
		var current_: Vector2i = start_
		var previous_: Vector2i = start_
		var closed_ := false
		var guard_ := 0
		while guard_ < Catalog.TILE_COUNT and not visited_.has(current_):
			guard_ += 1
			visited_[current_] = true
			length_ += 1
			var next_ := _step(field_, current_, color_, previous_)
			if next_ == start_:
				closed_ = true
				break
			if not _has_color(field_, next_, color_):
				break
			previous_ = current_
			current_ = next_
		if closed_ and length_ > best_:
			best_ = length_
	return best_


func _has_color(field_: ChainFieldData, coord_: Vector2i, color_: int) -> bool:
	if not field_.cell_to_cell.has(coord_):
		return false
	var cell_: ChainCellData = field_.cell_to_cell[coord_]
	return _link_of(cell_, color_) != null


func _link_of(cell_: ChainCellData, color_: int) -> LinkData:
	if cell_ == null or cell_.tile == null:
		return null
	for link_ in cell_.tile.links:
		if link_.color == color_:
			return link_
	return null


func _step(field_: ChainFieldData, current_: Vector2i, color_: int, previous_: Vector2i) -> Vector2i:
	var cell_: ChainCellData = field_.cell_to_cell[current_]
	var link_ := _link_of(cell_, color_)
	if link_ == null:
		return current_
	var neighbor_a_ := current_ + _offset(_global_dir(link_.edge_a, cell_.rotation))
	var neighbor_b_ := current_ + _offset(_global_dir(link_.edge_b, cell_.rotation))
	if neighbor_a_ != previous_:
		return neighbor_a_
	return neighbor_b_


func _global_dir(edge_: int, rotation_: int) -> int:
	return posmod(edge_ + rotation_, Catalog.EDGE_COUNT)


func _offset(direction_: int) -> Vector2i:
	var index_ := 0
	for offset_ in Digest.direction_to_offset.values():
		if index_ == direction_:
			return offset_
		index_ += 1
	return Vector2i.ZERO
