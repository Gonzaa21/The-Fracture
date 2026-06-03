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
		"battery":
			if GameManager.battery_collected:
				queue_free()
		"A", "B", "C":
			if GameManager.generator_pieces.get(item_id, false):
				queue_free()

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
		"battery":
			GameManager.has_battery = true
			GameManager.battery_collected = true
		"A", "B", "C":
			GameManager.generator_pieces[item_id] = true
	
	if inventory_icon:
		player.add_inventory(inventory_icon)
		GameManager.current_inventory_icon = inventory_icon
	print("Item obtenido: ", item_id)
	
	var tween = create_tween()
	tween.tween_property(sprite, "position:y", sprite.position.y - 50, 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and not already_collected:
		player_nearby = true
		label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		label.visible = false
