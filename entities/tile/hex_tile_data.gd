class_name HexTileData
extends RefCounted


var id: int
var links: Array[LinkData] = []


func _init(id_: int) -> void:
	#region init
	id = id_
	if not Digest.tile_id_to_links.has(id_):
		return
	links.assign(Digest.tile_id_to_links[id_])
	#endregion
