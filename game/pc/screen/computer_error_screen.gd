extends CanvasLayer
@onready var panel = $Panel
@onready var install_button = $Panel/InstallButton

func _ready():
	panel.visible = false
	visible = true
	install_button.visible = false
	install_button.pressed.connect(_on_install_pressed)

func show_error():
	panel.visible = true
	
	if GameManager.current_item_id == "modulo_sync":
		install_button.visible = true
		install_button.disabled = false
	else:
		install_button.visible = false
	
	Global.input_locked = true

func _on_install_pressed():
	hide_error()
	var computer = get_tree().current_scene.get_node("Computer")
	if computer: computer.install_module()

func _input(event):
	if panel.visible and event.is_action_pressed("ui_cancel"):
		hide_error()

func hide_error():
	panel.visible = false
	install_button.visible = false
	Global.input_locked = false
