extends AirState

var fast_longjump := false

func _enter() -> void:
	_mario.velocity.y = 30.0
	fast_longjump = _mario.forward_velocity > 16.0
	
	_mario.forward_velocity *= 1.5
	if _mario.forward_velocity > 48.0:
		_mario.forward_velocity = 48.0
	
	_mario.play_anim("mario-fast-longjump" if fast_longjump else "mario-slow-longjump")
	_mario.play_mario_sound(_mario.SOUND_YAHOO)

func _update(delta : float):
	action_in_air("mario-fast-longjump-land" if fast_longjump else "mario-slow-longjump-land", AIR_CHECK_LEDGE_GRAB | AIR_CHECK_FALL_DAMAGE | AIR_CHECK_WALL_KICK)

func get_flags() -> int:
	return ACT_FLAG_AIR
