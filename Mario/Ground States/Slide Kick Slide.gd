extends GroundState

func _enter() -> void:
	_mario.start_slide_sound()

func _update(delta : float):
	if Input.is_action_just_pressed("jump"):
		return "rollout"
	
	if _mario.forward_velocity < 1.0:
		_mario.play_anim("mario-stop-slide-kick")
		return "crouching"
	
	update_sliding(1.0)
	match perform_ground_q_steps():
		GROUND_STEP_LEFT_GROUND:
			_fsm.change_state("free falling")
		GROUND_STEP_HIT_WALL:
			_mario.bonk_reflection(true)
			_fsm.get_node_by_state("ground knockback").knockback_strength = -2
			_fsm.change_state("ground knockback")
	
#    m->particleFlags |= PARTICLE_DUST;

func _exit():
	_mario.rotation.x = 0
	_mario.rotation.z = 0
	_mario.stop_slide_sound()

func get_flags() -> int:
	return ACT_FLAG_MOVING | ACT_FLAG_ATTACKING
