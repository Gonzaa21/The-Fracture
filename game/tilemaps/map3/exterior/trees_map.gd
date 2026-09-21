extends Node

@export var eye_scene: PackedScene
@export var eye_behavior: GhostBehavior

func _ready():
	for tree in _get_trees():
		_spawn_eyes_for_tree(tree)

func _get_trees() -> Array[Node2D]:
	var trees: Array[Node2D] = []
	for child in get_children():
		if child is Node2D and child.name.begins_with("TreeLowYellow"):
			trees.append(child)
	return trees

func _spawn_eyes_for_tree(tree: Node2D):
	var anchors = tree.get_node_or_null("EyeAnchors")
	var tree_top = tree.get_node_or_null("TreeTop")
	var z = tree_top.z_index if tree_top else 0

	if anchors and anchors.get_child_count() > 0:
		for anchor in anchors.get_children():
			_instantiate_eye(tree.get_parent(), anchor.global_position, z)
	else:
		_instantiate_eye(tree.get_parent(), tree.global_position, z)

func _instantiate_eye(ysort_root: Node, pos: Vector2, z: int):
	var eye = eye_scene.instantiate()
	ysort_root.add_child(eye)
	eye.global_position = pos
	if eye is CanvasItem: eye.z_index = z
	if eye_behavior: eye.behavior = eye_behavior
