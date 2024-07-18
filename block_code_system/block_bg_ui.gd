@tool
extends Control

const KNOB_X = 10.0
const KNOB_W = 20.0
const KNOB_H = 5.0
const KNOB_Z = 5.0
const CONTROL_MARGIN = 20.0
const OUTLINE_WIDTH = 3.0
const MINIMUM_SNAP_DISTANCE = 80.0

var outline_color: Color

@export var color: Color:
	set = _set_color

@export var show_top: bool = true:
	set = _set_show_top

## Horizontally shift the top knob
@export var shift_top: float = 0.0:
	set = _set_shift_top

## Horizontally shift the bottom knob
@export var shift_bottom: float = 0.0:
	set = _set_shift_bottom


func _set_color(new_color):
	color = new_color
	outline_color = color.darkened(0.2)
	queue_redraw()


func _set_show_top(new_show_top):
	show_top = new_show_top
	queue_redraw()


func _set_shift_top(new_shift_top):
	shift_top = new_shift_top
	queue_redraw()


func _set_shift_bottom(new_shift_bottom):
	shift_bottom = new_shift_bottom
	queue_redraw()


func _draw():
	var fill_polygon: PackedVector2Array
	fill_polygon.append(Vector2(0.0, 0.0))
	if show_top:
		fill_polygon.append(Vector2(KNOB_X + shift_top, 0.0))
		fill_polygon.append(Vector2(KNOB_X + KNOB_Z + shift_top, KNOB_H))
		fill_polygon.append(Vector2(KNOB_X + KNOB_Z + KNOB_W + shift_top, KNOB_H))
		fill_polygon.append(Vector2(KNOB_X + KNOB_Z * 2 + KNOB_W + shift_top, 0.0))

	fill_polygon.append(Vector2(size.x, 0.0))
	fill_polygon.append(Vector2(size.x, size.y))
	fill_polygon.append(Vector2(KNOB_X + KNOB_Z * 2 + KNOB_W + shift_bottom, size.y))
	fill_polygon.append(Vector2(KNOB_X + KNOB_Z + KNOB_W + shift_bottom, size.y + KNOB_H))
	fill_polygon.append(Vector2(KNOB_X + KNOB_Z + shift_bottom, size.y + KNOB_H))
	fill_polygon.append(Vector2(KNOB_X + shift_bottom, size.y))
	fill_polygon.append(Vector2(0.0, size.y))
	fill_polygon.append(Vector2(0.0, 0.0))

	var stroke_polygon: PackedVector2Array
	stroke_polygon.append(Vector2(shift_top, 0.0))
	if show_top:
		stroke_polygon.append(Vector2(KNOB_X + shift_top, 0.0))
		stroke_polygon.append(Vector2(KNOB_X + KNOB_Z + shift_top, KNOB_H))
		stroke_polygon.append(Vector2(KNOB_X + KNOB_Z + KNOB_W + shift_top, KNOB_H))
		stroke_polygon.append(Vector2(KNOB_X + KNOB_Z * 2 + KNOB_W + shift_top, 0.0))

	stroke_polygon.append(Vector2(size.x, 0.0))
	stroke_polygon.append(Vector2(size.x, size.y))
	stroke_polygon.append(Vector2(KNOB_X + KNOB_Z * 2 + KNOB_W + shift_bottom, size.y))
	stroke_polygon.append(Vector2(KNOB_X + KNOB_Z + KNOB_W + shift_bottom, size.y + KNOB_H))
	stroke_polygon.append(Vector2(KNOB_X + KNOB_Z + shift_bottom, size.y + KNOB_H))
	stroke_polygon.append(Vector2(KNOB_X + shift_bottom, size.y))

	stroke_polygon.append(Vector2(shift_bottom, size.y))
	if shift_top + shift_bottom == 0:
		stroke_polygon.append(Vector2(0.0, 0.0))

	draw_colored_polygon(fill_polygon, color)
	draw_polyline(stroke_polygon, outline_color, OUTLINE_WIDTH)
