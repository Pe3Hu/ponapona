extends Node


const kink_orders: Array[int] = [
	Bozo.Order.I,
	Bozo.Order.II,
	Bozo.Order.III,
]

const direction_indexes: Array[int] = [0, 1, 2, 3, 4, 5]

const hex_directions: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
	Vector2i(1, -1),
]

const direction_differences: Array = [
	[
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0),
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
	],
	[
		Vector2i(1, 1),
		Vector2i(0, 1),
		Vector2i(-1, 1),
		Vector2i(-1, 0),
		Vector2i(0, -1),
		Vector2i(1, 0),
	],
]

const line_color_to_godot_color: Dictionary = {
	Bozo.LineColor.RED: Color.CRIMSON,
	Bozo.LineColor.BLUE: Color.ROYAL_BLUE,
	Bozo.LineColor.GREEN: Color.WEB_GREEN,
	Bozo.LineColor.YELLOW: Color.GOLD,
}

const line_colors: Array[int] = [
	Bozo.LineColor.RED,
	Bozo.LineColor.BLUE,
	Bozo.LineColor.GREEN,
	Bozo.LineColor.YELLOW,
]

var chunk_patterns: Array[Pattern] = []


#region init
func _init() -> void:
	chunk_patterns = [
		load("res://tantrix/tile/patterns/aabbcc.tres"),
		load("res://tantrix/tile/patterns/aabcbc.tres"),
		load("res://tantrix/tile/patterns/aabccb.tres"),
		load("res://tantrix/tile/patterns/abcabc.tres"),
		load("res://tantrix/tile/patterns/abcacb.tres"),
	]
	for pattern in chunk_patterns:
		pattern.init_order_to_indexs()
#endregion
