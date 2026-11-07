extends Area2D

signal player_glimpsed(seconds)
signal player_caught
signal vision_changed(sees: bool)
signal jam_started
signal jam_ended

@export var camera_sprite: Sprite2D
@export var vision_polygon: Polygon2D
@export var orientations: Array[float] = [-45.0, 0.0]
@export var frames: Array[int] = [1, 2]
@export var pause_time: float = 2.0
@export var start_delay: float = 0.0
@export var detect_limit: float = 1.0
@export_flags_2d_physics var los_mask: int = 4
@export var caught_cooldown: float = 3.0
@export var jam_range: float = 96.0
@export var jam_tint: Color = Color(1.0, 1.0, 1.0, 1.0)

const COLOR_IDLE := Color(0.2, 1.0, 0.3, 0.5)
const COLOR_WARN := Color(1.0, 0.9, 0.1, 0.5)
const COLOR_ALERT := Color(1.0, 0.1, 0.1, 0.6)

var player_inside: bool = false
var player_ref: CollisionObject2D = null
var seen_time: float = 0.0
var jammed: bool = false

var _idx: int = 0
var _patrol_timer: Timer
var _jam_token: int = 0

var sees_player: bool = false:
	set(value):
		if sees_player == value: return
		sees_player = value
		vision_changed.emit(sees_player)
		if sees_player:
			AlarmManager.camera_started_seeing()
		else:
			AlarmManager.camera_stopped_seeing()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	AlarmManager.pulse_fired.connect(_on_pulse_fired)
	_apply_orientation(0)
	update_color(0.0)
	_patrol_timer = Timer.new()
	_patrol_timer.wait_time = pause_time
	_patrol_timer.timeout.connect(_on_patrol_timeout)
	add_child(_patrol_timer)
	if start_delay > 0.0:
		await get_tree().create_timer(start_delay).timeout
	_patrol_timer.start()

func _exit_tree() -> void:
	if sees_player:
		AlarmManager.camera_stopped_seeing()

func _physics_process(delta: float) -> void:
	if jammed:
		return
	
	sees_player = player_inside and has_line_of_sight()
	_patrol_timer.paused = sees_player
	
	if sees_player:
		seen_time += delta
		update_color(seen_time / detect_limit)
		if seen_time >= detect_limit:
			player_caught.emit()
			set_physics_process(false)
			await get_tree().create_timer(caught_cooldown).timeout
			if is_inside_tree():
				reset()
			return
	elif seen_time > 0.0:
		player_glimpsed.emit(seen_time)
		seen_time = 0.0
		update_color(0.0)

func has_line_of_sight() -> bool:
	if player_ref == null:
		return false
	var dir := Vector2.RIGHT.rotated(global_rotation)
	var from := global_position + dir * 4.0
	var query := PhysicsRayQueryParameters2D.create(from, player_ref.global_position, los_mask)
	query.exclude = [player_ref.get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func update_color(ratio: float) -> void:
	if vision_polygon == null:
		return
	ratio = clampf(ratio, 0.0, 1.0)
	if ratio < 0.5:
		vision_polygon.color = COLOR_IDLE.lerp(COLOR_WARN, ratio * 2.0)
	else:
		vision_polygon.color = COLOR_WARN.lerp(COLOR_ALERT, (ratio - 0.5) * 2.0)

func reset() -> void:
	seen_time = 0.0
	update_color(0.0)
	set_physics_process(not jammed)

func _player_in_range() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	return global_position.distance_to(player.global_position) <= jam_range

func _on_pulse_fired(duration: float) -> void:
	if jammed or not _player_in_range():
		return
	jam(duration)

func jam(duration: float) -> void:
	jammed = true
	_jam_token += 1
	var token := _jam_token
	
	sees_player = false
	seen_time = 0.0
	update_color(0.0)
	_patrol_timer.paused = true
	if vision_polygon:
		vision_polygon.visible = false
	if camera_sprite:
		camera_sprite.modulate = jam_tint
	jam_started.emit()
	
	await get_tree().create_timer(duration).timeout
	if not is_inside_tree() or token != _jam_token:
		return
	unjam()

func unjam() -> void:
	jammed = false
	if vision_polygon:
		vision_polygon.visible = true
	if camera_sprite:
		camera_sprite.modulate = Color.WHITE
	_patrol_timer.paused = false
	set_physics_process(true)
	jam_ended.emit()

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		player_inside = true
		player_ref = body

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _on_patrol_timeout() -> void:
	_idx = (_idx + 1) % orientations.size()
	_apply_orientation(_idx)

func _apply_orientation(i: int) -> void:
	rotation_degrees = orientations[i]
	if camera_sprite:
		camera_sprite.frame = frames[i]
		camera_sprite.global_rotation = 0.0
