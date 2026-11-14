extends Node

signal time_changed(seconds_left: float)
signal time_up
signal pulse_warning
signal pulse_fired(duration: float)

const HUD_SCENE := preload("res://game/tilemaps/map3/interior/minigames/laboratory/hud_timer.tscn")
const FX_SCRIPT := preload("res://game/tilemaps/map3/interior/minigames/laboratory/alarm_sfx.gd")
const BAD_END_NEXT_SCENE := "res://game/tilemaps/map2/level_2.tscn"

const FIRST_PULSE_DELAY := 5.0
const PULSE_MIN_INTERVAL := 8.0
const PULSE_MAX_INTERVAL := 16.0
const PULSE_WARNING_TIME := 0.5
const JAM_MIN := 2.0
const JAM_MAX := 3.0

var time_left: float = 0.0
var running: bool = false
var finished: bool = false
var speed_multiplier: float = 1.0
var watchers: int = 0
var in_basement: bool = false
var _hud: Node = null
var _fx: Node = null

var _pulse_countdown: float = 0.0
var _pulse_warned: bool = false

func _ready() -> void:
	time_up.connect(_on_time_up)

func start(seconds: float) -> void:
	if running or finished: return
	time_left = seconds
	running = true
	speed_multiplier = 1.0
	watchers = 0
	_pulse_countdown = FIRST_PULSE_DELAY
	_pulse_warned = false
	
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	_fx = FX_SCRIPT.new()
	add_child(_fx)
	_fx.set_zone(in_basement)
	GameManager.lower_background_music(-26.0, 1.5)
	time_changed.emit(time_left)

func stop() -> void:
	running = false
	finished = true
	watchers = 0
	speed_multiplier = 1.0
	_free_hud()
	_free_fx()
	GameManager.restore_background_music(1.5)

func reset() -> void:
	stop()
	finished = false

func set_zone(basement: bool) -> void:
	in_basement = basement
	if _fx:
		_fx.set_zone(basement)

func _process(delta: float) -> void:
	if not running: return
	_tick(delta * speed_multiplier)
	_update_pulse(delta)

func _update_pulse(delta: float) -> void:
	_pulse_countdown -= delta
	if not _pulse_warned and _pulse_countdown <= PULSE_WARNING_TIME:
		_pulse_warned = true
		pulse_warning.emit()
	if _pulse_countdown <= 0.0:
		pulse_fired.emit(randf_range(JAM_MIN, JAM_MAX))
		_pulse_countdown = randf_range(PULSE_MIN_INTERVAL, PULSE_MAX_INTERVAL)
		_pulse_warned = false

func apply_penalty(seconds: float) -> void:
	if running:
		_tick(seconds)

func _tick(amount: float) -> void:
	time_left -= amount
	time_changed.emit(maxf(time_left, 0.0))
	if time_left <= 0.0:
		running = false
		finished = true
		time_up.emit()

func camera_started_seeing() -> void:
	watchers += 1
	_update_speed()

func camera_stopped_seeing() -> void:
	watchers = maxi(0, watchers - 1)
	_update_speed()

func _update_speed() -> void:
	speed_multiplier = 2.0 if watchers > 0 else 1.0

func _free_hud() -> void:
	if _hud:
		_hud.queue_free()
		_hud = null

func _free_fx() -> void:
	if _fx:
		_fx.queue_free()
		_fx = null

func _on_time_up() -> void:
	reset()
	GameManager.reset_basement()
	await CinematicsManager.play("final_malo", BAD_END_NEXT_SCENE)
