extends CanvasLayer

@onready var panel = $Panel
@onready var title_label = $Panel/MarginContainer/VBoxContainer/VBoxContainer2/TitleLabel
@onready var content_label = $Panel/MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/ContentLabel
@onready var metadata_label = $Panel/MarginContainer/VBoxContainer/VBoxContainer2/VBoxContainer/MetadataLabel
@onready var close_button = $Panel/MarginContainer/VBoxContainer/CloseButton

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

func _on_close_button_pressed():
	panel.visible = false
	Global.input_locked = false
