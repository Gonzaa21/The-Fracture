extends CanvasLayer

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const WRONG_PENALTY: float = 8.0
const HIT_RADIUS: float = 10.0
const WIRE_COUNT: int = 5

const WIRE_OUTLINE := Color(0.0, 0.0, 0.0, 0.85)
const WRONG_COLOR := Color(1.0, 0.2, 0.2, 0.75)
const SELECT_COLOR := Color(1.0, 1.0, 1.0, 0.4)

@export var board_scale: float = 1.0
@export var debug_ports: bool = false
@export var overlay_right_colors: bool = false
@export var port_size: Vector2 = Vector2(11, 8)

@export var left_ports: Array[Vector2] = [
	Vector2(84, 97), Vector2(84, 113), Vector2(84, 130), Vector2(84, 147), Vector2(84, 164)
]
@export var right_ports: Array[Vector2] = [
	Vector2(172, 97), Vector2(172, 113), Vector2(172, 130), Vector2(172, 147), Vector2(172, 164)
]

@export var wire_colors: Array[Color] = [
	Color(0.9, 0.15, 0.15),
	Color(0.95, 0.8, 0.15),
	Color(0.2, 0.75, 0.25),
	Color(0.2, 0.5, 0.95),
	Color(0.95, 0.5, 0.15),
]

@export var right_colors: Array[Color] = [
	Color(0.95, 0.8, 0.15),
	Color(0.9, 0.15, 0.15),
	Color(0.2, 0.5, 0.95),
	Color(0.95, 0.5, 0.15),
	Color(0.2, 0.75, 0.25),
]

@onready var board: TextureRect = $Board
@onready var lines: Control = $Board/Lines
@onready var close_button: Button = $CloseButton

var connections: Dictionary = {}        # índice izquierdo -> índice derecho
var right_match: Array[int] = []        # para cada conector derecho, qué índice izquierdo le corresponde
var drag_left: int = -1
var _wrong_left: int = -1
var _wrong_right: int = -1
var _finished: bool = false
var _closing: bool = false

func _ready() -> void:
	var tex_size := board.texture.get_size()
	board.size = tex_size
	board.scale = Vector2.ONE * board_scale
	board.position = ((get_viewport().get_visible_rect().size - tex_size * board_scale) / 2.0).round()
	lines.position = Vector2.ZERO
	lines.size = tex_size
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.draw.connect(_on_lines_draw)
	
	close_button.text = "[X]"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_override("font", FONT)
	close_button.add_theme_font_size_override("font_size", 8)
	close_button.pressed.connect(close)
	
	_build_right_match()
	lines.queue_redraw()

func _build_right_match() -> void:
	right_match.clear()
	for j in right_colors.size():
		var idx := -1
		for i in wire_colors.size():
			if right_colors[j].is_equal_approx(wire_colors[i]):
				idx = i
				break
		if idx < 0:
			push_warning("wires_minigame: right_colors[%d] no coincide con ningún color de wire_colors" % j)
		right_match.append(idx)

func _process(_delta: float) -> void:
	if _closing or _finished:
		return
	if not GameManager.is_cooling_active() or GameManager.emergency_disabled:
		close()
		return
	if Input.is_action_just_pressed("ui_cancel"):
		close()
		return
	if drag_left >= 0:
		lines.queue_redraw()

func _input(event: InputEvent) -> void:
	if _closing or _finished:
		return
	if not (event is InputEventMouseButton):
		return
	
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_cancel_drag()
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	var pos := lines.get_local_mouse_position()
	
	if event.pressed:
		var li := _port_at(left_ports, pos)
		if li >= 0 and not connections.has(li):
			drag_left = li
			lines.queue_redraw()
			get_viewport().set_input_as_handled()
	else:
		if drag_left < 0:
			return
		get_viewport().set_input_as_handled()
		var rj := _port_at(right_ports, pos)
		if rj >= 0:
			_try_connect(rj)
		else:
			_cancel_drag()

func _port_at(ports: Array[Vector2], pos: Vector2) -> int:
	for i in ports.size():
		if pos.distance_to(ports[i]) <= HIT_RADIUS:
			return i
	return -1

func _cancel_drag() -> void:
	drag_left = -1
	lines.queue_redraw()

func _try_connect(j: int) -> void:
	var i := drag_left
	drag_left = -1
	if i < 0 or j >= right_match.size() or connections.values().has(j):
		lines.queue_redraw()
		return
	
	if right_match[j] == i:
		connections[i] = j
		lines.queue_redraw()
		if connections.size() == WIRE_COUNT:
			_complete()
	else:
		AlarmManager.apply_penalty(WRONG_PENALTY)
		_flash_wrong(i, j)

func _flash_wrong(i: int, j: int) -> void:
	_wrong_left = i
	_wrong_right = j
	lines.queue_redraw()
	await get_tree().create_timer(0.35).timeout
	if not is_inside_tree() or _closing:
		return
	_wrong_left = -1
	_wrong_right = -1
	lines.queue_redraw()

func _complete() -> void:
	_finished = true
	drag_left = -1
	lines.queue_redraw()
	await get_tree().create_timer(0.9).timeout
	if _closing:
		return
	GameManager.complete_basement_system("wires")
	close()

func close() -> void:
	if _closing:
		return
	_closing = true
	queue_free()

func _on_lines_draw() -> void:
	# cuadros de color sobre los conectores derechos (opcional)
	if overlay_right_colors:
		for j in right_ports.size():
			var rect := Rect2(right_ports[j] - port_size / 2.0, port_size)
			lines.draw_rect(rect, right_colors[j], true)
			lines.draw_rect(rect, WIRE_OUTLINE, false, 1.0)
	
	# cables conectados: el color es el del conector izquierdo
	for i in connections.keys():
		var j: int = connections[i]
		_draw_wire(left_ports[i], right_ports[j], wire_colors[i])
	
	# cable que se está arrastrando
	if drag_left >= 0:
		lines.draw_circle(left_ports[drag_left], 6.0, SELECT_COLOR)
		_draw_wire(left_ports[drag_left], lines.get_local_mouse_position(), wire_colors[drag_left])
	
	# error
	if _wrong_left >= 0:
		lines.draw_circle(left_ports[_wrong_left], 6.0, WRONG_COLOR)
		lines.draw_circle(right_ports[_wrong_right], 6.0, WRONG_COLOR)
	
	# calibración
	if debug_ports:
		for p in left_ports:
			lines.draw_circle(p, 2.0, Color(0, 1, 0))
		for p in right_ports:
			lines.draw_circle(p, 2.0, Color(0, 1, 0))

func _draw_wire(from: Vector2, to: Vector2, color: Color) -> void:
	lines.draw_line(from, to, WIRE_OUTLINE, 4.0)
	lines.draw_line(from, to, color, 2.0)
