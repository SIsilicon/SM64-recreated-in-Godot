extends GroundState
class_name StationaryState

func stationary_ground_step() -> int:
	if _mario.floor_surf:
		_mario.translation.y = _mario.floor_height
	
	return GROUND_STEP_NONE

func is_stationary() -> void:
	pass