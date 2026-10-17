class_name HintData
extends RefCounted


signal enabled_changed
signal phantoms_changed

var enabled: bool = true:
	set(value_):
		enabled = value_
		enabled_changed.emit()

var phantoms: Array[Vector3i] = []


func recalc(rules_: RulesData, selection_: SelectionData, gobbles_: GobbleData, phase_: int, field_: ChainFieldData, pile_: PileData) -> void:
	phantoms.clear()
	var kind_name_ := Bozo.enum_to_string(Bozo.Type.SELECTION, selection_.kind)
	if enabled and kind_name_ != "none":
		var tile_ := _tile(pile_, selection_.coord)
		if tile_ != null:
			phantoms = rules_.get_valid_slots(field_, tile_, gobbles_, phase_)
	phantoms_changed.emit()


func _tile(pile_: PileData, coord_: Vector2i) -> HexTileData:
	if not pile_.cell_to_cell.has(coord_):
		return null
	var cell_: PileCellData = pile_.cell_to_cell[coord_]
	if not cell_.is_revealed:
		return null
	return cell_.tile
