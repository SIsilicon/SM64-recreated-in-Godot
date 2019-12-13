extends AirState

var wall_kicked : bool
var wall_kick_timer : int

func _enter() -> void:
	wall_kicked = false
	wall_kick_timer = 2
	_mario.peak_height = _mario.translation.y

func _update(delta : float):
	if not wall_kicked:
		if Input.is_action_just_pressed("jump"):
			wall_kicked = true
			_mario.velocity.y = 52.0
			_mario.face_angle.y += PI
			_mario.rotation.y = _mario.face_angle.y
			_mario.play_anim("mario-wallkick")
			_mario.play_mario_sound(_mario.SOUND_WA)
		elif wall_kick_timer == 0:
			if _mario.forward_velocity >= 38.0:
				_mario.rotation.y += PI
				_mario.velocity.y = min(_mario.velocity.y, 0.0)
				_fsm.get_node_by_state("air knockback").wall_kick_timer = 4
				_fsm.get_node_by_state("air knockback").dir = -1
				_mario.play_mario_sound(_mario.SOUND_DOH)
				return "air knockback"
			else:
				_mario.velocity.y = min(_mario.velocity.y, 0.0)
				if _mario.forward_velocity > 8.0:
					_mario.set_forward_velocity(-8.0)
				_fsm.get_node_by_state("soft bonk").wall_kick_timer = 4
				return "soft bonk"
		else:
			wall_kick_timer -= 1
	
	if wall_kicked:
		if Input.is_action_just_pressed("punch"):
			return "dive"
		if Input.is_action_just_pressed("crouch"):
			return "ground pound"
		
		action_in_air("mario-freefall-land", AIR_CHECK_LEDGE_GRAB | AIR_CHECK_FALL_DAMAGE | AIR_CHECK_WALL_KICK)
		if _fsm.next_state_manual == "wall kick":
			_enter()
	else:
		_mario.play_anim("mario-pre-wallkick")

func get_flags() -> int:
	return ACT_FLAG_AIR | ACT_FLAG_CONTROL_JUMP_HEIGHT
