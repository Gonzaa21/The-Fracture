extends Control

var signal_level: float = 0.0

var bar_height: int = 16
var border_width: float = 1.5

# Colores
var color_bg = Color(0.09, 0.09, 0.09)
var color_fill_low = Color(0.36, 0.22, 0.21)
var color_fill_mid = Color(0.40, 0.35, 0.22)
var color_fill_high = Color(0.24, 0.38, 0.25)

func set_signal(value: float):
	signal_level = clamp(value, 0.0, 100.0)
	queue_redraw()

func _draw():
	var width = size.x
	var height = size.y
	
	draw_rect(Rect2(border_width, border_width, 
		width - border_width * 2, 
		height - border_width * 2), color_bg, true)
		
	var fill_width = (width - border_width * 4) * (signal_level / 100.0)
	
	if fill_width > 0:
		var fill_color = color_fill_low
		if signal_level > 70:
			fill_color = color_fill_high
		elif signal_level > 40:
			fill_color = color_fill_mid
		
		draw_rect(Rect2(border_width * 2, border_width * 2, 
			fill_width, 
			height - border_width * 4), fill_color, true)
		
		for i in range(int(fill_width / 4)):
			var x = border_width * 2 + i * 4
			draw_line(
				Vector2(x, border_width * 2), 
				Vector2(x, height - border_width * 2),
				Color(1, 1, 1, 0.1), 1
			)
