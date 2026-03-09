extends CanvasLayer

var t := 0.0
var shader_material: ShaderMaterial

func _ready() -> void:
	if has_node("FilterParticles"):
		shader_material = $FilterParticles.material

func _process(delta):
	t += delta
	
	if not shader_material:
		return
	
	shader_material.set_shader_parameter("time", t)
	
	_update_player_position()

func _update_player_position():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var viewport = get_viewport()
	var viewport_rect = viewport.get_visible_rect()
	var camera = viewport.get_camera_2d()
	
	if not camera:
		print("No hay cámara")
		return
	
	var canvas_transform = camera.get_canvas_transform()
	var player_screen_pos = canvas_transform * player.global_position
	
	var normalized_pos = Vector2(
		player_screen_pos.x / viewport_rect.size.x,
		player_screen_pos.y / viewport_rect.size.y
	)
	
	shader_material.set_shader_parameter("player_position", normalized_pos)
