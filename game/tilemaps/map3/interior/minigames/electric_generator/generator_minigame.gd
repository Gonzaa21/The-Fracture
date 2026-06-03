extends CanvasLayer

signal generator_fixed
@onready var slot_a: Panel = $Panel/SlotsContainer/SlotA
@onready var slot_b: Panel = $Panel/SlotsContainer/SlotB
@onready var slot_c: Panel = $Panel/SlotsContainer/SlotC
@onready var pressure_bar: ProgressBar = $Panel/PressureBar
@onready var hint: Label = $Panel/Hint
@onready var close_button: Button = $Panel/CloseButton

var pressure_speed: float = 30.0
var pressure_decay: float = 15.0
var all_pieces_placed: bool = false
var is_complete: bool = false

func _ready():
	var slots = GameManager.generator_pieces
	slot_a.modulate = Color.WHITE if slots["A"] else Color(0.3, 0.3, 0.3)
	slot_b.modulate = Color.WHITE if slots["B"] else Color(0.3, 0.3, 0.3)
	slot_c.modulate = Color.WHITE if slots["C"] else Color(0.3, 0.3, 0.3)
	all_pieces_placed = slots["A"] and slots["B"] and slots["C"]
	close_button.pressed.connect(_on_close_pressed)

func _process(delta):
	if all_pieces_placed and not is_complete:
		if Input.is_action_pressed("interact"):
			hint.text = "Mantener E"
			pressure_bar.value += pressure_speed * delta
		else:
			pressure_bar.value -= pressure_decay * delta
		pressure_bar.value = clamp(pressure_bar.value, 0, 100)
		if pressure_bar.value >= 100: _on_pressure_complete()

func _on_pressure_complete():
	is_complete = true
	generator_fixed.emit()
	GameManager.generator_repaired = true
	GameManager.lab_door_powered = true
	
	var player = get_tree().get_first_node_in_group("player")
	if player: player.set_process_input(true)
	get_tree().paused = false
	queue_free()

func _on_close_pressed():
	var player = get_tree().get_first_node_in_group("player")
	if player: player.set_process_input(true)
	get_tree().paused = false
	queue_free()
