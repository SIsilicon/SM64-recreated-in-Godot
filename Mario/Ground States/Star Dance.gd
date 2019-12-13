extends StationaryState

func _enter() -> void:
	_mario.play_anim("mario-star-dance")
	_mario.star.get_node("AnimationPlayer").play("star dance")
	_mario.rotation.y = Global.camera.rotation.y

func _update(delta : float):
	_mario.star.translation = _mario.translation
	_mario.star.rotation = _mario.rotation
	
	stationary_ground_step()

func get_flags() -> int:
	return ACT_FLAG_STATIONARY | ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE