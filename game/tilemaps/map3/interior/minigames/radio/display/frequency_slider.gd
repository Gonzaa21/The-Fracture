extends Control

signal value_changed(value: float)

@export var min_value: float = -0.5
@export var max_value: float = 0.5
@export var current_value: float = 0.0

var is_dragging: bool = false

var bar_height: int = 10
var knob_width: int = 5
var knob_height: int = 5

var color_bar_bg =  Color(0.162, 0.162, 0.162, 1.0)
var color_bar_fill = Color(0.2, 0.2, 0.2)
var color_knob = Color(0.385, 0.385, 0.385, 1.0)

func _ready():
	set_process_input(true)

func _draw():
	var width = size.x
	var height = size.y
	var center_y = height / 2.0
	
	var bar_rect = Rect2(0, center_y - bar_height / 2.0, width, bar_height)
	draw_rect(bar_rect, color_bar_bg, true)
	
	var normalized = (current_value - min_value) / (max_value - min_value)
	var fill_width = width * normalized
	var fill_rect = Rect2(0, center_y - bar_height / 2.0, fill_width, bar_height)
	draw_rect(fill_rect, color_bar_fill, true)
	
	var knob_x = fill_width - knob_width
	var knob_rect = Rect2(
		knob_x / 1.03, 
		center_y - knob_height / 2.0,
		knob_width,
		knob_height
	)
	
	draw_rect(knob_rect.grow(2), Color(0, 0, 0, 0.5), true)
	
	draw_rect(knob_rect, color_knob, true)
	

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var local_pos = get_local_mouse_position()
			if Rect2(Vector2.ZERO, size).has_point(local_pos):
				is_dragging = true
				_update_value_from_position(event.position.x)
				accept_event()
		else:
			is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		_update_value_from_position(event.position.x)

func _update_value_from_position(x: float):
	var width = size.x
	var normalized = clamp(x / width, 0.0, 1.0)
	current_value = lerp(min_value, max_value, normalized)
	emit_signal("value_changed", current_value)
	queue_redraw()

func set_value(value: float):
	current_value = clamp(value, min_value, max_value)
	queue_redraw()

func get_custom_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)
