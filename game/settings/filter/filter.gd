extends CanvasLayer

var t := 0.0
var shader_material: ShaderMaterial
var _beam: float = 0.0

@export var vision_circle: bool = true

func _ready() -> void:
	if has_node("FilterParticles"):
		shader_material = $FilterParticles.material
	_beam = 1.0 if Flashlight.active() else 0.0
	shader_material.set_shader_parameter("use_vision_circle", vision_circle)

func _process(delta: float) -> void:
	t += delta
	if not shader_material:
		return
	
	shader_material.set_shader_parameter("time", t)
	_update_player_position()
	_update_flashlight(delta)

func _update_flashlight(delta: float) -> void:
	
	var target_beam := 1.0 if Flashlight.active() else 0.0
	_beam = lerpf(_beam, target_beam, 1.0 - exp(-10.0 * delta))
	
	shader_material.set_shader_parameter("flashlight_enabled", _beam)
	shader_material.set_shader_parameter("flashlight_dir", Flashlight.direction)

func _update_player_position() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var viewport = get_viewport()
	var viewport_rect = viewport.get_visible_rect()
	var camera = viewport.get_camera_2d()
	if not camera:
		return
	
	var canvas_transform = camera.get_canvas_transform()
	var player_screen_pos = canvas_transform * player.global_position
	
	var normalized_pos = Vector2(
		player_screen_pos.x / viewport_rect.size.x,
		player_screen_pos.y / viewport_rect.size.y
	)
	
	shader_material.set_shader_parameter("player_position", normalized_pos)
