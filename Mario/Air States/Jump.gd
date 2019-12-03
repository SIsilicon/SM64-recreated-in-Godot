extends AirState

func _enter() -> void:
	_mario.forward_velocity *= 0.8
	_mario.velocity.y = 42 + _mario.forward_velocity * 0.25
	_mario.play_anim("mario-jump")
	
	match randi() % 3:
		0: _mario.play_mario_sound(_mario.SOUND_WA)
		1: _mario.play_mario_sound(_mario.SOUND_WOO)
		2: _mario.play_mario_sound(_mario.SOUND_YA)


func _update(delta : float):
	if Input.is_action_just_pressed("punch"):
		return kick_or_dive_in_air()
	
	return action_in_air("mario-jump-land", AIR_CHECK_LEDGE_GRAB | AIR_CHECK_FALL_DAMAGE | AIR_CHECK_WALL_KICK)