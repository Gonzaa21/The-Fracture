extends Control

@onready var cell_bg = $CellBackground
@onready var item_icon = $ItemIcon
@onready var sound = $Sound

var current_icon: Texture2D = null

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
	visible = true
	
	if play_sound and sound:
		sound.play()
	
	fade_in()

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
