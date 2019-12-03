extends GroundState

func _enter() -> void:
	_mario.play_anim("mario-turning")

func _update(delta : float):
	if Input.is_action_just_pressed("jump"):
		return set_jumping_state("sideflip")
	
	update_walking_speed()
	
	if perform_ground_q_steps() == GROUND_STEP_LEFT_GROUND:
		return "free falling"
	
	if _mario.anim_at_end():
		return "running"
	
	_mario.rotation.y = _mario.face_angle.y + PI
