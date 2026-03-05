class_name AnomalySpawner
extends Node

@onready var pool: ObjectPool = get_parent().get_node("ObjectPool") 

var original_tree_scales: Dictionary = {}
var original_tree_colors: Dictionary = {}
var original_player_speed_walk: float = 0.0
var original_player_speed_run: float = 0.0

func save_original_state() -> void:
	var trees = pool.get_all_trees()
	
	for tree in trees:
		original_tree_scales[tree] = tree.scale
		original_tree_colors[tree] = tree.modulate

	var player = pool.get_player()
	if player:
		original_player_speed_walk = player.speed_walk
		original_player_speed_run = player.speed_run
	
func apply_anomaly(anomaly: Anomaly) -> void:
	match anomaly.effect:
		Anomaly.Effect.SCALE:
			_apply_scale(anomaly)
		
		Anomaly.Effect.COLOR:
			_apply_color(anomaly)
			
		Anomaly.Effect.SPEED:
			_apply_speed(anomaly)


func restore_state() -> void:
	for tree in original_tree_scales:
		tree.scale = original_tree_scales[tree]
	
	for tree in original_tree_colors:
		tree.modulate = original_tree_colors[tree]
	
	var player = pool.get_player()
	if player:
		player.speed_walk = original_player_speed_walk
		player.speed_run = original_player_speed_run
	
	original_tree_scales.clear()
	original_tree_colors.clear()


func _apply_scale(anom: Anomaly) -> void:
	if anom.scope == Anomaly.Scope.GLOBAL:
		var trees = pool.get_all_trees()
		for tree in trees:
			tree.scale = anom.scale_value
	
	elif anom.scope == Anomaly.Scope.SINGLE:
		var tree = pool.get_random_tree()
		if tree:
			tree.scale = anom.scale_value


func _apply_color(anom: Anomaly) -> void:
	if anom.scope == Anomaly.Scope.GLOBAL:
		var trees = pool.get_all_trees()
		for tree in trees:
			tree.modulate = anom.color_value
	
	elif anom.scope == Anomaly.Scope.SINGLE:
		var tree = pool.get_random_tree()
		if tree:
			tree.modulate = anom.color_value

func _apply_speed(anom: Anomaly) -> void:
	var player = pool.get_player()
	if player:
		player.speed_walk = original_player_speed_walk * anom.speed_multiplier
		player.speed_run = original_player_speed_run * anom.speed_multiplier
