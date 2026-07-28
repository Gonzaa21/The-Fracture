extends Area2D

enum ComputerState { NO_POWER, LOCKED, UNLOCKED, DEGRADING, DESTROYED }
var current_state: ComputerState = ComputerState.NO_POWER
var player_nearby: bool = false
var degradation_active: bool = false

@onready var sprite = $Sprite2D
@onready var icon = $CanvasLayer/TextureRect

func _ready():
	if GameManager.computer_has_battery:
		current_state = ComputerState.LOCKED
		sprite.texture = load("res://assets/backgrounds_popup/computer/background_pc.png")
	else:
		current_state = ComputerState.NO_POWER

func _process(delta: float) -> void:
	if degradation_active and current_state != ComputerState.DESTROYED:
		GameManager.degradation_elapsed += delta * GameManager.degradation_speed_multiplier
		if GameManager.degradation_elapsed >= GameManager.degradation_limit:
			_force_shutdown()

	if player_nearby and Input.is_action_just_pressed("interact"):
		interact()

func interact():
	match current_state:
		ComputerState.NO_POWER:
			if GameManager.current_item_id == "modulo_sync":
				install_module()
			else:
				show_error_screen()
		ComputerState.LOCKED:
			show_boot_sequence()
		ComputerState.UNLOCKED, ComputerState.DEGRADING:
			show_terminal()
		ComputerState.DESTROYED:
			show_destroyed_screen()

func install_module():
	current_state = ComputerState.LOCKED
	GameManager.computer_has_battery = true
	sprite.texture = load("res://assets/backgrounds_popup/computer/background_pc.png")

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.use_item()
	GameManager.current_item_id = ""

	degradation_active = true
	GameManager.degradation_elapsed = 0.0

	show_boot_sequence()
	print("Módulo instalado, degradación iniciada")

func show_error_screen():
	var error_screen = get_tree().current_scene.get_node("ComputerErrorScreen")
	if error_screen:
		error_screen.show_error()

func _force_shutdown():
	degradation_active = false
	current_state = ComputerState.DESTROYED
	var terminal = get_parent().get_node("ComputerTerminalScreen")
	if terminal and terminal.panel.visible:
		terminal.close_terminal()
	
	var shutdown_sfx = AudioStreamPlayer.new()
	add_child(shutdown_sfx)
	shutdown_sfx.stream = load("res://assets/sound/effects/pc/electrical_shok.mp3")
	shutdown_sfx.volume_db = -3
	shutdown_sfx.bus = "SFX"
	shutdown_sfx.play()

func show_destroyed_screen():
	print("La PC está destruida, no se puede usar")

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

func _on_login_successful():
	current_state = ComputerState.DEGRADING
	show_terminal()

func _on_login_cancelled():
	pass

func is_degrading() -> bool:
	return current_state == ComputerState.DEGRADING

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		icon.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		icon.visible = false
