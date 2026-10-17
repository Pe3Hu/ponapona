class_name ChainCell
extends Node2D


@onready var tile_view: Tile = %Tile

var data: ChainCellData:
	set(value_):
		data = value_
		_place()
		refresh()


func _ready() -> void:
	refresh()


func refresh() -> void:
	if not is_node_ready():
		return
	if data == null:
		return
	_place()
	var show_tile := data.tile != null
	tile_view.visible = show_tile
	if not show_tile:
		return
	tile_view.data = data.tile
	tile_view.rotation_step = data.rotation


func _place() -> void:
	if data == null:
		return
	position = Helper.axial_to_world(data.coord)
