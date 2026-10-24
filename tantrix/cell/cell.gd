class_name Cell
extends Node2D


const KINK_SCENE := preload("res://tantrix/tile/kink/kink.tscn")

var is_selected: bool = false
var is_interactive: bool = true
var highlight: bool = false
var highlight_forced: bool = false
var data: CellData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()
		init_view()


func connect_datas() -> void:
	pass

func connect_signals() -> void:
	pass

func init_view() -> void:
	_draw_hex()
	_draw_lines()
	_apply_highlight()

func _on_area_2d_mouse_entered() -> void:
	is_selected = true

func _on_area_2d_mouse_exited() -> void:
	is_selected = false

func _draw_hex() -> void:
	var points := PackedVector2Array()
	for index in Catalog.CHUNK_N:
		var angle := deg_to_rad(60.0 * index - 30.0)
		points.append(Vector2.from_angle(angle) * Catalog.CHUNK_L)
	%Hex.polygon = points
	if data.tile_data == null:
		%Hex.color = Color(0.75, 0.75, 0.78)
	else:
		%Hex.color = Color(0.93, 0.93, 0.95)

func _draw_lines() -> void:
	Helper.clear_children(%Lines)
	if data.tile_data == null:
		return
	%Lines.rotation = Catalog.CHUNK_ANGLE * data.tile_data.rotation_steps
	var tile := data.tile_data
	for edge in tile.connections.size():
		var partner: int = tile.connections[edge]
		if partner < edge:
			continue
		var kink := KINK_SCENE.instantiate() as Kink
		%Lines.add_child(kink)
		kink.setup(_edge_mid(edge), _edge_mid(partner), tile.edge_colors[edge])

func _edge_mid(edge_: int) -> Vector2:
	var first := deg_to_rad(60.0 * edge_ - 30.0)
	var second := deg_to_rad(60.0 * (edge_ + 1) - 30.0)
	var start := Vector2.from_angle(first) * Catalog.CHUNK_L
	var finish := Vector2.from_angle(second) * Catalog.CHUNK_L
	return (start + finish) / 2.0

func _apply_highlight() -> void:
	if highlight_forced:
		modulate = Color(0.65, 0.88, 1.0)
	elif highlight:
		modulate = Color(1.0, 0.92, 0.55)
	else:
		modulate = Color.WHITE
