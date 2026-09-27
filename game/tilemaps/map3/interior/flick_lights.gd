extends PointLight2D

@export var base_energy: float = 0.5
@export var flicker_min: float = 0.1
@export var flicker_max: float = 0.7
@export var min_interval: float = 0.05
@export var max_interval: float = 0.3
@export var flicker_chance: float = 0.7

var timer: Timer

func _ready():
	energy = base_energy
	enabled = false
	
	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	
	GameManager.lab_door_locked.connect(_on_generator_activated)
	
	if GameManager.lab_door_powered:
		_start_flicker()

func _on_generator_activated():
	_start_flicker()

func _start_flicker():
	enabled = true
	_schedule_next_flicker()

func _schedule_next_flicker():
	timer.start(randf_range(min_interval, max_interval))

func _on_timer_timeout():
	if randf() < flicker_chance:
		energy = randf_range(flicker_min, flicker_max)
	else:
		energy = base_energy
	_schedule_next_flicker()
