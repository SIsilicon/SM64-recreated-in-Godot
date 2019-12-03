extends AirState

func _enter() -> void:
	_mario.play_anim("mario-freefall")
	_mario.peak_height = _mario.translation.y

func _update(delta : float):
	if Input.is_action_just_pressed("punch"):
		return "dive"
	
	return action_in_air("mario-freefall-land", AIR_CHECK_LEDGE_GRAB | AIR_CHECK_FALL_DAMAGE | AIR_CHECK_WALL_KICK)
