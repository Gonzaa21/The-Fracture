extends Node

var messages_database: Array = []
var current_message: Dictionary = {}
var target_frequency: float = 92.3

@onready var play_button: Button = get_tree().get_root().find_child("PlayButton", true, false)
@onready var audio_player: AudioStreamPlayer
@onready var morse_timer: Timer
var morse_sequence: Array = []
var sequence_index: int = 0

const DOT_DURATION = 0.1
const DASH_DURATION = 0.4
const SYMBOL_SPACE = 0.3
const LETTER_SPACE = 0.8
const WORD_SPACE = 1.5
const BEEP_FREQUENCY = 600.0

const MORSE_CODE = {
	"A": ".-",    "B": "-...",  "C": "-.-.",  "D": "-..",
	"E": ".",     "F": "..-.",  "G": "--.",   "H": "....",
	"I": "..",    "J": ".---",  "K": "-.-",   "L": ".-..",
	"M": "--",    "N": "-.",    "O": "---",   "P": ".--.",
	"Q": "--.-",  "R": ".-.",   "S": "...",   "T": "-",
	"U": "..-",   "V": "...-",  "W": ".--",   "X": "-..-",
	"Y": "-.--",  "Z": "--..", "1": ".----",  "2": "..---", 
	"3": "...--", "4": "....-", "5": ".....", "6": "-....",
	"7": "--...", "8": "---..", "9": "----.", "0": "-----", " ": "/"
}

func _ready() -> void:
	load_messages()
	print("MorseManager: Cargados ", messages_database.size(), " mensajes")
	_setup_audio()
	generate_new_message()

func load_messages() -> void:
	var file_path = "res://game/tilemaps/map3/interior/minigames/radio/morse/morse_messages.json"
	
	if not FileAccess.file_exists(file_path):
		push_error("MorseManager: No se encontró " + file_path)
		return
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null: return
	
	var content = file.get_as_text()
	file.close()
	var json = JSON.parse_string(content)
	
	if json == null or not json.has("messages"):
		push_error("MorseManager: JSON inválido")
		return
	
	messages_database = json["messages"]

func _setup_audio():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	morse_timer = Timer.new()
	add_child(morse_timer)
	morse_timer.one_shot = true
	morse_timer.timeout.connect(_on_morse_timeout)
	
	morse_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS

func generate_random_frequency() -> float:
	var rand_frequency = randf_range(87.0, 99.0)
	target_frequency = snapped(rand_frequency, 0.1)
	return target_frequency

func get_target_frequency() -> float:
	return target_frequency

func generate_new_message():
	if messages_database.is_empty():
		push_error("MorseManager: No hay mensajes disponibles")
		return
		
	current_message = messages_database.pick_random()
	generate_random_frequency()
	#GameManager.morse_code = current_message["code"]
	#GameManager.radio_frequency = target_frequency

func get_current_code() -> Array:
	if current_message.is_empty():
		return []
	print("Code:", current_message["code"])
	return current_message["code"]

func play_current_message() -> void:
	if current_message.is_empty(): return
	var text = current_message["text"]
	var morse = to_morse(text)
	morse_sequence = morse_to_sequence(morse)
	sequence_index = 0
	_play_next_symbol()

func to_morse(input_text: String) -> String:
	var result = ""
	input_text = input_text.to_upper()
	for chars in input_text:
		if MORSE_CODE.has(chars):
			result += MORSE_CODE[chars] + " "
	
	return result.strip_edges()

func morse_to_sequence(morse_string: String) -> Array:
	var sequence = []
	for chars in morse_string:
		if chars == ".":
			sequence.append("dot")
		elif chars == "-":
			sequence.append("dash")
		elif chars == " ":
			sequence.append("symbol_space")
		elif chars == "/":
			sequence.append("word_space")
	return sequence

func _play_next_symbol():
	if sequence_index >= morse_sequence.size():
		play_button.text = "Volver a reproducir"
		print("MorseManager: Transmisión completa")
		return
	
	var symbol = morse_sequence[sequence_index]
	sequence_index += 1
	
	match symbol:
		"dot":
			await generate_tone(BEEP_FREQUENCY, DOT_DURATION)
			morse_timer.start(DOT_DURATION + SYMBOL_SPACE)
			pass
		"dash":
			await generate_tone(BEEP_FREQUENCY, DASH_DURATION)
			morse_timer.start(DASH_DURATION + SYMBOL_SPACE)
			pass
		"symbol_space":
			morse_timer.start(SYMBOL_SPACE)
			pass
		"letter_space":
			morse_timer.start(LETTER_SPACE)
			pass
		"word_space":
			morse_timer.start(WORD_SPACE)
			pass

func _on_morse_timeout():
	_play_next_symbol()

func generate_tone(frequency: float, duration: float):
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.5
	
	audio_player.stream = stream
	audio_player.play()
	await get_tree().process_frame
	
	var playback: AudioStreamGeneratorPlayback = audio_player.get_stream_playback()
	
	var sample_count = int(stream.mix_rate * duration)
	var phase = 0.0
	var increment = frequency / stream.mix_rate
	
	for i in range(sample_count):
		while playback.get_frames_available() == 0:
			await get_tree().process_frame
		
		var sample = sin(phase * TAU)
		playback.push_frame(Vector2(sample, sample))
		phase = fmod(phase + increment, 1.0)

func stop_transmission():
	if morse_timer and morse_timer.is_inside_tree():
		morse_timer.stop()

	if audio_player and audio_player.is_inside_tree():
		audio_player.stop()
	
	morse_sequence.clear()
	sequence_index = 0
