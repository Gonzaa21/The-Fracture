extends CanvasLayer

@onready var panel = $Panel
@onready var title_label = get_node_or_null("%TitleLabel")
@onready var content_label = get_node_or_null("%ContentLabel")
@onready var metadata_label = get_node_or_null("%MetadataLabel")
@onready var close_button = get_node_or_null("Panel/MarginContainer/VBoxContainer/CloseButton")
@onready var photo_texture = get_node_or_null("Panel/MarginContainer/VBoxContainer/TextureRect")

func _ready():
	panel.visible = false
	close_button.pressed.connect(_on_close_button_pressed)
	
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

func show_photo(texture: Texture2D, key_code: Array):
	if texture == null: return
	photo_texture.texture = texture
	photo_texture.visible = true
	
	var code_string = " - ".join(key_code.map(func(num): return str(num)))
	content_label.text = code_string
	content_label.visible = true
	
	title_label.visible = false
	metadata_label.visible = false
	
	panel.visible = true
	Global.input_locked = true

func _on_close_button_pressed():
	panel.visible = false
	if photo_texture:
		photo_texture.visible = false
		photo_texture.texture = null
	if content_label:
		content_label.visible = true
	Global.input_locked = false
