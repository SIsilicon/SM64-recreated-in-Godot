extends AirState

var wall_kick_timer := 0

func _enter() -> void:
	_mario.play_anim("mario-freefall")
	_mario.play_mario_sound(_mario.SOUND_UGH)
	_mario.peak_height = _mario.translation.y

func _update(delta : float):
	if wall_kick_timer != 0:
		wall_kick_timer -= 1
		if Input.is_action_just_pressed("jump"):
			_mario.set_forward_velocity(-_mario.forward_velocity)
			return "wall kick"
	
	return action_knockback(0, _mario.forward_velocity)

func _exit() -> void:
	wall_kick_timer = 0

func get_flags() -> int:
	return ACT_FLAG_AIR