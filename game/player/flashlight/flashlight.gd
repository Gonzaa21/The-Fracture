extends Node

signal acquired
signal toggled(is_on: bool)

enum AimMode { MOUSE, ARROWS }

const TOGGLE_ACTION := "flashlight"
const TURN_SPEED := 14.0
const MIN_MOUSE_DISTANCE := 6.0
const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")

var aim_mode: AimMode = AimMode.MOUSE
var has_flashlight: bool = false
var is_on: bool = true
var angle: float = 0.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	if not InputMap.has_action(TOGGLE_ACTION):
		InputMap.add_action(TOGGLE_ACTION)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_F
		InputMap.action_add_event(TOGGLE_ACTION, ev)

func active() -> bool:
	return has_flashlight and is_on

func acquire(sound: AudioStream = null) -> void:
	if has_flashlight:
		return
	has_flashlight = true
	is_on = true
	_play(sound)
	_show_hint()
	acquired.emit()

func set_on(value: bool) -> void:
	if is_on == value:
		return
	is_on = value
	toggled.emit(is_on)

func _process(delta: float) -> void:
	if not has_flashlight or Global.input_locked:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	if Input.is_action_just_pressed(TOGGLE_ACTION):
		set_on(not is_on)
	
	var aim := _aim_vector(player)
	if aim != Vector2.ZERO:
		angle = lerp_angle(angle, aim.angle(), 1.0 - exp(-TURN_SPEED * delta))
		direction = Vector2.from_angle(angle)

func _aim_vector(player: Node2D) -> Vector2:
	if aim_mode == AimMode.MOUSE:
		var v := player.get_global_mouse_position() - player.global_position
		return v if v.length() > MIN_MOUSE_DISTANCE else Vector2.ZERO
	
	var v := Vector2(
		int(Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_LEFT)),
		int(Input.is_key_pressed(KEY_DOWN)) - int(Input.is_key_pressed(KEY_UP))
	)
	return v.normalized()

func _play(sound: AudioStream) -> void:
	if sound == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = sound
	p.bus = "SFX"
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _show_hint() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	
	var l := Label.new()
	var how := "mouse: apuntar" if aim_mode == AimMode.MOUSE else "flechas: apuntar"
	l.text = "[F] linterna   " + how
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	l.offset_top = -24.0
	l.offset_bottom = -10.0
	layer.add_child(l)
	
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(layer.queue_free)
