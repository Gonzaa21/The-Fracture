extends Area2D

@onready var sprite = $Sprite2D
@onready var label = $Label
@export var inventory_icon: Texture2D
@export var item_id: String = ""
@export var item_sprite: Texture2D

var player_nearby: bool = false
var already_collected: bool = false

func _ready():
	if item_sprite:
		sprite.texture = item_sprite
	match item_id:
		"instructor":
			if GameManager.instructor_collected:
				queue_free()
			elif not GameManager.omega_acceleration_triggered:
				visible = false
				set_process(false)
				monitoring = false
		"A", "B", "C":
			if GameManager.items_collected.get(item_id, false):
				queue_free()
			label.text = ""
		"modulo_sync":
			pass

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact"):
		collect()

func collect():
	if already_collected:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player == null: return
	if player.inventory_cell.has_item(): return
	
	already_collected = true
	match item_id:
		"instructor":
			GameManager.has_instructor = true
			GameManager.instructor_collected = true
		"A", "B", "C":
			GameManager.items_collected[item_id] = true
			label.text = ""
	
	if inventory_icon:
		player.add_inventory(inventory_icon)
		GameManager.current_inventory_icon = inventory_icon
		GameManager.current_item_id = item_id
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and not already_collected:
		player_nearby = true
		label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		label.visible = false
