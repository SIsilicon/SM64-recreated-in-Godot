extends GroundState

func _update(delta : float):
	if should_begin_sliding():
		return "sliding"
	
	if Input.is_action_just_pressed("jump"):
		return set_jumping_state("jump")
	
	if Input.is_action_just_pressed("punch"):
		return check_ground_dive_or_punch()
	
	if _mario.intended_mag == 0 and not Input.is_action_pressed("jump"):
		return "crouching"
	if not Input.is_action_pressed("crouch"):
		return "crouching"
	
	_mario.intended_mag *= 0.1
	
	update_walking_speed()
	
	match perform_ground_q_steps():
		GROUND_STEP_LEFT_GROUND:
			_fsm.change_state("free falling")
		GROUND_STEP_HIT_WALL:
			if _mario.forward_velocity > 10.0:
				_mario.set_forward_velocity(10.0)
		GROUND_STEP_NONE:
			pass
	
	var forward_vec : Vector3 = _mario.velocity * sign(_mario.forward_velocity)
	var right_vec := Vector3.UP.cross(forward_vec)
	_mario.look_at(_mario.translation + _mario.floor_surf.normal.cross(right_vec), Vector3.UP)
	_mario.anim_player.playback_speed = _mario.intended_mag * 2.0
	_mario.play_anim("mario-crawling")

func get_flags() -> int:
	return ACT_FLAG_MOVING | ACT_FLAG_SHORT_HITBOX | ACT_FLAG_ALLOW_FIRST_PERSON