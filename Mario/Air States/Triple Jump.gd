extends AirState

func _enter() -> void:
	_mario.forward_velocity *= 0.8
	_mario.velocity.y = 69 + _mario.forward_velocity * 0.25
	_mario.play_anim("mario-triple-jump")
	
	match randi() % 2:
		0: _mario.play_mario_sound(_mario.SOUND_YAHOO)
		1: _mario.play_mario_sound(_mario.SOUND_WAHA)

func _update(delta : float):
	if Input.is_action_just_pressed("punch"):
		return "dive"
	if Input.is_action_just_pressed("crouch"):
		return "ground pound"
	
	action_in_air("mario-landing-celebration", AIR_CHECK_FALL_DAMAGE)

func get_flags() -> int:
	return ACT_FLAG_AIR
