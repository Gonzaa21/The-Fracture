extends Node2D

func _ready():
	if Global.next_spawn_id != "":
		var spawn_node = find_child(Global.next_spawn_id)
		var player = find_child("Player")
		if spawn_node and player:
			player.global_position = spawn_node.global_position
			Global.next_spawn_id = ""
	
	var location = MorseManager.get_current_location()
	var marker = find_child(location, true, false)
	if marker:
		var photo = preload("res://game/tilemaps/map3/exterior/objects/photo_object.tscn").instantiate()
		photo.global_position = marker.global_position
		add_child(photo)
	else:
		push_error("No se encontró marker: " + location)
