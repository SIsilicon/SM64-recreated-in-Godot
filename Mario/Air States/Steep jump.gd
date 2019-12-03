extends AirState

var steep_yaw : float

func _enter() -> void:
	_mario.forward_velocity *= 0.8
	_mario.velocity.y = 42 + _mario.forward_velocity * 0.25
	_mario.face_angle.x = -PI/2
	_mario.play_anim("mario-jump")
	_mario.play_mario_sound(_mario.SOUND_WA)

func _update(delta : float):
	if Input.is_action_just_pressed("punch"):
		return "dive"
	
	_mario.set_forward_velocity(_mario.forward_velocity * 0.98)
	
	match perform_air_q_steps(AIR_CHECK_LEDGE_GRAB):
		AIR_STEP_LANDED:
			_mario.face_angle.y = steep_yaw
			
			_mario.play_anim("mario-jump-land")
			return check_fall_damage("landing" if _mario.forward_velocity > 0.0 else "sliding")
			
		AIR_STEP_HIT_WALL:
			_mario.set_forward_velocity(0.0)
		AIR_STEP_GRABBED_LEDGE:
			return "ledge grab"
	
	_mario.rotation.y = steep_yaw