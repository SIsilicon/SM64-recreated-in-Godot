extends Entity

func get_wall_collide_radius() -> float:
	return $CollisionShape.shape.radius