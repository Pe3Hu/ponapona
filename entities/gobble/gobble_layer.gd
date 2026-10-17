class_name GobbleLayer
extends Node2D


@onready var template: Polygon2D = %MarkerTemplate
@onready var markers: Node2D = %Markers

var data: GobbleData:
	set(value_):
		data = value_
		connect_signals()
		refresh()


func _ready() -> void:
	refresh()


func connect_signals() -> void:
	if data == null:
		return
	if not data.gobbles_changed.is_connected(_on_gobbles_changed):
		data.gobbles_changed.connect(_on_gobbles_changed)
	if not data.forced_changed.is_connected(_on_forced_changed):
		data.forced_changed.connect(_on_forced_changed)


func refresh() -> void:
	if not is_node_ready():
		return
	Helper.clear_children(markers)
	if data == null:
		return
	for coord_ in data.coords:
		add_marker(coord_, data.forced_coords.has(coord_))


func add_marker(coord_: Vector2i, forced_: bool) -> void:
	var marker := template.duplicate() as Polygon2D
	marker.visible = true
	marker.position = Helper.axial_to_world(coord_)
	marker.color = Color(0.95, 0.55, 0.15, 0.85)
	if forced_:
		marker.color = Color(0.9, 0.2, 0.15, 0.9)
	markers.add_child(marker)


func _on_gobbles_changed() -> void:
	refresh()


func _on_forced_changed() -> void:
	refresh()
