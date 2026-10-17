class_name Tile
extends Node2D


@onready var edges: Node2D = %Edges
@onready var links: Node2D = %Links

var data: HexTileData:
	set(value_):
		data = value_
		_redraw()

var rotation_step: int = 0:
	set(value_):
		rotation_step = value_
		rotation = rotation_step * TAU / float(Catalog.EDGE_COUNT)


func _ready() -> void:
	_redraw()


func _redraw() -> void:
	if not is_node_ready():
		return
	for child in links.get_children():
		(child as Line2D).points = PackedVector2Array()
	if data == null:
		return
	for index in data.links.size():
		if index >= links.get_child_count():
			return
		var link := data.links[index] as LinkData
		var line := links.get_child(index) as Line2D
		line.points = _link_points(link)
		line.default_color = _link_color(link.color)


func _edge_position(edge_: int) -> Vector2:
	return edges.get_child(edge_).position


func _link_points(link_: LinkData) -> PackedVector2Array:
	var point_a := _edge_position(link_.edge_a)
	var point_b := _edge_position(link_.edge_b)
	var shape_name := Bozo.enum_to_string(Bozo.Type.LINK_SHAPE, link_.shape)
	if shape_name == "straight":
		return PackedVector2Array([point_a, point_b])
	var pull := point_a.length()
	if shape_name == "bend":
		pull *= Catalog.LINK_BEND_PULL
	var control := (point_a + point_b).normalized() * pull
	return PackedVector2Array([point_a, control, point_b])


func _link_color(color_: int) -> Color:
	var name_ := Bozo.enum_to_string(Bozo.Type.HUE, color_)
	if name_ == "red":
		return Color(0.86, 0.18, 0.18)
	if name_ == "yellow":
		return Color(0.9, 0.75, 0.15)
	if name_ == "green":
		return Color(0.2, 0.65, 0.3)
	if name_ == "blue":
		return Color(0.2, 0.4, 0.85)
	return Color(1, 1, 1)
