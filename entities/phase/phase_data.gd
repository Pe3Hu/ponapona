class_name PhaseData
extends RefCounted


signal phase_changed

var phase: int = Bozo.Phase.NORMAL
var result: int = Bozo.Result.NONE


func recalc(pile_: PileData, field_: ChainFieldData, pool_: PoolData, rules_: RulesData, gobbles_: GobbleData) -> void:
	var rules_phase_ := Bozo.Phase.NORMAL
	if pile_.is_empty_hidden():
		rules_phase_ = Bozo.Phase.ENDGAME
	var next_phase_ := Bozo.Phase.NORMAL
	var next_result_ := Bozo.Result.NONE
	if field_.chain_size == Catalog.TILE_COUNT:
		next_phase_ = Bozo.Phase.FINISHED
		next_result_ = Bozo.Result.WIN
	elif _is_stuck(pile_, pool_, field_, rules_, gobbles_, rules_phase_):
		next_phase_ = Bozo.Phase.FINISHED
		next_result_ = Bozo.Result.LOSE
	elif pile_.is_empty_hidden():
		next_phase_ = Bozo.Phase.ENDGAME
	if next_phase_ == phase and next_result_ == result:
		return
	phase = next_phase_
	result = next_result_
	phase_changed.emit()


func _is_stuck(pile_: PileData, pool_: PoolData, field_: ChainFieldData, rules_: RulesData, gobbles_: GobbleData, phase_: int) -> bool:
	if field_.is_empty() or pool_.coords.is_empty():
		return false
	for coord_ in pool_.coords:
		if not pile_.cell_to_cell.has(coord_):
			continue
		var cell_: PileCellData = pile_.cell_to_cell[coord_]
		if cell_.tile == null:
			continue
		if not rules_.get_valid_slots(field_, cell_.tile, gobbles_, phase_).is_empty():
			return false
	return true
