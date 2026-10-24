extends Node


const CHUNK_SIZE: Vector2 = Vector2(190, 164)
const CHUNK_N: int = 6
const BAG_SIZE: int = 56
const HAND_SIZE: int = 6
const FIRST_MOVE_RADIUS: int = 2
const HEX_SIZE: float = 90.0
const HAND_TILE_SCALE: float = 0.7
const CAMERA_PAN_SPEED: float = 800.0
const AUTO_PLACE_ATTEMPTS: int = 200
const LINE_COLOR_POOL: Array[int] = [
	Bozo.LineColor.RED,
	Bozo.LineColor.BLUE,
	Bozo.LineColor.GREEN,
	Bozo.LineColor.YELLOW,
]
const CHUNK_L: int = 90
const CHUNK_ANGLE: float = PI / 3.0
const MEDIUM_INSIDE_SCALE: float = 0.5
const MEDIUM_OUTSIDE_SCALE: float = 1.0

var outside_mediums: Array[Vector2] = []


#region init
func _init() -> void:
	init_mediums()

func init_mediums() -> void:
	var vertexs: Array[Vector2] = []
	for index in CHUNK_N:
		var vertex := Vector2.from_angle(PI * 2.0 / CHUNK_N * index) * CHUNK_L
		vertexs.append(vertex)
	for index in CHUNK_N:
		var next := (index + 1) % CHUNK_N
		var midpoint := (vertexs[index] + vertexs[next]) / 2.0
		outside_mediums.append(midpoint * MEDIUM_OUTSIDE_SCALE)
#endregion
