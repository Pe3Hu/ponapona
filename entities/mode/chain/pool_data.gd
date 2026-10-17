class_name PoolData
extends RefCounted


signal pool_changed

var coords: Array[Vector2i] = []


func refill(pile_: PileData, size_: int) -> void:
	while coords.size() < size_:
		if pile_.is_empty_hidden():
			break
		var cell_ := pile_.reveal_random()
		if cell_ == null:
			break
		if coords.has(cell_.coord):
			continue
		coords.append(cell_.coord)
	pool_changed.emit()


func take(coord_: Vector2i) -> void:
	coords.erase(coord_)
	pool_changed.emit()
