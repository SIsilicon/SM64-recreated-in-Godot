extends GroundState

var _previous_state : String

var prev_yaw : float
var torso_rot : Vector2

var sidestepping = false
var pushing = false

func _enter() -> void:
	var mag = min(_mario.intended_mag, 8.0)
	if _mario.get_floor_class() != Surface.SURFACE_CLASS_VERY_SLIPPERY:
		if 0.0 <= _mario.forward_velocity and _mario.forward_velocity < mag:
			_mario.forward_velocity = mag
	
	prev_yaw = _mario.face_angle.y
	torso_rot = Vector2()

func update_visual_walking_speed() -> void:
	var speed = _mario.intended_mag if _mario.forward_velocity < _mario.intended_mag else _mario.forward_velocity
	speed = max(speed, 4.0)
	
	while true:
		match action_timer:
			0:
				if speed > 8.0:
					action_timer = 1
				else:
					_mario.play_anim("mario-tiptoe")
					return
			1:
				if speed < 5.0:
					action_timer = 0
				elif speed > 22.0:
					action_timer = 2
				else:
					_mario.play_anim("mario-walk")
					_mario.anim_player.playback_speed = speed / 8.0
					return
			2:
				if speed < 18.0:
					action_timer = 1
				else:
					_mario.play_anim("mario-run")
					_mario.anim_player.playback_speed = speed / 8.0
					return

func update_against_wall(start_pos : Vector3) -> void:
	action_timer = 0
	_mario.reset_custom_poses()
	
	var wall_angle : float
	var diff_wall_angle : float
	var dx : float = _mario.translation.x - start_pos.x
	var dz : float = _mario.translation.z - start_pos.z
	var moved_distance := sqrt(dx * dx + dz * dz)
	var sidestep_speed = moved_distance * 160.0
	
	_mario.set_forward_velocity(min(_mario.forward_velocity, 6.0))
	
	if _mario.wall_surf:
		wall_angle = atan2(_mario.wall_surf.normal.x, _mario.wall_surf.normal.z)
		diff_wall_angle = Utils.angle_diff(wall_angle, _mario.face_angle.y)
	
	if not _mario.wall_surf or diff_wall_angle <= -deg2rad(160) or diff_wall_angle >= deg2rad(160):
		_mario.rotation.y = _mario.face_angle.y
		_mario.play_anim("mario-pushing")
		_mario.anim_player.playback_speed = 1.0
		pushing = true
	else:
		if diff_wall_angle < 0:
			_mario.play_anim("mario-sidestep-right")
		else:
			_mario.play_anim("mario-sidestep-left")
		
		sidestepping = true
		_mario.anim_player.playback_speed = sidestep_speed
		_mario.rotation.y = wall_angle + PI;
		_mario.rotation.z = _mario.find_floor_slope(PI/2)

func check_ledge_climb_down() -> bool:
	
	if _mario.forward_velocity < 10.0:
		var wall_cols := Collisions.find_wall_collisions(_mario.translation, -0.1, 0.1)
		
		if wall_cols.num_walls != 0:
			
			var floor_data := Collisions.find_floor(Vector3(wall_cols.x, _mario.translation.y, wall_cols.z))
			if floor_data.floor != null:
				if _mario.translation.y - floor_data.height > 1.6:
					var wall : Surface = wall_cols.walls[wall_cols.num_walls - 1];
					var wall_angle = atan2(wall.normal.x, wall.normal.z)
					var wall_diff_yaw = Utils.angle_diff(wall_angle, _mario.face_angle.y)
					
					if wall_diff_yaw > -PI/2 and wall_diff_yaw < PI/2:
						_mario.translation.x = wall_cols.x - 0.2 * wall.normal.x
						_mario.translation.x = wall_cols.x - 0.2 * wall.normal.x
						
						_mario.face_angle.x = 0
						_mario.face_angle.y = wall_angle + PI
						
						return true
	
	return false

func _update(delta : float):
	
	if should_begin_sliding():
		return "sliding"
	
	if Input.is_action_just_pressed("punch"):
		return check_ground_dive_or_punch()
	elif Input.is_action_just_pressed("crouch"):
		return "crouch slide"
	elif Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("crouch"):
			return set_jumping_state("long jump")
		else:
			return set_jump_from_landing()
	elif not Input.is_action_pressed("analog"):
		if pushing or sidestepping:
			return "idle"
		else:
			return begin_braking_state()
	elif _mario.analog_held_back() and _mario.forward_velocity >= 16.0:
		return "turning"
	
	update_walking_speed()
	
	var prev_pos = _mario.translation
	sidestepping = false
	pushing = false
	match perform_ground_q_steps():
		GROUND_STEP_LEFT_GROUND:
			_fsm.change_state("free falling")
		GROUND_STEP_NONE:
			update_visual_walking_speed()
			
			var skeleton : Skeleton = _mario.skeleton
			var diff_yaw : float = _mario.face_angle.y - prev_yaw
			var val00 := clamp(_mario.forward_velocity * 0.03, 0, 0.524)
			var val02 := clamp(diff_yaw * _mario.forward_velocity / 12.0, -0.524, 0.524)
			
			torso_rot.x = Utils.approach(torso_rot.x, val00, 0.1 * _mario.intended_mag / 64.0)
			torso_rot.y = Utils.approach(torso_rot.y, val02, 0.1)
			
			_mario.rotation.y = _mario.face_angle.y
			skeleton.set_bone_custom_pose(10, Transform().rotated(Vector3.FORWARD, torso_rot.x).rotated(Vector3.RIGHT, -torso_rot.y))
			skeleton.set_bone_custom_pose(1, Transform().rotated(Vector3.FORWARD, -torso_rot.x).rotated(Vector3.UP, torso_rot.y))
		GROUND_STEP_HIT_WALL:
			update_against_wall(prev_pos)
	
	if check_ledge_climb_down():
		_fsm.change_state("ledge grab")
	prev_yaw = _mario.face_angle.y

func _exit():
	_mario.rotation.z = 0
	_mario.reset_custom_poses()

func get_flags() -> int:
	return ACT_FLAG_MOVING | ACT_FLAG_ALLOW_FIRST_PERSON
