class_name Anomaly
extends Resource

enum Scope {
	GLOBAL,
	SINGLE,
	MULTIPLE
}

enum Target {
	ALL_TREES,
	ONE_TREE,
	PLAYER,
	NEW_ENTITY
}

enum Effect {
	SCALE,
	COLOR,
	POSITION_SHIFT,
	SPEED,
	SPRITE_SWAP,
	SPAWN_ENTITY
}

@export var scope: Scope
@export var target: Target  
@export var effect: Effect

@export var scale_value: Vector2 = Vector2.ONE
@export var color_value: Color = Color.WHITE
@export var position_offset: Vector2 = Vector2.ZERO
@export var speed_multiplier: float = 1.0
@export var entity_scene: PackedScene
