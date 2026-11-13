extends Area2D

const SYSTEM_ID := "cooling"

@export var label: Label
@export var fill_speed: float = 35.0
@export var drain_speed: float = 2.5
@export var overheat_penalty: float = 15.0
@export var pause_while_input_locked: bool = false

var player_nearby: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if label:
		label.visible = false

func _process(delta: float) -> void:
	if GameManager.emergency_disabled:
		return
	
	var level: float = GameManager.cooling_level
	var holding: bool = player_nearby and Input.is_action_pressed("interact")
	
	if holding:
		level += fill_speed * delta
	elif not (pause_while_input_locked and Global.input_locked):
		level -= drain_speed * delta
	level = clampf(level, 0.0, 100.0)
	GameManager.cooling_level = level
	
	var active: bool = GameManager.is_cooling_active()
	if not active and level >= 100.0:
		GameManager.set_basement_system(SYSTEM_ID, true)
	elif active and level <= 0.0:
		GameManager.set_basement_system(SYSTEM_ID, false)
		AlarmManager.apply_penalty(overheat_penalty)
	
	_update_label()

func _update_label() -> void:
	if label == null or not label.visible:
		return
	var filled := int(GameManager.cooling_level / 10.0)
	var bar := "█".repeat(filled) + "░".repeat(10 - filled)
	var state := "ACTIVA" if GameManager.is_cooling_active() else "APAGADA"
	label.text = "Refrigeracion: %s\n[%s] %d%%" % [state, bar, int(GameManager.cooling_level)]

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if label:
			label.visible = true
			_update_label()

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if label:
			label.visible = false
