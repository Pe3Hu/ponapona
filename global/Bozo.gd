extends Node


enum Type {
	NONE = 0,
	ORDER = 8,
	ASPECT = 9,
	LINE_COLOR = 17,
	TILE_FIT = 18,
}

enum Aspect {
	NONE = 0,
	ENDURANCE = 1,
	STRENGTH = 2,
	AGILITY = 3,
	OBSERVATION = 4,
}

enum Order {
	NONE = 0,
	I = 5,
	II = 6,
	III = 7,
}

enum LineColor {
	NONE = 0,
	RED = 10,
	BLUE = 11,
	GREEN = 12,
	YELLOW = 13,
}

enum TileFit {
	NONE = 0,
	ABC = 14,
	ABA = 15,
	AAB = 16,
}


var type_to_enum: Dictionary = {}
var type_to_index: Dictionary = {}


#region init
func _init() -> void:
	type_to_enum = {
		Type.ORDER: Order,
		Type.ASPECT: Aspect,
		Type.LINE_COLOR: LineColor,
		Type.TILE_FIT: TileFit,
	}
	init_type_to_index()

func init_type_to_index() -> void:
	type_to_index.clear()
	for type in type_to_enum:
		var values: Dictionary = type_to_enum[type]
		var value_to_index := {}
		var index := 0
		for key in values:
			value_to_index[values[key]] = index
			index += 1
		type_to_index[type] = value_to_index
#endregion


func enum_to_string(type_: Type, value_: int) -> String:
	var values: Dictionary = type_to_enum[type_]
	for key in values:
		if values[key] == value_:
			return String(key).to_lower()
	return ""
