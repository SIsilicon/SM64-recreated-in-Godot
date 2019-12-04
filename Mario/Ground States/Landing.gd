extends GroundState

var _previous_state

var knockback : bool

func _init():
	action_timer = 4

func _enter() -> void:
	if _previous_state == "long jump" and _mario.intended_mag == 0:
		_mario.play_mario_sound(_mario.SOUND_UNGH)

func _update(delta : float):
	if _mario.anim_at_end():
		if _previous_state == "long jump":
			return "crouching"
		else:
			return "idle"
	
	if Input.is_action_just_pressed("punch"):
		return "punch"
	
	if action_timer != 0: # Still moving
		action_timer -= 1
		
		var next_state = landing_cancel()
		if next_state:
			return next_state
		
		if should_begin_sliding():
			return "sliding"
		
		if Input.is_action_pressed("analog"):
			apply_landing_accel(0.98)
		elif _mario.forward_velocity >= 16.0:
			apply_slope_decel(2.0)
		else:
			_mario.velocity.y = 0
		
		match perform_ground_q_steps():
			GROUND_STEP_LEFT_GROUND:
				_mario.velocity.y = 0
				if knockback:
					return "air knockback"
				else:
					return "free falling"
	
	else: # Not moving
		
		if Input.is_action_just_pressed("jump"):
			if _previous_state == "long jump":
				return set_jumping_state("jump")
			else:
				return set_jump_from_landing()
		
		if _mario.intended_mag != 0:
			return "running"
		elif _mario.off_floor:
			_mario.off_floor = false
			return "free falling"
		elif _mario.above_slide:
			return "sliding"
		
		_mario.set_forward_velocity(0)
		_mario.translation.y = _mario.floor_height

func _exit():
	knockback = false
	action_timer = 4

func landing_cancel():
	if _mario.floor_surf.normal.y < 0.2923717:
		return "free falling"
	
	if should_begin_sliding():
		return "sliding"
	
#	var debug_blj = _mario.forward_velocity < 0 and _previous_state == "long jump"
#	debug_blj = debug_blj and (_mario.translation.x > -327.68 and _mario.translation.x < 327.67 ||\
#				_mario.translation.z > -327.68 and _mario.translation.z < 327.67)
	
	if Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("crouch"):
			if _previous_state == "long jump":
				return set_jumping_state("long jump")
			elif _previous_state == "backflip":
				return set_jumping_state("backflip")
		return set_jump_from_landing()
	
	if _mario.off_floor:
		return "free falling"

func get_flags():
	var flags := 0
	
	match _previous_state:
		"backflip":
			flags |= ACT_FLAG_PAUSE_EXIT
		"triple jump":
			flags |= ACT_FLAG_PAUSE_EXIT
		"long jump":
			flags |= ACT_FLAG_PAUSE_EXIT
		_:
			flags |= ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT
	
	if action_timer == 0: # stopped
		flags |= ACT_FLAG_STATIONARY
	else:
		flags |= ACT_FLAG_MOVING
	
	return flags
