extends Area2D
enum PopupStyle { WARNING, DOCUMENT, NOTES, DIALOGUE }

@export var fragment_id: String = ""
@export var popup_style: PopupStyle = PopupStyle.DOCUMENT 
@onready var sprite = $Sprite2D
@onready var icon = $CanvasLayer/TextureRect

var player_nearby: bool = false
var already_collected: bool = false

var collect_sound: AudioStream
var audio_player: AudioStreamPlayer

func _ready() -> void:
	if GameManager.has_fragment(fragment_id):
		already_collected = true
	setup_audio()

func setup_audio():
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.volume_db = -8
	audio_player.bus = "SFX"
	
	collect_sound = load("res://assets/sound/effects/collect/paper_slide.mp3")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		icon.visible = true
		

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		icon.visible = false

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact"):
		interact()

func interact():
	if already_collected: return
	
	var success = GameManager.collect_fragment(fragment_id)
	if success:
		already_collected = true
		sprite.modulate = Color(0, 0, 0, 0)
		
		if should_play_collect_sound():
			if collect_sound and audio_player:
				audio_player.stream = collect_sound
				audio_player.pitch_scale = randf_range(0.9, 1.05)
				audio_player.play()
		
		var popup_node_name = ""
		match popup_style:
			PopupStyle.WARNING:
				popup_node_name = "FragmentPopupWarn"
			PopupStyle.DOCUMENT:
				popup_node_name = "FragmentPopupDoc"
			PopupStyle.NOTES:
				popup_node_name = "FragmentPopupNotes"
			PopupStyle.DIALOGUE:
				var dialogue_popup = get_tree().current_scene.get_node_or_null("DialoguePopup")
				if dialogue_popup:
					dialogue_popup.show_fragment(fragment_id)
		
		var popup = get_tree().current_scene.get_node_or_null(popup_node_name)
		if popup:
			popup.show_fragment(fragment_id)
			print("¡Fragmento recolectado! ID: ", fragment_id)

func should_play_collect_sound() -> bool:
	return popup_style == PopupStyle.DOCUMENT or popup_style == PopupStyle.NOTES
