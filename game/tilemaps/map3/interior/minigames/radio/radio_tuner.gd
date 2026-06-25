extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var frequency_label: Label = $Panel/FrequencyLabel
@onready var frequency_slider: Control = $Panel/FrequencySlider
@onready var signal_bar: Control = $Panel/SignalStrength
@onready var waveform: Control = $Panel/WaveForm
@onready var dial_control: Control = $Panel/DialControl
@onready var play_button: Button = $Panel/PlayButton
@onready var close_button: Button = $Panel/CloseButton
@onready var dial_port: Control = $Panel/DialPort
@onready var port_label: Label = $Panel/Port

@onready var static_player: AudioStreamPlayer = $StaticPlayer
@onready var morse_player: AudioStreamPlayer = $MorsePlayer

var target_frequency: float = 92.3
var tolerance: float = 0.05

var correct_port_selected: bool = false
var morse_port_active: bool = true

var dial_value: float = 87.5 
var slider_value: float = 0.0
var combined_frequency: float = 87.5

var is_calibrated: bool = false

var transmission_authorized: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	target_frequency = MorseManager.get_target_frequency()
	
	frequency_slider.value_changed.connect(_on_slider_changed)
	dial_control.value_changed.connect(_on_dial_changed)
	play_button.pressed.connect(_on_play_pressed)
	close_button.pressed.connect(_on_close_pressed)
	MorseManager.transmission_finished.connect(_on_morse_finished)
	dial_port.value_changed.connect(_on_port_changed)
	
	_setup_controls()
	#play_button.disabled = not (GameManager.generator_repaired and GameManager.chain_auth["terminal_1"] and GameManager.chain_auth["terminal_2"])
	_on_port_changed(dial_port.current_value)
	
	if static_player:
		static_player.play()
	
	_update_combined_frequency()

func _on_morse_finished() -> void:
	$Panel/PlayButton.text = "Volver a reproducir"

func _setup_controls():
	dial_control.min_value = 85.0
	dial_control.max_value = 100.0
	dial_control.current_value = 87.5
	
	dial_port.min_value = 0
	dial_port.max_value = 9
	dial_port.current_value = 0
	
	frequency_slider.min_value = -0.5
	frequency_slider.max_value = 0.5
	frequency_slider.current_value = 0.0

func _on_dial_changed(value: float):
	dial_value = value
	_update_combined_frequency()

func _on_slider_changed(value: float):
	slider_value = value
	_update_combined_frequency()

func _update_combined_frequency():
	combined_frequency = dial_value + slider_value
	
	frequency_label.text = "%.2f MHz" % combined_frequency
	
	var distance = abs(combined_frequency - target_frequency)
	
	var signal_strength = 100.0 * exp(-distance * 8.0)
	signal_strength = clamp(signal_strength, 0, 100)
	
	signal_bar.set_signal(signal_strength)
	
	var sync = clamp(1.0 - (distance / 2.0), 0.0, 1.0)
	waveform.set_sync_level(sync)
	
	if static_player:
		var static_volume = lerp(-10.0, -30.0, signal_strength / 100.0)
		static_player.volume_db = static_volume
	
	is_calibrated = (distance <= tolerance)
	play_button.disabled = not is_calibrated or (not morse_port_active and not correct_port_selected)

	
func _on_play_pressed():
	play_button.text = "REPRODUCIENDO..."	
	if static_player:
		static_player.stop()
	if morse_port_active:
		MorseManager.play_current_message()
		print("Reproduciendo morse...")
	elif correct_port_selected:
		if not GameManager.generator_repaired: return
		if not (GameManager.chain_auth["terminal_1"] and GameManager.chain_auth["terminal_2"]): return
		GameManager.chain_auth["terminal_3"] = true
		transmission_authorized = true
	else: return

func _on_port_changed(value: float):
	if GameManager.key_code.is_empty(): return
	if not GameManager.generator_repaired: return
	if not (GameManager.chain_auth["terminal_1"] and GameManager.chain_auth["terminal_2"]): return
	
	port_label.text = "%02d" % int(value)
	var port = int(value)
	morse_port_active = (port == 0)
	
	dial_control.set_value(randf_range(dial_control.min_value, dial_control.max_value))
	frequency_slider.set_value(randf_range(-0.5, 0.5))
	play_button.disabled = true
	
	var correct_port = int(GameManager.key_code[4])
	
	if waveform:
		waveform.set_port_pattern(port)
	
	correct_port_selected = (port == correct_port)
	GameManager.chain_auth["terminal_3"] = correct_port_selected
	
	if not correct_port_selected:
		MorseManager.stop_transmission()
	
	_update_combined_frequency()

func _on_close_pressed():
	MorseManager.stop_transmission()
	if static_player:
		static_player.stop()
	if morse_player:
		morse_player.stop()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_input(true)
	
	get_tree().paused = false
	if transmission_authorized:
		var echo_player = AudioStreamPlayer.new()
		GameManager.add_child(echo_player)
		echo_player.stream = load("res://assets/sound/effects/eco.wav")
		echo_player.play()
		echo_player.finished.connect(func():
			echo_player.queue_free())
		GameManager.open_lab_door.emit()
	queue_free()
