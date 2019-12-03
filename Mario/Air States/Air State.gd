extends State
class_name AirState

var kb_state : Node

enum {AIR_STEP_NONE, AIR_STEP_HIT_WALL, AIR_STEP_LANDED, AIR_STEP_GRABBED_LEDGE}

enum {AIR_CHECK_LEDGE_GRAB = 1, AIR_CHECK_FALL_DAMAGE = 2, AIR_CHECK_WALL_KICK = 4}

func check_ledge_grab(wall : Surface, intended_pos : Vector3, next_pos : Vector3) -> bool:
	var ledge_floor : Surface
	var ledge_pos : Vector3
	var displacement_x : float
	var displacement_z : float
	
	if _mario.velocity.y > 0:
		return false
	
	displacement_x = next_pos.x - intended_pos.x
	displacement_z = next_pos.z - intended_pos.z
	
	# Only ledge grab if the wall displaced mario in the opposite direction of
	# his velocity.
	if displacement_x * _mario.velocity.x + displacement_z * _mario.velocity.z > 0.0:
		return false
	
	#! Since the search for floors starts at y + 160, we will sometimes grab
	# a higher ledge than expected (glitchy ledge grab)
	ledge_pos.x = next_pos.x - wall.normal.x * 0.6
	ledge_pos.z = next_pos.z - wall.normal.z * 0.6
	var ledge_dict = Collisions.find_floor(Vector3(ledge_pos.x, next_pos.y + 1.6, ledge_pos.z))
	ledge_floor = ledge_dict.floor
	ledge_pos.y = ledge_dict.height
	
	if ledge_pos.y - next_pos.y <= 1.0:
		return false
	
	_mario.translation = ledge_pos
	_mario.floor_surf = ledge_floor
	_mario.floor_height = ledge_pos.y
	_mario.floor_angle = atan2(ledge_floor.normal.x, ledge_floor.normal.z)
	
	_mario.face_angle.x = 0
	_mario.face_angle.y = Utils.angle_diff(atan2(wall.normal.x, wall.normal.z), -PI)
	return true

func air_q_step(step : Vector3, step_args := 0) -> int:
#	s16 wallDYaw
#	struct Surface *upperWall
#	struct Surface *lowerWall
#	struct Surface *ceil
#	f32 ceilHeight
#	f32 floorHeight
#	f32 waterLevel
	
	var intended_step = step
	var step_dict := {"vec": step}
	var lower_wall : Surface = _mario.resolve_and_return_wall_collisions(step_dict, 1.5, 0.5)
	var upper_wall : Surface = _mario.resolve_and_return_wall_collisions(step_dict, 0.3, 0.5)
	step = step_dict.vec
	
	var floor_dat := Collisions.find_floor(step)
	var ceil_height := _mario.find_ceil(step, floor_dat.height)
#	waterLevel = find_water_level(next_pos.x, next_pos.z)
	
	_mario.wall_surf = null
	
	# Explicitly implemented overflow jump :)
	step.y = wrapf(step.y, -327.68, 327.67)
	
	if not floor_dat.floor:
		if step.y <= _mario.floor_height:
			_mario.translation.y = _mario.floor_height
			return AIR_STEP_LANDED
		
		_mario.translation.y = step.y
		return AIR_STEP_HIT_WALL
	
	if step.y <= floor_dat.height: 
		if ceil_height - floor_dat.height > 1.6: 
			_mario.translation.x = step.x 
			_mario.translation.z = step.z
			_mario.floor_surf = floor_dat.floor
			_mario.floor_height = floor_dat.height
		
		_mario.translation.y = floor_dat.height
		return AIR_STEP_LANDED
	
	if step.y + 1.6 > ceil_height:
		if _mario.velocity.y >= 0.0:
			_mario.velocity.y = 0.0
			
			#! Uses referenced ceiling instead of ceil (ceiling hang upwarp)
#			if (stepArg & AIR_STEP_CHECK_HANG) && _mario.ceil != NULL
#				&& _mario.ceil->type == SURFACE_HANGABLE) 
#				return AIR_STEP_GRABBED_CEILING
			
			return AIR_STEP_NONE
		
		#! Potential subframe downwarp->upwarp?
		if step.y <= _mario.floor_height:
			_mario.translation.y = _mario.floor_height
			return AIR_STEP_LANDED
		
		_mario.translation.y = step.y
		return AIR_STEP_HIT_WALL
	
	if (step_args & AIR_CHECK_LEDGE_GRAB) and (not upper_wall) and lower_wall: 
		if check_ledge_grab(lower_wall, intended_step, step):
			return AIR_STEP_GRABBED_LEDGE
	
	_mario.translation = step
	_mario.floor_surf = floor_dat.floor
	_mario.floor_height = floor_dat.height
	
	if upper_wall or lower_wall:
		_mario.wall_surf = upper_wall if upper_wall else lower_wall
		var wall_yaw := atan2(_mario.wall_surf.normal.x, _mario.wall_surf.normal.z)
		var wall_diff_yaw := Utils.angle_diff(wall_yaw, _mario.face_angle.y)
		
		if wall_diff_yaw < -2.356 or wall_diff_yaw > 2.356:
			return AIR_STEP_HIT_WALL
	
	return AIR_STEP_NONE

func perform_air_q_steps(step_args := 0) -> int:
	var quarterStepResult : int
	var stepResult = AIR_STEP_NONE
	
	_mario.wall_surf = null
	
	for i in 4:
		var intended_pos = _mario.translation + _mario.velocity * 0.25 * Constants.UNIT_SCALE
		
		quarterStepResult = air_q_step(intended_pos, step_args)
		
		if quarterStepResult != AIR_STEP_NONE:
			stepResult = quarterStepResult
		
		if quarterStepResult == AIR_STEP_LANDED || quarterStepResult == AIR_STEP_GRABBED_LEDGE:
		#		|| quarterStepResult == AIR_STEP_GRABBED_CEILING
		#		|| quarterStepResult == AIR_STEP_HIT_LAVA_WALL):
			break
	
	if _mario.velocity.y >= 0.0:
		_mario.peak_height = _mario.translation.y
	
	if _fsm.active_state == "long jump":
		_mario.velocity.y -= 2
	elif should_strengthen_gravity_for_jump_ascent():
		_mario.velocity.y /= 4.0
	else:
		_mario.velocity.y -= 4
	_mario.velocity.y = max(_mario.velocity.y, -75)
	
	if not _mario.got_hurt and _mario.peak_height - _mario.translation.y > 11.5 and not _mario.screamed:
		_mario.play_mario_sound(_mario.SOUND_SCREAM)
		_mario.screamed = true
	
	return stepResult

func check_fall_damage(land_state : String) -> String:
	if not _mario.got_hurt:
		var fall_height = _mario.peak_height - _mario.translation.y
		
		if fall_height > 30.0:
			_mario.health_dec += 16
#			set_camera_shake(SHAKE_FALL_DAMAGE);
			kb_state.knockback_strength = 3 if _fsm.active_state == "dive" else -3
			_mario.play_mario_sound(_mario.SOUND_PAIN)
			return "ground knockback"
		elif fall_height > 11.5 and not _mario.floor_is_slippery():
			_mario.health_dec += 8
			_mario.squished = 30
#			set_camera_shake(SHAKE_FALL_DAMAGE);
			_mario.play_mario_sound(_mario.SOUND_PAIN)
	
	return land_state

func kick_or_dive_in_air():
	return "dive" if _mario.forward_velocity > 28.0 else "air kick"

func update_air_without_turn() -> void:
	var sideways_speed := 0
	var drag_threshold : float
	var intended_diff_yaw : float
	var intendedMag : float
	
	drag_threshold = 48.0 if _fsm.active_state == "long jump" else 32.0
	_mario.forward_velocity = Utils.approach(_mario.forward_velocity, 0.0, 0.35)
	
	if _mario.intended_mag > 0.0:
		intended_diff_yaw = _mario.intended_yaw - _mario.face_angle.y
		intendedMag = _mario.intended_mag / 32.0
		
		_mario.forward_velocity += intendedMag * cos(intended_diff_yaw) * 1.5
		sideways_speed = intendedMag * sin(intended_diff_yaw) * 10.0
		
		#! Uncapped air speed. Net positive when moving forward.
		if _mario.forward_velocity > drag_threshold:
			_mario.forward_velocity -= 1.0
		if _mario.forward_velocity < -16.0:
			_mario.forward_velocity += 2.0
		
		_mario.slide_vel_x = _mario.forward_velocity * sin(_mario.face_angle.y)
		_mario.slide_vel_z = _mario.forward_velocity * cos(_mario.face_angle.y)
		
		_mario.slide_vel_x += sideways_speed * sin(_mario.face_angle.y + PI/2)
		_mario.slide_vel_z += sideways_speed * cos(_mario.face_angle.y + PI/2)
		
		_mario.velocity.x = _mario.slide_vel_x
		_mario.velocity.z = _mario.slide_vel_z

func should_strengthen_gravity_for_jump_ascent() -> bool:
	if _fsm.active_state == "jump" || _fsm.active_state == "double jump" || _fsm.active_state == "triple jump":
		if !Input.is_action_pressed("jump") and _mario.velocity.y > 20 and not _mario.jumped_on_entity:
			return true
	
	return false

func action_in_air(land_animation : String, step_args := 0):
	update_air_without_turn()
	
	match perform_air_q_steps(step_args):
		AIR_STEP_LANDED:
			_mario.jumped_on_entity = false
			
			_mario.last_air_state = _fsm.active_state
			_mario.play_anim(land_animation)
			
			if step_args % AIR_CHECK_FALL_DAMAGE:
				return check_fall_damage("landing")
			else:
				return "landing"
			
		AIR_STEP_HIT_WALL:
			if _mario.forward_velocity > 16.0:
				_mario.bonk_reflection(false)
				_mario.face_angle.y = wrapf(_mario.face_angle.y + PI, -PI, PI)
				
				if _mario.wall_surf:
					return "wall kick" #set_mario_action(m, ACT_AIR_HIT_WALL, 0)
				else:
					_mario.velocity.y = min(_mario.velocity.y, 0.0)
					
					if _mario.forward_velocity >= 38.0:
						_mario.play_mario_sound(_mario.SOUND_DOH)
						_fsm.get_node_by_state("air knockback").dir = -1
						return "air knockback"
					else:
						if _mario.forward_velocity > 8.0:
							_mario.set_forward_velocity(-8.0)
						
						return "soft bonk" # set_mario_action(m, ACT_SOFT_BONK, 0)
			else:
				_mario.set_forward_velocity(0.0) # This line is preventing pu movements
		AIR_STEP_GRABBED_LEDGE:
			return "ledge grab"
            
func action_knockback(kb_strength : int, speed : float):
	_mario.set_forward_velocity(speed)
	
	match perform_air_q_steps():
		AIR_STEP_LANDED:
			_mario.jumped_on_entity = false
			
			if check_fall_damage("landing") != "ground knockback":
				kb_state.knockback_strength = kb_strength
			
			if kb_state.knockback_strength == 0:
				_mario.play_anim("mario-freefall-land")
				return "landing"
			else:
				return "ground knockback"
			
		AIR_STEP_HIT_WALL:
			_mario.bonk_reflection(false)
			_mario.play_anim("mario-backward-air-kb")
			
			_mario.velocity.y = min(_mario.velocity.y, 0.0)
			_mario.set_forward_velocity(-speed)

func _exit():
	_mario.double_jump_timer = 5
	_mario.screamed = false
	_mario.last_air_state = _fsm.active_state

func _process(delta : float) -> void:
	kb_state = _fsm.get_node_by_state("ground knockback")

func is_air_state() -> void:
	pass