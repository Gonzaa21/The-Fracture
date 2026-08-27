class_name ObjectPool
extends Node

@onready var tree_container: Node2D = get_parent().get_node("Tilemap/TreesTilemap")
@onready var pines_container: Node2D = get_parent().get_node("Tilemap/TreePinesMap")
@onready var decorations: TileMapLayer = get_parent().get_node("Tilemap/TechDeco")
@onready var ghost_spawn_container: Node2D = get_parent().get_node("GhostSpawnPoints")
@onready var signs_layer: TileMapLayer = get_parent().get_node("Tilemap/Signs")

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


func get_decorations() -> Array[TileMapLayer]:
	var deco: Array[TileMapLayer] = []
	if not is_instance_valid(decorations):
		return deco
	
	for child in decorations.get_children():
		if child is TileMapLayer:
			deco.append(child)
	return deco

func get_random_deco() -> Node2D:
	var all = get_decorations()
	return all.pick_random()


func get_player() -> CharacterBody2D:
	var player = get_tree().get_first_node_in_group("player")
	return player

func get_random_ghost_spawn_point() -> Marker2D:
	var points = ghost_spawn_container.get_children()
	return points.pick_random() as Marker2D

func get_all_ghost_spawn_points() -> Array[Marker2D]:
	var points: Array[Marker2D] = []
	for child in ghost_spawn_container.get_children():
		if child is Marker2D:
			points.append(child)
	return points

func get_all_sign_cells() -> Array[Vector2i]:
	return signs_layer.get_used_cells()

func get_random_sign_cell() -> Vector2i:
	var cells = get_all_sign_cells()
	return cells.pick_random()
