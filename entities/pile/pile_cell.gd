class_name PileCell
extends Node2D


const TILE_SCENE := preload("uid://btile0scene01")

@onready var back: Polygon2D = %Back
@onready var face: Node2D = %Face

var data: PileCellData:
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
	Helper.clear_children(face)
	var show_tile := data.tile != null and data.is_revealed
	back.visible = data.tile != null and not data.is_revealed
	face.visible = show_tile
	if not show_tile:
		return
	var tile := TILE_SCENE.instantiate() as Tile
	face.add_child(tile)
	tile.data = data.tile


func _place() -> void:
	if data == null:
		return
	position = Helper.axial_to_world(data.coord)
