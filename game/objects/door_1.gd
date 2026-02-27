extends Area2D

var community_office: String = "res://game/tilemaps/map1/CommunityOffice.tscn"

var player_nearby: bool = false
var is_opening: bool = false


func _ready():
	# Conectar señales del Area2D
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false


func _process(_delta):
	if Input.is_action_just_pressed("interact"):
		print("E PRESIONADA")
		
	if player_nearby and Input.is_action_just_pressed("interact") and not is_opening:
		_open_door()

func _open_door():
	if is_opening:
		return

	is_opening = true
	TransitionEffect.fade_to_scene(community_office)
