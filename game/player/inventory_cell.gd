extends CanvasLayer

@onready var visuals = $Visuals
@onready var cell_bg = $Visuals/CellBackground
@onready var item_icon = $Visuals/ItemIcon
@onready var sound = $Visuals/Sound
@export var icon_offset := Vector2(0, -12)
var current_icon: Texture2D = null

const TARGET_ICON_SIZE := 6.0

@onready var player = get_parent() as Node2D

func _ready() -> void:
	visuals.modulate.a = 0
	visible = false

func _process(_delta: float) -> void:
	if player and is_instance_valid(player):
		var canvas_transform = get_viewport().canvas_transform
		visuals.global_position = canvas_transform * (player.global_position + icon_offset)

func show_item(icon: Texture2D):
	_show_item_internal(icon, true)

func show_item_silent(icon: Texture2D):
	_show_item_internal(icon, false)

func _show_item_internal(icon: Texture2D, play_sound: bool):
	current_icon = icon
	item_icon.texture = icon
	_normalize_icon_scale(icon)
	visible = true
	
	if play_sound and sound:
		sound.play()
	
	fade_in()

func _normalize_icon_scale(icon: Texture2D):
	if icon == null:
		return
	var tex_size = icon.get_size()
	var max_dimension = max(tex_size.x, tex_size.y)
	if max_dimension > 0:
		var scale_factor = TARGET_ICON_SIZE / max_dimension
		item_icon.scale = Vector2(scale_factor, scale_factor)

func fade_in():
	var tween = create_tween()
	tween.tween_property(visuals, "modulate:a", 1.0, 0.5)

func remove_item():
	if sound: sound.play()
	fade_out()
	current_icon = null

func fade_out():
	var tween = create_tween()
	tween.tween_property(visuals, "modulate:a", 0.0, 0.5)
	await tween.finished
	visible = false
	item_icon.texture = null

func has_item(): return current_icon != null
