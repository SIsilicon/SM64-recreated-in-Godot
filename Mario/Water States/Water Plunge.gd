extends WaterState

var _previous_state : String

func _enter():
	action_timer = 0
	_mario.play_anim("mario-water-action-end")
	if _mario.peak_height - _mario.translation.y > 11.5:
		_mario.play_mario_sound(_mario.SOUND_HAHA)

func _update(delta : float):
	var end_speed := 0.0 if swimming_near_surface() else -5.0
	
#	if (m->flags & MARIO_METAL_CAP) {
#		stateFlags |= 4
#	} else if ((m->prevAction & ACT_FLAG_DIVING) || (m->input & INPUT_A_DOWN)) {
#		stateFlags |= 2
#	}
	
	action_timer += 1
	stationary_slow_down()
	
	var step_result := perform_water_step()
	if step_result == WATER_STEP_HIT_FLOOR or _mario.velocity.y >= end_speed or action_timer > 20:
		if _previous_state == "sliding" or _previous_state == "dive":
			return "flutter kick"
		elif false: #Metal cap on:
				return "metal falling"
		else:
			return "water idle"

func get_flags() -> int:
	return ACT_FLAG_STATIONARY | ACT_FLAG_SWIMMING
