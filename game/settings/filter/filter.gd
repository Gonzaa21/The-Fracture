extends CanvasLayer

@export var base_brightness := 0.55
@export var base_outer_darkness := 0.45
@export var reacts_to_generator := false
@export var powered_brightness := 0.8
@export var powered_outer_darkness := 0.15

@onready var filter_particles: ColorRect = $FilterParticles

var t := 0.0
var _beam: float = 0.0
var shader_material: ShaderMaterial

func _ready() -> void:
	if has_node("FilterParticles"):
		shader_material = $FilterParticles.material
	_beam = 1.0 if Flashlight.active() else 0.0

	_apply_look(base_brightness, base_outer_darkness)

	if reacts_to_generator:
		if GameManager.generator_repaired:
			_apply_look(powered_brightness, powered_outer_darkness)
		else:
			GameManager.lab_door_locked.connect(_on_generator_fixed, CONNECT_ONE_SHOT)

func _apply_look(brightness: float, darkness: float) -> void:
	filter_particles.color = Color(brightness, brightness, brightness)
	if shader_material:
		shader_material.set_shader_parameter("outer_darkness", darkness)

func _on_generator_fixed() -> void:
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var c := Color(powered_brightness, powered_brightness, powered_brightness)
	tw.tween_property(filter_particles, "color", c, 2.0)
	if shader_material:
		tw.tween_property(shader_material, "shader_parameter/outer_darkness", powered_outer_darkness, 2.0)

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
