extends Area2D

enum ComputerState { NO_POWER, LOCKED, UNLOCKED }

var current_state: ComputerState = ComputerState.NO_POWER
var player_nearby: bool = false

@onready var sprite = $Sprite2D
@onready var icon = $CanvasLayer/TextureRect

func _ready():
	if GameManager.computer_has_battery:
		current_state = ComputerState.LOCKED
		sprite.texture = load("res://assets/backgrounds_popup/computer/background_pc.png")
	else:
		current_state = ComputerState.NO_POWER
		
func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		interact()

func interact():
	match current_state:
		ComputerState.NO_POWER:
			if GameManager.has_battery:
				show_install_prompt()
			else:
				show_error_screen()
		ComputerState.LOCKED:
			show_boot_sequence()
		ComputerState.UNLOCKED:
			show_terminal()

func show_install_prompt():
	show_error_screen()

func show_error_screen():
	var error_screen = get_tree().current_scene.get_node("ComputerErrorScreen")
	if error_screen:
		error_screen.show_error()
	else:
		print("ERROR: ComputerErrorScreen no encontrado")
	
func _on_battery_button_pressed():
	install_battery()
	Global.input_locked = false

func install_battery():
	current_state = ComputerState.LOCKED
	GameManager.computer_has_battery = true
	GameManager.has_battery = false
	sprite.texture = load("res://assets/backgrounds_popup/computer/background_pc.png")
	var player = get_tree().get_first_node_in_group("player")
	if player: player.use_item()
	show_boot_sequence()
	print("Batería instalada correctamente")

func show_boot_sequence():
	if GameManager.computer_has_booted:
		show_login_screen()
		return
	
	var boot_screen = get_parent().get_node("ComputerBootScreen")
	if boot_screen: 
		boot_screen.start_boot()
		await boot_screen.boot_finished
		GameManager.computer_has_booted = true
		show_login_screen()
	else:
		print("Boot screen no encontrado")

func show_login_screen():
	var login_screen = get_parent().get_node("ComputerLoginScreen")
	if login_screen:
		login_screen.visible = true
		login_screen.panel.visible = true
		login_screen.show_login()
		
		login_screen.login_successful.connect(_on_login_successful, CONNECT_ONE_SHOT)
		login_screen.login_cancelled.connect(_on_login_cancelled, CONNECT_ONE_SHOT)

func show_terminal():
	var terminal = get_parent().get_node("ComputerTerminalScreen")
	if terminal:
		terminal.show_terminal()
	else:
		print("ERROR: Terminal no encontrada")

func _on_login_successful():
	current_state = ComputerState.UNLOCKED
	show_terminal()

func _on_login_cancelled():
	print("Login cancelado, estado permanece LOCKED")


func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		icon.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		icon.visible = false
