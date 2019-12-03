extends State
class_name GroundState

enum {GROUND_STEP_NONE, GROUND_STEP_HIT_WALL_STOP_QSTEPS, GROUND_STEP_HIT_WALL_CONTINUE_QSTEPS, GROUND_STEP_LEFT_GROUND, GROUND_STEP_HIT_WALL}

func apply_slope_accel() -> void:
	var slope_accel := 0.0
	
	var floor_surf := _mario.floor_surf
	var steepness := sqrt(floor_surf.normal.x * floor_surf.normal.x + floor_surf.normal.z * floor_surf.normal.z)
	
	var normal_y := floor_surf.normal.y
	var floor_diff_yaw := wrapf(_mario.floor_angle - _mario.face_angle.y, -PI, PI)
	
	if _mario.floor_is_slope():
		var slope_class := 0
		
#		if (m->action != ACT_SOFT_BACKWARD_GROUND_KB && m->action != ACT_SOFT_FORWARD_GROUND_KB) {
		slope_class = _mario.get_floor_class()
#		}
#		
		match slope_class:
			Surface.SURFACE_CLASS_VERY_SLIPPERY:
				slope_accel = 5.3
			Surface.SURFACE_CLASS_SLIPPERY:
				slope_accel = 2.7
			Surface.SURFACE_CLASS_DEFAULT:
				slope_accel = 1.7
			Surface.SURFACE_CLASS_NOT_SLIPPERY:
				slope_accel = 0.0
		
		if floor_diff_yaw > -PI/2.0 and floor_diff_yaw < PI/2.0:
			_mario.forward_velocity += slope_accel * steepness
		else:
			_mario.forward_velocity -= slope_accel * steepness
	
	_mario.slide_yaw = _mario.face_angle.y
	
	_mario.slide_vel_x = _mario.forward_velocity * sin(_mario.face_angle.y)
	_mario.slide_vel_z = _mario.forward_velocity * cos(_mario.face_angle.y)
	
	_mario.velocity = Vector3(_mario.slide_vel_x, 0, _mario.slide_vel_z)

func apply_slope_decel(decel_coeff : float) -> bool:
	var decel : float
	var stopped := false
	
	match _mario.get_floor_class():
		Surface.SURFACE_CLASS_VERY_SLIPPERY:
			decel = decel_coeff * 0.2
		Surface.SURFACE_CLASS_SLIPPERY:
			decel = decel_coeff * 0.7
		Surface.SURFACE_CLASS_DEFAULT:
			decel = decel_coeff * 2.0
		Surface.SURFACE_CLASS_NOT_SLIPPERY:
			decel = decel_coeff * 3.0
	
	_mario.forward_velocity = Utils.approach(_mario.forward_velocity, 0.0, decel)
	if _mario.forward_velocity == 0:
		stopped = true
	apply_slope_accel()
	
	return stopped

func apply_landing_accel(friction : float) -> bool:
	var stopped = false
	
	if true:#(!mario_floor_is_slope(m)) {
		_mario.forward_velocity *= friction
		if abs(_mario.forward_velocity) < 1.0:
			_mario.set_forward_velocity(0)
			stopped = true
	
	return stopped

func ground_q_step(step : Vector3) -> int:
	
	var step_dict := {"vec": step}
	var lower_wall : Surface = _mario.resolve_and_return_wall_collisions(step_dict, 0.3, 0.24)
	var upper_wall : Surface = _mario.resolve_and_return_wall_collisions(step_dict, 0.6, 0.50)
	step = step_dict.vec
	var floor_dat := Collisions.find_floor(step)
	var ceil_height := _mario.find_ceil(step, floor_dat.height)
#	var water_level = Collisions.find_water_level(step)
	
	_mario.wall_surf = upper_wall
	if (floor_dat.floor == null):
		return GROUND_STEP_HIT_WALL_STOP_QSTEPS
	
	if step.y > floor_dat.height + 1.0:
		if (step.y + 1.6 >= ceil_height):
			return GROUND_STEP_HIT_WALL_STOP_QSTEPS
		_mario.translation = step
		_mario.floor_surf = floor_dat.floor
		_mario.floor_height = floor_dat.height
		return GROUND_STEP_LEFT_GROUND
	
	if floor_dat.height + 1.6 >= ceil_height:
		return GROUND_STEP_HIT_WALL_STOP_QSTEPS
	
	_mario.translation = Vector3(step.x, floor_dat.height, step.z)
	_mario.floor_surf = floor_dat.floor
	_mario.floor_height = floor_dat.height
	
	if upper_wall:
		var wall_angle_yaw := atan2(upper_wall.normal.x, upper_wall.normal.z)
		var wall_diff_yaw := Utils.angle_diff(wall_angle_yaw, _mario.face_angle.y)
		
		if wall_diff_yaw >= 1.047 and wall_diff_yaw <= 2.094:
			return GROUND_STEP_NONE
		if wall_diff_yaw <= -1.047 and wall_diff_yaw >= -2.094:
			return GROUND_STEP_NONE
		
		return GROUND_STEP_HIT_WALL_CONTINUE_QSTEPS
	
	return GROUND_STEP_NONE

func perform_ground_q_steps() -> int:
	var step_result := GROUND_STEP_NONE
	
	for i in 4:
		var intended_pos = _mario.translation + Vector3(
				_mario.velocity.x * _mario.floor_surf.normal.y,
				0,
				_mario.velocity.z * _mario.floor_surf.normal.y
		) * 0.25 * Constants.UNIT_SCALE
		
		step_result = ground_q_step(intended_pos)
		if step_result == GROUND_STEP_LEFT_GROUND || step_result == GROUND_STEP_HIT_WALL_STOP_QSTEPS:
			break
	
	if step_result == GROUND_STEP_HIT_WALL_CONTINUE_QSTEPS || \
			step_result == GROUND_STEP_HIT_WALL_STOP_QSTEPS:
		step_result = GROUND_STEP_HIT_WALL
	
#	prints(step_result, _mario.floor_surf)
	return step_result;

func begin_braking_state() -> String:
	if _mario.forward_velocity >= 16.0 and _mario.floor_surf.normal.y >= 0.17364818:
		return "braking"
	
	return "decelerating"

func begin_walking_state(vel : float, state : String) -> String:
	_mario.face_angle.y = _mario.intended_yaw
	_mario.set_forward_velocity(vel)
	return state

func set_steep_jump_state() -> String:
	if _mario.forward_velocity > 0.0:
		#! ((s16)0x8000) has undefined behavior. Therefore, this downcast has
		# undefined behavior if m->floorAngle >= 0.
		_fsm.get_node_by_state("steep jump").steep_yaw = _mario.face_angle.y
		var angle_temp := _mario.floor_angle + PI
		var face_angle_temp = _mario.face_angle.y - angle_temp
		
		var y = sin(face_angle_temp) * _mario.forward_velocity
		var x = cos(face_angle_temp) * _mario.forward_velocity * 0.75
		
		_mario.forward_velocity = sqrt(y * y + x * x)
		_mario.face_angle.y = Utils.angle_diff(atan2(y, x), -angle_temp)
	
	return "steep jump"

func set_jumping_state(state : String) -> String:
	if _mario.floor_is_steep():
		return set_steep_jump_state()
	else:
		return state

func set_jump_from_landing() -> String:
	if _mario.floor_is_steep():
		_mario.double_jump_timer = 0
		return set_steep_jump_state()
	else:
		if _mario.double_jump_timer != 0:
			_mario.double_jump_timer = 0
			match _mario.last_air_state:
				"jump":
					return "double jump"
				"double jump":
					return "jump"
				"free falling":
					return "double jump"
				"air kick":
					return "double jump"
				"sideflip":
					return "double jump"
				_:
					return "jump"
		else:
			return "jump"

func update_decelerating_speed() -> bool:
	var stopped = false
	
	_mario.forward_velocity = Utils.approach(_mario.forward_velocity, 0.0, 1.0)
	if _mario.forward_velocity == 0.0:
		stopped = true
	
	_mario.set_forward_velocity(_mario.forward_velocity)
	
	return stopped

func update_walking_speed() -> void:
	var target_speed = min(32, _mario.intended_mag)
	if _mario.forward_velocity <= 0.0:
		_mario.forward_velocity += 1.1
	elif _mario.forward_velocity <= target_speed:
		_mario.forward_velocity += 1.1 - _mario.forward_velocity / 43.0
	elif _mario.floor_surf.normal.y >= 0.95:
		_mario.forward_velocity -= 1.0
	
	_mario.forward_velocity = min(_mario.forward_velocity, 48)
	
	var dir = Utils.angle_diff(_mario.intended_yaw, _mario.face_angle.y)
	_mario.face_angle.y += clamp(dir, -0.19, 0.19)
	
	apply_slope_accel()

func should_begin_sliding() -> bool:
	if _mario.above_slide:
		return _mario.forward_velocity <= -1.0 or _mario.facing_downhill()
	return false

func update_sliding_angle(accel : float, loss_factor : float) -> void:
	var new_facing_diff_yaw
	var facing_diff_yaw
	
	var floor_surf = _mario.floor_surf
	var slope_angle = atan2(floor_surf.normal.x, floor_surf.normal.z)
	var steepness = sqrt(floor_surf.normal.x * floor_surf.normal.x + floor_surf.normal.z * floor_surf.normal.z)
	
	_mario.slide_vel_x += accel * steepness * sin(slope_angle)
	_mario.slide_vel_z += accel * steepness * cos(slope_angle)
	
	_mario.slide_vel_x *= loss_factor
	_mario.slide_vel_z *= loss_factor
	
	_mario.slide_yaw = atan2(_mario.slide_vel_x, _mario.slide_vel_z)
	
	facing_diff_yaw = Utils.angle_diff(_mario.face_angle.y, _mario.slide_yaw)
	new_facing_diff_yaw = facing_diff_yaw
	
	if new_facing_diff_yaw > 0 and new_facing_diff_yaw <= PI/2:
		new_facing_diff_yaw = max(new_facing_diff_yaw - 0.05, 0)
	elif new_facing_diff_yaw > -PI/2 and new_facing_diff_yaw < 0:
		new_facing_diff_yaw = min(new_facing_diff_yaw + 0.05, 0)
	elif new_facing_diff_yaw > PI/2 and new_facing_diff_yaw < PI:
		new_facing_diff_yaw = min(new_facing_diff_yaw + 0.05, PI)
	elif new_facing_diff_yaw > -PI and new_facing_diff_yaw < -PI/2:
		new_facing_diff_yaw = max(new_facing_diff_yaw - 0.05, -PI)
	
	_mario.face_angle.y = _mario.slide_yaw + new_facing_diff_yaw
	
	_mario.velocity.x = _mario.slide_vel_x
	_mario.velocity.y = 0.0
	_mario.velocity.z = _mario.slide_vel_z
	
	#! _speed is capped a frame late (butt slide HSG)
	_mario.forward_velocity = sqrt(_mario.slide_vel_x * _mario.slide_vel_x + _mario.slide_vel_z * _mario.slide_vel_z)
	if _mario.forward_velocity > 100.0:
		_mario.slide_vel_x = _mario.slide_vel_x * 100.0 / _mario.forward_velocity
		_mario.slide_vel_z = _mario.slide_vel_z * 100.0 / _mario.forward_velocity
	
	if new_facing_diff_yaw < -PI/2 or new_facing_diff_yaw > PI/2:
		_mario.forward_velocity *= -1.0

func update_sliding(stop_speed : float) -> bool:
	var loss_factor : float
	var accel : float
	var old_speed : float
	var new_speed : float
	
	var stopped := false
	
	var intended_diff_yaw := Utils.angle_diff(_mario.intended_yaw, _mario.slide_yaw)
	var forward := cos(intended_diff_yaw)
	var sideward := sin(intended_diff_yaw)
	
	if forward < 0.0 and _mario.forward_velocity >= 0.0:
		forward *= 0.5 + 0.5 * _mario.forward_velocity / 100.0
	
	
	match _mario.get_floor_class():
		Surface.SURFACE_CLASS_VERY_SLIPPERY:
			accel = 10.0
			loss_factor = _mario.intended_mag / 32.0 * forward * 0.02 + 0.98
		Surface.SURFACE_CLASS_SLIPPERY:
			accel = 8.0
			loss_factor = _mario.intended_mag / 32.0 * forward * 0.02 + 0.96
		Surface.SURFACE_CLASS_DEFAULT:
			accel = 7.0
			loss_factor = _mario.intended_mag / 32.0 * forward * 0.02 + 0.92
		Surface.SURFACE_CLASS_NOT_SLIPPERY:
			accel = 5.0
			loss_factor = _mario.intended_mag / 32.0 * forward * 0.02 + 0.92
	
	old_speed = sqrt(_mario.slide_vel_x * _mario.slide_vel_x + _mario.slide_vel_z * _mario.slide_vel_z)
	
	_mario.slide_vel_x += _mario.slide_vel_z * (_mario.intended_mag / 32.0) * sideward * 0.05
	_mario.slide_vel_z -= _mario.slide_vel_x * (_mario.intended_mag / 32.0) * sideward * 0.05
	
	new_speed = sqrt(_mario.slide_vel_x * _mario.slide_vel_x + _mario.slide_vel_z * _mario.slide_vel_z)
	
	if old_speed > 0.0 and new_speed > 0.0:
		_mario.slide_vel_x = _mario.slide_vel_x * old_speed / new_speed
		_mario.slide_vel_z = _mario.slide_vel_z * old_speed / new_speed
	
	
	update_sliding_angle(accel, loss_factor)
	
	if not _mario.floor_is_slope() and _mario.forward_velocity * _mario.forward_velocity < stop_speed * stop_speed:
		_mario.set_forward_velocity(0.0)
		stopped = true
	
	return stopped

func slide_bonk(fast_action : String, slow_action : String):
	if _mario.forward_velocity > 16.0:
		_mario.bonk_reflection(true)
		return fast_action
	else:
		_mario.set_forward_velocity(0.0)
		return slow_action

func common_sliding_movement(stop_state : String):
	match perform_ground_q_steps():
		GROUND_STEP_LEFT_GROUND:
			if _mario.forward_velocity < -50.0 or 50.0 < _mario.forward_velocity:
				_mario.play_mario_sound(_mario.SOUND_WOOHOO)
			return "free falling"
		GROUND_STEP_NONE:
			var forward_vec := _mario.velocity * sign(_mario.forward_velocity)
			var right_vec := Vector3.UP.cross(forward_vec)
			_mario.look_at(_mario.translation + _mario.floor_surf.normal.cross(right_vec), Vector3.UP)
		GROUND_STEP_HIT_WALL:
			if not _mario.floor_is_slippery():
				return slide_bonk("landing", stop_state)
			elif _mario.wall_surf:
				var wall_angle = atan2(_mario.wall_surf.normal.x, _mario.wall_surf.normal.z)
				var slide_speed = sqrt(_mario.slide_vel_x * _mario.slide_vel_x + _mario.slide_vel_z * _mario.slide_vel_z)
				
				slide_speed = max(slide_speed * 0.9, 4.0)
				
				_mario.slide_yaw = Utils.angle_diff(wall_angle - (_mario.slide_yaw - wall_angle), -PI)
				_mario.slide_vel_x = slide_speed * sin(_mario.slide_yaw)
				_mario.slide_vel_z = slide_speed * cos(_mario.slide_yaw)
				_mario.velocity.x = _mario.slide_vel_x
				_mario.velocity.z = _mario.slide_vel_z
			
			#func_80263C14(m)

func common_sliding_movement_with_jump(stop_state : String, jump_state : String):
	if action_timer >= 5:
		if Input.is_action_just_pressed("jump"):
			return set_jumping_state(jump_state)
	else:
		action_timer += 1
	
	if update_sliding(4.0):
		return stop_state
	
	return common_sliding_movement(stop_state)

func check_ground_dive_or_punch():
	if _mario.forward_velocity >= 29.0 and _mario.intended_mag > 20.0:
		_mario.velocity.y = 20.0
		return "dive"
	else:
		return "punch"

func is_ground_state() -> void:
	pass
