extends Area2D

@export var sprite: Sprite2D
@export var target_scene: String = ""
@export var spawn_point_id: String = "default"
@export var requires_key: bool = false
@export var key_id: String = ""
@export var consume_key: bool = false
@export var requires_power: bool = false
@export var feedback_label: Label

var auth = GameManager.chain_auth
var player_nearby: bool = false
var is_opening: bool = false
var _feedback_token: int = 0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameManager.open_lab_door.connect(_on_lab_door_opened)
	if feedback_label:
		feedback_label.visible = false

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact") and not is_opening:
		_open_door()

func _has_key() -> bool:
	return GameManager.items_collected.get(key_id, false) or GameManager.has_fragment(key_id)

func _open_door():
	if is_opening or target_scene.is_empty():
		return
	
	if requires_power:
		if not GameManager.lab_door_powered:
			_show_feedback("Sin energía")
			return
		if not (auth["terminal_1"] and auth["terminal_2"] and auth["terminal_3"]):
			_show_feedback("Faltan autorizaciones")
			return
	
	if requires_key and not _has_key():
		_show_feedback("Puerta bloqueada")
		return
	
	if requires_key and consume_key:
		_consume_key()
	
	is_opening = true
	
	if not spawn_point_id.is_empty():
		Global.next_spawn_id = spawn_point_id
	
	TransitionEffect.fade_to_scene(target_scene)

func _consume_key() -> void:
	if GameManager.current_item_id != key_id:
		return
	GameManager.current_item_id = ""
	GameManager.current_inventory_icon = null
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var inventory = player.get_node_or_null("InventoryCell")
		if inventory:
			inventory.remove_item()

func _show_feedback(text: String) -> void:
	print(text)
	if feedback_label == null:
		return
	_feedback_token += 1
	var token := _feedback_token
	feedback_label.text = text
	feedback_label.visible = true
	await get_tree().create_timer(1.5).timeout
	if token == _feedback_token and is_instance_valid(feedback_label):
		feedback_label.visible = false

func _on_lab_door_opened():
	if target_scene != "res://game/tilemaps/map3/interior/laboratory_interior1.tscn": return
	if not is_instance_valid(sprite): return
