extends CanvasLayer

@onready var panel = $Panel
@onready var background_texture = get_node_or_null("Panel/BackgroundTexture")
@onready var margin_container = get_node_or_null("Panel/MarginContainer")
@onready var content_container = get_node_or_null("Panel/MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer")
@onready var title_label = get_node_or_null("%TitleLabel")
@onready var content_label = get_node_or_null("%ContentLabel")
@onready var metadata_label = get_node_or_null("%MetadataLabel")
@onready var close_button = get_node_or_null("%CloseButton")
@onready var photo_texture = get_node_or_null("Panel/MarginContainer/VBoxContainer/TextureRect")
@onready var lots_label = get_node_or_null("Panel/MarginContainer/VBoxContainer/TextureRect/LotsLabel")

@export var doc_texture: Texture2D
@export var diary_texture: Texture2D
@export var back_texture: Texture2D

@export_group("Doc Transform")
@export var doc_size: Vector2 = Vector2(581.25, 496.0)
@export var doc_position: Vector2 = Vector2(-72.0, -80.0)
@export var doc_rotation_degrees: float = -7.0
@export var doc_margin_position: Vector2 = Vector2(149.5, 48)
@export var doc_container_size: Vector2 = Vector2(128, 114)

const LOT_GROUPS := [[0, 1], [2, 3], [4]]
const FLIP_HINT := "[clic para voltear]"

var _front_texture: Texture2D = null
var _back_lots: Array = []
var _showing_back: bool = false

var _default_bg_texture: Texture2D = null
var _default_bg_size: Vector2 = Vector2.ZERO
var _default_bg_position: Vector2 = Vector2.ZERO
var _default_bg_rotation: float = 0.0
var _default_margin_position: Vector2 = Vector2.ZERO
var _default_container_min_size: Vector2 = Vector2.ZERO

func _ready():
	panel.visible = false
	assert(close_button != null, "Error: mi_boton es null en " + name)
	close_button.pressed.connect(_on_close_button_pressed)
	if photo_texture:
		photo_texture.mouse_filter = Control.MOUSE_FILTER_STOP
		photo_texture.gui_input.connect(_on_photo_gui_input)
	if lots_label:
		lots_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lots_label.visible = false
	_cache_default_layout()

func _cache_default_layout() -> void:
	if background_texture:
		_default_bg_texture = background_texture.texture
		_default_bg_size = background_texture.size
		_default_bg_position = background_texture.position
		_default_bg_rotation = background_texture.rotation_degrees
	if margin_container:
		_default_margin_position = margin_container.position
	if content_container:
		_default_container_min_size = content_container.custom_minimum_size

func _restore_default_layout() -> void:
	if background_texture:
		if _default_bg_texture:
			background_texture.texture = _default_bg_texture
		background_texture.size = _default_bg_size
		background_texture.position = _default_bg_position
		background_texture.rotation_degrees = _default_bg_rotation
	if margin_container:
		margin_container.position = _default_margin_position
	if content_container:
		content_container.custom_minimum_size = _default_container_min_size

func show_fragment(fragment_id: String, is_diary: bool = false, apply_doc_transform: bool = true):
	var fragment_data = GameManager.fragments_database[fragment_id]
	if fragment_data == null:
		print("ERROR: Fragmento no encontrado: ", fragment_id)
		return
	
	if is_diary:
		_restore_default_layout()
		if background_texture and diary_texture:
			background_texture.texture = diary_texture
	elif apply_doc_transform:
		if background_texture:
			if doc_texture:
				background_texture.texture = doc_texture
			background_texture.size = doc_size
			background_texture.position = doc_position
			background_texture.rotation_degrees = doc_rotation_degrees
		if margin_container:
			margin_container.position = doc_margin_position
		if content_container:
			content_container.custom_minimum_size = doc_container_size
	else:
		_restore_default_layout()
	
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
			photo_texture.texture = _front_texture
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
	var all_parts: Array = []
	for group in LOT_GROUPS:
		for i in group:
			if i < lots.size():
				all_parts.append(str(lots[i]))
	return "  ".join(all_parts)

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
