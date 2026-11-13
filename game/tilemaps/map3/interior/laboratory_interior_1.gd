extends Node2D

const LAB_TIME := 480.0 

func _ready():
	if Global.next_spawn_id != "":
		var spawn_node = find_child(Global.next_spawn_id)
		var player = find_child("Player")
		if spawn_node and player:
			player.global_position = spawn_node.global_position
			Global.next_spawn_id = ""
	
	if not AlarmManager.running and not AlarmManager.finished:
		GameManager.reset_basement()
		await CinematicsManager.play("intrusion")
		AlarmManager.start(LAB_TIME)
