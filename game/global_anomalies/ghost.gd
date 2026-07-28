extends Area2D
@onready var sprite = $Sprite2D

func _ready() -> void:
	$AnimationPlayer.play("ghost_idle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		set_deferred("monitoring", false)
		await vanish()
		queue_free()

func vanish():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
