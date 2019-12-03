extends State
class_name WaterState

enum {WATER_STEP_NONE, WATER_STEP_CANCELLED, WATER_STEP_HIT_CEILING, WATER_STEP_HIT_FLOOR, WATER_STEP_HIT_WALL}

func swimming_near_surface() -> bool:
#	if _mario.flags & MARIO_METAL_CAP:
#        return FALSE
	
	return (_mario.water_level - 0.8) - _mario.translation.y < 4.0

func check_water_jump() -> bool:
	var probe := _mario.translation.y + 0.015
	
	if Input.is_action_just_pressed("jump"):
		if probe >= _mario.water_level - 0.8 and _mario.face_angle.x >= 0 and _mario.stick_dir.y < -60.0:
			_mario.ang_velocity = Vector3()
			_mario.velocity.y = 62.0
			
			return true
	return false


func get_buoyancy() -> float:
	var buoyancy := 0.0
	
#    if _mario.flags & MARIO_METAL_CAP:
#        if _mario.action & ACT_FLAG_INVULNERABLE:
#            buoyancy = -2.0f
#         else:
#            buoyancy = -18.0f
#         else
	if swimming_near_surface():
		buoyancy = 1.25
	elif _fsm.active_state != "water idle" and _fsm.active_state != "water action end":
		buoyancy = -2.0
	
	return buoyancy

func water_full_step(step : Vector3) -> int:
	
	var step_dict := {"vec": step}
	var wall : Surface = _mario.resolve_and_return_wall_collisions(step_dict, 0.1, 1.1)
	step = step_dict.vec
	var floor_dat := Collisions.find_floor(step)
	var ceil_height := _mario.find_ceil(step, floor_dat.height)
	
	if not floor_dat.floor:
		print("no floor")
		return WATER_STEP_CANCELLED
	
	if step.y >= floor_dat.height:
		if ceil_height - step.y >= 1.6:
			_mario.translation = step
			_mario.floor_surf = floor_dat.floor
			_mario.floor_height = floor_dat.height
			
			if wall:
				return WATER_STEP_HIT_WALL
			else:
				return WATER_STEP_NONE
		
		if ceil_height - floor_dat.height < 1.6:
			print("no space between floor and ceiling")
			return WATER_STEP_CANCELLED
		
		_mario.translation = Vector3(step.x, ceil_height - 1.6, step.z)
		_mario.floor_surf = floor_dat.floor
		_mario.floor_height = floor_dat.height
		return WATER_STEP_HIT_CEILING
	else:
		if ceil_height - floor_dat.height < 1.6:
			print("no space between floor and ceiling 2")
			return WATER_STEP_CANCELLED
		
		_mario.translation = Vector3(step.x, floor_dat.height, step.z)
		_mario.floor_surf = floor_dat.floor
		_mario.floor_height = floor_dat.height
		return WATER_STEP_HIT_FLOOR

func perform_water_step() -> int:
	
#	if _mario.action & ACT_FLAG_SWIMMING:
#		apply_water_current(m, step)
#    
	var next_pos = _mario.translation + _mario.velocity * 0.01
	if next_pos.y > _mario.water_level - 0.8:
		next_pos.y = _mario.water_level - 0.8
		_mario.velocity.y = 0.0
	
	var step_result = water_full_step(next_pos)
	
	_mario.rotation = _mario.face_angle * Vector3(-1, 1, 1)
	
	return step_result

func stationary_slow_down() -> void:
	var buoyancy = get_buoyancy()
	
	_mario.ang_velocity.x = 0
	_mario.ang_velocity.y = 0
	
	_mario.forward_velocity = Utils.approach(_mario.forward_velocity, 0.0, 1.0)
	_mario.velocity.y = Utils.approach_signed(_mario.velocity.y, buoyancy, 2.0, 1.0)
	
	_mario.face_angle.x = Utils.approach(_mario.face_angle.x, 0.0, deg2rad(2.8125))
	_mario.face_angle.z = Utils.approach(_mario.face_angle.z, 0.0, deg2rad(1.40625))
	
	_mario.velocity.x = _mario.forward_velocity * cos(_mario.face_angle.x) * sin(_mario.face_angle.y)
	_mario.velocity.z = _mario.forward_velocity * cos(_mario.face_angle.x) * cos(_mario.face_angle.y)

func update_swimming_yaw() -> void:
	var target_yaw_vel = -deg2rad(0.0879) * _mario.stick_dir.x
	
	if target_yaw_vel > 0:
		if _mario.ang_velocity.y < 0:
			_mario.ang_velocity.y += deg2rad(0.3516)
			if _mario.ang_velocity.y > deg2rad(0.0879):
				_mario.ang_velocity.y = deg2rad(0.0879)
		else:
			_mario.ang_velocity.y = Utils.approach_signed(_mario.ang_velocity.y, target_yaw_vel, deg2rad(0.0879), 0x20)
	
	elif target_yaw_vel < 0:
		if _mario.ang_velocity.y > 0:
			_mario.ang_velocity.y -= deg2rad(0.3516)
			if _mario.ang_velocity.y < -deg2rad(0.0879):
				_mario.ang_velocity.y = -deg2rad(0.0879)
		else:
			_mario.ang_velocity.y = Utils.approach_signed(_mario.ang_velocity.y, target_yaw_vel, 0x20, deg2rad(0.0879))
	else:
		_mario.ang_velocity.y = Utils.approach_signed(_mario.ang_velocity.y, 0, deg2rad(0.3516), deg2rad(0.3516))
	
	
	_mario.face_angle.y += _mario.ang_velocity.y
	_mario.face_angle.z = -_mario.ang_velocity.y * 8.0

func update_swimming_pitch() -> void:
	var target_pitch = -deg2rad(1.3843) * _mario.stick_dir.y
	
	var pitch_vel
	if _mario.face_angle.x < 0:
		pitch_vel = deg2rad(1.4063)
	else:
		pitch_vel = deg2rad(2.8125)
	
	if _mario.face_angle.x < target_pitch:
		_mario.face_angle.x += pitch_vel
		if _mario.face_angle.x > target_pitch:
			_mario.face_angle.x = target_pitch
	elif _mario.face_angle.x > target_pitch:
		_mario.face_angle.x -= pitch_vel
		if _mario.face_angle.x < target_pitch:
			_mario.face_angle.x = target_pitch

func update_swimming_speed(decel_threshold : float) -> void:
	var buoyancy = get_buoyancy()
	var max_speed = 28.0
	
	if is_state_stationary(_fsm.active_state):
		_mario.forward_velocity -= 2.0
	
	if _mario.forward_velocity < 0.0:
		_mario.forward_velocity = 0.0
	
	if _mario.forward_velocity > max_speed:
		_mario.forward_velocity = max_speed
	
	if _mario.forward_velocity > decel_threshold:
		_mario.forward_velocity -= 0.5
	
	
	_mario.velocity.x = _mario.forward_velocity * cos(_mario.face_angle.x) * sin(_mario.face_angle.y)
	_mario.velocity.y = _mario.forward_velocity * sin(_mario.face_angle.x) + buoyancy
	_mario.velocity.z = _mario.forward_velocity * cos(_mario.face_angle.x) * cos(_mario.face_angle.y)

func common_idle_step() -> void:
	update_swimming_yaw()
	update_swimming_pitch()
	update_swimming_speed(16.0)
	perform_water_step()
#	func_80270504()

func common_swimming_step(swim_strength : float) -> void:
	update_swimming_yaw()
	update_swimming_pitch()
	update_swimming_speed(swim_strength / 10.0)
	
	match perform_water_step():
		WATER_STEP_HIT_FLOOR:
			var floor_pitch = -_mario.find_floor_slope(-PI)
			_mario.face_angle.x = max(_mario.face_angle.x, floor_pitch)
		WATER_STEP_HIT_CEILING:
			if _mario.face_angle.x > -deg2rad(67.5):
				_mario.face_angle.x -= deg2rad(1.4063)
		WATER_STEP_HIT_WALL:
			if _mario.stick_dir.y == 0.0:
				if _mario.face_angle.x > 0.0:
					_mario.face_angle.x += deg2rad(2.8125)
					_mario.face_angle.x = min(_mario.face_angle.x, deg2rad(178.6))
				else:
					_mario.face_angle.x -= deg2rad(2.8125)
					_mario.face_angle.x = max(_mario.face_angle.x, -deg2rad(178.6))

func is_state_stationary(state : String) -> bool:
	return state == "water idle" or state == "water plunge" or state == "water knockback"

func is_underwater_state() -> void:
	pass