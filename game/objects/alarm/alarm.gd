extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D

enum State { OFF, LOCKED, OPEN }

const FRAME_OFF := 0
const FRAME_OPEN := 1
const FRAME_LOCKED := 2

func _ready():
	GameManager.lab_door_locked.connect(_on_lab_door_locked)
	GameManager.open_lab_door.connect(_on_lab_door_open)
	_refresh_state_from_gamemanager()

func _refresh_state_from_gamemanager():
	if GameManager.lab_door_is_open:
		_set_state(State.OPEN)
	elif GameManager.lab_door_powered:
		_set_state(State.LOCKED)
	else:
		_set_state(State.OFF)

func _on_lab_door_locked():
	_set_state(State.LOCKED)

func _on_lab_door_open():
	_set_state(State.OPEN)

func _set_state(state: State):
	match state:
		State.OFF:
			sprite.frame = FRAME_OFF
			light.enabled = false
		State.LOCKED:
			sprite.frame = FRAME_LOCKED
			light.color = Color.RED
			light.enabled = true
		State.OPEN:
			sprite.frame = FRAME_OPEN
			light.color = Color.GREEN
			light.enabled = true
