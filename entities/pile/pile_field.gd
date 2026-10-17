class_name PileField
extends Node2D


const CELL_SCENE := preload("uid://bpilecellscn1")

@onready var pile_cells: Node2D = %PileCells

var coord_to_cell: Dictionary[Vector2i, PileCell] = {}

var data: PileData:
	set(value_):
		data = value_
		connect_signals()
		init_cells()


func _ready() -> void:
	init_cells()


func connect_signals() -> void:
	if data == null:
		return
	if not data.tile_revealed.is_connected(_on_tile_revealed):
		data.tile_revealed.connect(_on_tile_revealed)
	if not data.tile_taken.is_connected(_on_tile_taken):
		data.tile_taken.connect(_on_tile_taken)


func init_cells() -> void:
	if not is_node_ready():
		return
	Helper.clear_children(pile_cells)
	coord_to_cell.clear()
	if data == null:
		return
	for cell_data_ in data.cell_to_cell.values():
		add_cell(cell_data_)


func add_cell(cell_data_: PileCellData) -> void:
	var cell := CELL_SCENE.instantiate() as PileCell
	pile_cells.add_child(cell)
	cell.data = cell_data_
	coord_to_cell[cell_data_.coord] = cell


func _on_tile_revealed(coord_: Vector2i) -> void:
	_refresh_cell(coord_)


func _on_tile_taken(coord_: Vector2i) -> void:
	_refresh_cell(coord_)


func cell_at(point_: Vector2) -> PileCell:
	if pile_cells == null:
		return null
	for child in pile_cells.get_children():
		var cell_ := child as PileCell
		if cell_ == null or cell_.data == null or cell_.data.tile == null:
			continue
		if not cell_.data.is_revealed:
			continue
		if cell_.global_position.distance_to(point_) > Catalog.HEX_SIZE * 0.5:
			continue
		return cell_
	return null


func _refresh_cell(coord_: Vector2i) -> void:
	if not coord_to_cell.has(coord_):
		return
	coord_to_cell[coord_].refresh()
