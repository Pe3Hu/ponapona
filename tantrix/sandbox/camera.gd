class_name SandboxCamera
extends Camera2D


const ZOOM_MIN: float = 0.4
const ZOOM_MAX: float = 2.0
const ZOOM_STEP: float = 0.1


func pan(delta_: Vector2) -> void:
	position += delta_

func zoom_at(mouse_pos_: Vector2, factor_: float) -> void:
	var old_zoom: float = zoom.x
	var new_zoom: float = clampf(old_zoom + factor_, ZOOM_MIN, ZOOM_MAX)
	position += (mouse_pos_ - position) * (1.0 - old_zoom / new_zoom)
	zoom = Vector2(new_zoom, new_zoom)

func reset() -> void:
	position = Vector2.ZERO
	zoom = Vector2.ONE
