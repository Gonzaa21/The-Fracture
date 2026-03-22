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
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/trees/scale/trees_global_giant.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/trees/scale/trees_global_tiny.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/trees/scale/trees_multiple_giant.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/trees/scale/trees_multiple_tiny.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/trees/color/trees_color_global.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/trees/color/trees_color_multiples.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/player/speed/player_fast.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/player/speed/player_slow.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/player/size/player_giant.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/player/size/player_tiny.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/trees/invisibility/trees_missing.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/trees/invisibility/trees_normal_missing.tres"))
	unlock_echo_sound = load("res://assets/sound/effects/eco.wav")

func start_forest(scene: Node, anomaly_spawner: AnomalySpawner):
	current_scene = scene
	spawner = anomaly_spawner
	
	current_level = 0
	levels_completed = 0
	
	GameManager.change_music("res://assets/sound/music/Triptych III  Desolation - Bosque.mp3")
	
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
	GameManager.change_music("res://assets/sound/music/River's Bend - background_act3.mp3")
	await get_tree().create_timer(2.0).timeout
	TransitionEffect.fade_to_scene("res://game/tilemaps/map3/level_3.tscn")
	pass
