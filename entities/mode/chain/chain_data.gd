class_name ChainData
extends RefCounted


var pile: PileData
var field: ChainFieldData
var pool: PoolData
var selection: SelectionData
var hints: HintData
var gobbles: GobbleData
var phase_data: PhaseData
var phase: int = Bozo.Phase.NORMAL
var result: int = Bozo.Result.NONE
var display: DisplayData
var rules: RulesData
var input

var is_moving: bool = false


func _init() -> void:
	#region init
	var tiles_: Array[HexTileData] = []
	for index_ in Catalog.TILE_COUNT:
		tiles_.append(HexTileData.new(index_ + 1))
	pile = PileData.new(tiles_)
	pool = PoolData.new()
	field = ChainFieldData.new()
	gobbles = GobbleData.new()
	phase_data = PhaseData.new()
	phase = phase_data.phase
	result = phase_data.result
	display = DisplayData.new()
	rules = RulesData.new()
	selection = SelectionData.new()
	hints = HintData.new()
	input = preload("res://entities/input/input_data.gd").new(self)
	_connect()
	pool.refill(pile, Catalog.POOL_SIZE)
	_recalc_chain()
	#endregion


func hover(coord_: Vector2i) -> void:
	selection.hover(coord_)


func pick() -> void:
	selection.pick()


func unpick() -> void:
	selection.unpick()


func rotate(dir_: int) -> void:
	selection.rotate(dir_)


func toggle_hints() -> void:
	hints.enabled = not hints.enabled
	_recalc_hints()


func try_first_move(coord_a_: Vector2i, coord_b_: Vector2i) -> void:
	if _is_finished() or not field.is_empty():
		return
	var tile_a_ := _revealed_tile(coord_a_)
	var tile_b_ := _revealed_tile(coord_b_)
	if tile_a_ == null or tile_b_ == null:
		return
	var rot_a_ := 0
	if selection.coord == coord_a_:
		rot_a_ = selection.rotation
	var direction_ := Catalog.EDGE_COUNT
	var rot_b_ := 0
	for dir_ in Catalog.EDGE_COUNT:
		for rotation_ in Catalog.EDGE_COUNT:
			if not rules.is_first_move_valid(tile_a_, rot_a_, tile_b_, rotation_):
				continue
			var opposite_ := Helper.opposite_direction(dir_)
			var color_a_ := RulesData.get_edge_color(tile_a_, rot_a_, dir_)
			var color_b_ := RulesData.get_edge_color(tile_b_, rotation_, opposite_)
			if color_a_ == Bozo.Hue.NONE or color_a_ != color_b_:
				continue
			direction_ = dir_
			rot_b_ = rotation_
			break
		if direction_ < Catalog.EDGE_COUNT:
			break
	if direction_ == Catalog.EDGE_COUNT:
		return
	var origin_ := Vector2i(Catalog.BOARD_RADIUS, 0)
	var neighbor_: Vector2i = origin_
	var index_ := 0
	for offset_ in Digest.direction_to_offset.values():
		if index_ == direction_:
			neighbor_ = origin_ + offset_
			break
		index_ += 1
	is_moving = true
	pool.take(coord_a_)
	pool.take(coord_b_)
	pile.move_to_chain(coord_a_)
	pile.move_to_chain(coord_b_)
	field.set_tile(origin_, tile_a_, rot_a_)
	field.set_tile(neighbor_, tile_b_, rot_b_)
	pool.refill(pile, Catalog.POOL_SIZE)
	selection.unpick()
	is_moving = false
	_recalc_chain()


func place_tile(coord_: Vector2i, rotation_: int) -> void:
	if _is_finished():
		return
	var tile_ := _selected_tile()
	if tile_ == null:
		return
	if not rules.is_place_valid(field, coord_, tile_, rotation_, gobbles, phase):
		return
	var from_ := selection.coord
	is_moving = true
	pool.take(from_)
	pile.move_to_chain(from_)
	field.set_tile(coord_, tile_, rotation_)
	pool.refill(pile, Catalog.POOL_SIZE)
	selection.unpick()
	is_moving = false
	_recalc_chain()


func end_turn() -> void:
	phase_data.recalc(pile, field, pool, rules, gobbles)
	phase = phase_data.phase
	result = phase_data.result
	display.recalc(field, gobbles, phase_data)


func _connect() -> void:
	pile.tile_revealed.connect(_on_pile_changed)
	pile.tile_taken.connect(_on_pile_changed)
	field.tile_placed.connect(_on_tile_placed)
	gobbles.forced_changed.connect(_on_forced_changed)
	selection.selection_changed.connect(_on_selection_changed)
	phase_data.phase_changed.connect(_on_phase_changed)


func _on_pile_changed(_coord_: Vector2i) -> void:
	if is_moving:
		return
	gobbles.recalc_forced(pool, rules, phase, pile, field)


func _on_tile_placed(_coord_: Vector2i) -> void:
	if is_moving:
		return
	_recalc_chain()


func _on_forced_changed() -> void:
	if is_moving:
		return
	_recalc_hints()


func _on_selection_changed() -> void:
	if is_moving:
		return
	_recalc_hints()


func _on_phase_changed() -> void:
	phase = phase_data.phase
	result = phase_data.result
	display.recalc(field, gobbles, phase_data)


func _recalc_chain() -> void:
	field.recalc_frontier()
	gobbles.recalc(field)
	gobbles.recalc_controlled(field)
	gobbles.recalc_forced(pool, rules, phase, pile, field)
	_recalc_hints()
	end_turn()


func _recalc_hints() -> void:
	hints.recalc(rules, selection, gobbles, phase, field, pile)


func _selected_tile() -> HexTileData:
	var kind_name_ := Bozo.enum_to_string(Bozo.Type.SELECTION, selection.kind)
	if kind_name_ == "none":
		return null
	return _revealed_tile(selection.coord)


func _revealed_tile(coord_: Vector2i) -> HexTileData:
	if not pile.cell_to_cell.has(coord_):
		return null
	var cell_ := pile.cell_to_cell[coord_]
	if not cell_.is_revealed:
		return null
	return cell_.tile


func _is_finished() -> bool:
	return Bozo.enum_to_string(Bozo.Type.PHASE, phase) == "finished"
