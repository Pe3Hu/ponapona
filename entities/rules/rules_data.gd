class_name RulesData
extends RefCounted


static func get_edge_color(tile_: HexTileData, rotation_: int, direction_: int) -> int:
	if tile_ == null:
		return Bozo.Hue.NONE
	var local_ := posmod(direction_ - rotation_, Catalog.EDGE_COUNT)
	for link_ in tile_.links:
		if link_.edge_a == local_ or link_.edge_b == local_:
			return link_.color
	return Bozo.Hue.NONE


static func is_occupied(field_: ChainFieldData, coord_: Vector2i) -> bool:
	if not field_.cell_to_cell.has(coord_):
		return false
	return field_.cell_to_cell[coord_].tile != null


static func is_place_valid(field_: ChainFieldData, coord_: Vector2i, tile_: HexTileData, rotation_: int, gobbles_: GobbleData, phase_: int) -> bool:
	if tile_ == null or is_occupied(field_, coord_):
		return false
	if not _connects(field_, coord_):
		return false
	if not _matches(field_, coord_, tile_, rotation_):
		return false
	var phase_name_ := Bozo.enum_to_string(Bozo.Type.PHASE, phase_)
	if phase_name_ == "normal" and gobbles_.is_creating_forbidden(field_, coord_, tile_, rotation_):
		return false
	if gobbles_.is_forced and not gobbles_.forced_coords.has(coord_):
		return false
	return true


static func is_first_move_valid(tile_a_: HexTileData, rot_a_: int, tile_b_: HexTileData, rot_b_: int) -> bool:
	for direction_ in Catalog.EDGE_COUNT:
		var opposite_ := Helper.opposite_direction(direction_)
		var color_a_ := get_edge_color(tile_a_, rot_a_, direction_)
		var color_b_ := get_edge_color(tile_b_, rot_b_, opposite_)
		if color_a_ == Bozo.Hue.NONE:
			continue
		if color_a_ == color_b_:
			return true
	return false


static func get_valid_slots(field_: ChainFieldData, tile_: HexTileData, gobbles_: GobbleData, phase_: int) -> Array[Vector3i]:
	var slots_: Array[Vector3i] = []
	if tile_ == null:
		return slots_
	var coords_: Array[Vector2i] = field_.frontier
	if gobbles_.is_forced:
		coords_ = gobbles_.forced_coords
	for coord_ in coords_:
		for rotation_ in Catalog.EDGE_COUNT:
			if not is_place_valid(field_, coord_, tile_, rotation_, gobbles_, phase_):
				continue
			slots_.append(Vector3i(coord_.x, coord_.y, rotation_))
	return slots_


static func _connects(field_: ChainFieldData, coord_: Vector2i) -> bool:
	for neighbor_ in Helper.hex_neighbors(coord_):
		if is_occupied(field_, neighbor_):
			return true
	return false


static func _matches(field_: ChainFieldData, coord_: Vector2i, tile_: HexTileData, rotation_: int) -> bool:
	var direction_ := 0
	for offset_ in Digest.direction_to_offset.values():
		var neighbor_: Vector2i = coord_ + offset_
		if is_occupied(field_, neighbor_):
			var cell_: ChainCellData = field_.cell_to_cell[neighbor_]
			var mine_ := get_edge_color(tile_, rotation_, direction_)
			var theirs_ := get_edge_color(cell_.tile, cell_.rotation, Helper.opposite_direction(direction_))
			if mine_ != theirs_:
				return false
		direction_ += 1
	return true
