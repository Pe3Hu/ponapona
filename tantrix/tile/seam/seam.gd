class_name Seam
extends Sprite2D


var direction_index: int:
	set(value_):
		direction_index = value_
		position = Catalog.outside_mediums[direction_index] * 0.9
		rotation = PI * 2.0 / Catalog.CHUNK_N * (direction_index - 1)
