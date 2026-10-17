class_name ChainCellData
extends RefCounted


var coord: Vector2i
var tile: HexTileData
var rotation: int = 0


func _init(coord_: Vector2i) -> void:
	#region init
	coord = coord_
	#endregion
