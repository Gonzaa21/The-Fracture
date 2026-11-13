extends Area2D

const MINIGAME := preload("res://game/tilemaps/map3/interior/minigames/laboratory/lab2/wires/wires_minigame.tscn")

@export var label: Label

var player_nearby: bool = false
var minigame: Node = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if label:
		label.visible = false

func _process(_delta: float) -> void:
	if not player_nearby or minigame != null:
		return
	_update_label()
	if Input.is_action_just_pressed("interact") and _can_open():
		_open()

func _can_open() -> bool:
	if GameManager.emergency_disabled:
		return false
	if GameManager.basement_done.get("wires", false):
		return false
	return GameManager.is_cooling_active()

func _update_label() -> void:
	if label == null:
		return
	if GameManager.basement_done.get("wires", false):
		label.text = "Enlace restablecido"
	elif not GameManager.is_cooling_active():
		label.text = "Sin refrigeracion"
	else:
		label.text = "[E] Reconectar enlace"

func _open() -> void:
	minigame = MINIGAME.instantiate()
	get_tree().current_scene.add_child(minigame)
	minigame.tree_exited.connect(_on_minigame_closed)
	Global.input_locked = true
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(false)
	if label:
		label.visible = false

func _on_minigame_closed() -> void:
	minigame = null
	if not is_inside_tree():
		return
	Global.input_locked = false
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(true)
	if label:
		label.visible = player_nearby

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if label and minigame == null:
			_update_label()
			label.visible = true

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if label:
			label.visible = false
