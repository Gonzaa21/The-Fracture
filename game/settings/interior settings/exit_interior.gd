extends Area2D

@export var central_map := ""
@onready var spawn_point: Marker2D = $SpawnPoint

var is_opening := false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		Global.next_spawn_id = "community_office_exit"
		call_deferred("_change_scene")

func _change_scene():
	TransitionEffect.fade_to_scene(central_map)
