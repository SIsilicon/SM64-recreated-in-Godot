extends StationaryState

var _previous_state : String

var playing_climb_down : bool
var getting_up : bool

func _enter() -> void:
	getting_up = false
	action_timer = 0
	
	if _previous_state == "running":
		playing_climb_down = true
		_mario.play_anim("mario-climb-down-ledge")
	else:
		playing_climb_down = false
		_mario.play_anim("mario-idle-ledge")
	
	_mario.set_forward_velocity(0.0)
	
	_mario.play_mario_sound(_mario.SOUND_WHOA)
	_mario.rotation.y = _mario.face_angle.y

func _update(delta : float):
	if not getting_up:
		var intended_diff_yaw := Utils.angle_diff(_mario.intended_yaw, _mario.face_angle.y)
		var has_space_for_mario : float = _mario.ceil_height - _mario.floor_height >= 1.6
		
		if _mario.floor_surf.normal.y < 0.9063078:
			return let_go_of_ledge()
		elif Input.is_action_just_pressed("crouch"):
			return let_go_of_ledge()
		elif Input.is_action_just_pressed("jump") and has_space_for_mario and action_timer >= 10:
			_mario.play_anim("mario-quick-ledge-get-up")
			_mario.play_mario_sound(_mario.SOUND_UNGH)
			getting_up = true
		elif Input.is_action_pressed("analog") and action_timer >= 10:
			if intended_diff_yaw >= -PI/2 and intended_diff_yaw <= PI/2:
				if has_space_for_mario:
					_mario.play_anim("mario-slow-ledge-get-up")
					_mario.play_mario_sound(_mario.SOUND_PULLUP)
					getting_up = true
			else:
				return let_go_of_ledge()
	else:
		if _mario.anim_at_end():
			return "idle"
	
	if playing_climb_down and _mario.anim_at_end():
		playing_climb_down = false
		_mario.play_anim("mario-idle-ledge")
	
	stationary_ground_step()
	action_timer += 1

func let_go_of_ledge() -> String:
	_mario.velocity.y = 0.0
	_mario.forward_velocity = -8.0
	
	_mario.translation.x -= 0.6 * sin(_mario.face_angle.y)
	_mario.translation.z -= 0.6 * cos(_mario.face_angle.y)
	
	var floor_dat := Collisions.find_floor(_mario.translation)
	if floor_dat.height < _mario.translation.y - 1.0:
		_mario.translation.y -= 1.0
	else:
		_mario.translation.y = floor_dat.height
	
	return "soft bonk"

func get_flags() -> int:
	return ACT_FLAG_STATIONARY | ACT_FLAG_PAUSE_EXIT