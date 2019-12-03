extends GroundState

var knockback_strength : int

func _enter():
	
	match knockback_strength:
		-3:
			_mario.play_anim("mario-hard-backward-kb")
		-2:
			_mario.play_anim("mario-medium-backward-kb")
		-1:
			_mario.play_anim("mario-soft-backward-kb")
		1:
			_mario.play_anim("mario-soft-forward-kb")
		2:
			_mario.play_anim("mario-medium-forward-kb")
		3:
			_mario.play_anim("mario-hard-forward-kb")
	
	if _mario.got_hurt:
		_mario.play_mario_sound(_mario.SOUND_PAIN)
	else: 
		_mario.play_mario_sound(_mario.SOUND_OOF)

func _update(delta : float):
#	if arg3:
#		play_mario_heavy_landing_sound_once(SOUND_ACTION_TERRAIN_BODY_HIT_GROUND)
	
	_mario.forward_velocity = clamp(_mario.forward_velocity, -32.0, 32.0)
	
#	val04 = set_mario_animation(animation)
#	if val04 < arg2:
	apply_landing_accel(0.9)
#	if _mario.foward_velocity >= 0.0:
#		mario_set_forward_vel(0.1)
#	else: 
#		mario_set_forward_vel(-0.1)
	
	if perform_ground_q_steps() == GROUND_STEP_LEFT_GROUND:
		_mario.velocity.y = 0.0
		_fsm.get_node_by_state("air knockback").dir = sign(knockback_strength)
		return "air knockback"
	if _mario.anim_at_end():
		if _mario.health < 0x100:
			return "death"
		else: 
#			if _mario.got_hurt:
#				_mario.invincTimer = 30
			return "idle"

func check_dead():
	if _mario.health == 0x00FF:
		_fsm.change_state("death")