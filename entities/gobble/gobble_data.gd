class_name GobbleData
extends RefCounted


signal gobbles_changed
signal forced_changed
signal controlled_changed

var coords: Array[Vector2i] = []
var forced_coords: Array[Vector2i] = []
var is_forced: bool = false
var closes_to_tile: Dictionary[Vector2i, Array] = {}
var controlled_sides: Dictionary[Vector2i, Array] = {}


func recalc(field_: ChainFieldData) -> void:
	coords.clear()
	for coord_ in field_.frontier:
		if _tile_neighbors(field_, coord_).size() >= Catalog.GOBBLE_MIN_SIZE:
			coords.append(coord_)
	gobbles_changed.emit()


func recalc_controlled(field_: ChainFieldData) -> void:
	controlled_sides.clear()
	for gobble_ in coords:
		var around_ := _tile_neighbors(field_, gobble_)
		var blocked_: Array[Vector2i] = []
		for frontier_ in field_.frontier:
			if frontier_ == gobble_ or coords.has(frontier_):
				continue
			var touch_ := 0
			for neighbor_ in Helper.hex_neighbors(frontier_):
				if around_.has(neighbor_):
					touch_ += 1
			if touch_ >= Catalog.CONTROLLED_TOUCH:
				blocked_.append(frontier_)
		controlled_sides[gobble_] = blocked_
	controlled_changed.emit()


func recalc_forced(pool_: PoolData, rules_: RulesData, phase_: int, pile_: PileData, field_: ChainFieldData) -> void:
	is_forced = false
	forced_coords.clear()
	closes_to_tile.clear()
	for gobble_ in coords:
		var closers_: Array[HexTileData] = []
		for pool_coord_ in pool_.coords:
			var tile_ := _pool_tile(pile_, pool_coord_)
			if tile_ == null:
				continue
			if not _can_close(rules_, field_, gobble_, tile_, phase_):
				continue
			if closers_.has(tile_):
				continue
			closers_.append(tile_)
		if closers_.is_empty():
			continue
		forced_coords.append(gobble_)
		closes_to_tile[gobble_] = closers_
	is_forced = not forced_coords.is_empty()
	forced_changed.emit()


func is_creating_forbidden(field_: ChainFieldData, coord_: Vector2i, tile_: HexTileData, rotation_: int) -> bool:
	if _is_controlled(coord_):
		return true
	for neighbor_ in Helper.hex_neighbors(coord_):
		if RulesData.is_occupied(field_, neighbor_):
			continue
		var touch_ := _touching(field_, neighbor_, coord_)
		if touch_.size() >= Catalog.DOUBLE_GOBBLE_SIZE:
			return true
		if touch_.size() == Catalog.GOBBLE_MIN_SIZE and _is_same_color(field_, neighbor_, touch_, coord_, tile_, rotation_):
			return true
	return false


func _tile_neighbors(field_: ChainFieldData, coord_: Vector2i) -> Array[Vector2i]:
	var found_: Array[Vector2i] = []
	for neighbor_ in Helper.hex_neighbors(coord_):
		if RulesData.is_occupied(field_, neighbor_):
			found_.append(neighbor_)
	return found_


func _touching(field_: ChainFieldData, empty_: Vector2i, extra_: Vector2i) -> Array[Vector2i]:
	var found_: Array[Vector2i] = []
	for neighbor_ in Helper.hex_neighbors(empty_):
		if neighbor_ == extra_ or RulesData.is_occupied(field_, neighbor_):
			found_.append(neighbor_)
	return found_


func _is_same_color(field_: ChainFieldData, empty_: Vector2i, touch_: Array[Vector2i], extra_: Vector2i, tile_: HexTileData, rotation_: int) -> bool:
	var first_ := Bozo.Hue.NONE
	var seen_ := false
	for neighbor_ in touch_:
		var color_ := _facing_color(field_, neighbor_, empty_, extra_, tile_, rotation_)
		if not seen_:
			first_ = color_
			seen_ = true
			continue
		if color_ != first_:
			return false
	return seen_


func _facing_color(field_: ChainFieldData, neighbor_: Vector2i, empty_: Vector2i, extra_: Vector2i, tile_: HexTileData, rotation_: int) -> int:
	var direction_ := Helper.direction_index(empty_ - neighbor_)
	if neighbor_ == extra_:
		return RulesData.get_edge_color(tile_, rotation_, direction_)
	var cell_: ChainCellData = field_.cell_to_cell[neighbor_]
	return RulesData.get_edge_color(cell_.tile, cell_.rotation, direction_)


func _is_controlled(coord_: Vector2i) -> bool:
	for blocked_ in controlled_sides.values():
		if blocked_.has(coord_):
			return true
	return false


func _pool_tile(pile_: PileData, coord_: Vector2i) -> HexTileData:
	if not pile_.cell_to_cell.has(coord_):
		return null
	var cell_: PileCellData = pile_.cell_to_cell[coord_]
	if not cell_.is_revealed:
		return null
	return cell_.tile


func _can_close(rules_: RulesData, field_: ChainFieldData, gobble_: Vector2i, tile_: HexTileData, phase_: int) -> bool:
	for rotation_ in Catalog.EDGE_COUNT:
		if rules_.is_place_valid(field_, gobble_, tile_, rotation_, self, phase_):
			return true
	return false
