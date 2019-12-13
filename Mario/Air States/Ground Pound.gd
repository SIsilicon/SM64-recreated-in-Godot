extends AirState

var falling := false

func _enter():
	action_timer = 0
	falling = false
	
	_mario.play_anim("mario-ground-pound")

func _update(delta : float):
	
#	play_sound_if_no_flag(m, SOUND_ACTION_UNKNOWN435, MARIO_ACTION_SOUND_PLAYED)
	
	if not falling:
		if action_timer < 10:
			var y_offset = 0.2 - 0.02 * action_timer
			if _mario.translation.y + y_offset + 1.6 < _mario.ceil_height:
				_mario.translation.y += y_offset
				_mario.peak_height = _mario.translation.y
		
		_mario.velocity.y = -50.0
		_mario.set_forward_velocity(0.0)
		
#		if action_timer == 0:
#			play_sound(SOUND_ACTION_SWISH2, _mario.marioObj->header.gfx.cameraToObject)
		
		
		action_timer += 1
		if action_timer / 30.0 > _mario.anim_length + 0.133:
			_mario.play_mario_sound(_mario.SOUND_WA)
			falling = true
	else:
		var step_result = perform_air_q_steps(0)
		if step_result == AIR_STEP_LANDED:
#			play_mario_heavy_landing_sound(m, SOUND_ACTION_TERRAIN_HEAVY_LANDING)
			Global.camera.set_shake(0)
			
			check_fall_damage("landing")
			if _fsm.next_state_manual == "landing":
				_mario.play_anim("mario-ground-pound-land")
			
#			if !check_fall_damage(m, ACT_HARD_BACKWARD_GROUND_KB):
#				_mario.particleFlags |= PARTICLE_16 | PARTICLE_4
#				set_mario_action(m, ACT_GROUND_POUND_LAND, 0)
		
		elif step_result == AIR_STEP_HIT_WALL:
			_mario.set_forward_velocity(-16.0)
			if _mario.velocity.y > 0.0:
				_mario.velocity.y = 0.0
			
			return "air knockback"

func get_flags() -> int:
	return ACT_FLAG_AIR | ACT_FLAG_ATTACKING