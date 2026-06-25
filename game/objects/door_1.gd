extends Area2D

@export var sprite: Sprite2D
@export var target_scene: String = ""
@export var spawn_point_id: String = "default"  
@export var requires_key: bool = false 
@export var key_id: String = ""
@export var requires_power: bool = false
var auth = GameManager.chain_auth

var player_nearby: bool = false
var is_opening: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameManager.open_lab_door.connect(_on_lab_door_opened)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact") and not is_opening:
		_open_door()

func _open_door():
	if is_opening or target_scene.is_empty():
		return
	
	if requires_power:
		if not GameManager.lab_door_powered:
			print("Sin energía")
			return
		
		if not (auth["terminal_1"] and auth["terminal_2"] and auth["terminal_3"]):
			print("Faltan autorizaciones")
			return
	
	if requires_key:
		if not GameManager.has_fragment(key_id):
			print("Puerta bloqueada. Necesitas: ", key_id)
			return
	
	is_opening = true
	
	if not spawn_point_id.is_empty():
		Global.next_spawn_id = spawn_point_id
	
	print("Abriendo puerta hacia: ", target_scene)
	TransitionEffect.fade_to_scene(target_scene)

func _on_lab_door_opened():
	if target_scene != "res://game/tilemaps/map3/interior/laboratory_interior1.tscn": return
	if not is_instance_valid(sprite): return
