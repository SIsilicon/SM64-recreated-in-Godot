extends AirState

func _enter() -> void:
	_mario.play_anim("mario-air-kick")
	_mario.play_mario_sound(_mario.SOUND_HOO)
	_mario.velocity.y = 20.0

func _update(delta : float):
	update_air_without_turn()
	
	match perform_air_q_steps():
		AIR_STEP_LANDED:
			_mario.play_anim("mario-freefall-land")
			return check_fall_damage("landing")
		AIR_STEP_HIT_WALL:
			_mario.set_forward_velocity(0.0)