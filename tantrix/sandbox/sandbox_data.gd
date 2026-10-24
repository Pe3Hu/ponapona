class_name SandboxData
extends RefCounted


signal hand_changed
signal board_changed
signal selection_changed
signal forced_spaces_changed
signal bag_refilled

var bag: BagData
var board: BoardData
var hand: Array[HexTileData] = []
var selected_hand_tile: HexTileData


func _init() -> void:
	bag = BagData.new()

func init_sandbox() -> void:
	bag.init(Catalog.BAG_SIZE)
	board = BoardData.new()
	board.init_empty()
	hand = []
	selected_hand_tile = null
	draw_hand()

func draw_hand() -> void:
	var refills_before: int = bag.refill_count
	while hand.size() < Catalog.HAND_SIZE:
		hand.append(bag.draw_random())
	hand_changed.emit()
	if bag.refill_count != refills_before:
		bag_refilled.emit()

func apply_selection(tile_data_: HexTileData) -> void:
	if selected_hand_tile == tile_data_:
		selected_hand_tile = null
	else:
		selected_hand_tile = tile_data_
	selection_changed.emit()

func apply_rotation(delta_steps_: int) -> void:
	if selected_hand_tile == null or delta_steps_ == 0:
		return
	var steps: int = selected_hand_tile.rotation_steps + delta_steps_
	steps = steps % Catalog.CHUNK_N
	if steps < 0:
		steps += Catalog.CHUNK_N
	selected_hand_tile.rotation_steps = steps
	selection_changed.emit()

func apply_discard(tile_data_: HexTileData) -> void:
	if not hand.has(tile_data_):
		return
	var was_selected: bool = selected_hand_tile == tile_data_
	hand.erase(tile_data_)
	if was_selected:
		selected_hand_tile = null
	draw_hand()
	if was_selected:
		selection_changed.emit()

func can_place(tile_: HexTileData, cell_: Vector2i) -> bool:
	if tile_ == null or not tile_.is_valid():
		return false
	if not board.is_cell_free(cell_):
		return false
	if not board.tiles.is_empty() and board.get_neighbor_tile_count(cell_) == 0:
		return false
	for direction in Digest.direction_indexes:
		var neighbor: HexTileData = board.get_tile_at(cell_ + Digest.hex_directions[direction])
		if neighbor == null:
			continue
		var opposite: int = (direction + 3) % Catalog.CHUNK_N
		if tile_.get_world_edge_color(direction) != neighbor.get_world_edge_color(opposite):
			return false
	# 5. forced space priority: если есть closable forced spaces —
	#    cell_ must be one of them
	var forced := get_forced_spaces_with_fit()
	if not forced.is_empty() and cell_ not in forced:
		return false
	# 6. R1: three same colors
	if _creates_three_same_forced(cell_, tile_):
		return false
	# 7. R2, R3: fourth neighbor / controlled cell
	if _is_fourth_neighbor_of_forced(cell_):
		return false
	if _is_controlled_cell(cell_):
		return false
	return true

func apply_placement(tile_: HexTileData, cell_: Vector2i) -> bool:
	if not can_place(tile_, cell_):
		return false
	var placed := HexTileData.new()
	placed.init_with_colors(tile_.edge_colors, tile_.connections, cell_, tile_.rotation_steps)
	board.add_tile(placed)
	hand.erase(tile_)
	selected_hand_tile = null
	draw_hand()
	board_changed.emit()
	forced_spaces_changed.emit()
	selection_changed.emit()
	return true

func get_valid_cells_for(tile_: HexTileData) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if tile_ == null:
		return result
	var candidates: Array[Vector2i] = []
	if board.tiles.is_empty():
		var radius := Catalog.FIRST_MOVE_RADIUS
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var distance := maxi(absi(x), maxi(absi(y), absi(x + y)))
				if distance <= radius:
					candidates.append(Vector2i(x, y))
	else:
		var seen: Dictionary = {}
		for tile in board.tiles:
			for direction in Digest.direction_indexes:
				var coord: Vector2i = tile.origin + Digest.hex_directions[direction]
				if not board.is_cell_free(coord) or seen.has(coord):
					continue
				seen[coord] = true
				candidates.append(coord)
	for cell in candidates:
		if can_place(tile_, cell):
			result.append(cell)
	return result

func get_forced_spaces_with_fit() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in board.get_forced_spaces():
		var neighbors: Array = board.get_neighbor_tiles(cell)
		for tile in hand:
			if _tile_fits_notch(tile, neighbors):
				result.append(cell)
				break
	return result

func find_demanding_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if board.tiles.is_empty():
		result.append(Vector2i.ZERO)
		return result
	var grouped: Array = [[], [], [], []]
	var seen: Dictionary = {}
	for tile in board.tiles:
		for direction in Digest.direction_indexes:
			var coord: Vector2i = tile.origin + Digest.hex_directions[direction]
			if not board.is_cell_free(coord) or seen.has(coord):
				continue
			seen[coord] = true
			var count: int = board.get_neighbor_tile_count(coord)
			if count < 1 or count >= 4:
				continue
			var bucket: Array = grouped[count]
			bucket.append(coord)
	var order: Array[int] = [3, 2, 1]
	for count in order:
		var bucket: Array = grouped[count]
		Helper.shuffle(bucket)
		for coord in bucket:
			result.append(coord)
	return result

func apply_auto_place() -> bool:
	for cell in find_demanding_cells():
		var tile: HexTileData = _generate_tile_for_cell(cell)
		if tile == null:
			continue
		if apply_placement(tile, cell):
			return true
	return false

func has_any_legal_move() -> bool:
	for tile in hand:
		if not get_valid_cells_for(tile).is_empty():
			return true
	return false

func _creates_three_same_forced(cell_: Vector2i, tile_: HexTileData) -> bool:
	for direction in Digest.direction_indexes:
		var notch: Vector2i = cell_ + Digest.hex_directions[direction]
		if board.get_tile_at(notch) != null:
			continue
		var filled: Array[bool] = [false, false, false, false, false, false]
		var count := 0
		for edge in Digest.direction_indexes:
			var neighbor: Vector2i = notch + Digest.hex_directions[edge]
			var occupied: bool = neighbor == cell_ or board.get_tile_at(neighbor) != null
			filled[edge] = occupied
			if occupied:
				count += 1
		if count != 3:
			continue
		var start := -1
		for index in Catalog.CHUNK_N:
			var previous: int = (index + Catalog.CHUNK_N - 1) % Catalog.CHUNK_N
			var filled_here: bool = filled[index]
			var filled_next: bool = filled[(index + 1) % Catalog.CHUNK_N]
			var filled_after: bool = filled[(index + 2) % Catalog.CHUNK_N]
			if filled_here and filled_next and filled_after and not filled[previous]:
				start = index
				break
		if start < 0:
			continue
		var first_color := -1
		var same := true
		for offset in 3:
			var edge: int = (start + offset) % Catalog.CHUNK_N
			var neighbor: Vector2i = notch + Digest.hex_directions[edge]
			var facing: int = (edge + 3) % Catalog.CHUNK_N
			var color: int = tile_.get_world_edge_color(facing)
			if neighbor != cell_:
				color = board.get_tile_at(neighbor).get_world_edge_color(facing)
			if first_color < 0:
				first_color = color
			elif color != first_color:
				same = false
				break
		if same:
			return true
	return false

func _is_fourth_neighbor_of_forced(cell_: Vector2i) -> bool:
	for forced_cell in board.get_forced_spaces():
		for direction in Digest.direction_indexes:
			if forced_cell + Digest.hex_directions[direction] == cell_:
				return true
	return false

func _is_controlled_cell(cell_: Vector2i) -> bool:
	return cell_ in board.get_controlled_cells()

func _generate_tile_for_cell(cell_: Vector2i) -> HexTileData:
	var fixed: Dictionary = {}
	for direction in Digest.direction_indexes:
		var neighbor: HexTileData = board.get_tile_at(cell_ + Digest.hex_directions[direction])
		if neighbor == null:
			continue
		var opposite: int = (direction + 3) % Catalog.CHUNK_N
		fixed[direction] = neighbor.get_world_edge_color(opposite)
	if fixed.size() > 3:
		return null
	for _attempt in Catalog.AUTO_PLACE_ATTEMPTS:
		var tile: HexTileData = bag.generate_one()
		var matches := true
		for direction in fixed:
			var edge: int = int(direction)
			if tile.edge_colors[edge] != int(fixed[edge]):
				matches = false
				break
		if matches:
			return tile
	return null

func _tile_fits_notch(tile_: HexTileData, neighbors_: Array) -> bool:
	var saw_neighbor := false
	for direction in Digest.direction_indexes:
		var neighbor: HexTileData = neighbors_[direction]
		if neighbor == null:
			continue
		saw_neighbor = true
		var opposite: int = (direction + 3) % Catalog.CHUNK_N
		if tile_.get_world_edge_color(direction) != neighbor.get_world_edge_color(opposite):
			return false
	return saw_neighbor
