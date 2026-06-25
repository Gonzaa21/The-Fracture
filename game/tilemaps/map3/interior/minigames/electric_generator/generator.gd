extends Area2D

var player_nearby: bool = false
@onready var label = $Label
var is_fixed: bool = false

var pressure: float = 0.0
var pressure_speed: float = 30.0
var pressure_decay: float = 15.0

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.visible = false
	if GameManager.generator_repaired:
		is_fixed = true
		label.text = "Generador Activo"

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		label.visible = false

func _process(delta):
	var all_installed = GameManager.generator_pieces["A"] and GameManager.generator_pieces["B"] and GameManager.generator_pieces["C"]
	if player_nearby: _update_label(all_installed)
	
	if player_nearby and not all_installed and Input.is_action_just_pressed("interact"):
		var item = GameManager.current_item_id
		if item in ["A", "B", "C"] and not GameManager.generator_pieces[item]:
			_install_component(item)
	
	if player_nearby and all_installed and not is_fixed:
		if Input.is_action_pressed("interact"):
			pressure += pressure_speed * delta
		else:
			pressure -= pressure_decay * delta
		pressure = clamp(pressure, 0, 100)
		if pressure >= 100:
			_on_generator_fixed()

func _install_component(item_id: String):
	GameManager.generator_pieces[item_id] = true
	GameManager.current_item_id = ""
	GameManager.current_inventory_icon = null
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var inventory = player.get_node_or_null("InventoryCell")
		if inventory:
			inventory.remove_item()

func _update_label(all_installed: bool):
	if is_fixed:
		label.text = "Generador Activo"
		return
	
	if all_installed:
		var filled = int(pressure / 10)
		var bar = "█".repeat(filled) + "░".repeat(10 - filled)
		label.text = "[" + bar + "]"
	elif GameManager.current_item_id in ["A", "B", "C"] and not all_installed:
		label.text = "[E] para instalar"
	else:
		label.text = "Generador dañado"

func _on_generator_fixed():
	is_fixed = true
	GameManager.lab_door_powered = true
	GameManager.generator_repaired = true
	label.text = "Generador Activo"
