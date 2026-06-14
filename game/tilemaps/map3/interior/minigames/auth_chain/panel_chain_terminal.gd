extends CanvasLayer

signal authorized
@onready var panel: VBoxContainer = $Panel
@onready var digit_1: LineEdit = $Panel/HBoxContainer/Digit1
@onready var digit_2: LineEdit = $Panel/HBoxContainer/Digit2
@onready var error_label: Label = $Panel/Error
@onready var confirm_button: Button = $Panel/ConfirmButton
@export var terminal_id: String = ""
@export var digit_index: Array = []
var correct_digits: Array = []

func _ready() -> void:
	panel.visible = false
	var key = GameManager.key_code
	for i in digit_index:
		correct_digits.append(key[i])
	
	if digit_index.size() == 1:
		digit_2.visible = false
	
	error_label.visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)

func _on_confirm_pressed():
	var digits_int = []
	digits_int.append(int(digit_1.text))
	if digit_index.size() > 1:
		digits_int.append(int(digit_2.text))
	
	if correct_digits == digits_int:
		GameManager.chain_auth[terminal_id] = true
		authorized.emit()
		_on_close_pressed()
	else:
		error_label.visible = true
		await get_tree().create_timer(0.5).timeout
		error_label.visible = false

func _on_close_pressed():
	queue_free()
