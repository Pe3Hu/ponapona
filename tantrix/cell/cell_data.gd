class_name CellData
extends RefCounted


signal coord_changed

var tile_data: HexTileData = null
var coord: Vector2i:
	set(value_):
		coord = value_
		coord_changed.emit()


func register(board_, coord_: Vector2i) -> void:
	board_.cells.append(self)
	board_.external_coords.append(coord_)
	board_.coord_to_cell[coord_] = self
	coord = coord_
