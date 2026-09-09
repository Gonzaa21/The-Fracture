class_name AnomalySpawner
extends Node

@onready var pool: ObjectPool = get_parent().get_node("ObjectPool") 

var original_tree_scales: Dictionary = {}
var original_tree_colors: Dictionary = {}
var original_sign_cells: Dictionary = {}
var original_player_speed_walk: float = 0.0
var original_player_speed_run: float = 0.0
var original_player_scale: Vector2 = Vector2.ONE
var original_tree_visibility: Dictionary = {}
var spawned_entities: Array[Node] = []

func save_original_state() -> void:
	var trees = pool.get_all_trees()
	
	for tree in trees:
		original_tree_scales[tree] = tree.scale
		original_tree_colors[tree] = tree.modulate
		original_tree_visibility[tree] = tree.visible

	var player = pool.get_player()
	if player:
		original_player_speed_walk = player.speed_walk
		original_player_speed_run = player.speed_run
		original_player_scale = player.scale
	
func apply_anomaly(anomaly: Anomaly) -> void:
	match anomaly.effect:
		Anomaly.Effect.SCALE:
			_apply_scale(anomaly)
		
		Anomaly.Effect.COLOR:
			_apply_color(anomaly)
			
		Anomaly.Effect.SPEED:
			_apply_speed(anomaly)
		
		Anomaly.Effect.INVISIBLE:
			_apply_invisibility(anomaly)
		
		Anomaly.Effect.PLAYER_SCALE:
			_apply_player_scale(anomaly)
		
		Anomaly.Effect.SPAWN_ENTITY:
			_apply_spawn_entity(anomaly)
		
		Anomaly.Effect.SPRITE_SWAP:
			_apply_sprite_swap(anomaly)
		
		Anomaly.Effect.EYES:
			_apply_eyes(anomaly)

func restore_state() -> void:
	for tree in original_tree_scales:
		tree.scale = original_tree_scales[tree]
	
	for tree in original_tree_colors:
		tree.modulate = original_tree_colors[tree]
	
	for tree in original_tree_visibility:
		tree.visible = original_tree_visibility[tree]
	
	var player = pool.get_player()
	if player:
		player.speed_walk = original_player_speed_walk
		player.speed_run = original_player_speed_run
		player.scale = original_player_scale
	
	for ghost in spawned_entities:
		if is_instance_valid(ghost):
			ghost.queue_free()
	
	original_tree_scales.clear()
	original_tree_colors.clear()
	original_tree_visibility.clear()
	spawned_entities.clear()
	
	for cell in original_sign_cells:
		var data = original_sign_cells[cell]
		pool.signs_layer.set_cell(cell, data["source"], data["atlas"])
	original_sign_cells.clear()


func _apply_scale(anom: Anomaly) -> void:
	if anom.scope == Anomaly.Scope.GLOBAL:
		var trees = pool.get_all_trees()
		for tree in trees:
			tree.scale = anom.scale_value
	elif anom.scope == Anomaly.Scope.MULTIPLE:
		var trees = pool.get_all_trees()
		trees.shuffle()
		var number_trees = clamp(3, 0, trees.size())
		var selected_trees = trees.slice(0, number_trees)
		for tree in selected_trees:
			tree.scale = anom.scale_value


func _apply_color(anom: Anomaly) -> void:
	if anom.scope == Anomaly.Scope.GLOBAL:
		var trees = pool.get_all_trees()
		for tree in trees:
			tree.modulate = anom.color_value
	
	elif anom.scope == Anomaly.Scope.MULTIPLE:
		var trees = pool.get_all_trees()
		for tree in trees:
			if tree.get_parent().name == "TreePinesMap":
				tree.modulate = anom.color_value

func _apply_speed(anom: Anomaly) -> void:
	var player = pool.get_player()
	if player:
		player.speed_walk = original_player_speed_walk * anom.speed_multiplier
		player.speed_run = original_player_speed_run * anom.speed_multiplier

func _apply_player_scale(anom: Anomaly) -> void:
	var player = pool.get_player()
	if player:
		player.scale = anom.scale_value

func _apply_invisibility(anom: Anomaly) -> void:
	if anom.scope == Anomaly.Scope.GLOBAL:
		var trees = pool.get_all_trees()
		for tree in trees:
			tree.visible = false
	elif anom.scope == Anomaly.Scope.MULTIPLE:
		var trees = pool.get_all_trees()
		for tree in trees:
			if tree.get_parent().name == "TreesTilemap":
				tree.visible = false

func _apply_spawn_entity(anom: Anomaly) -> void:
	var count = 3 if anom.scope == Anomaly.Scope.MULTIPLE else 1
	var chosen_points: Array[Marker2D] = []

	if anom.scope == Anomaly.Scope.MULTIPLE:
		var all_points = pool.get_all_ghost_spawn_points()
		all_points.shuffle()
		chosen_points = all_points.slice(0, min(count, all_points.size()))
	else:
		chosen_points = [pool.get_random_ghost_spawn_point()]

	for point in chosen_points:
		call_deferred("_spawn_ghost_at", anom, point)

func _spawn_ghost_at(anom: Anomaly, point: Marker2D) -> void:
	var ghost = anom.entity_scene.instantiate()
	ghost.behavior = anom.ghost_behavior
	point.get_parent().add_child(ghost)
	ghost.global_position = point.global_position
	spawned_entities.append(ghost)

func _apply_sprite_swap(anom: Anomaly) -> void:
	var cell = pool.get_random_sign_cell()
	var signs_layer = pool.signs_layer

	var original_source = signs_layer.get_cell_source_id(cell)
	var original_atlas = signs_layer.get_cell_atlas_coords(cell)
	original_sign_cells[cell] = {"source": original_source, "atlas": original_atlas}

	signs_layer.set_cell(cell, anom.sign_source_id, anom.sign_atlas_coords)

func _apply_eyes(anom: Anomaly) -> void:
	var trees = pool.get_all_trees()
	trees.shuffle()
	var count = 10 if anom.scope == Anomaly.Scope.MULTIPLE else 5
	var chosen = trees.slice(0, min(count, trees.size()))
	
	for tree in chosen:
		call_deferred("_spawn_eye_at", anom, tree)

func _spawn_eye_at(anom: Anomaly, tree: Node2D) -> void:
	var ysort_root = tree.get_parent().get_parent()
	var anchors_container = tree.get_node_or_null("EyeAnchors")
	var tree_top = tree.get_node_or_null("TreeTop") as TileMapLayer
	var target_z = tree_top.z_index if tree_top else 1

	if anchors_container and anchors_container.get_child_count() > 0:
		for anchor in anchors_container.get_children():
			_instantiate_eye(anom, ysort_root, anchor.global_position, target_z)
	else:
		_instantiate_eye(anom, ysort_root, tree.global_position, target_z)

func _instantiate_eye(anom: Anomaly, ysort_root: Node, pos: Vector2, z_idx: int = 1) -> void:
	var eye = anom.entity_scene.instantiate()
	ysort_root.add_child(eye)
	eye.global_position = pos
	if eye is CanvasItem: eye.z_index = z_idx
	spawned_entities.append(eye)
