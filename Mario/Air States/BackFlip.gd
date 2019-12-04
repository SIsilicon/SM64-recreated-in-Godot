extends AirState

func _enter() -> void:
	_mario.forward_velocity = -16.0
	_mario.velocity.y = 62.0
	_mario.face_angle.y = _mario.intended_yaw
	_mario.play_anim("mario-backflip")
	_mario.play_mario_sound(_mario.SOUND_WA)

func _update(delta : float):
	return action_in_air("mario-landing-celebration", AIR_CHECK_FALL_DAMAGE)

func get_flags() -> int:
	return ACT_FLAG_AIR