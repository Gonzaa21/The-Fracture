extends CanvasLayer

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const TEXT_COLOR := Color(0.85, 0.95, 0.85)
const FADE_TIME := 0.4
const CHARS_PER_SEC := 45.0
const MIN_TIME_BEFORE_SKIP := 0.6

var _bg: ColorRect
var _content: Control
var _image: TextureRect
var _label: Label
var _typing: Tween
var _elapsed: float = 0.0
var _skip: bool = false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_bg = ColorRect.new()
	_bg.color = Color.BLACK
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)
	
	_content = Control.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.modulate.a = 0.0
	add_child(_content)
	
	_image = TextureRect.new()
	_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_image)
	
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.offset_left = 40
	_label.offset_right = -40
	_label.offset_top = 40
	_label.offset_bottom = -40
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 8)
	_label.add_theme_color_override("font_color", TEXT_COLOR)
	_content.add_child(_label)

func _process(_delta: float) -> void:
	if _elapsed >= MIN_TIME_BEFORE_SKIP and Input.is_action_just_pressed("interact"):
		_skip = true

func play(slides: Array, fade_out_at_end: bool) -> void:
	for slide in slides:
		await _show_slide(slide)
	if fade_out_at_end:
		var out := create_tween()
		out.tween_property(_bg, "modulate:a", 0.0, FADE_TIME)
		await out.finished
	queue_free()

func _show_slide(slide: Dictionary) -> void:
	var path: String = slide.get("imagen", "")
	if path != "" and ResourceLoader.exists(path):
		_image.texture = load(path)
	else:
		_image.texture = null
	
	var text: String = slide.get("texto", "")
	_label.text = text
	_label.visible_ratio = 0.0 if text != "" else 1.0
	_elapsed = 0.0
	_skip = false
	
	var fade_in := create_tween()
	fade_in.tween_property(_content, "modulate:a", 1.0, FADE_TIME)
	await fade_in.finished
	
	if text != "":
		_typing = create_tween()
		_typing.tween_property(_label, "visible_ratio", 1.0, text.length() / CHARS_PER_SEC)
	
	var duration: float = float(slide.get("duracion", 3.0))
	while _elapsed < duration and not _skip:
		await get_tree().process_frame
		_elapsed += get_process_delta_time()
	
	if _typing and _typing.is_valid():
		_typing.kill()
	_label.visible_ratio = 1.0
	
	var fade_out := create_tween()
	fade_out.tween_property(_content, "modulate:a", 0.0, FADE_TIME)
	await fade_out.finished
