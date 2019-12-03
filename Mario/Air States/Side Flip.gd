extends AirState

func _enter() -> void:
	_mario.forward_velocity = 8.0
	_mario.velocity.y = 62.0
	_mario.face_angle.y = _mario.intended_yaw
	_mario.rotation.y = _mario.face_angle.y + PI
	_mario.play_anim("mario-sideflip")
	_mario.play_mario_sound(_mario.SOUND_WOO)

func _update(delta : float):
	if Input.is_action_just_pressed("punch"):
		return "dive"
	
	return action_in_air("mario-freefall-land", AIR_CHECK_LEDGE_GRAB | AIR_CHECK_FALL_DAMAGE | AIR_CHECK_WALL_KICK)

func _exit():
	_mario.rotation.y += PI