extends GroundState

func _enter() -> void:
	_mario.play_anim("mario-braking")
	_mario.start_slide_sound()

func _update(delta : float):
	apply_slope_decel(2)
	
	if should_begin_sliding():
		return "sliding"
	
	if _mario.forward_velocity < 1:
		return "idle"
	elif Input.is_action_just_pressed("jump"):
		return set_jump_from_landing()
	elif Input.is_action_pressed("analog"):
		if _mario.analog_held_back():
			return "turning"
		else:
			return "running"
	
	match perform_ground_q_steps():
		GROUND_STEP_LEFT_GROUND:
			return "free falling"

func _exit() -> void:
	_mario.stop_slide_sound()

func get_flags() -> int:
	return ACT_FLAG_MOVING | ACT_FLAG_ALLOW_FIRST_PERSON
