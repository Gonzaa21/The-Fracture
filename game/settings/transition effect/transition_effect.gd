extends CanvasLayer

@onready var rect: ColorRect = $Control/ColorRect

var fade_time := 0.6
var is_transitioning := false

func _ready():
	rect.visible = false
	rect.color.a = 0.0

func fade_to_scene(scene_path: String):
	if is_transitioning:
		return

	is_transitioning = true
	Global.input_locked = true

	rect.visible = true
	rect.color.a = 0.0

	var tween := create_tween()
	tween.tween_property(rect, "color:a", 1.0, fade_time)

	tween.finished.connect(func():
		get_tree().change_scene_to_file(scene_path)
		await get_tree().process_frame

		var tween_in := create_tween()
		tween_in.tween_property(rect, "color:a", 0.0, fade_time)
		tween_in.finished.connect(func():
			rect.visible = false
			Global.input_locked = false
			is_transitioning = false
		)
	)

func fade_in_place(callback: Callable):
	if is_transitioning:
		return
	
	is_transitioning = true
	Global.input_locked = true
	
	rect.visible = true
	rect.color.a = 0.0
	
	var tween_out := create_tween()
	tween_out.tween_property(rect, "color:a", 1.0, fade_time)
	
	tween_out.finished.connect(func():
		callback.call()
		
		await get_tree().process_frame
		
		var tween_in := create_tween()
		tween_in.tween_property(rect, "color:a", 0.0, fade_time)
		
		tween_in.finished.connect(func():
			rect.visible = false
			Global.input_locked = false
			is_transitioning = false
		)
)
