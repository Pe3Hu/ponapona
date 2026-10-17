class_name ChainField
extends Node2D


const CELL_SCENE := preload("uid://cchaincellsc1")

@onready var chain_cells: Node2D = %ChainCells

var data: ChainFieldData:
	set(value_):
		data = value_
		connect_signals()
		init_cells()


func _ready() -> void:
	init_cells()


func connect_signals() -> void:
	if data == null:
		return
	if not data.tile_placed.is_connected(_on_tile_placed):
		data.tile_placed.connect(_on_tile_placed)
	if not data.field_cleared.is_connected(_on_field_cleared):
		data.field_cleared.connect(_on_field_cleared)


func init_cells() -> void:
	if not is_node_ready():
		return
	Helper.clear_children(chain_cells)
	if data == null:
		return
	for cell_data_ in data.cell_to_cell.values():
		if cell_data_.tile == null:
			continue
		add_cell(cell_data_)


func add_cell(cell_data_: ChainCellData) -> void:
	var cell := CELL_SCENE.instantiate() as ChainCell
	chain_cells.add_child(cell)
	cell.data = cell_data_


func _on_tile_placed(_coord_: Vector2i) -> void:
	init_cells()


func _on_field_cleared() -> void:
	init_cells()
