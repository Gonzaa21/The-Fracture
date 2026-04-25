extends Control

var wave_offset: float = 0.0
var sync_level: float = 0.0

var color_wave1 = Color(0.713, 0.998, 0.723, 1.0)
var color_wave2 = Color(0.37, 0.99, 0.445, 1.0)

var pixel_size: int = 3

func _ready():
	set_process(true)

func _process(delta):
	wave_offset += delta * 3.0
	queue_redraw()

func set_sync_level(level: float):
	sync_level = clamp(level, 0.0, 1.0)

func _draw():
	var width = size.x
	var height = size.y
	var center_y = height / 2.0
	var amplitude = height * 0.38
	var frequency = 1.0
	
	var phase_diff = lerp(PI * 0.5, 0.0, sync_level)
	
	for x in range(0, int(width), pixel_size):
		var y = center_y + sin(x * frequency + wave_offset) * amplitude
		y = clamp(y, 2, height - 2)
		y = floor(y / pixel_size) * pixel_size
		
		draw_rect(Rect2(x, y, pixel_size, pixel_size), color_wave1, true)
	
	for x in range(0, int(width), pixel_size):
		var y = center_y + sin(x * frequency + wave_offset + phase_diff) * amplitude
		y = clamp(y, 2, height - 2)
		y = floor(y / pixel_size) * pixel_size
		
		draw_rect(Rect2(x, y, pixel_size, pixel_size), color_wave2, true)
	
