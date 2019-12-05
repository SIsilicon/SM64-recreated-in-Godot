extends AirState

var attack_window_open : bool

func _enter() -> void:
	action_timer = 0
	attack_window_open = true
	
	_mario.play_anim("mario-air-kick")
	_mario.play_mario_sound(_mario.SOUND_HOO)
	_mario.velocity.y = 20.0

func _update(delta : float):
	update_air_without_turn()
	
	if action_timer < 5:
		action_timer += 1
	else:
		attack_window_open = false
	
	match perform_air_q_steps():
		AIR_STEP_LANDED:
			_mario.play_anim("mario-freefall-land")
			return check_fall_damage("landing")
		AIR_STEP_HIT_WALL:
			_mario.set_forward_velocity(0.0)

func get_flags() -> int:
	return ACT_FLAG_AIR | ACT_FLAG_ATTACKING