extends CharacterBody2D
@onready var animated_sprite = $AnimatedSprite2D
@onready var inventory_cell = $InventoryCell

# config
var speed_walk = 50.0;
var speed_run = 70.0;
var default_direction = "up";
#audio
var footstep_sounds: Array[AudioStream] = []
var footstep_player: AudioStreamPlayer2D
var footstep_timer: float = 0.0
var footstep_interval: float = 0.3

func _ready() -> void:
	setup_footstep_audio()
	if GameManager.current_inventory_icon:
		inventory_cell.show_item_silent(GameManager.current_inventory_icon)

func _physics_process(delta: float) -> void:
	if Global.input_locked:
		velocity = Vector2.ZERO
		update_animation("idle")
		return
		
	get_input()
	move_and_slide()
	
	# audio
	var is_moving = velocity.length() > 0
	var is_running = Input.is_action_pressed("run")
	
	if is_moving:
		play_footsteps(delta, is_running)
	else:
		footstep_timer = 0.0

# get direction
func get_input():
	var direction = Input.get_vector("left", "right", "up", "down")

	# IDLE
	if direction == Vector2.ZERO:
		velocity = Vector2.ZERO
		update_animation("idle")
		return

	# DIRECTION
	var x = abs(direction.x)
	var y = abs(direction.y)
	if x > y * 0.8:
		default_direction = "right" if direction.x > 0 else "left"
	elif y > x * 0.8:
		default_direction = "down" if direction.y > 0 else "up"

	# VELOCITY run/walk
	if Input.is_action_pressed("run"):
		velocity = direction * speed_run
		update_animation("run")
	else:
		velocity = direction * speed_walk
		update_animation("walk")


# update and play animation
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

# inventory cell
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
