extends Control

@onready var cell_bg = $CellBackground
@onready var item_icon = $ItemIcon
@onready var sound = $Sound
var current_icon: Texture2D = null

const TARGET_ICON_SIZE := 6.0

func _ready() -> void:
	modulate.a = 0
	visible = false

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
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func remove_item():
	if sound: sound.play()
	fade_out()
	current_icon = null

func fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	visible = false
	cell_bg.texture = null
	item_icon.texture = null

func has_item(): return current_icon != null
