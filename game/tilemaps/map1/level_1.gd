extends Node2D

func _ready():
	if Global.next_spawn_id != "":
		var spawn := get_node("SpawnOffice")
		$Player.global_position = spawn.global_position
		Global.next_spawn_id = ""
