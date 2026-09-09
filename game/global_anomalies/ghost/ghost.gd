class_name Ghost
extends Area2D

signal player_caught

enum GhostState { IDLE, ACTIVE, GONE }

@export var behavior: GhostBehavior

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var proximity: Area2D = $ProximityDetector

var detection_sfx: Array[AudioStream] = [
	preload("res://assets/sound/horror/jumpscare1.mp3"),
	preload("res://assets/sound/horror/jumpscare2.mp3"),
	preload("res://assets/sound/horror/jumpscare3.mp3"),
	preload("res://assets/sound/horror/jumpscare4.mp3")
]
var last_sfx_index: int = -1

var state: GhostState = GhostState.IDLE
var run_start_position: Vector2
var chase_elapsed: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	ForestManager.player_crossed_portal.connect(_on_portal_crossed)
	
	if behavior.mode == GhostBehavior.Mode.FLASH:
		modulate.a = 0.0
	else:
		anim.play("ghost_idle")
	
	if behavior.mode == GhostBehavior.Mode.IDLE_ONLY:
		return
	
	_setup_proximity()

func _setup_proximity() -> void:
	var shape: CircleShape2D = proximity.get_node("CollisionShape2D").shape
	shape.radius = behavior.detection_radius
	proximity.body_entered.connect(_on_proximity_entered)

func _on_proximity_entered(body: Node2D) -> void:
	if state != GhostState.IDLE or not body.is_in_group("player"):
		return
	proximity.set_deferred("monitoring", false)
	_play_detection_sfx()

	match behavior.mode:
		GhostBehavior.Mode.RUN_PAST:
			state = GhostState.ACTIVE
			anim.play("ghost_run")
			run_start_position = global_position
		GhostBehavior.Mode.FLASH:
			anim.play("ghost_idle")
			modulate.a = 1.0
			await get_tree().create_timer(behavior.flash_duration).timeout
			await vanish()
			queue_free()
		GhostBehavior.Mode.CHASE:
			state = GhostState.ACTIVE
			anim.play("ghost_run")
			chase_elapsed = 0.0

func _play_detection_sfx() -> void:
	if detection_sfx.is_empty():
		return
	
	var random_index: int = randi() % detection_sfx.size()
	if detection_sfx.size() > 1:
		while random_index == last_sfx_index:
			random_index = randi() % detection_sfx.size()
	
	last_sfx_index = random_index
	
	var player := AudioStreamPlayer2D.new()
	get_tree().current_scene.add_child(player)
	player.stream = detection_sfx[random_index]
	player.global_position = global_position
	player.bus = "SFX"
	player.play()
	player.finished.connect(player.queue_free)

func _physics_process(delta: float) -> void:
	if state != GhostState.ACTIVE:
		return

	match behavior.mode:
		GhostBehavior.Mode.RUN_PAST:
			global_position += behavior.run_direction.normalized() * behavior.run_speed * delta
			if global_position.distance_to(run_start_position) > behavior.run_distance:
				_go_gone()
		GhostBehavior.Mode.CHASE:
			chase_elapsed += delta
			var player := get_tree().get_first_node_in_group("player")
			if player:
				var to_player = (player.global_position - global_position).normalized()
				global_position += to_player * behavior.chase_speed * delta
			if chase_elapsed >= behavior.chase_duration:
				_go_gone()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or state == GhostState.GONE:
		return

	if behavior.mode == GhostBehavior.Mode.CHASE and state == GhostState.ACTIVE:
		state = GhostState.GONE
		set_deferred("monitoring", false)
		player_caught.emit()
		queue_free()
		return

	_go_gone()

func _on_portal_crossed() -> void:
	_go_gone()

func _go_gone() -> void:
	if state == GhostState.GONE:
		return
	state = GhostState.GONE
	set_deferred("monitoring", false)
	await vanish()
	queue_free()

func vanish() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
