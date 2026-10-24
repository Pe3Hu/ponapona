class_name HexTileData
extends RefCounted


signal rotation_steps_changed

var edge_colors: Array[int] = []
var connections: Array[int] = []
var origin: Vector2i = Vector2i.ZERO
var rotation_steps: int = 0:
	set(value_):
		rotation_steps = value_
		rotation_steps_changed.emit()


func init_with_colors(edge_colors_: Array[int], connections_: Array[int], origin_: Vector2i = Vector2i.ZERO, rotation_steps_: int = 0) -> void:
	edge_colors = edge_colors_.duplicate()
	connections = connections_.duplicate()
	origin = origin_
	rotation_steps = rotation_steps_

func get_world_edge_color(world_edge_: int) -> int:
	return edge_colors[(world_edge_ - rotation_steps + Catalog.CHUNK_N) % Catalog.CHUNK_N]

func get_world_connection(world_edge_: int) -> int:
	var local_edge: int = (world_edge_ - rotation_steps + Catalog.CHUNK_N) % Catalog.CHUNK_N
	return (connections[local_edge] + rotation_steps) % Catalog.CHUNK_N

func get_world_cells() -> Array[Vector2i]:
	return [origin]

func is_valid() -> bool:
	if edge_colors.size() != Catalog.CHUNK_N or connections.size() != Catalog.CHUNK_N:
		return false
	if rotation_steps < 0 or rotation_steps > 5:
		return false
	for color in edge_colors:
		if not _is_line_color(int(color)):
			return false
	for index in Catalog.CHUNK_N:
		var partner: int = connections[index]
		if partner == index or partner < 0 or partner >= Catalog.CHUNK_N:
			return false
		if connections[partner] != index:
			return false
	return true

func register(board_) -> void:
	board_.tiles.append(self)
	board_.coord_to_tile[origin] = self
	board_.internal_coords.append(origin)

func _is_line_color(color_: int) -> bool:
	return color_ == Bozo.LineColor.NONE or color_ == Bozo.LineColor.RED or color_ == Bozo.LineColor.BLUE or color_ == Bozo.LineColor.GREEN or color_ == Bozo.LineColor.YELLOW
