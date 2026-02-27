extends Area2D

@export var level2_scene := "res://game/tilemaps/map2/level_2.tscn"
@onready var spawn_point: Marker2D = $SpawnPoint

var player_nearby: bool = false
var is_transitioning := false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		try_enter_level2()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func try_enter_level2():
	if not GameManager.level2_unlocked:
		print("bosque de Datos está bloqueado")
		return
	
	is_transitioning = true
	Global.next_spawn_id = "LevelEntrance"
	call_deferred("_change_scene")

func _change_scene():
	print("Entrando al Bosque de Datos...")
	TransitionEffect.fade_to_scene(level2_scene)
