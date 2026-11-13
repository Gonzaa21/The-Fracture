extends Area2D

const WRONG_PENALTY: float = 20.0
const SPARK_OK := Color(1.0, 0.95, 0.5)
const SPARK_WRONG := Color(1.0, 0.3, 0.2)

@export_range(1, 4) var switch_id: int = 1
@export var label: Label
@export var ok_sound: AudioStream
@export var wrong_sound: AudioStream

var player_nearby: bool = false
var _feedback_active: bool = false
var _feedback_token: int = 0
var _sfx: AudioStreamPlayer

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "SFX"
	add_child(_sfx)
	if label:
		label.visible = false

func _process(_delta: float) -> void:
	if not player_nearby:
		return
	if label and not _feedback_active:
		label.text = _idle_text()
	if Input.is_action_just_pressed("interact"):
		_try_activate()

func _is_cut() -> bool:
	return switch_id in GameManager.switch_progress

func _try_activate() -> void:
	if _is_cut() or GameManager.emergency_disabled:
		return
	if not GameManager.is_cooling_active():
		_show_feedback("Sin refrigeracion")
		return
	
	var order: Array = GameManager.switch_order()
	var expected: int = order[GameManager.switch_progress.size()]
	
	if switch_id == expected:
		GameManager.switch_progress.append(switch_id)
		_play(ok_sound)
		if GameManager.switch_progress.size() == order.size():
			_show_feedback("Secuencia completa")
			GameManager.complete_basement_system("switches")
		else:
			_show_feedback("Interruptor %d: OK" % switch_id)
	else:
		GameManager.switch_progress.clear()
		_play(wrong_sound)
		AlarmManager.apply_penalty(WRONG_PENALTY)
		_show_feedback("Secuencia incorrecta")

func _idle_text() -> String:
	if _is_cut():
		return "Interruptor %d: cortado" % switch_id
	return "[E] Interruptor %d" % switch_id

func _show_feedback(text: String) -> void:
	if label == null:
		return
	_feedback_token += 1
	var token := _feedback_token
	_feedback_active = true
	label.text = text
	label.visible = true
	await get_tree().create_timer(1.5).timeout
	if token != _feedback_token or not is_inside_tree():
		return
	_feedback_active = false
	label.visible = player_nearby

func _play(stream: AudioStream) -> void:
	if stream == null or _sfx == null:
		return
	_sfx.stream = stream
	_sfx.play()

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if label:
			if not _feedback_active:
				label.text = _idle_text()
			label.visible = true

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if label and not _feedback_active:
			label.visible = false
