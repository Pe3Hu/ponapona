class_name PileCellData
extends RefCounted


var coord: Vector2i
var tile: HexTileData
var is_revealed: bool = false


func _init(coord_: Vector2i, tile_: HexTileData) -> void:
	#region init
	coord = coord_
	tile = tile_
	#endregion
