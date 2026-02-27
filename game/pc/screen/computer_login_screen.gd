extends CanvasLayer

signal login_successful
signal login_cancelled

@onready var panel = $Panel
@onready var password_input = $Panel/CenterContainer/Control/PasswordInput
@onready var hint_label = $Panel/CenterContainer/Control/HintLabel
@onready var error_label = $Panel/CenterContainer/Control/ErrorLabel
@onready var login_button = $Panel/CenterContainer/Control/LoginButton

func _ready():
	panel.visible = false
	visible = true
	password_input.text_submitted.connect(_on_password_submitted)
	login_button.pressed.connect(_on_login_button_pressed)
	hint_label.visible = false
	error_label.visible = false
	
func show_login():
	panel.visible = true
	Global.input_locked = true

func validate_password(input_text: String):
	if input_text.strip_edges() == "":
		return
		
	if input_text == GameManager.computer_password:
		emit_signal("login_successful")
		panel.visible = false
		Global.input_locked = false
		print("Login exitoso!")
	else:
		error_label.visible = true
		if not GameManager.password_hint_shown:
			hint_label.visible = true
			GameManager.password_hint_shown = true
	
	password_input.text = ""
	password_input.grab_focus()
	
func _on_password_submitted(text: String):
	validate_password(text)

func _on_login_button_pressed():
	var input = password_input.text
	validate_password(input)

func _input(event):
	if panel.visible and event.is_action_pressed("ui_cancel"):
		close_login()

func close_login():
	panel.visible = false
	emit_signal("login_cancelled")
	Global.input_locked = false
