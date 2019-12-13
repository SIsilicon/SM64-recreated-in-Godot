extends AirState

var current_anim : String

func _enter() -> void:
	_mario.forward_velocity *= 0.8
	_mario.velocity.y = 52 + _mario.forward_velocity * 0.25
	
	_mario.play_anim("mario-double-jump-1")
	current_anim = "mario-double-jump-1"
	_mario.play_mario_sound(_mario.SOUND_WOOHOO)

func _update(delta : float):
	if Input.is_action_just_pressed("punch"):
		return kick_or_dive_in_air()
	if Input.is_action_just_pressed("crouch"):
		return "ground pound"
	
	if _mario.velocity.y > 0:
		if current_anim != "mario-double-jump-1":
			_mario.play_anim("mario-double-jump-1")
			current_anim = "mario-double-jump-1"
	else:
		if current_anim != "mario-double-jump-2":
			_mario.play_anim("mario-double-jump-2")
			current_anim = "mario-double-jump-2"
	
	action_in_air("mario-double-jump-land", AIR_CHECK_LEDGE_GRAB | AIR_CHECK_HANG | AIR_CHECK_FALL_DAMAGE | AIR_CHECK_WALL_KICK)

func get_flags() -> int:
	return ACT_FLAG_AIR | ACT_FLAG_CONTROL_JUMP_HEIGHT
