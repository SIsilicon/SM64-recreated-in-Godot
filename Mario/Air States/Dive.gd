extends AirState

func _enter() -> void:
	var forward_vel = min(_mario.forward_velocity + 15.0, 48.0)
	_mario.set_forward_velocity(forward_vel)
	
	_mario.play_anim("mario-dive")
	_mario.play_mario_sound(_mario.SOUND_WOOHOO)
	_mario.peak_height = _mario.translation.y

func _update(delta : float):
	update_air_without_turn()
	
	match perform_air_q_steps():
		AIR_STEP_NONE:
			if _mario.velocity.y < 0.0 and _mario.face_angle.x > -PI/3:
				_mario.face_angle.x -= 0.05
				_mario.face_angle.x = max(_mario.face_angle.x, -PI/3)
			_mario.rotation.x = -_mario.face_angle.x
		AIR_STEP_LANDED:
			_mario.face_angle.x = 0
			return check_fall_damage("sliding")
		AIR_STEP_HIT_WALL:
			_mario.bonk_reflection(false)
			_mario.face_angle.y = wrapf(_mario.face_angle.y + PI, -PI, PI)
			
			_mario.play_mario_sound(_mario.SOUND_DOH)
			_fsm.get_node_by_state("air knockback").dir = -1
			return "air knockback"

func _exit() -> void:
	_mario.rotation.x = 0
