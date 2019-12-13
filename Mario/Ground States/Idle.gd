extends StationaryState

var _previous_state : String

onready var anim_player = $"../../AnimationPlayer"
var against_wall := false
var wait_on_animation : bool

func _enter() -> void:
	_mario.got_hurt = false
	wait_on_animation = true
	against_wall = false
	match _previous_state:
		"braking":
			_mario.play_anim("mario-stop-braking")
		"crouching":
			_mario.play_anim("mario-stop-crouch")
		"sliding":
			_mario.play_anim(_fsm.get_node_by_state("sliding").stop_animation)
		"landing":
			if _mario.last_air_state == "ground pound":
				_mario.play_anim("mario-stop-sliding")
			else:
				wait_on_animation = false
				_mario.play_anim("mario-idle")
		"running":
			wait_on_animation = false
			if _fsm.get_node_by_state(_previous_state).sidestepping:
				_mario.rotation.y = atan2(_mario.wall_surf.normal.x, _mario.wall_surf.normal.z) + PI
				_mario.play_anim("mario-idle-against-wall")
			else:
				_mario.play_anim("mario-idle")
		_:
			wait_on_animation = false
			_mario.play_anim("mario-idle")

func _update(delta : float):
	if _mario.anim_at_end() and wait_on_animation:
		wait_on_animation = false
		_mario.play_anim("mario-idle")
	
	if should_begin_sliding():
		return "sliding"
	
	if _mario.off_floor:
		return "free falling"
	
	stationary_ground_step()
	
	if not wait_on_animation:
		if Input.is_action_just_pressed("punch"):
			return "punch"
		
		if Input.is_action_pressed("crouch"):
			if _mario.anim_player.current_animation == "mario-idle":
				return "crouching"
			if Input.is_action_just_pressed("jump"):
				return set_jumping_state("backflip")
		
		if Input.is_action_just_pressed("jump"):
			return set_jump_from_landing()
		
		if Input.is_action_pressed("analog"):
			_mario.face_angle.y = _mario.intended_yaw
			return "running"

func get_flags() -> int:
	return ACT_FLAG_STATIONARY | ACT_FLAG_IDLE | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT
