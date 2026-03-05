extends Node

var spawner: AnomalySpawner
var current_scene: Node
var unlock_echo_sound: AudioStream

var current_level: int = 0
var levels_completed: int = 0
var TOTAL_LEVELS: int = 5

var has_anomaly: bool = false
var current_anomaly: Anomaly = null
var anomaly_pool: Array[Anomaly] = []

func _ready() -> void:
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/trees/trees_giant.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/trees/trees_yellow.tres"))
	unlock_echo_sound = load("res://assets/sound/effects/eco.wav")

func start_forest(scene: Node, anomaly_spawner: AnomalySpawner):
	current_scene = scene
	spawner = anomaly_spawner
	
	current_level = 0
	levels_completed = 0
	
	generate_level()

func generate_level():
	current_level += 1
	print("=== NIVEL ", current_level, " ===")
	spawner.save_original_state()
	
	has_anomaly = randf() > 0.5
	if has_anomaly:
		current_anomaly = anomaly_pool.pick_random()
		spawner.apply_anomaly(current_anomaly)
		print("anomalia: ", current_anomaly.resource_path)
	else: print("nada")

func validate_choice(back: bool):
	var correct = (back == has_anomaly)
	
	if correct:
		print("crack")
		levels_completed += 1
		if levels_completed >= TOTAL_LEVELS:
			exit_forest()
		else:
			next_level()
	else:
		print("bobi")
		reset_progress()

func play_echo():
	if unlock_echo_sound:
		var echo_player = AudioStreamPlayer.new()
		add_child(echo_player)
		echo_player.stream = unlock_echo_sound
		echo_player.volume_db = -5
		echo_player.bus = "SFX"
		echo_player.play()
		echo_player.finished.connect(func(): echo_player.queue_free())

func reset_player_position():
	var player = spawner.pool.get_player()
	var entrance = current_scene.get_node("LevelEntrance")
	if player and entrance:
		player.global_position = entrance.global_position

func next_level():
	TransitionEffect.fade_in_place(func():
		spawner.restore_state()
		reset_player_position()
		play_echo()
		generate_level()
	)

func reset_progress():
	TransitionEffect.fade_in_place(func():
		spawner.restore_state()
		reset_player_position()
		levels_completed = 0
		current_level = 0
		generate_level()
	)

func exit_forest():
	print("saliste pa")
	#transicion a siguiente escena
	# get_tree().change_scene_to_file("res://scenes/...")
	pass
