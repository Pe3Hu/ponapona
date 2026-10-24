class_name Pattern
extends Resource


@export var orders: Array[int] = []

var order_to_indexs: Dictionary = {}
var order_at_index: Array[int] = []


func init_order_to_indexs() -> void:
	order_to_indexs.clear()
	order_at_index.clear()
	order_at_index.resize(orders.size())
	for index in orders.size():
		var order: int = orders[index]
		order_at_index[index] = order
		if not order_to_indexs.has(order):
			order_to_indexs[order] = []
		order_to_indexs[order].append(index)
