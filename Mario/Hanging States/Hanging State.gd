extends State
class_name HangingState

enum {HANG_HIT_CEIL_OR_OOB, HANG_LEFT_CEIL, HANG_NONE}

func perform_hanging_step(step : Vector3) -> int:
	var intended_step = step
	var step_dict := {"vec": step}
	_mario.wall_surf = _mario.resolve_and_return_wall_collisions(step_dict, 0.5, 0.5)
	step = step_dict.vec
	
	var floor_dat := Collisions.find_floor(step)
	var ceil_height : float = _mario.find_ceil(step, floor_dat.height)
	
	if not floor_dat.floor:
		return HANG_HIT_CEIL_OR_OOB
	if not _mario.ceil_surf:
		return HANG_LEFT_CEIL
	if ceil_height - floor_dat.height <= 1.6:
		return HANG_HIT_CEIL_OR_OOB
	if _mario.ceil_surf.type != Surface.SURFACE_HANGABLE:
		return HANG_LEFT_CEIL
	
	var ceil_offset := ceil_height - (step.y + 1.6)
	if ceil_offset < -0.3:
		return HANG_HIT_CEIL_OR_OOB
	if ceil_offset > 0.3:
		return HANG_LEFT_CEIL
	
	step.y = _mario.ceil_height - 1.6
	_mario.translation = step
	
	_mario.floor_surf = floor_dat.floor
	_mario.floor_height = floor_dat.height
	
	return HANG_NONE

func update_hang_stationary() -> void:
	_mario.forward_velocity = 0.0
	_mario.slide_vel_x = 0.0
	_mario.slide_vel_z = 0.0
	
	_mario.translation.y = _mario.ceil_height - 1.6
	_mario.velocity = Vector3.ZERO

func update_hang_moving() -> int:
	var max_speed := 4.0
	
	_mario.forward_velocity += 1.0
	_mario.forward_velocity = min(_mario.forward_velocity, max_speed)
	
	var dir = Utils.angle_diff(_mario.intended_yaw, _mario.face_angle.y)
	_mario.face_angle.y += clamp(dir, -0.2, 0.2)
	
	_mario.slide_yaw = _mario.face_angle.y
	_mario.slide_vel_x = _mario.forward_velocity * sin(_mario.face_angle.y)
	_mario.slide_vel_z = _mario.forward_velocity * cos(_mario.face_angle.y)
	
	_mario.velocity = Vector3(_mario.slide_vel_x, 0.0, _mario.slide_vel_z)
	
	var step : Vector3 = _mario.translation + _mario.velocity * 0.01
	
	var step_result := perform_hanging_step(step)
	
	_mario.rotation = Vector3(0, _mario.face_angle.y, 0)
	return step_result
