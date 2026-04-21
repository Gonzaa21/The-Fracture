extends CanvasLayer

@onready var frequency_label: Label = $Panel/FrequencyLabel
@onready var frequency_slider: HSlider = $Panel/FrequencySlider
@onready var signal_bar: ProgressBar = $Panel/SignalStrength
@onready var play_button: Button = $Panel/PlayButton
@onready var close_button: Button = $Panel/CloseButton

@onready var static_player: AudioStreamPlayer = $StaticPlayer
@onready var morse_player: AudioStreamPlayer = $MorsePlayer

var target_frequency: float = 92.3
var tolerance: float = 0.2

var is_calibrated: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	frequency_slider.value_changed.connect(_on_frequency_changed)
	play_button.pressed.connect(_on_play_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	get_tree().paused = true
	if static_player:
		static_player.play()
	
	_on_frequency_changed(frequency_slider.value)

func _on_frequency_changed(value: float):
	frequency_label.text = "FRECUENCIA: %.1f MHz" % value
	
	var distance = abs(value - target_frequency)
	
	var signal_strength = 100.0 * exp(-distance * 5.0)
	signal_strength = clamp(signal_strength, 0, 100)

	signal_bar.value = signal_strength
	
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
	# MorseManager.play_current_message()

func _on_close_pressed():
	if static_player:
		static_player.stop()
	if morse_player:
		morse_player.stop()
	
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		player.set_process_input(true)
	
	get_tree().paused = false
	queue_free()
