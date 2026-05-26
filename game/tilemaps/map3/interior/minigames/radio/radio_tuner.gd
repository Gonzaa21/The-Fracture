extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var frequency_label: Label = $Panel/FrequencyLabel
@onready var frequency_slider: Control = $Panel/FrequencySlider
@onready var signal_bar: Control = $Panel/SignalStrength
@onready var waveform: Control = $Panel/WaveForm
@onready var dial_control: Control = $Panel/DialControl
@onready var play_button: Button = $Panel/PlayButton
@onready var close_button: Button = $Panel/CloseButton

@onready var static_player: AudioStreamPlayer = $StaticPlayer
@onready var morse_player: AudioStreamPlayer = $MorsePlayer

var target_frequency: float = 92.3
var tolerance: float = 0.05

var dial_value: float = 87.5 
var slider_value: float = 0.0
var combined_frequency: float = 87.5

var is_calibrated: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	target_frequency = MorseManager.get_target_frequency()
	
	frequency_slider.value_changed.connect(_on_slider_changed)
	dial_control.value_changed.connect(_on_dial_changed)
	play_button.pressed.connect(_on_play_pressed)
	close_button.pressed.connect(_on_close_pressed)
	MorseManager.transmission_finished.connect(_on_morse_finished)
	
	_setup_controls()
	
	if static_player:
		static_player.play()
	
	_update_combined_frequency()

func _on_morse_finished() -> void:
	$Panel/PlayButton.text = "Volver a reproducir"

func _setup_controls():
	dial_control.min_value = 85.0
	dial_control.max_value = 100.0
	dial_control.current_value = 87.5
	
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
	play_button.disabled = not is_calibrated
	
	if is_calibrated:
		play_button.disabled = false
	else:
		play_button.disabled = true

func _on_play_pressed():
	play_button.text = "REPRODUCIENDO..."	
	if static_player:
		static_player.stop()
	print("Reproduciendo morse...")
	MorseManager.play_current_message()

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
	queue_free()
