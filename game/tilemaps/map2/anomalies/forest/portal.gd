extends Area2D

enum PortalType {LEFT, RIGHT}

@export var portal_type: PortalType = PortalType.LEFT

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		set_deferred("monitoring", false)
		
		ForestManager.validate_choice(portal_type as ForestManager.EntrySide)
		
		await get_tree().create_timer(5).timeout
		monitoring = true
