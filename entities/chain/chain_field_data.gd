class_name ChainFieldData
extends RefCounted


signal tile_placed(coord_: Vector2i)
signal field_cleared

var cell_to_cell: Dictionary[Vector2i, ChainCellData] = {}
var chain_size: int = 0
var frontier: Array[Vector2i] = []


func get_cell(coord_: Vector2i) -> ChainCellData:
	if cell_to_cell.has(coord_):
		return cell_to_cell[coord_]
	var cell_ := ChainCellData.new(coord_)
	cell_to_cell[coord_] = cell_
	return cell_


func is_empty() -> bool:
	return chain_size == 0


func set_tile(coord_: Vector2i, tile_: HexTileData, rotation_: int) -> void:
	var cell_ := get_cell(coord_)
	var was_empty_ := cell_.tile == null
	cell_.tile = tile_
	cell_.rotation = rotation_
	if was_empty_ and tile_ != null:
		chain_size += 1
	tile_placed.emit(coord_)


func recalc_frontier() -> void:
	frontier.clear()
	var seen_: Dictionary = {}
	for coord_ in cell_to_cell.keys():
		var cell_: ChainCellData = cell_to_cell[coord_]
		if cell_.tile == null:
			continue
		for neighbor_ in Helper.hex_neighbors(coord_):
			if seen_.has(neighbor_):
				continue
			if cell_to_cell.has(neighbor_) and cell_to_cell[neighbor_].tile != null:
				continue
			seen_[neighbor_] = true
			frontier.append(neighbor_)
