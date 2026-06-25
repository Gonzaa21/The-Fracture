extends Control

signal value_changed(value: float)

@export var min_value: float = 0.0
@export var max_value: float = 9.0
@export var current_value: float = 87.5

var is_dragging: bool = false
var last_mouse_y: float = 0.0
var drag_sensitivity: float = 0.1

var color_bg = Color(0.10, 0.10, 0.10, 1.0)
var color_ring_outer = Color(0.20, 0.20, 0.20)
var color_ring_inner = Color(0.32, 0.32, 0.32)
var color_needle = Color(0.48, 0.26, 0.24)
var color_center = Color(0.38, 0.38, 0.38)

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw():
	var w = size.x
	var h = size.y
	var margin = 6.9
	
	var num_lines = 5
	var spacing = h / num_lines
	
	var normalized = (current_value - min_value) / (max_value - min_value)
	var offset = fmod(normalized * spacing * num_lines, spacing)
	
	for i in range(num_lines + 1):
		var y = fmod(i * spacing + offset, h)
		var thickness = 1
		if abs(y - h/2) < spacing * 0.2:
			thickness = 1.5
		_draw_pixelated_line(
			Vector2(margin, y), 
			Vector2(w - margin, y), 
			color_ring_inner, 
			thickness
		)
	
	_draw_pixelated_line(
		Vector2(margin, h/2),
		Vector2(w - margin, h/2),
		color_needle,
		1.5
	)

func _draw_pixelated_line(from: Vector2, to: Vector2, color: Color, thickness: int):
	var x0 = int(from.x)
	var y0 = int(from.y)
	var x1 = int(to.x)
	var y1 = int(to.y)
	
	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx - dy
	
	while true:
		for ty in range(-thickness/2.0, thickness/2.0 + 1.0):
			for tx in range(-thickness/2.0, thickness/2.0 + 1.0):
				draw_rect(Rect2(x0 + tx, y0 + ty, 1, 1), color, true)
		
		if x0 == x1 and y0 == y1:
			break
		
		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var local_pos = get_local_mouse_position()
			var rect = Rect2(Vector2.ZERO, size)
			if not rect.has_point(local_pos): return
			
			is_dragging = true
			last_mouse_y = event.position.y
			get_viewport().set_input_as_handled()
		else:
			is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		var delta_y = last_mouse_y - event.position.y
		last_mouse_y = event.position.y
		current_value = clamp(current_value + delta_y * drag_sensitivity, min_value, max_value)
		emit_signal("value_changed", current_value)
		queue_redraw()

func _update_value_from_mouse(mouse_pos: Vector2):
		emit_signal("value_changed", current_value)
		queue_redraw()

func set_value(value: float):
	if abs(value - current_value) > 0.01:
		current_value = clamp(value, min_value, max_value)
		queue_redraw()
