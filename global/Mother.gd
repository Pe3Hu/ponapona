extends Node


var chain: ChainData


func _ready() -> void:
	#region init
	Digest.init_tile_links()
	chain = ChainData.new()
	#endregion
