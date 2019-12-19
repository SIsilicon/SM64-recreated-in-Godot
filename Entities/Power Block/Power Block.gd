extends StaticBody

func _on_Area_body_entered(body) -> void:
	if body is Mario:
		if body.is_attacking(translation):
			explode()
		elif body.velocity.y > 0 and body.translation.y < translation.y:
			explode()
			body.velocity.y = 0

func explode() -> void:
	hide()
	$CollisionShape.disabled = true
	$Area.queue_free()
	$BoxBreakSound.play()