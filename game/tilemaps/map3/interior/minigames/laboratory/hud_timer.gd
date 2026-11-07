extends CanvasLayer

@onready var label: Label = $Label

const COLOR_NORMAL := Color(1, 1, 1, 1)
const COLOR_LOW := Color(1.0, 0.2, 0.2, 1)

func _ready() -> void:
	_on_time_changed(AlarmManager.time_left)
	AlarmManager.time_changed.connect(_on_time_changed)

func _on_time_changed(t: float) -> void:
	var total := maxi(0, ceili(t))
	label.text = "%02d:%02d" % [floori(total / 60.0), total % 60]
	label.modulate = COLOR_LOW if t < 30.0 else COLOR_NORMAL
