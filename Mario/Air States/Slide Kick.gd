extends AirState

var bounced : bool

func _enter() -> void:
	bounced = false
	action_timer = 0
	
	_mario.velocity.y = 12.0
	_mario.forward_velocity = max(_mario.forward_velocity, 32.0)
	_mario.play_anim("mario-slide-kick")
	_mario.play_mario_sound(_mario.SOUND_WOOHOO)

func _update(delta : float):
	_mario.rotation.x = 0.0
	action_timer += 1
	if action_timer > 30 and _mario.translation.y - _mario.floor_height > 5.0:
		return "free falling"
	
	update_air_without_turn()
	
	match perform_air_q_steps():
		AIR_STEP_NONE:
			if not bounced:
				_mario.rotation.x = atan2(-_mario.velocity.y, _mario.forward_velocity)
				_mario.rotation.x = min(_mario.rotation.x, 0.6)
		AIR_STEP_LANDED:
			if not bounced and _mario.velocity.y < 0.0:
				_mario.velocity.y = -_mario.velocity.y / 2.0
				bounced = true
				action_timer = 0
			else:
				_fsm.change_state("slide kick slide")
#			play_mario_landing_sound(m, SOUND_ACTION_TERRAIN_LANDING);
		
		AIR_STEP_HIT_WALL:
			_mario.velocity.y = min(_mario.velocity.y, 0.0)
			_fsm.get_node_by_state("air knockback").dir = -2
			_fsm.change_state("air knockback")

#func get_flags() -> int:
#	return ACT_FLAG_AIR | ACT_FLAG_ATTACKING