extends CharacterBody2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var inventory_cell = $InventoryCell
@onready var use_prompt: Label = $UsePrompt

var speed_walk = 50.0;
var speed_run = 70.0;
var default_direction = "up";

var footstep_sounds: Array[AudioStream] = []
var footstep_player: AudioStreamPlayer2D
var footstep_timer: float = 0.0
var footstep_interval: float = 0.3
var idle_frames: int = 0

func _ready() -> void:
	setup_footstep_audio()
	if GameManager.current_inventory_icon:
		inventory_cell.show_item_silent(GameManager.current_inventory_icon)
	use_prompt.visible = false

func _process(_delta: float) -> void:
	var show_prompt = GameManager.current_item_id == "instructor" and not GameManager.level2_unlocked
	use_prompt.visible = show_prompt
	if show_prompt and Input.is_action_just_pressed("interact"):
		_use_instructor()

func _use_instructor():
	GameManager.unlock_level2()
	use_item()

func _physics_process(delta: float) -> void:
	if Global.input_locked:
		velocity = Vector2.ZERO
		update_animation("idle")
		return
		
	get_input()
	
	var pos_before = global_position
	
	move_and_slide()
	
	var distance_moved = global_position.distance_to(pos_before)
	var is_trying_to_move = velocity.length() > 0
	var is_actually_moving = is_trying_to_move and (distance_moved > 0.02)
	
	var is_running = Input.is_action_pressed("run")
	
	if is_actually_moving:
		idle_frames = 0
		if is_running:
			update_animation("run")
		else:
			update_animation("walk")
		play_footsteps(delta, is_running)
	else:
		idle_frames += 1
		if idle_frames >= 4 or not is_trying_to_move:
			update_animation("idle")
			footstep_timer = 0.0

func get_input():
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		return
	
	var x = abs(direction.x)
	var y = abs(direction.y)
	if x > y * 0.8:
		default_direction = "right" if direction.x > 0 else "left"
	elif y > x * 0.8:
		default_direction = "down" if direction.y > 0 else "up"
	
	if Input.is_action_pressed("run"):
		velocity = direction * speed_run
	else:
		velocity = direction * speed_walk


func update_animation(state):
	animated_sprite.play(state + "_" + default_direction)

func setup_footstep_audio():
	footstep_player = AudioStreamPlayer2D.new()
	add_child(footstep_player)
	footstep_player.volume_db = 0
	footstep_player.bus = "SFX"

	var sound = load("res://assets/sound/effects/walk.wav")
	if sound: footstep_sounds.append(sound)
	
func play_footsteps(delta: float, is_running: bool):
	var current_interval = footstep_interval
	if is_running:
		current_interval = footstep_interval * 0.8
	
	footstep_timer += delta
	
	if footstep_timer >= current_interval:
		footstep_timer = 0.0
		if footstep_sounds.size() > 0:
			var random_index = randi() % footstep_sounds.size()
			footstep_player.stream = footstep_sounds[random_index]
			footstep_player.volume_db = 5
			footstep_player.pitch_scale = randf_range(0.9, 1.1)
			footstep_player.play()

func add_inventory(item_icon: Texture2D):
	if inventory_cell.has_item():
		return false
	inventory_cell.show_item(item_icon)
	return true

func use_item():
	if inventory_cell.has_item():
		inventory_cell.remove_item()
		GameManager.current_inventory_icon = null
		return true
	return false
