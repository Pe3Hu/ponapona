class_name HandTile
extends Control


signal pressed(tile_data_: HexTileData)
signal discard_pressed(tile_data_: HexTileData)

const KINK_SCENE := preload("res://tantrix/tile/kink/kink.tscn")

var is_selected: bool = false:
	set(value_):
		is_selected = value_
		_apply_highlight()

var data: HexTileData:
	set(value_):
		data = value_
		_draw_tile()


func _ready() -> void:
	var span := Catalog.HEX_SIZE * Catalog.HAND_TILE_SCALE * 2.2
	custom_minimum_size = Vector2(span, span)
	mouse_filter = Control.MOUSE_FILTER_STOP
	%Pivot.scale = Vector2(Catalog.HAND_TILE_SCALE, Catalog.HAND_TILE_SCALE)
	%Pivot.position = custom_minimum_size / 2.0
	_draw_tile()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		%Pivot.position = size / 2.0

func _gui_input(event_: InputEvent) -> void:
	if not event_ is InputEventMouseButton or not event_.pressed:
		return
	if event_.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(data)
		accept_event()
	elif event_.button_index == MOUSE_BUTTON_RIGHT:
		discard_pressed.emit(data)
		accept_event()

func _draw_tile() -> void:
	if not is_node_ready():
		return
	var points := PackedVector2Array()
	for index in Catalog.CHUNK_N:
		var angle := deg_to_rad(60.0 * index - 30.0)
		points.append(Vector2.from_angle(angle) * Catalog.HEX_SIZE)
	%Hex.polygon = points
	Helper.clear_children(%Lines)
	if data == null:
		return
	%Lines.rotation = Catalog.CHUNK_ANGLE * data.rotation_steps
	for edge in data.connections.size():
		var partner: int = data.connections[edge]
		if partner < edge:
			continue
		var kink := KINK_SCENE.instantiate() as Kink
		%Lines.add_child(kink)
		kink.setup(_edge_mid(edge), _edge_mid(partner), data.edge_colors[edge])

func _edge_mid(edge_: int) -> Vector2:
	var first := deg_to_rad(60.0 * edge_ - 30.0)
	var second := deg_to_rad(60.0 * (edge_ + 1) - 30.0)
	var start := Vector2.from_angle(first) * Catalog.HEX_SIZE
	var finish := Vector2.from_angle(second) * Catalog.HEX_SIZE
	return (start + finish) / 2.0

func _apply_highlight() -> void:
	modulate = Color(1.0, 0.92, 0.55) if is_selected else Color.WHITE
