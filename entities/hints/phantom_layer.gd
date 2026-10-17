class_name PhantomLayer
extends Node2D


const TILE_SCENE := preload("uid://btile0scene01")

@onready var phantoms_root: Node2D = %Phantoms

var hints: HintData
var pile: PileData
var selection: SelectionData

var data: HintData:
	set(value_):
		data = value_
		hints = value_
		connect_signals()
		refresh()


func _ready() -> void:
	refresh()


func connect_signals() -> void:
	if hints == null:
		return
	if not hints.phantoms_changed.is_connected(_on_phantoms_changed):
		hints.phantoms_changed.connect(_on_phantoms_changed)
	if not hints.enabled_changed.is_connected(_on_phantoms_changed):
		hints.enabled_changed.connect(_on_phantoms_changed)


func refresh() -> void:
	if not is_node_ready():
		return
	Helper.clear_children(phantoms_root)
	if hints == null or pile == null or selection == null:
		return
	var tile_ := _tile()
	if tile_ == null:
		return
	for slot_ in hints.phantoms:
		add_phantom(slot_, tile_)


func add_phantom(slot_: Vector3i, tile_: HexTileData) -> void:
	var node := TILE_SCENE.instantiate() as Tile
	phantoms_root.add_child(node)
	node.position = Helper.axial_to_world(Vector2i(slot_.x, slot_.y))
	node.rotation_step = slot_.z
	node.modulate.a = Catalog.PHANTOM_ALPHA
	node.data = tile_
	node.set_meta("slot", slot_)


func phantom_at(point_: Vector2) -> Variant:
	if phantoms_root == null:
		return null
	for child in phantoms_root.get_children():
		if child.global_position.distance_to(point_) > Catalog.HEX_SIZE * 0.5:
			continue
		return child.get_meta("slot")
	return null


func _tile() -> HexTileData:
	if selection == null or pile == null:
		return null
	var kind_name_ := Bozo.enum_to_string(Bozo.Type.SELECTION, selection.kind)
	if kind_name_ == "none":
		return null
	if not pile.cell_to_cell.has(selection.coord):
		return null
	var cell_: PileCellData = pile.cell_to_cell[selection.coord]
	if not cell_.is_revealed:
		return null
	return cell_.tile


func _on_phantoms_changed() -> void:
	refresh()
