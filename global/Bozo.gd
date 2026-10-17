extends Node


# NONE = 0 у каждого enum. Остальные значения продолжают общий ряд.


enum Hue {
	NONE = 0,
	RED = 1,
	YELLOW = 2,
	GREEN = 3,
	BLUE = 4,
}

enum LinkShape {
	NONE = 0,
	CORNER = 5,
	BEND = 6,
	STRAIGHT = 7,
}

enum Direction {
	NONE = 0,
	E = 8,
	NE = 9,
	NW = 10,
	W = 11,
	SW = 12,
	SE = 13,
}

enum Selection {
	NONE = 0,
	HOVER = 14,
	PICKED = 15,
}

enum Phase {
	NONE = 0,
	NORMAL = 16,
	ENDGAME = 17,
	FINISHED = 18,
}

enum Result {
	NONE = 0,
	WIN = 19,
	LOSE = 20,
}

enum CellKind {
	NONE = 0,
	PILE = 21,
	CHAIN = 22,
}

enum Type {
	NONE = 0,
	HUE = 23,
	LINK_SHAPE = 24,
	DIRECTION = 25,
	SELECTION = 26,
	PHASE = 27,
	RESULT = 28,
	CELL_KIND = 29,
}

# Первое значение после NONE. Индекс ключа: value - index + 1.
const type_to_index: Dictionary[int, int] = {
	Type.HUE: Hue.RED,
	Type.LINK_SHAPE: LinkShape.CORNER,
	Type.DIRECTION: Direction.E,
	Type.SELECTION: Selection.HOVER,
	Type.PHASE: Phase.NORMAL,
	Type.RESULT: Result.WIN,
	Type.CELL_KIND: CellKind.PILE,
}

const type_to_enum: Dictionary[int, Dictionary] = {
	Type.HUE: Hue,
	Type.LINK_SHAPE: LinkShape,
	Type.DIRECTION: Direction,
	Type.SELECTION: Selection,
	Type.PHASE: Phase,
	Type.RESULT: Result,
	Type.CELL_KIND: CellKind,
}


func enum_to_string(type_: int, value_: int) -> String:
	var enum_dict: Dictionary = type_to_enum[type_]
	if value_ == 0:
		return String(enum_dict.keys()[0]).to_lower()
	var index: int = value_ - type_to_index[type_] + 1
	return String(enum_dict.keys()[index]).to_lower()
