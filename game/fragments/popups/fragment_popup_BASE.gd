extends CanvasLayer

@onready var panel = $Panel
@onready var title_label = get_node_or_null("%TitleLabel")
@onready var content_label = get_node_or_null("%ContentLabel")
@onready var metadata_label = get_node_or_null("%MetadataLabel")
@onready var close_button = get_node_or_null("Panel/MarginContainer/VBoxContainer/CloseButton")
@onready var photo_texture = get_node_or_null("Panel/MarginContainer/VBoxContainer/TextureRect")
@onready var lots_label = get_node_or_null("Panel/MarginContainer/VBoxContainer/TextureRect/LotsLabel")

@export var back_texture: Texture2D

const LOT_GROUPS := [[0, 1], [2, 3], [4]]
const FLIP_HINT := "[clic para voltear]"

var _front_texture: Texture2D = null
var _back_lots: Array = []
var _showing_back: bool = false

func _ready():
	panel.visible = false
	close_button.pressed.connect(_on_close_button_pressed)
	if photo_texture:
		photo_texture.mouse_filter = Control.MOUSE_FILTER_STOP  # el TextureRect ignora el mouse por defecto
		photo_texture.gui_input.connect(_on_photo_gui_input)
	if lots_label:
		lots_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lots_label.visible = false
 
func show_fragment(fragment_id: String):
	var fragment_data = GameManager.fragments_database[fragment_id]
	if fragment_data == null:
		print("ERROR: Fragmento no encontrado: ", fragment_id)
		return
	
	if "title" in fragment_data:
		title_label.text = fragment_data["title"]
	else:
		title_label.text = fragment_id.capitalize()
	
	content_label.text = fragment_data["content"]
	
	var metadata_parts = []
	
	if "date" in fragment_data:
		metadata_parts.append(fragment_data["date"])
	if "author" in fragment_data: 
		metadata_parts.append(fragment_data["author"])
	
	metadata_label.text = " | ".join(metadata_parts)
	panel.visible = true
	Global.input_locked = true
 
func show_photo(texture: Texture2D, back_lots: Array = []):
	if texture == null: return
	_front_texture = texture
	_back_lots = back_lots
	_showing_back = false
	_apply_side()
	
	title_label.visible = false
	metadata_label.visible = false
	
	panel.visible = true
	Global.input_locked = true

func _apply_side() -> void:
	var has_back: bool = not _back_lots.is_empty()
	
	if _showing_back and has_back:
		if back_texture != null:
			photo_texture.texture = back_texture
			photo_texture.self_modulate = Color.WHITE
		else:
			photo_texture.texture = _front_texture  # provisional hasta tener el sprite del reverso
			photo_texture.self_modulate = Color(0.4, 0.35, 0.3)
		if lots_label:
			lots_label.text = _format_lots(_back_lots)
			lots_label.visible = true
	else:
		photo_texture.texture = _front_texture
		photo_texture.self_modulate = Color.WHITE
		if lots_label:
			lots_label.visible = false
	
	photo_texture.visible = true
	content_label.text = FLIP_HINT if has_back else ""
	content_label.visible = true

func _format_lots(lots: Array) -> String:
	var lines: Array = []
	for group in LOT_GROUPS:
		var parts: Array = []
		for i in group:
			if i < lots.size():
				parts.append(str(lots[i]))
		if not parts.is_empty():
			lines.append("   ".join(parts))
	return "\n".join(lines)

func _on_photo_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _back_lots.is_empty():
			return
		_showing_back = not _showing_back
		_apply_side()
		photo_texture.accept_event()

func _on_close_button_pressed():
	panel.visible = false
	_showing_back = false
	_back_lots = []
	_front_texture = null
	if lots_label:
		lots_label.visible = false
	if photo_texture:
		photo_texture.visible = false
		photo_texture.texture = null
		photo_texture.self_modulate = Color.WHITE
	if content_label:
		content_label.text = ""
		content_label.visible = true
	Global.input_locked = false
