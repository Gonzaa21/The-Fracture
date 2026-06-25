extends Area2D

var minigame_instance = null
var player_nearby: bool = false
var authchain_minigame = preload("res://game/tilemaps/map3/interior/minigames/auth_chain/panel_chain_terminal.tscn")
var is_authorized: bool = false
@export var terminal_id: String = ""
@export var digit_index: Array = []

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		if not is_authorized and GameManager.generator_repaired:
			_open_authchain_minigame()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		if is_instance_valid(minigame_instance):
			minigame_instance.queue_free()
			minigame_instance = null
			var player = get_tree().get_first_node_in_group("player")
			if player: player.set_process_input(true)
			get_tree().paused = false

func _open_authchain_minigame():
	minigame_instance = authchain_minigame.instantiate()
	minigame_instance.terminal_id = terminal_id
	minigame_instance.digit_index = digit_index
	
	get_tree().current_scene.add_child(minigame_instance)
	minigame_instance.authorized.connect(_on_authorized)
	minigame_instance.get_node("Panel").visible = true

func _on_authorized():
	is_authorized = true
