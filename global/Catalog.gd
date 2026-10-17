extends Node


const TILE_COUNT: int = 56
const EDGE_COUNT: int = 6
const LINK_COUNT: int = 3
const PLAYER_COLORS: Array[int] = [
	Bozo.Hue.RED,
	Bozo.Hue.YELLOW,
	Bozo.Hue.GREEN,
	Bozo.Hue.BLUE,
]
const BOARD_RADIUS: int = 14
const POOL_SIZE: int = 6
const PILE_STEP: int = 2
const GOBBLE_MIN_SIZE: int = 3
const DOUBLE_GOBBLE_SIZE: int = 4
const HOLE_SIZE: int = 6
const LINK_BEND_PULL: float = 0.5
const HEX_SIZE: float = 96.0
const CONTROLLED_TOUCH: int = 2
const PHANTOM_ALPHA: float = 0.5
