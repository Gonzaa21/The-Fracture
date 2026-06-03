extends Node

signal fragment_collected(fragment_id)

# fragments var
var fragments_database = {}
var fragments_collected = []
# computer vars
var computer_has_battery = false
var has_battery = false
var battery_collected: bool = false
var computer_password = "20483"
var password_hint_shown = false
var computer_has_booted: bool = false
# pc terminal vars
var filesystem_data: Dictionary = {}
var current_directory: String = "C:\\Users\\User"
var phoenix_viewed: bool = false
var omega_decrypted: bool = false
# audio
var background_sound: AudioStreamPlayer
var current_music_volume: float = -10.0
# inventory
var current_inventory_icon: Texture2D = null
# lab
var key_code: Array = []
#level2
var level2_unlocked: bool = false
var unlock_echo_sound: AudioStream
#level3
var generator_pieces: Dictionary = { "A": false, "B": false,  "C": false }
var lab_door_powered: bool = false
var generator_repaired: bool = false

func load_database():
	var file = FileAccess.open("res://game/fragments/fragments.json",FileAccess.READ)
	if file == null:
		print("ERROR: No se pudo abrir fragments.json")
		return
	
	var content = file.get_as_text()
	
	var result = JSON.parse_string(content)
	if result == null: return
		
	fragments_database = result
	pass

func has_fragment(fragment_id: String) -> bool:
	return fragment_id in fragments_collected

func collect_fragment(fragment_id: String) -> bool:
	if fragment_id in fragments_collected:
		return false
	else:
		fragments_collected.append(fragment_id)
		emit_signal("fragment_collected", fragment_id)
		return true
		

func load_filesystem():
	var file = FileAccess.open("res://game/pc/filesystem.json", FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			filesystem_data = json.data
			current_directory = filesystem_data.get("current_directory", "C:\\Users\\User")
			
			# Cargar estado de archivos especiales
			var special = filesystem_data.get("special_files", {})
			phoenix_viewed = special.get("phoenix_viewed", false)
			omega_decrypted = special.get("omega_decrypted", false)
			
			print("Filesystem cargado correctamente")
		else:
			print("ERROR: No se pudo parsear filesystem.json")
		
		file.close()
	else:
		print("ERROR: No se pudo abrir filesystem.json")

func mark_phoenix_viewed():
	phoenix_viewed = true
	# Eliminar el archivo del filesystem
	var phoenix_dir = "C:\\Users\\User\\Downloads\\SOP_PROTOCOL_ENFORCEMENT"
	if filesystem_data["directories"].has(phoenix_dir):
		var files = filesystem_data["directories"][phoenix_dir]["files"]
		files.erase("4271PRTO_INT-85U37_PHNX.txt")
	print("Protocolo Phoenix eliminado permanentemente")

func background_music():
	background_sound = AudioStreamPlayer.new()
	add_child(background_sound)
	
	var music = load("res://assets/sound/music/Repetition Relay - background_act1.mp3")
	if music:
		background_sound.stream = music
		background_sound.volume_db = current_music_volume
		background_sound.bus = "Music"
		background_sound.play()

func lower_background_music(target_volume: float = -30.0, duration: float = 1.5):
	if background_music:
		var tween = create_tween()
		tween.tween_property(background_sound, "volume_db", target_volume, duration)

func restore_background_music(duration: float = 1.5):
	if background_music:
		var tween = create_tween()
		tween.tween_property(background_sound, "volume_db", current_music_volume, duration)

func change_music(new_music_path: String, fade_duration: float = 1.5):
	if not background_sound:
		return
	
	var tween_out = create_tween()
	tween_out.tween_property(background_sound, "volume_db", -80.0, fade_duration)
	
	tween_out.finished.connect(func():
		var new_music = load(new_music_path)
		if new_music:
			background_sound.stream = new_music
			background_sound.play()
			
			background_sound.volume_db = -80.0
			var tween_in = create_tween()
			tween_in.tween_property(background_sound, "volume_db", current_music_volume, fade_duration)
	)

func unlock_audio():
	unlock_echo_sound = load("res://assets/sound/effects/eco.wav")

func unlock_level2():
	if level2_unlocked:
		return
	level2_unlocked = true
	print("desbloqueado bosuqe")
	unlock_echo()

func unlock_echo():
	if unlock_echo_sound:
		var echo_player = AudioStreamPlayer.new()
		add_child(echo_player)
		echo_player.stream = unlock_echo_sound
		echo_player.volume_db = -5
		echo_player.bus = "SFX"
		echo_player.play()
		
		echo_player.finished.connect(func(): echo_player.queue_free())

func _ready():
	load_database()
	load_filesystem()
	background_music()
	unlock_audio()
	print("Fragmentos cargados: ", fragments_database.size())
