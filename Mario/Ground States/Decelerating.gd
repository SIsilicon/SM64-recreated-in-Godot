extends GroundState

func _enter() -> void:
	_mario.play_anim("mario-walk")

func _update(delta : float):
	
	if _mario.intended_mag > 0:
		return "running"
	elif _mario.above_slide:
		return "sliding"
	elif Input.is_action_pressed("crouch"):
			return "crouch slide"
	elif Input.is_action_just_pressed("jump"):
		return set_jump_from_landing()
	
	if update_decelerating_speed():
		return "idle"
	
	match perform_ground_q_steps():
		GROUND_STEP_LEFT_GROUND:
			return "free falling"

func get_flags() -> int:
	return ACT_FLAG_MOVING | ACT_FLAG_ALLOW_FIRST_PERSON
