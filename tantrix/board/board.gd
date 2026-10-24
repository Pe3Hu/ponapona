class_name Board
extends Node2D


@export var cell_scene: PackedScene

@export var is_interactive: bool = true

var data: BoardData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()
		init_tiles()

var coord_to_cell_view: Dictionary = {}
var highlight_cell_coords: Array[Vector2i] = []
var highlight_forced_coords: Array[Vector2i] = []


func connect_datas() -> void:
	pass

func connect_signals() -> void:
	data.changed.connect(_on_changed)
	_on_changed()
	data.layout_changed.connect(_on_changed)
	data.legality_changed.connect(_on_legality_changed)
	_on_legality_changed()

func init_tiles() -> void:
	pass

func _on_changed() -> void:
	Helper.clear_children(%Cells)
	coord_to_cell_view.clear()
	if data.tiles.is_empty():
		var radius := Catalog.FIRST_MOVE_RADIUS
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var distance := maxi(absi(x), maxi(absi(y), absi(x + y)))
				if distance <= radius:
					_add_board_cell(Vector2i(x, y), null)
		_apply_highlights()
		return
	var occupied: Dictionary = {}
	for tile_data in data.tiles:
		occupied[tile_data.origin] = tile_data
		_add_board_cell(tile_data.origin, tile_data)
	var seen: Dictionary = {}
	for tile_data in data.tiles:
		for direction in Digest.direction_indexes:
			var coord: Vector2i = tile_data.origin + Digest.hex_directions[direction]
			if occupied.has(coord) or seen.has(coord):
				continue
			seen[coord] = true
			_add_board_cell(coord, null)
	_apply_highlights()

func _on_legality_changed() -> void:
	pass

func _add_board_cell(coord_: Vector2i, tile_data_: HexTileData) -> void:
	var cell_data := CellData.new()
	cell_data.tile_data = tile_data_
	cell_data.coord = coord_
	var cell := cell_scene.instantiate() as Cell
	%Cells.add_child(cell)
	cell.is_interactive = is_interactive
	cell.data = cell_data
	cell.position = get_pixel_at_coord(coord_)
	coord_to_cell_view[coord_] = cell

func get_pixel_at_coord(coord_: Vector2i) -> Vector2:
	return Helper.hex_to_pixel(coord_, Catalog.CHUNK_L)

func get_cell_at_global(pos_: Vector2) -> Vector2i:
	return Helper.pixel_to_hex(to_local(pos_), Catalog.CHUNK_L)

func highlight_cells(cells_: Array) -> void:
	highlight_cell_coords.clear()
	for coord in cells_:
		highlight_cell_coords.append(coord)
	_apply_highlights()

func highlight_forced(cells_: Array) -> void:
	highlight_forced_coords.clear()
	for coord in cells_:
		highlight_forced_coords.append(coord)
	_apply_highlights()

func _apply_highlights() -> void:
	for coord in coord_to_cell_view:
		var cell: Cell = coord_to_cell_view[coord]
		cell.highlight = highlight_cell_coords.has(coord)
		cell.highlight_forced = highlight_forced_coords.has(coord)
		cell._apply_highlight()
