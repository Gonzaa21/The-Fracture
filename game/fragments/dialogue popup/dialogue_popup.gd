extends CanvasLayer

@onready var panel = $Panel
@onready var title_label = $Panel/TitleLabel
@onready var content_label = $Panel/ContentLabel
@onready var metadata_label = $Panel/DateLabel

var is_typing: bool = false
var full_text: String = ""
var current_char_index: int = 0
var typing_speed: float = 0.04

var typewriter_sounds: Array[AudioStream] = []
var typewriter_player: AudioStreamPlayer

func _ready():
	panel.visible = false
	typewriter_audio()

func typewriter_audio():
	typewriter_player = AudioStreamPlayer.new()
	add_child(typewriter_player)
	typewriter_player.volume_db = -10
	typewriter_player.bus = "SFX"
	
	for i in range(1, 7):
		var sound = load("res://assets/sound/effects/typewritter/Typewritter%d.mp3" % i)
		if sound:
			typewriter_sounds.append(sound)

func show_fragment(fragment_id: String):
	if not fragment_id in GameManager.fragments_database:
		print("ERROR: Fragmento no encontrado:", fragment_id)
		return
	
	var fragment_data = GameManager.fragments_database[fragment_id]
	
	# Título
	title_label.text = fragment_data.get("title", fragment_id.capitalize())
	
	# Metadata
	var metadata_parts = []
	if "date" in fragment_data:
		metadata_parts.append(fragment_data["date"])
	if "author" in fragment_data:
		metadata_parts.append(fragment_data["author"])
	metadata_label.text = " | ".join(metadata_parts)
	
	# Contenido con typewriter
	full_text = fragment_data["content"]
	current_char_index = 0
	content_label.text = ""
	
	panel.visible = true
	start_typing()

func start_typing():
	is_typing = true
	type_next_character()

func get_char_delay(_char: String) -> float:
	match char:
		".": return typing_speed * 4
		",": return typing_speed * 2
		" ": return typing_speed * 0.5
		_: return typing_speed

func type_next_character():
	if current_char_index < full_text.length():
		var character = full_text[current_char_index]
		content_label.text += character
		current_char_index += 1
		
		if character != " " and character != "\n":
			random_typewriter_sound()
		
		var delay = get_char_delay(character)
		await get_tree().create_timer(delay).timeout
		type_next_character()
	else:
		is_typing = false
		await get_tree().create_timer(1.5).timeout
		close_popup()

func random_typewriter_sound():
	if typewriter_sounds.size() > 0:
		var random_index = randi() % typewriter_sounds.size()
		typewriter_player.stream = typewriter_sounds[random_index]
		typewriter_player.pitch_scale = randf_range(0.95, 1.05)
		typewriter_player.play()

func _input(event):
	if panel.visible:
		if is_typing and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")):
			skip_typing()
		elif not is_typing and event.is_action_pressed("ui_cancel"):
			close_popup()

func skip_typing():
	is_typing = false
	content_label.text = full_text
	current_char_index = full_text.length()

func close_popup():
	panel.visible = false
