extends Control

signal value_changed(value: float)

@export var min_value: float = -0.5
@export var max_value: float = 0.5
@export var current_value: float = 0.0

var edge_margin: int = 2.5
var is_dragging: bool = false

var bar_height: int = 10
var knob_width: int = 5
var knob_height: int = 5

var color_bar_bg =  Color(0.162, 0.162, 0.162, 1.0)
var color_bar_fill = Color(0.2, 0.2, 0.2)
var color_knob = Color(0.385, 0.385, 0.385, 1.0)

func _ready():
	set_process_input(true)

func _draw() -> void:
	var width = size.x
	var height = size.y
	var center_y = (height - bar_height) / 2.0
	
	var bar_rect = Rect2(0, center_y, width, bar_height)
	draw_rect(bar_rect, color_bar_bg, true)
	
	var normalized = (current_value - min_value) / (max_value - min_value)
	
	var usable_width = width - (knob_width + (edge_margin * 2.0))
	var fill_width = edge_margin + (normalized * usable_width)
	
	var fill_rect = Rect2(0, center_y, fill_width + (knob_width / 2.0), bar_height)
	draw_rect(fill_rect, color_bar_fill, true)
	
	var knob_x = fill_width
	var knob_center_y = (height - knob_height) / 2.0
	var knob_rect = Rect2(knob_x, knob_center_y, knob_width, knob_height)
	
	var shadow_rect = Rect2(knob_x - 2, knob_center_y - 2, knob_width + 4, knob_height + 4)
	draw_rect(shadow_rect, Color(0, 0, 0, 0.3), true)
	
	draw_rect(knob_rect, color_knob, true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var local_pos = get_local_mouse_position()
			if Rect2(Vector2.ZERO, size).has_point(local_pos):
				is_dragging = true
				_update_value_from_position(local_pos.x)
				accept_event()
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = false
			
	elif event is InputEventMouseMotion and is_dragging:
		_update_value_from_position(get_local_mouse_position().x)

func _update_value_from_position(x: float) -> void:
	var width = size.x
	var usable_width = width - (knob_width + (edge_margin * 2.0))
	var adjusted_x = x - edge_margin - (knob_width / 2.0)
	adjusted_x = clamp(adjusted_x, 0.0, usable_width)
	var normalized = adjusted_x / usable_width
	current_value = lerp(min_value, max_value, normalized)
	
	emit_signal("value_changed", current_value)
	queue_redraw()

func set_value(value: float) -> void:
	current_value = clamp(value, min_value, max_value)
	queue_redraw()

func get_custom_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)
