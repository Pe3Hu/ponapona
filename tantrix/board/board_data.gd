class_name BoardData
extends RefCounted


signal layout_changed
signal legality_changed
signal changed
var forced_spaces: Array[Vector2i] = []

var tiles: Array[HexTileData] = []
var cells: Array[CellData] = []
var internal_coords: Array[Vector2i] = []
var external_coords: Array[Vector2i] = []
var legal_coords: Array[Vector2i] = []
var illegal_coords: Array[Vector2i] = []
var highlighted_edges: Array[Vector3i] = []
var coord_to_tile: Dictionary = {}
var coord_to_cell: Dictionary = {}


func init_board() -> void:
	init_empty()

func add_tile(tile_data_: HexTileData) -> void:
	tile_data_.register(self)
	remove_cell(tile_data_.origin)
	add_neighbor_cells(tile_data_.origin)
	_rebuild_forced_spaces()
	changed.emit()
	layout_changed.emit()

func remove_cell(coord_: Vector2i) -> void:
	if not coord_to_cell.has(coord_):
		return
	var cell: CellData = coord_to_cell[coord_]
	coord_to_cell.erase(coord_)
	external_coords.erase(coord_)
	cells.erase(cell)
	legal_coords.erase(coord_)
	illegal_coords.erase(coord_)

func add_neighbor_cells(coord_: Vector2i) -> void:
	for direction in Digest.direction_indexes:
		var neighbor := Helper.get_neighbor_coord(coord_, direction)
		if internal_coords.has(neighbor):
			continue
		if external_coords.has(neighbor):
			continue
		CellData.new().register(self, neighbor)

func update_legality() -> void:
	legal_coords.clear()
	illegal_coords.clear()
	highlighted_edges.clear()
	if tiles.is_empty():
		legal_coords.append(Vector2i.ZERO)
	legality_changed.emit()

func is_open_edge(coord_: Vector2i, direction_: int) -> bool:
	var neighbor := Helper.get_neighbor_coord(coord_, direction_)
	return not internal_coords.has(neighbor)

func mark_legal(coord_: Vector2i) -> void:
	illegal_coords.erase(coord_)
	if legal_coords.has(coord_):
		return
	legal_coords.append(coord_)

func mark_illegal(coord_: Vector2i) -> void:
	legal_coords.erase(coord_)
	if illegal_coords.has(coord_):
		return
	illegal_coords.append(coord_)

func init_empty() -> void:
	clear_tiles()
	update_legality()

func get_tile_at(cell_: Vector2i) -> HexTileData:
	return coord_to_tile.get(cell_, null)

func is_cell_free(cell_: Vector2i) -> bool:
	return not coord_to_tile.has(cell_)

func update_tile(tile_data_: HexTileData) -> void:
	var previous: HexTileData = get_tile_at(tile_data_.origin)
	if previous != null:
		tiles.erase(previous)
	if not tiles.has(tile_data_):
		tiles.append(tile_data_)
	coord_to_tile[tile_data_.origin] = tile_data_
	if not internal_coords.has(tile_data_.origin):
		internal_coords.append(tile_data_.origin)
	_rebuild_forced_spaces()
	changed.emit()
	layout_changed.emit()

func clear_tiles() -> void:
	tiles.clear()
	internal_coords.clear()
	coord_to_tile.clear()
	cells.clear()
	external_coords.clear()
	coord_to_cell.clear()
	legal_coords.clear()
	illegal_coords.clear()
	forced_spaces.clear()
	changed.emit()
	layout_changed.emit()

func get_neighbor_tiles(cell_: Vector2i) -> Array:
	var result: Array = []
	result.resize(Catalog.CHUNK_N)
	for direction in Digest.direction_indexes:
		result[direction] = get_tile_at(cell_ + Digest.hex_directions[direction])
	return result

func get_neighbor_tile_count(cell_: Vector2i) -> int:
	var count := 0
	for tile in get_neighbor_tiles(cell_):
		if tile != null:
			count += 1
	return count

func get_forced_spaces() -> Array[Vector2i]:
	return forced_spaces.duplicate()

func is_forced_space(cell_: Vector2i) -> bool:
	return forced_spaces.has(cell_)

func get_controlled_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var seen: Dictionary = {}
	for cell in forced_spaces:
		var run_end := _v_run_end(cell)
		if run_end < 0:
			continue
		for direction in [(run_end + 1) % Catalog.CHUNK_N, (run_end + 3) % Catalog.CHUNK_N]:
			var controlled: Vector2i = cell + Digest.hex_directions[direction]
			if seen.has(controlled):
				continue
			seen[controlled] = true
			result.append(controlled)
	return result

func get_first_tile() -> HexTileData:
	if tiles.is_empty():
		return null
	return tiles[0]

func _rebuild_forced_spaces() -> void:
	forced_spaces.clear()
	var seen: Dictionary = {}
	for tile in tiles:
		for direction in Digest.direction_indexes:
			var cell: Vector2i = tile.origin + Digest.hex_directions[direction]
			if coord_to_tile.has(cell) or seen.has(cell):
				continue
			seen[cell] = true
			if _is_v_notch(cell):
				forced_spaces.append(cell)

func _is_v_notch(cell_: Vector2i) -> bool:
	var filled: Array[bool] = []
	var count := 0
	for direction in Digest.direction_indexes:
		var occupied := get_tile_at(cell_ + Digest.hex_directions[direction]) != null
		filled.append(occupied)
		if occupied:
			count += 1
	if count != 3:
		return false
	for start in Catalog.CHUNK_N:
		if filled[start] and filled[(start + 1) % 6] and filled[(start + 2) % 6]:
			return true
	return false

func _v_run_end(cell_: Vector2i) -> int:
	var filled: Array[bool] = []
	for direction in Digest.direction_indexes:
		filled.append(get_tile_at(cell_ + Digest.hex_directions[direction]) != null)
	for start in Catalog.CHUNK_N:
		var previous := (start + 5) % Catalog.CHUNK_N
		if filled[start] and filled[(start + 1) % 6] and filled[(start + 2) % 6] and not filled[previous]:
			return (start + 2) % Catalog.CHUNK_N
	return -1
