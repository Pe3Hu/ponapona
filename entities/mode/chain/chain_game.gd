class_name ChainGame
extends Node2D


@onready var pile_field: PileField = %PileField
@onready var chain_field: ChainField = %ChainField
@onready var gobble_layer: GobbleLayer = %GobbleLayer
@onready var phantom_layer: PhantomLayer = %PhantomLayer
@onready var hud: DisplayHud = %Hud

var data: ChainData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()


func _ready() -> void:
	data = Mother.chain


func connect_datas() -> void:
	if data == null or pile_field == null:
		return
	phantom_layer.pile = data.pile
	phantom_layer.selection = data.selection
	pile_field.data = data.pile
	chain_field.data = data.field
	gobble_layer.data = data.gobbles
	phantom_layer.data = data.hints
	hud.data = data.display


func connect_signals() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if data == null or pile_field == null:
		return
	if event is InputEventKey:
		var key_ := event as InputEventKey
		if not key_.pressed or key_.echo:
			return
		data.input.handle_key(key_.keycode)
		return
	if event is InputEventMouseButton:
		var mouse_ := event as InputEventMouseButton
		if not mouse_.pressed:
			return
		var point_ := get_global_mouse_position()
		data.input.handle_click(mouse_.button_index, pile_field.cell_at(point_), phantom_layer.phantom_at(point_))
