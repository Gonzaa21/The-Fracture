extends Node2D

@onready var spawner: AnomalySpawner = $AnomalySpawner
var test_anomaly: Anomaly = preload("res://game/tilemaps/map2/anomalies/trees/trees_giant.tres")

func _ready():
	await get_tree().process_frame
	
	spawner.save_original_state()
	print("original state saved")
	
	spawner.apply_anomaly(test_anomaly)
	print("anomaly")
