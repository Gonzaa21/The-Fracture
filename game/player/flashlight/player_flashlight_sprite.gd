extends Sprite2D

@export var hand_origin: Vector2 = Vector2(0, -6)
@export var hand_offset: float = 7.0
@export var behind_threshold: float = -0.35   # dir.y menor a esto = mira hacia arriba: va detrás del jugador

func _ready() -> void:
	hframes = 8
	visible = false

func _process(_delta: float) -> void:
	var on := Flashlight.active()
	visible = on
	if not on:
		return
	var dir := Flashlight.direction
	frame = wrapi(roundi(Flashlight.angle / (TAU / 8.0)), 0, 8)
	position = hand_origin + dir * hand_offset
	show_behind_parent = dir.y < behind_threshold
