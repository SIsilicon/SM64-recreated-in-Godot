extends WaterState

func _enter() -> void:
	_mario.play_anim("mario-water-grab")

func _update(delta : float):
	if _mario.forward_velocity < 7.0:
		_mario.forward_velocity += 1.0
	
	update_swimming_yaw()
	update_swimming_pitch()
	update_swimming_speed(16.0)
	perform_water_step()
#	func_80270504(m)
	
#	marioBodyState.unk12[0] = approach_s32(marioBodyState.unk12[0], 0, 0x200, 0x200)
	
#	play_sound_if_no_flag(m, SOUND_ACTION_UNKNOWN433, MARIO_ACTION_SOUND_PLAYED)
	
	if _mario.anim_at_end():
		return "swimming end"
