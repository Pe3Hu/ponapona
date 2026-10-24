class_name Sandbox
extends Node


@export var hand_tile_scene: PackedScene

var _camera_dragging: bool = false

var data: SandboxData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()
		init_hand()


#region init
func _ready() -> void:
	data = Mother.sandbox
#endregion


func connect_datas() -> void:
	%Board.data = data.board

func connect_signals() -> void:
	data.hand_changed.connect(_on_hand_changed)
	_on_hand_changed()
	data.board_changed.connect(_on_board_changed)
	_on_board_changed()
	data.selection_changed.connect(_on_selection_changed)
	_on_selection_changed()
	data.forced_spaces_changed.connect(_on_forced_spaces_changed)
	_on_forced_spaces_changed()
	data.bag_refilled.connect(_on_bag_refilled)
	_on_bag_refilled()

func init_hand() -> void:
	_rebuild_hand()

func _on_hand_changed() -> void:
	_rebuild_hand()
	_update_bag_label(false)
	_update_status()

func _on_board_changed() -> void:
	_highlight_board()
	_update_status()

func _on_selection_changed() -> void:
	_rebuild_hand()
	_highlight_board()
	_update_status()

func _on_forced_spaces_changed() -> void:
	%Board.highlight_forced(data.get_forced_spaces_with_fit())
	var spaces := data.get_forced_spaces_with_fit()
	if spaces.is_empty():
		%HintLabel.text = ""
	else:
		%HintLabel.text = "Можно закрыть вырезов: %d" % spaces.size()

func _on_bag_refilled() -> void:
	_update_bag_label(true)

func _rebuild_hand() -> void:
	Helper.clear_children(%Hand)
	for tile in data.hand:
		add_hand_tile(tile)

func add_hand_tile(tile_: HexTileData) -> void:
	var view := hand_tile_scene.instantiate() as HandTile
	%Hand.add_child(view)
	view.data = tile_
	view.is_selected = tile_ == data.selected_hand_tile
	view.pressed.connect(_on_hand_tile_pressed)
	view.discard_pressed.connect(_on_hand_tile_discard)

func _on_hand_tile_pressed(tile_data_: HexTileData) -> void:
	data.apply_selection(tile_data_)

func _on_hand_tile_discard(tile_data_: HexTileData) -> void:
	data.apply_discard(tile_data_)

func _highlight_board() -> void:
	if data.selected_hand_tile == null:
		%Board.highlight_cells([])
	else:
		%Board.highlight_cells(data.get_valid_cells_for(data.selected_hand_tile))

func _update_bag_label(is_refill_: bool) -> void:
	if is_refill_:
		%BagLabel.text = "В мешке: %d (мешок #%d)" % [data.bag.remaining_count(), data.bag.refill_count]
	else:
		%BagLabel.text = "В мешке: %d" % data.bag.remaining_count()

func _update_status() -> void:
	if not data.has_any_legal_move():
		%StatusLabel.text = "Нет ходов — сбросьте тайл"
	elif data.selected_hand_tile == null:
		%StatusLabel.text = "Выберите тайл"
	else:
		%StatusLabel.text = "Поставьте тайл"

func _process(delta_: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("camera_left"):
		direction.x -= 1.0
	if Input.is_action_pressed("camera_right"):
		direction.x += 1.0
	if Input.is_action_pressed("camera_up"):
		direction.y -= 1.0
	if Input.is_action_pressed("camera_down"):
		direction.y += 1.0
	if direction == Vector2.ZERO:
		return
	%Camera.pan(direction.normalized() * Catalog.CAMERA_PAN_SPEED * delta_)

func _unhandled_input(event_: InputEvent) -> void:
	if event_ is InputEventMouseButton:
		var button := event_ as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_MIDDLE:
			_camera_dragging = button.pressed
			get_viewport().set_input_as_handled()
			return
		if button.pressed and (button.button_index == MOUSE_BUTTON_WHEEL_UP or button.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var step: float = SandboxCamera.ZOOM_STEP
			if button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				step = -SandboxCamera.ZOOM_STEP
			%Camera.zoom_at(_world_mouse(button), step)
			get_viewport().set_input_as_handled()
			return
	if event_ is InputEventMouseMotion and _camera_dragging:
		var motion := event_ as InputEventMouseMotion
		%Camera.pan(-motion.relative / %Camera.zoom)
		get_viewport().set_input_as_handled()
		return
	if event_.is_action_pressed("camera_reset"):
		%Camera.reset()
		return
	if data == null:
		return
	if event_.is_action_pressed("auto_place"):
		var placed: bool = data.apply_auto_place()
		if placed:
			%StatusLabel.text = "Авто: поставлено"
		else:
			%StatusLabel.text = "Не могу поставить"
		get_viewport().set_input_as_handled()
		return
	if event_.is_action_pressed("tile_rotate_left"):
		data.apply_rotation(-1)
	elif event_.is_action_pressed("tile_rotate_right"):
		data.apply_rotation(1)
	elif event_.is_action_pressed("click") and event_ is InputEventMouseButton:
		if data.selected_hand_tile == null:
			return
		var click := event_ as InputEventMouseButton
		var cell: Vector2i = %Board.get_cell_at_global(_world_mouse(click))
		if data.apply_placement(data.selected_hand_tile, cell):
			_update_status()
		else:
			%StatusLabel.text = "Нельзя"

func _world_mouse(event_: InputEventMouse) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * event_.position
