extends Node2D

@onready var spawner: AnomalySpawner = $AnomalySpawner

func _ready():
	ForestManager.start_forest(self, spawner)
