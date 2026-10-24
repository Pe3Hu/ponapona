class_name Kink
extends Line2D


var start: Vector2
var medium: Vector2
var end: Vector2
var line_color: int = Bozo.LineColor.NONE


func setup(start_: Vector2, end_: Vector2, line_color_: int) -> void:
	start = start_
	end = end_
	medium = Vector2.ZERO
	line_color = line_color_
	default_color = Digest.line_color_to_godot_color[line_color_]
	recalc_points()

func recalc_points() -> void:
	clear_points()
	var curve := Curve2D.new()
	curve.add_point(start)
	curve.add_point(end, medium - end)
	for point in curve.get_baked_points():
		add_point(point)
