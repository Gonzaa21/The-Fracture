extends Node

const DATA_PATH := "res://game/cinematics/cinematics.json"
const PlayerScript: Script = preload("res://game/cinematics/cinematic_player.gd")

var _data: Dictionary = {}
var playing: bool = false

func _ready() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Cinematics: no se pudo abrir " + DATA_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_data = parsed
	else:
		push_error("Cinematics: JSON inválido")

func play(key: String, next_scene: String = "") -> void:
	if playing:
		return
	if not _data.has(key):
		push_error("Cinematics: no existe la cinemática '%s'" % key)
		return
	
	playing = true
	Global.input_locked = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(false)
	
	var cine = PlayerScript.new()
	add_child(cine)
	await cine.play(_data[key], next_scene.is_empty())
	
	Global.input_locked = false
	if is_instance_valid(player):
		player.set_process_input(true)
	playing = false
	
	if not next_scene.is_empty():
		TransitionEffect.fade_to_scene(next_scene)
