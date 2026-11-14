extends Node2D

const DEFAULT_MOTOR := "res://assets/sound/effects/electric_generator.mp3"

@export var system_id: String = "cooling"
@export var light: PointLight2D
@export var shake_targets: Array[Node2D] = []
@export var invert_logic: bool = false
@export var shake_amplitude: float = 1.0
@export var shake_interval: float = 0.04
@export var light_color: Color = Color(0.3, 1.0, 0.4)
@export var light_energy: float = 1.0
@export var motor_stream: AudioStream
@export var motor_pitch: float = 1.0
@export var motor_volume_db: float = 0.0
@export var motor_max_distance: float = 180.0

var _shaking: bool = false
var _shake_timer: float = 0.0
var _base_positions: Dictionary = {}
var _light_tween: Tween
var _motor: AudioStreamPlayer2D
var _motor_tween: Tween

func _ready() -> void:
	for t in shake_targets:
		if t:
			_base_positions[t] = t.position
	if light:
		light.color = light_color
	_setup_motor()
	GameManager.basement_system_changed.connect(_on_system_changed)
	_refresh(false)

func _process(delta: float) -> void:
	if not _shaking:
		return
	_shake_timer += delta
	if _shake_timer < shake_interval:
		return
	_shake_timer = 0.0
	var offset := Vector2(
		randf_range(-shake_amplitude, shake_amplitude),
		randf_range(-shake_amplitude, shake_amplitude)
	)
	for t in _base_positions:
		if is_instance_valid(t):
			t.position = _base_positions[t] + offset

func _setup_motor() -> void:
	var stream: AudioStream = motor_stream
	if stream == null and ResourceLoader.exists(DEFAULT_MOTOR):
		stream = load(DEFAULT_MOTOR)
	if stream == null:
		return
	if stream is AudioStreamMP3:
		stream.loop = true
	_motor = AudioStreamPlayer2D.new()
	_motor.stream = stream
	_motor.bus = &"SFX"
	_motor.pitch_scale = motor_pitch
	_motor.max_distance = motor_max_distance
	_motor.attenuation = 1.5
	_motor.volume_db = -60.0
	add_child(_motor)

func _set_motor(on: bool) -> void:
	if _motor == null:
		return
	if _motor_tween and _motor_tween.is_valid():
		_motor_tween.kill()
	_motor_tween = create_tween()
	if on:
		if not _motor.playing:
			_motor.volume_db = -60.0
			_motor.play(randf() * minf(2.0, _motor.stream.get_length()))
		_motor_tween.tween_property(_motor, "volume_db", motor_volume_db, 0.6)
	else:
		_motor_tween.tween_property(_motor, "volume_db", -60.0, 0.8)
		_motor_tween.tween_callback(_motor.stop)

func _on_system_changed(id: String, _active: bool) -> void:
	if id == system_id:
		_refresh(true)

func _refresh(animate: bool) -> void:
	var done: bool = GameManager.basement_done.get(system_id, false)
	_shaking = not done
	if done:
		_reset_targets()
	_set_motor(not done)
	_set_light(done != invert_logic, animate)

func _reset_targets() -> void:
	for t in _base_positions:
		if is_instance_valid(t):
			t.position = _base_positions[t]

func _set_light(on: bool, animate: bool) -> void:
	if light == null:
		return
	if _light_tween and _light_tween.is_valid():
		_light_tween.kill()
	if not on:
		light.enabled = false
		return
	light.enabled = true
	if animate:
		light.energy = 0.0
		_light_tween = create_tween()
		_light_tween.tween_property(light, "energy", light_energy, 0.25)
	else:
		light.energy = light_energy
