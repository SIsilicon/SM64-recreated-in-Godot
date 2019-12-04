extends GroundState

func _enter() -> void:
	action_timer = 0
	_mario.play_anim("mario-start-crouch")

func _update(delta : float):
	if _mario.above_slide:
		return "sliding"
	
	if action_timer < 30:
		action_timer += 1
		if Input.is_action_just_pressed("jump") and _mario.forward_velocity > 10.0:
			return set_jumping_state("long jump")
	
	if Input.is_action_just_pressed("jump"):
		return set_jumping_state("jump")
	
	if _mario.anim_at_end():
		_mario.play_anim("mario-crouch")
	
	return common_sliding_movement_with_jump("crouching", "jump")

func _exit() -> void:
	_mario.rotation.x = 0
	_mario.rotation.z = 0

func get_flags() -> int:
	return ACT_FLAG_MOVING | ACT_FLAG_SHORT_HITBOX | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_FIRST_PERSON
