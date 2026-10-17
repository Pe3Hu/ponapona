extends Node


# int -> Array[LinkData]. Заполняется в _ready.
var tile_id_to_links: Dictionary = {}

# Vector2i(edge_a, edge_b) -> Bozo.LinkShape, edge_a < edge_b
const edge_pair_to_shape: Dictionary[Vector2i, int] = {
	Vector2i(0, 1): Bozo.LinkShape.CORNER,
	Vector2i(0, 2): Bozo.LinkShape.BEND,
	Vector2i(0, 3): Bozo.LinkShape.STRAIGHT,
	Vector2i(0, 4): Bozo.LinkShape.BEND,
	Vector2i(0, 5): Bozo.LinkShape.CORNER,
	Vector2i(1, 2): Bozo.LinkShape.CORNER,
	Vector2i(1, 3): Bozo.LinkShape.BEND,
	Vector2i(1, 4): Bozo.LinkShape.STRAIGHT,
	Vector2i(1, 5): Bozo.LinkShape.BEND,
	Vector2i(2, 3): Bozo.LinkShape.CORNER,
	Vector2i(2, 4): Bozo.LinkShape.BEND,
	Vector2i(2, 5): Bozo.LinkShape.STRAIGHT,
	Vector2i(3, 4): Bozo.LinkShape.CORNER,
	Vector2i(3, 5): Bozo.LinkShape.BEND,
	Vector2i(4, 5): Bozo.LinkShape.CORNER,
}

# Bozo.Direction -> Vector2i(q, r), pointy-top
const direction_to_offset: Dictionary[int, Vector2i] = {
	Bozo.Direction.E: Vector2i(1, 0),
	Bozo.Direction.NE: Vector2i(1, -1),
	Bozo.Direction.NW: Vector2i(0, -1),
	Bozo.Direction.W: Vector2i(-1, 0),
	Bozo.Direction.SW: Vector2i(-1, 1),
	Bozo.Direction.SE: Vector2i(0, 1),
}

# 0..5 в порядке Bozo.Direction: E, NE, NW, W, SW, SE
const pile_neighbor_offsets: Dictionary[int, Vector2i] = {
	0: Vector2i(2, -1),
	1: Vector2i(1, -2),
	2: Vector2i(-1, -1),
	3: Vector2i(-2, 1),
	4: Vector2i(-1, 2),
	5: Vector2i(1, 1),
}

const pile_layout: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(-1, -1),
	Vector2i(1, -2),
	Vector2i(2, -1),
	Vector2i(1, 1),
	Vector2i(-1, 2),
	Vector2i(-2, 1),
	Vector2i(0, -3),
	Vector2i(3, -3),
	Vector2i(3, 0),
	Vector2i(0, 3),
	Vector2i(-3, 3),
	Vector2i(-3, 0),
	Vector2i(-2, -2),
	Vector2i(2, -4),
	Vector2i(4, -2),
	Vector2i(2, 2),
	Vector2i(-2, 4),
	Vector2i(-4, 2),
	Vector2i(-4, -1),
	Vector2i(-1, -4),
	Vector2i(1, -5),
	Vector2i(4, -5),
	Vector2i(5, -4),
	Vector2i(5, -1),
	Vector2i(4, 1),
	Vector2i(1, 4),
	Vector2i(-1, 5),
	Vector2i(-4, 5),
	Vector2i(-5, 4),
	Vector2i(-5, 1),
	Vector2i(-3, -3),
	Vector2i(0, -6),
	Vector2i(3, -6),
	Vector2i(6, -6),
	Vector2i(6, -3),
	Vector2i(6, 0),
	Vector2i(3, 3),
	Vector2i(0, 6),
	Vector2i(-3, 6),
	Vector2i(-6, 6),
	Vector2i(-6, 3),
	Vector2i(-6, 0),
	Vector2i(2, -7),
	Vector2i(5, -7),
	Vector2i(7, -5),
	Vector2i(7, -2),
	Vector2i(5, 2),
	Vector2i(2, 5),
	Vector2i(-2, 7),
	Vector2i(-5, 7),
	Vector2i(-7, 5),
	Vector2i(-7, 2),
	Vector2i(7, 1),
	Vector2i(4, 4),
	Vector2i(1, 7),
]

# Bozo.Hue -> String
const color_to_label: Dictionary[int, String] = {
	Bozo.Hue.RED: "red",
	Bozo.Hue.YELLOW: "yellow",
	Bozo.Hue.GREEN: "green",
	Bozo.Hue.BLUE: "blue",
}


func _ready() -> void:
	init_tile_links()


func init_tile_links() -> void:
	if not tile_id_to_links.is_empty():
		return
	var colors_: Array[int] = []
	for color_ in Catalog.PLAYER_COLORS:
		colors_.append(color_)
		if colors_.size() == Catalog.LINK_COUNT:
			break
	for index_ in Catalog.TILE_COUNT:
		var links_: Array[LinkData] = []
		var cursor_ := 0
		for color_index_ in Catalog.LINK_COUNT:
			var edge_a_ := cursor_
			cursor_ += 1
			var edge_b_ := cursor_
			cursor_ += 1
			links_.append(LinkData.new(edge_a_, edge_b_, colors_[color_index_]))
		tile_id_to_links[index_ + 1] = links_
