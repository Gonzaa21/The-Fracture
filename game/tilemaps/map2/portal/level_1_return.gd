extends Area2D

@export var level1_scene := "res://game/tilemaps/map1/level_1.tscn"
@onready var spawn_point: Marker2D = $SpawnPoint

var is_transitioning := false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_transitioning:
		is_transitioning = true
		Global.next_spawn_id = "level2_exit"
		call_deferred("_change_scene")

func _change_scene():
	print("Regresando...")
	TransitionEffect.fade_to_scene(level1_scene)
