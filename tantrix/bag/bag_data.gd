class_name BagData
extends RefCounted


var remaining: Array[HexTileData] = []
var refill_count: int = 0
var bag_size: int = 0


func init(bag_size_: int) -> void:
	bag_size = bag_size_
	remaining.clear()
	refill_count = 0
	if bag_size_ == 0:
		return
	_refill()

func draw_random() -> HexTileData:
	if remaining.is_empty():
		if bag_size == 0:
			return null
		_refill()
	if remaining.is_empty():
		return null
	var index := Helper.rng.randi_range(0, remaining.size() - 1)
	var tile: HexTileData = remaining[index]
	remaining.remove_at(index)
	return tile

func remaining_count() -> int:
	return remaining.size()

func is_empty() -> bool:
	return remaining.is_empty()

func _refill() -> void:
	for _index in bag_size:
		remaining.append(_generate_tile())
	refill_count += 1

func generate_one() -> HexTileData:
	return _generate_tile()

func _generate_tile() -> HexTileData:
	for _attempt in Catalog.CHUNK_N:
		var tile := _make_tile()
		if tile.is_valid():
			return tile
		push_warning("BagData: invalid tile, retry")
	return _make_tile()

func _make_tile() -> HexTileData:
	var pool: Array[int] = []
	pool.append_array(Catalog.LINE_COLOR_POOL)
	Helper.shuffle(pool)
	var edges: Array[int] = [0, 1, 2, 3, 4, 5]
	Helper.shuffle(edges)
	var edge_colors: Array[int] = []
	var links: Array[int] = []
	edge_colors.resize(Catalog.CHUNK_N)
	links.resize(Catalog.CHUNK_N)
	for pair in 3:
		var left: int = edges[pair * 2]
		var right: int = edges[pair * 2 + 1]
		var color: int = pool[pair]
		edge_colors[left] = color
		edge_colors[right] = color
		links[left] = right
		links[right] = left
	var tile := HexTileData.new()
	tile.init_with_colors(edge_colors, links, Vector2i.ZERO, 0)
	return tile
