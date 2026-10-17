class_name InputData
extends RefCounted


var pile: PileData
var chain_root: ChainData
var selection: SelectionData
var hints: HintData
var gobbles: GobbleData
var phase: PhaseData
var rules: RulesData


func _init(chain_root_: ChainData) -> void:
	#region init
	chain_root = chain_root_
	pile = chain_root_.pile
	selection = chain_root_.selection
	hints = chain_root_.hints
	gobbles = chain_root_.gobbles
	phase = chain_root_.phase_data
	rules = chain_root_.rules
	#endregion


func handle_key(keycode_: int) -> void:
	if keycode_ == KEY_Q:
		chain_root.rotate(-1)
		return
	if keycode_ == KEY_E:
		chain_root.rotate(1)
		return
	if keycode_ == KEY_SPACE:
		chain_root.toggle_hints()


func handle_click(button_: int, pile_cell_: PileCell, phantom_: Variant) -> void:
	if button_ == MOUSE_BUTTON_LEFT and phantom_ != null:
		var slot_: Vector3i = phantom_
		chain_root.place_tile(Vector2i(slot_.x, slot_.y), slot_.z)
		return
	if button_ == MOUSE_BUTTON_LEFT and pile_cell_ != null:
		_on_pile_left(pile_cell_.data.coord)
		return
	if button_ == MOUSE_BUTTON_LEFT:
		chain_root.unpick()
		return
	if button_ == MOUSE_BUTTON_RIGHT and pile_cell_ != null:
		_on_pile_right(pile_cell_.data.coord)
		return
	if button_ == MOUSE_BUTTON_RIGHT:
		chain_root.unpick()


func _on_pile_left(coord_: Vector2i) -> void:
	var kind_name_ := Bozo.enum_to_string(Bozo.Type.SELECTION, selection.kind)
	if chain_root.field.is_empty() and kind_name_ != "none" and selection.coord != coord_:
		chain_root.try_first_move(selection.coord, coord_)
		return
	chain_root.hover(coord_)


func _on_pile_right(coord_: Vector2i) -> void:
	var kind_name_ := Bozo.enum_to_string(Bozo.Type.SELECTION, selection.kind)
	if kind_name_ == "picked":
		chain_root.unpick()
		return
	chain_root.hover(coord_)
	chain_root.pick()
