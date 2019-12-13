extends AirState

func _enter() -> void:
	_mario.play_anim("mario-freefall")
	_mario.peak_height = _mario.translation.y

func _update(delta : float):
	if Input.is_action_just_pressed("punch"):
		return "dive"
	if Input.is_action_just_pressed("crouch"):
		return "ground pound"
	
	action_in_air("mario-freefall-land", AIR_CHECK_LEDGE_GRAB | AIR_CHECK_FALL_DAMAGE | AIR_CHECK_WALL_KICK)

func get_flags() -> int:
	return ACT_FLAG_AIR
