extends Area2D

var player_nearby: bool = false
@onready var label = $Label
var generator_minigame = preload("res://game/tilemaps/map3/interior/minigames/electric_generator/generator_minigame.tscn")
var is_fixed: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		label.visible = false

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact"):
		if not is_fixed: _open_generator_minigame()

func _open_generator_minigame():
	var minigame = generator_minigame.instantiate()
	get_tree().current_scene.add_child(minigame)
	minigame.generator_fixed.connect(_on_generator_fixed)
	get_tree().paused = true
	var player = get_tree().get_first_node_in_group("player")
	if player: player.set_process_input(false)
	label.visible = false

func _on_generator_fixed(): is_fixed = true
