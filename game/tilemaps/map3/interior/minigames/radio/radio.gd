extends Area2D

@export var radio_sprite: Sprite2D
var player_nearby: bool = false
@onready var label = $Label
var radio_tuner_scene = preload("res://game/tilemaps/map3/interior/minigames/radio/radio_tuner.tscn")

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
		if GameManager.generator_repaired:
			_open_radio_tuner()
		else:
			_show_no_power_feedback()

func _show_no_power_feedback():
	label.text = "Sin energía"
	await get_tree().create_timer(1.0).timeout
	label.text = "[E] para encender"

func _open_radio_tuner():
	var radio_instance = radio_tuner_scene.instantiate()
	get_tree().current_scene.add_child(radio_instance)
	Global.input_locked = true
	GameManager.lower_background_music(-28, 1.5)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(false)
	label.visible = false
	print("Abriendo radio...")
