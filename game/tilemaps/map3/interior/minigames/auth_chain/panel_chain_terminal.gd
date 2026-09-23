extends CanvasLayer

signal authorized
@onready var panel: VBoxContainer = $Control/Panel
@onready var control: Control = $Control
@onready var digit_1: LineEdit = $Control/Panel/HBoxContainer/Digit1
@onready var digit_2: LineEdit = $Control/Panel/HBoxContainer/Digit2
@onready var error_label: Label = $Control/Panel/VBoxContainer/Error
@onready var confirm_button: Button = $Control/Panel/VBoxContainer/ConfirmButton
@onready var locked_label: Label = $Control/Panel/Locked
@export var terminal_id: String = ""
@export var digit_index: Array = []
var content_target_position: Vector2
var correct_digits: Array = []

var failed_attempts: int = 0
var is_locked: bool = false
const FAILS_BEFORE_LOCK := 2
const LOCK_DURATION := 20.0

func _ready() -> void:
	control.visible = true
	content_target_position = control.position
	var key = GameManager.key_code
	for i in digit_index:
		correct_digits.append(int(key[i]))
	
	if digit_index.size() == 1:
		digit_2.visible = false
	
	if GameManager.terminal_lock_until.has(terminal_id):
		var remaining_ms = GameManager.terminal_lock_until[terminal_id] - Time.get_ticks_msec()
		if remaining_ms > 0:
			_lock_terminal(remaining_ms / 1000.0)
	
	error_label.visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	digit_1.text_changed.connect(_on_digit1_changed)
	digit_2.text_changed.connect(_on_digit2_changed)
	digit_2.focus_entered.connect(_on_digit2_focus_entered)

func open_panel():
	control.visible = true
	control.position = content_target_position + Vector2(0, 100)
	control.modulate.a = 0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "position", content_target_position, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, 0.3)

func _on_confirm_pressed():
	var digits_int = []
	digits_int.append(int(digit_1.text))
	print(correct_digits)
	if digit_index.size() > 1:
		digits_int.append(int(digit_2.text))
	print(digits_int)
	if correct_digits == digits_int:
		failed_attempts = 0
		GameManager.chain_auth[terminal_id] = true
		authorized.emit()
		close_panel()
	else:
		failed_attempts += 1
		error_label.visible = true
		await get_tree().create_timer(0.5).timeout
		error_label.visible = false
		if failed_attempts >= FAILS_BEFORE_LOCK: _lock_terminal()
	digit_1.text = ""
	digit_2.text = ""

func _lock_terminal(duration := LOCK_DURATION):
	is_locked = true
	failed_attempts = 0
	confirm_button.visible = false
	error_label.visible = false
	digit_1.visible = false
	digit_2.visible = false
	locked_label.visible = true
	
	GameManager.terminal_lock_until[terminal_id] = Time.get_ticks_msec() + duration * 1000
	await get_tree().create_timer(duration).timeout
	
	is_locked = false
	confirm_button.visible = true
	digit_1.visible = true
	if digit_index.size() > 1:
		digit_2.visible = true
	locked_label.visible = false
	GameManager.terminal_lock_until.erase(terminal_id)

func _on_digit1_changed(new_text: String):
	if new_text.length() > 0 and digit_2.visible:
		digit_2.grab_focus()

func _on_digit2_changed(new_text: String):
	if new_text.length() == 0:
		digit_1.grab_focus()

func _on_digit2_focus_entered():
	if digit_1.text.is_empty():
		digit_1.grab_focus()

func close_panel():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(control, "position", content_target_position + Vector2(0, 100), 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(control, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()

func _on_close_pressed():
	close_panel()
