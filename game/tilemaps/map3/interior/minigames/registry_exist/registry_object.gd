extends Area2D

@export var popup_scene: PackedScene
@onready var icon = $CanvasLayer/TextureRect

var player_nearby: bool = false
var popup: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	icon.visible = false
 
 
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		icon.visible = popup == null

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		icon.visible = false

func _process(_delta: float) -> void:
	if player_nearby and popup == null and Input.is_action_just_pressed("interact"):
		_open()
 
func _open() -> void:
	if popup_scene == null:
		push_error("RegistryObject: falta asignar popup_scene en el Inspector")
		return
	
	popup = popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.tree_exited.connect(_on_popup_closed)
	
	Global.input_locked = true
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(false)
	icon.visible = false

func _on_popup_closed() -> void:
	popup = null
	Global.input_locked = false
	if not is_inside_tree():
		return
	
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(true)
	icon.visible = player_nearby
