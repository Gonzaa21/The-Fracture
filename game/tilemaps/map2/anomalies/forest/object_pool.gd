class_name ObjectPool
extends Node

@onready var tree_container: Node2D = get_parent().get_node("Tilemap/TreesTilemap")
@onready var pines_container: Node2D = get_parent().get_node("Tilemap/TreePinesMap")

func get_all_trees() -> Array[Node2D]:
	var trees: Array[Node2D] = []
	for child in tree_container.get_children():
		if child is Node2D:
			trees.append(child)
	
	for child in pines_container.get_children():
		if child is Node2D:
			trees.append(child)
	return trees


func get_random_tree() -> Node2D:
	var all = get_all_trees()
	return all.pick_random()


func get_player() -> CharacterBody2D:
	var player = get_tree().get_first_node_in_group("player")
	return player
