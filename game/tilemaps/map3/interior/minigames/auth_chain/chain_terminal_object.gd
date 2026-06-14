extends Area2D

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
		var ui = get_tree().current_scene.get_node_or_null("PanelChainTerminal")
		if ui:
			ui.queue_free()
			var player = get_tree().get_first_node_in_group("player")
			if player: player.set_process_input(true)
			get_tree().paused = false

func _open_authchain_minigame():
	var minigame = authchain_minigame.instantiate()
	minigame.terminal_id = terminal_id
	minigame.digit_index = digit_index
	
	get_tree().current_scene.add_child(minigame)
	minigame.authorized.connect(_on_authorized)
	minigame.get_node("Panel").visible = true

func _on_authorized():
	is_authorized = true
