extends TextureRect
class_name DraggablePage

@export var pick_by_alpha: bool = true
@export var min_visible: float = 100.0

var _dragging: bool = false
var _grab_offset: Vector2 = Vector2.ZERO
var _image: Image = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if pick_by_alpha and texture != null:
		_image = texture.get_image()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_grab_offset = get_global_mouse_position() - global_position
			move_to_front()
			accept_event()
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		global_position = _clamp_to_screen(get_global_mouse_position() - _grab_offset)
		accept_event()

func _clamp_to_screen(pos: Vector2) -> Vector2:
	var screen: Vector2 = get_viewport_rect().size
	var page_size: Vector2 = size * scale
	var min_pos := Vector2(min_visible - page_size.x, min_visible - page_size.y)
	var max_pos := Vector2(screen.x - min_visible, screen.y - min_visible)
	return Vector2(clampf(pos.x, min_pos.x, max_pos.x), clampf(pos.y, min_pos.y, max_pos.y))

func _has_point(point: Vector2) -> bool:
	if _image == null or size.x <= 0.0 or size.y <= 0.0:
		return Rect2(Vector2.ZERO, size).has_point(point)

	var tex_size := Vector2(_image.get_size())
	var px := Vector2i((point / size * tex_size).floor())
	if px.x < 0 or px.y < 0 or px.x >= _image.get_width() or px.y >= _image.get_height():
		return false
	return _image.get_pixelv(px).a > 0.1
