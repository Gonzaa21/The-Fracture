extends CanvasLayer

@onready var panel = $Panel
@onready var output_label = $Panel/Control/OutputScroll/OutputLabel
@onready var prompt_label = $Panel/Control/InputContainer/PromptLabel
@onready var command_input = $Panel/Control/InputContainer/CommandInput

@onready var glitch_burst_timer: Timer = Timer.new()
@onready var computer_ref = get_parent().get_node("Computer")
@onready var glitch_material: ShaderMaterial = $Panel/ColorRect.material

var typewriter_sounds: Array[AudioStream] = []
var typewriter_player: AudioStreamPlayer

var pc_ambient_sfx: AudioStreamPlayer
var glitch_ambient_sfx: AudioStreamPlayer
var terminal_boot_sfx: AudioStreamPlayer
var terminal_error_sfx: AudioStreamPlayer
var glitch_sfx: AudioStreamPlayer

var is_initialized = false
var has_booted_before: bool = false

func _ready():
	panel.visible = false
	command_input.text_submitted.connect(_on_command_submitted)
	is_initialized = true
	typewriter_audio()
	pc_audio()
	glitch_burst_timer.one_shot = true
	glitch_burst_timer.timeout.connect(_on_glitch_burst_timeout)
	add_child(glitch_burst_timer)

func _process(_delta: float) -> void:
	if not panel.visible or not computer_ref.is_degrading(): return
	if not panel.visible: return
	if not glitch_material: return
	
	var ratio = clamp(GameManager.degradation_elapsed / GameManager.degradation_limit, 0.0, 1.0)
	glitch_material.set_shader_parameter("intensity", ratio)
	glitch_material.set_shader_parameter("time_offset", Time.get_ticks_msec() / 1000.0)

func show_terminal():
	Global.input_locked = true
	
	if not is_initialized:
		await ready
	
	if panel.visible: return
	
	output_label.text = ""
	panel.visible = true
	visible = true
	
	GameManager.lower_background_music(-28, 1.5)
	if pc_ambient_sfx and pc_ambient_sfx.stream:
		pc_ambient_sfx.play()
	
	if not has_booted_before:
		if terminal_boot_sfx and terminal_boot_sfx.stream:
			terminal_boot_sfx.play()
			glitch_ambient_sfx.play()
		has_booted_before = true
	
	# Mostrar mensaje de bienvenida
	print_line("NeuralCorp PowerShell")
	print_line("Copyright (C) Neural Corporation. All rights reserved.")
	print_line("Type 'help' for available commands.")
	print_line("")
	update_prompt()
	
	command_input.grab_focus()

func _on_command_submitted(text: String):
	if not command_input.editable: return
	
	print_line(prompt_label.text + " " + text)
	process_command(text)
	scroll_to_bottom()
	update_prompt()
	command_input.text = ""

func process_command(input: String):
	# limpiar input y convertir a minusculas
	var clean_input = input.strip_edges()
	if clean_input == "":
		return
	
	# separar comandos y argumentos
	var parts = clean_input.split(" ", false, 1)
	var command = parts[0].to_lower()
	var argument = parts[1] if parts.size() > 1 else ""
	
	match command:
		"help": TerminalCommands.cmd_help(self)
		"dir": TerminalCommands.cmd_dir(self)
		"cd": TerminalCommands.cmd_cd(self, argument)
		"type": TerminalCommands.cmd_type(self, argument)
		"netstat": TerminalCommands.cmd_netstat(self)
		"exit": TerminalCommands.cmd_exit(self)
		_:
			print_line("'" + command + "' is not recognized as an internal or external command.")
	
	print_line("")

func print_line(text: String):
	output_label.text += text + "\n"
	
func scroll_to_bottom():
	await get_tree().process_frame
	var scroll = $Panel/Control/OutputScroll
	if scroll:
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func update_prompt():
	prompt_label.text = "PS " + GameManager.current_directory + ">"

func close_terminal():
	panel.visible = false
	Global.input_locked = false
	
	if pc_ambient_sfx and pc_ambient_sfx.playing:
		pc_ambient_sfx.stop()
	
	GameManager.restore_background_music(1.5)

# ====== PHOENIX PROTOCOL ======

func handle_special_file(content: String):
	if content == "[SPECIAL_TRIGGER:PHOENIX_GLITCH]":
		phoenix_sequence()

func phoenix_sequence():
	command_input.editable = false
	await glitch_effect()
	await phoenix_conversation()
	await get_tree().create_timer(1.5).timeout
	command_input.editable = true
	command_input.grab_focus()
	GameManager.mark_phoenix_viewed()
	default_terminal()

func default_terminal():
	output_label.add_theme_color_override("default_color", Color.WHITE)
	await get_tree().create_timer(0.1).timeout
	output_label.add_theme_color_override("default_color", Color.BLACK)
	await get_tree().create_timer(0.1).timeout
	output_label.add_theme_color_override("default_color", Color.WHITE)
	await get_tree().create_timer(0.1).timeout
	
	output_label.text = ""
	var terminal_color = Color(1.0, 1.0, 1.0, 1.0)
	output_label.add_theme_color_override("default_color", terminal_color)

func glitch_effect():
	# Colores para el glitch
	var terminal_green = Color(0, 1, 0)
	var glitch_red = Color(1, 0, 0)
	var glitch_white = Color(1, 1, 1)
	var glitch_blue = Color(0, 0.5, 1)
	var glitch_purple = Color(0.8, 0, 1)
	var glitch_yellow = Color(1, 1, 0)
	
	output_label.add_theme_color_override("default_color", glitch_red)
	play_error_burst(3)
	print_line("█████████████████████████████████████████")
	await get_tree().create_timer(1.1).timeout
	
	# Parpadeo rápido: rojo → verde → rojo
	output_label.add_theme_color_override("default_color", terminal_green)
	await get_tree().create_timer(0.05).timeout
	output_label.add_theme_color_override("default_color", glitch_red)
	play_error_burst(2)
	print_line("███ ERROR ████ ACCESO ████ DENEGADO ███")
	await get_tree().create_timer(0.08).timeout
	
	# Parpadeo caótico: blanco → azul → amarillo
	output_label.add_theme_color_override("default_color", glitch_white)
	await get_tree().create_timer(0.05).timeout
	output_label.add_theme_color_override("default_color", glitch_blue)
	await get_tree().create_timer(0.05).timeout
	output_label.add_theme_color_override("default_color", glitch_yellow)
	print_line("▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓")
	await get_tree().create_timer(0.08).timeout
	
	if glitch_sfx and glitch_sfx.stream:
		glitch_sfx.play()
	
	# Estallido rápido de colores
	for i in range(6):  # 6 parpadeos rápidos
		var colors = [glitch_red, glitch_white, glitch_blue, glitch_purple, glitch_yellow, terminal_green]
		output_label.add_theme_color_override("default_color", colors[i])
		
		if i % 2 == 0:
			play_error_sound()
		
		await get_tree().create_timer(0.04).timeout
	
	output_label.add_theme_color_override("default_color", glitch_white)
	print_line("P̴̛r̵o̶t̷o̴c̵o̶l̴o̶ P̴h̶o̴e̵n̶i̷x̴ - A̶C̵C̶E̵S̶O̷ R̴E̵S̶T̷R̴I̵N̶G̷I̴D̵O̶")
	await get_tree().create_timer(0.1).timeout
	
	# Parpadeo intenso: púrpura → rojo → púrpura
	output_label.add_theme_color_override("default_color", glitch_purple)
	await get_tree().create_timer(0.06).timeout
	output_label.add_theme_color_override("default_color", glitch_red)
	await get_tree().create_timer(0.06).timeout
	play_error_burst(7)
	output_label.add_theme_color_override("default_color", glitch_purple)
	print_line("██ INICIANDO BYPASS DE SEGURIDAD ██")
	await get_tree().create_timer(0.15).timeout
	
	# Parpadeo final caótico antes de estabilizar
	output_label.add_theme_color_override("default_color", glitch_yellow)
	await get_tree().create_timer(0.05).timeout
	output_label.add_theme_color_override("default_color", glitch_blue)
	await get_tree().create_timer(0.05).timeout
	play_error_burst(3)
	output_label.add_theme_color_override("default_color", glitch_white)
	await get_tree().create_timer(0.05).timeout
	output_label.add_theme_color_override("default_color", glitch_red)
	await get_tree().create_timer(0.05).timeout
	
	output_label.add_theme_color_override("default_color", glitch_white)
	print_line("")
	print_line("ESTABLECIENDO CONEXIÓN SEGURA...")
	await get_tree().create_timer(0.3).timeout
	
	# Parpadeo verde-blanco (estabilizando)
	output_label.add_theme_color_override("default_color", terminal_green)
	await get_tree().create_timer(0.1).timeout
	output_label.add_theme_color_override("default_color", glitch_white)
	await get_tree().create_timer(0.1).timeout
	output_label.add_theme_color_override("default_color", terminal_green)
	
	print_line("BYPASSING ENCRYPTION...")
	await get_tree().create_timer(0.4).timeout
	
	# Último parpadeo antes de establecer
	output_label.add_theme_color_override("default_color", glitch_blue)
	await get_tree().create_timer(0.08).timeout
	output_label.add_theme_color_override("default_color", terminal_green)
	
	print_line("CONEXIÓN ESTABLECIDA.")
	await get_tree().create_timer(0.3).timeout
	
	print_line("")
	# Parpadeo final dramático
	output_label.add_theme_color_override("default_color", glitch_white)
	await get_tree().create_timer(0.1).timeout
	output_label.add_theme_color_override("default_color", terminal_green)
	
	print_line("")
	await get_tree().create_timer(0.5).timeout

# Reproducir un sonido de error
func play_error_sound():
	if terminal_error_sfx and terminal_error_sfx.stream:
		terminal_error_sfx.play()

# Reproducir varios errores con delays
func play_error_burst(count: int):
	for i in range(count):
		play_error_sound()
		await get_tree().create_timer(0.08).timeout

func phoenix_conversation():
	var conversation = GameManager.filesystem_data.get("phoenix_conversation", [])
	for message in conversation:
		var speaker = message.get("speaker", "")
		var text = message.get("text", "")
		
		var color = get_speaker_color(speaker)
		var formatted_text = "[color=" + color + "]" + text + "[/color]\n"
		
		
		# Mostrar con efecto typewriter
		await print_typewriter(formatted_text, 0.02)
		
		# Delay entre mensajes
		await get_tree().create_timer(0.5).timeout
	
	print_line("")

func get_speaker_color(speaker: String) -> String:
	match speaker:
		"SYSTEM": return "#00ff00"
		"NEXUS":  return "#00c400"
		"???":    return "#008300"
		_:        return "#ffffff"

# typewriter
func typewriter_audio():
	# Crear reproductor
	typewriter_player = AudioStreamPlayer.new()
	add_child(typewriter_player)
	typewriter_player.volume_db = -10
	typewriter_player.bus = "SFX"
	
	for i in range(1, 7):
		var sound = load("res://assets/sound/effects/typewritter/Typewritter%d.mp3" % i)
		if sound:
			typewriter_sounds.append(sound)

func print_typewriter(text: String, speed: float = 0.02):
	var _current_text = ""
	for character in text:
		_current_text += character
		# Actualizar el output agregando solo el último caracter
		output_label.text += character
		
		if character != " " and character != "\n":
			random_typewriter_sound()
		
		# Auto-scroll
		await get_tree().process_frame
		var scroll = $Panel/Control/OutputScroll
		if scroll:
			scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value
		
		# Delay entre caracteres
		await get_tree().create_timer(speed).timeout
	
	# Nueva línea al final
	output_label.text += "\n"

func random_typewriter_sound():
	if typewriter_sounds.size() > 0:
		var random_index = randi() % typewriter_sounds.size()
		typewriter_player.stream = typewriter_sounds[random_index]
		typewriter_player.pitch_scale = randf_range(0.95, 1.05)
		typewriter_player.play()

func pc_audio():
	# PC Ambient
	pc_ambient_sfx = AudioStreamPlayer.new()
	add_child(pc_ambient_sfx)
	pc_ambient_sfx.stream = load("res://assets/sound/effects/pc/pc.mp3")
	pc_ambient_sfx.volume_db = -6
	pc_ambient_sfx.bus = "SFX"
	
	glitch_ambient_sfx = AudioStreamPlayer.new()
	add_child(glitch_ambient_sfx)
	glitch_ambient_sfx.stream = load("res://assets/sound/effects/pc/pc_glitch_background.mp3")
	glitch_ambient_sfx.volume_db = -6
	glitch_ambient_sfx.bus = "SFX"
	
	# Terminal Boot
	terminal_boot_sfx = AudioStreamPlayer.new()
	add_child(terminal_boot_sfx)
	terminal_boot_sfx.stream = load("res://assets/sound/effects/pc/pc_start.mp3")
	terminal_boot_sfx.volume_db = -9
	terminal_boot_sfx.bus = "SFX"
	
	# Terminal Error
	terminal_error_sfx = AudioStreamPlayer.new()
	add_child(terminal_error_sfx)
	terminal_error_sfx.stream = load("res://assets/sound/effects/pc/pc_error.wav")
	terminal_error_sfx.volume_db = -5
	terminal_error_sfx.bus = "SFX"
	
	# Glitch
	glitch_sfx = AudioStreamPlayer.new()
	add_child(glitch_sfx)
	glitch_sfx.stream = load("res://assets/sound/effects/pc/pc_glitch.wav")
	glitch_sfx.volume_db = -3
	glitch_sfx.bus = "SFX"

func _on_glitch_burst_timeout():
	if panel.visible and computer_ref.is_degrading():
		play_error_burst(1)
		_schedule_next_glitch()

func _schedule_next_glitch():
	var ratio = clamp(GameManager.degradation_elapsed / GameManager.degradation_limit, 0.0, 1.0)
	var wait = lerp(4.0, 0.3, ratio)
	glitch_burst_timer.start(wait)
