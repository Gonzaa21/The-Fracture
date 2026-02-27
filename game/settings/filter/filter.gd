extends CanvasLayer

var t := 0.0

func _ready() -> void:
	pass

# execute filter
func _process(delta):
	t += delta
	if has_node("FilterParticles"):
		$FilterParticles.material.set_shader_parameter("time", t)
