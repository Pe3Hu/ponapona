class_name PileData
extends RefCounted


signal tile_revealed(coord_: Vector2i)
signal tile_taken(coord_: Vector2i)

var cell_to_cell: Dictionary[Vector2i, PileCellData] = {}
var hidden_tiles: Array[HexTileData] = []


func _init(tiles_: Array[HexTileData]) -> void:
	#region init
	for index in Digest.pile_layout.size():
		var cell_ := get_cell(Digest.pile_layout[index])
		if index >= tiles_.size():
			continue
		cell_.tile = tiles_[index]
		hidden_tiles.append(cell_.tile)
	#endregion


func get_cell(coord_: Vector2i) -> PileCellData:
	if cell_to_cell.has(coord_):
		return cell_to_cell[coord_]
	var cell_ := PileCellData.new(coord_, null)
	cell_to_cell[coord_] = cell_
	return cell_


func reveal_random() -> PileCellData:
	if hidden_tiles.is_empty():
		return null
	var index := Helper.rng.randi_range(0, hidden_tiles.size() - 1)
	var tile_ := hidden_tiles[index]
	hidden_tiles.remove_at(index)
	for cell_ in cell_to_cell.values():
		if cell_.tile != tile_:
			continue
		cell_.is_revealed = true
		tile_revealed.emit(cell_.coord)
		return cell_
	return null


func move_to_chain(coord_: Vector2i) -> void:
	if not cell_to_cell.has(coord_):
		return
	var cell_ := cell_to_cell[coord_]
	if cell_.tile == null:
		return
	hidden_tiles.erase(cell_.tile)
	cell_.tile = null
	cell_.is_revealed = false
	tile_taken.emit(coord_)


func is_empty_hidden() -> bool:
	return hidden_tiles.is_empty()
