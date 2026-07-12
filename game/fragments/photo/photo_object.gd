extends Area2D
var player_nearby: bool = false
@onready var sprite: Sprite2D = $Sprite2D
@onready var icon = $CanvasLayer/TextureRect
var already_collected: bool = false
var collect_sound: AudioStream
var audio_player: AudioStreamPlayer
var fragment_id: String = "foto_clave"

func _ready() -> void:
	if GameManager.has_fragment(fragment_id):
		already_collected = true
	setup_audio()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		if !already_collected: icon.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		icon.visible = false

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		interact()

func setup_audio():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.volume_db = -8
	audio_player.bus = "SFX"
	collect_sound = load("res://assets/sound/effects/collect/paper_slide.mp3")

func interact():
	if already_collected: return
	var success = GameManager.collect_fragment(fragment_id)
	if success: 
		already_collected = true
		
		if collect_sound and audio_player:
			audio_player.stream = collect_sound
			audio_player.pitch_scale = randf_range(0.9, 1.05)
			audio_player.play()
		
		var photo_id = MorseManager.current_message["photo_id"]
		var texture = load("res://assets/photos/Picture%s.png" % photo_id)
		var key_code = GameManager.key_code
		sprite.modulate = Color(0, 0, 0, 0)
		var popup = get_tree().current_scene.get_node("FragmentPopupPhoto")
		if popup:
			popup.show_photo(texture, key_code)
