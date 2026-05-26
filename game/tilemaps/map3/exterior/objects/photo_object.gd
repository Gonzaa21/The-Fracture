extends Area2D
var player_nearby: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func _process(_delta: float) -> void:
	if player_nearby and Input.is_action_just_pressed("interact"):
		interact()

func interact():
	var photo_id = MorseManager.current_message["photo_id"]
	var texture = load("res://assets/photos/Picture%s.png" % photo_id)
	var key_code = GameManager.key_code
	
	var popup = get_tree().current_scene.get_node("FragmentPopupPhoto")
	if popup:
		popup.show_photo(texture, key_code)
