extends Node2D

@export var system_id: String = "cooling"
@export var light: PointLight2D
@export var shake_targets: Array[Node2D] = []
@export var invert_logic: bool = false
@export var shake_amplitude: float = 1.0
@export var shake_interval: float = 0.04
@export var light_color: Color = Color(0.3, 1.0, 0.4)
@export var light_energy: float = 1.0

var _shaking: bool = false
var _shake_timer: float = 0.0
var _base_positions: Dictionary = {}
var _light_tween: Tween

func _ready() -> void:
	for t in shake_targets:
		if t:
			_base_positions[t] = t.position
	if light:
		light.color = light_color
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

func _on_system_changed(id: String, _active: bool) -> void:
	if id == system_id:
		_refresh(true)

func _refresh(animate: bool) -> void:
	var done: bool = GameManager.basement_done.get(system_id, false)
	_shaking = not done
	if done:
		_reset_targets()
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
