extends Area2D

@export var label: Label
@export var pickup_sound: AudioStream

var player_nearby: bool = false

func _ready() -> void:
	if Flashlight.has_flashlight:
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if label:
		label.visible = false

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		set_process(false)
		Flashlight.acquire(pickup_sound)
		queue_free()

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if label:
			label.visible = true

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if label:
			label.visible = false
