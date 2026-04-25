extends Control

signal value_changed(value: float)

@export var min_value: float = 85.0
@export var max_value: float = 100.0
@export var current_value: float = 87.5

var is_dragging: bool = false
var dial_radius: int = 32

var color_bg = Color(0.10, 0.10, 0.10, 1.0)
var color_ring_outer = Color(0.20, 0.20, 0.20)
var color_ring_inner = Color(0.32, 0.32, 0.32)
var color_needle = Color(0.48, 0.26, 0.24)
var color_center = Color(0.38, 0.38, 0.38)

func _ready():
	custom_minimum_size = Vector2(dial_radius * 2 + 10, dial_radius * 2 + 10)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _draw():
	var center = size / 2.0
	
	var mark_distance = dial_radius - 7
	_draw_pixel_block(center + Vector2(0, -mark_distance), 2, color_ring_inner)  # N
	_draw_pixel_block(center + Vector2(mark_distance, 0), 2, color_ring_inner)   # E
	_draw_pixel_block(center + Vector2(0, mark_distance), 2, color_ring_inner)   # S
	_draw_pixel_block(center + Vector2(-mark_distance, 0), 2, color_ring_inner)  # O
	
	var normalized = (current_value - min_value) / (max_value - min_value)
	var angle = lerp(-PI * 0.75, PI * 0.75, normalized) - PI/2
	
	var needle_length = dial_radius - 16
	var needle_tip = center + Vector2(cos(angle), sin(angle)) * needle_length
	
	_draw_pixelated_line(center, needle_tip, color_needle, 2)
	
	_draw_filled_pixelated_circle(center, 2, color_center)

func _draw_filled_pixelated_circle(center_pos: Vector2, radius: int, color: Color):
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x*x + y*y <= radius*radius:
				draw_rect(Rect2(
					floor(center_pos.x) + x,
					floor(center_pos.y) + y,
					1, 1
				), color, true)


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

func _draw_pixel_block(pos: Vector2, size: int, color: Color):
	for y in range(size):
		for x in range(size):
			draw_rect(Rect2(
				floor(pos.x) - size/2.0 + x,
				floor(pos.y) - size/2.0 + y,
				1, 1
			), color, true)

func _input(event):
	var center = size / 2.0
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var local_pos = get_local_mouse_position()
			
			if local_pos.distance_to(center) <= dial_radius + 5:
				is_dragging = true
				_update_value_from_mouse(local_pos)
				get_viewport().set_input_as_handled()
		else:
			is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		var local_pos = get_local_mouse_position()
		_update_value_from_mouse(local_pos)
		get_viewport().set_input_as_handled()

func _update_value_from_mouse(mouse_pos: Vector2):
	var center = size / 2.0
	var angle = (mouse_pos - center).angle() + PI/2
	var normalized = (angle + PI * 0.75) / (PI * 1.5)
	normalized = clamp(normalized, 0.0, 1.0)
	
	var new_value = lerp(min_value, max_value, normalized)
	
	if abs(new_value - current_value) > 0.01:
		current_value = new_value
		emit_signal("value_changed", current_value)
		queue_redraw()

func set_value(value: float):
	if abs(value - current_value) > 0.01:
		current_value = clamp(value, min_value, max_value)
		queue_redraw()
