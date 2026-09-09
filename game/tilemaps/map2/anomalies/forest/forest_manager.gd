extends Node
signal player_crossed_portal

var spawner: AnomalySpawner
var current_scene: Node
var unlock_echo_sound: AudioStream

var current_level: int = 0
var levels_completed: int = 0
var TOTAL_LEVELS: int = 5

var has_anomaly: bool = false
var current_anomaly: Anomaly = null
var anomaly_pool: Array[Anomaly] = []

enum EntrySide { LEFT, RIGHT }
var current_entry_side: EntrySide = EntrySide.LEFT

var ambient_player: AudioStreamPlayer
var ambient_timer: Timer
var ambient_sounds: Array[AudioStream] = []

const AMBIENT_MIN_WAIT := 18.0
const AMBIENT_MAX_WAIT := 30.0

func _ready() -> void:
	_setup_ambient()
	_setup_anomalies()

func _setup_ambient() -> void:
	var paths = [
		"res://assets/sound/horror/ambient_terror1.mp3",
		"res://assets/sound/horror/ambient_terror2.mp3",
		"res://assets/sound/horror/ambient_terror3.mp3",
	]
	for path in paths:
		var stream = load(path)
		if stream:
			ambient_sounds.append(stream)
		else:
			push_warning("ForestManager: no se pudo cargar " + path)

	ambient_player = AudioStreamPlayer.new()
	add_child(ambient_player)
	ambient_player.bus = "SFX"
	ambient_player.volume_db = -30

	ambient_timer = Timer.new()
	add_child(ambient_timer)
	ambient_timer.one_shot = true
	ambient_timer.timeout.connect(_on_ambient_timer_timeout)

func _start_ambient_cycle() -> void:
	if ambient_sounds.is_empty():
		return
	_schedule_next_ambient()

func _schedule_next_ambient() -> void:
	ambient_timer.start(randf_range(AMBIENT_MIN_WAIT, AMBIENT_MAX_WAIT))

func _on_ambient_timer_timeout() -> void:
	_play_random_ambient()
	_schedule_next_ambient()

func _play_random_ambient() -> void:
	if ambient_sounds.is_empty():
		return
	ambient_player.stream = ambient_sounds.pick_random()
	ambient_player.play()

func _stop_ambient_cycle() -> void:
	ambient_timer.stop()
	ambient_player.stop()

func start_forest(scene: Node, anomaly_spawner: AnomalySpawner):
	current_scene = scene
	spawner = anomaly_spawner
	current_level = 0
	levels_completed = 0
	current_entry_side = EntrySide.LEFT
	_start_ambient_cycle()
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

func validate_choice(portal_crossed: EntrySide):
	var back = (portal_crossed == current_entry_side)
	var target_marker = "LevelExit" if portal_crossed == EntrySide.LEFT else "LevelEntrance"
	var correct = (back == has_anomaly)
	print("current entry side: ", current_entry_side)
	current_entry_side = EntrySide.RIGHT if portal_crossed == EntrySide.LEFT else EntrySide.LEFT
	player_crossed_portal.emit()
	
	if correct:
		print("crack")
		levels_completed += 1
		if levels_completed >= TOTAL_LEVELS:
			exit_forest()
		else:
			next_level(target_marker)
	else:
		print("bobi")
		reset_progress(target_marker)

func play_echo():
	if unlock_echo_sound:
		var echo_player = AudioStreamPlayer.new()
		add_child(echo_player)
		echo_player.stream = unlock_echo_sound
		echo_player.volume_db = -5
		echo_player.bus = "SFX"
		echo_player.play()
		echo_player.finished.connect(func(): echo_player.queue_free())

func reset_player_position(target_marker_name: String):
	var player = spawner.pool.get_player()
	var target = current_scene.get_node(target_marker_name)
	if player and target:
		player.global_position = target.global_position

func next_level(target_marker: String = "LevelEntrance"):
	spawner.restore_state()
	reset_player_position(target_marker)
	play_echo()
	generate_level()
	var player = spawner.pool.get_player()
	var camera: Camera2D = player.get_node("Camera2D")
	camera.reset_smoothing()

func reset_progress(target_marker: String = "LevelEntrance"):
	spawner.restore_state()
	reset_player_position(target_marker)
	levels_completed = 0
	current_level = 0
	generate_level()
	var player = spawner.pool.get_player()
	var camera: Camera2D = player.get_node("Camera2D")
	camera.reset_smoothing()

func exit_forest():
	print("saliste pa")
	GameManager.change_music("res://assets/sound/music/River's Bend - background_act3.mp3")
	TransitionEffect.fade_to_scene("res://game/tilemaps/map3/level_3.tscn")
	_stop_ambient_cycle()
	pass

func _setup_anomalies() -> void:
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
	anomaly_pool.append(preload("res://game/global_anomalies/ghost/anomaly_ghost/global/anomaly_ghost_chase.tres"))
	anomaly_pool.append(preload("res://game/global_anomalies/ghost/anomaly_ghost/global/anomaly_ghost_flash.tres"))
	anomaly_pool.append(preload("res://game/global_anomalies/ghost/anomaly_ghost/global/anomaly_ghost_run.tres"))
	anomaly_pool.append(preload("res://game/global_anomalies/ghost/anomaly_ghost/global/anomaly_ghost_idle.tres"))
	anomaly_pool.append(preload("res://game/global_anomalies/ghost/anomaly_ghost/multiple/anomaly_ghost_chase.tres"))
	anomaly_pool.append(preload("res://game/global_anomalies/ghost/anomaly_ghost/multiple/anomaly_ghost_flash.tres"))
	anomaly_pool.append(preload("res://game/global_anomalies/ghost/anomaly_ghost/multiple/anomaly_ghost_idle.tres"))
	anomaly_pool.append(preload("res://game/global_anomalies/ghost/anomaly_ghost/multiple/anomaly_ghost_run.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/objects/signs/anomaly_sign1.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/objects/signs/anomaly_sign2.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/objects/signs/anomaly_sign3.tres"))
	anomaly_pool.append(preload("res://game/tilemaps/map2/anomalies/objects/signs/anomaly_sign4.tres"))
	anomaly_pool.append(preload("res://game/global_anomalies/eye/anomaly_multiple_eye.tres"))
	anomaly_pool.append(preload("res://game/global_anomalies/eye/anomaly_global_eye.tres"))
	unlock_echo_sound = load("res://assets/sound/effects/eco.wav")
