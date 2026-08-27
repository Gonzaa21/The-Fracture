class_name GhostBehavior
extends Resource

enum Mode {
	IDLE_ONLY,
	RUN_PAST,
	FLASH,
	CHASE
}

@export var mode: Mode

@export var run_distance: float = 150.0
@export var detection_radius: float = 100.0

@export var run_speed: float = 80.0
@export var run_direction: Vector2 = Vector2.RIGHT

@export var flash_duration: float = 0.15

@export var chase_speed: float = 100.0
@export var chase_duration: float = 4.0 
