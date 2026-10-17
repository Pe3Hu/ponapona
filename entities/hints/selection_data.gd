class_name SelectionData
extends RefCounted


signal selection_changed

var coord: Vector2i
var kind: int = Bozo.Selection.NONE
var rotation: int = 0


func hover(coord_: Vector2i) -> void:
	if coord != coord_:
		rotation = 0
	coord = coord_
	kind = Bozo.Selection.HOVER
	selection_changed.emit()


func pick() -> void:
	kind = Bozo.Selection.PICKED
	selection_changed.emit()


func unpick() -> void:
	kind = Bozo.Selection.NONE
	selection_changed.emit()


func rotate(dir_: int) -> void:
	rotation = posmod(rotation + dir_, Catalog.EDGE_COUNT)
	selection_changed.emit()
