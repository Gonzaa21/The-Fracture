class_name AnomalySpawner
extends Node

@onready var pool: ObjectPool = get_parent().get_node("ObjectPool") 

var original_tree_scales: Dictionary = {}
var original_tree_colors: Dictionary = {}
var original_player_speed_walk: float = 0.0
var original_player_speed_run: float = 0.0
var original_player_scale: Vector2 = Vector2.ONE
var original_tree_visibility: Dictionary = {}

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
	
	original_tree_scales.clear()
	original_tree_colors.clear()
	original_tree_visibility.clear()


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
