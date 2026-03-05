extends Area2D

enum PortalType {LEFT, RIGHT}

@export var portal_type: PortalType = PortalType.LEFT

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		var back = (portal_type == PortalType.LEFT)
		ForestManager.validate_choice(back)
