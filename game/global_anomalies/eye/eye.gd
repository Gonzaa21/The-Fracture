class_name Eye
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

const FRAME_IDLE := 0
const FRAME_UPLEFT := 1
const FRAME_UP := 2
const FRAME_UPRIGHT := 3
const FRAME_RIGHT := 4
const FRAME_DOWNRIGHT := 5
const FRAME_DOWN := 6
const FRAME_DOWNLEFT := 7
const FRAME_LEFT := 8

func _ready() -> void:
	sprite.hframes = 9
	sprite.self_modulate.a = 0.9
	sprite.frame = FRAME_IDLE

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		sprite.frame = FRAME_IDLE
		return

	var dir = player.global_position - global_position
	sprite.frame = _get_direction_frame(dir)

func _get_direction_frame(dir: Vector2) -> int:
	if dir.length() < 1.0:
		return FRAME_IDLE
	
	var angle = dir.angle()
	var sector = posmod(int(round((angle + TAU / 16.0) / (TAU / 8.0))), 8)
	
	match sector:
		0: return FRAME_RIGHT
		1: return FRAME_DOWNRIGHT
		2: return FRAME_DOWN
		3: return FRAME_DOWNLEFT
		4: return FRAME_LEFT
		5: return FRAME_UPLEFT
		6: return FRAME_UP
		7: return FRAME_UPRIGHT
		_: return FRAME_IDLE
