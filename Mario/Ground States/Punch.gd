extends GroundState

var _previous_state : String
var first_frame : bool
var action_state := 0
var velocity : float

var attack_window_open : bool

func _enter() -> void:
	action_timer = 0
	action_state = 0
	attack_window_open = true
	first_frame = true
	velocity = 10.0
	
	_mario.play_anim("mario-first-punch")
	_mario.play_mario_sound(_mario.SOUND_YA)
	Input.action_release("punch")

func _update(delta : float):
	if first_frame and Input.is_action_pressed("jump"):
		return "air kick"
	first_frame = false
	
	if Input.is_action_just_pressed("jump"):
		return set_jumping_state("jump")
	elif _mario.above_slide:
		return "sliding"
	elif _mario.off_floor:
		return "free falling"
	
	if Input.is_action_just_pressed("punch"):
		match action_state:
			0:
				_mario.play_anim("mario-second-punch")
				_mario.play_mario_sound(_mario.SOUND_WA)
				action_state = 1
				action_timer = 0
			1:
				_mario.play_anim("mario-ground-kick")
				_mario.play_mario_sound(_mario.SOUND_HOO)
				action_state = 2
				action_timer = 0
	
	if _mario.anim_at_end():
		if _fsm.get_node_by_state(_previous_state).has_method("is_stationary_state"):
			return "idle"
		else:
			return "running"
	
	if action_timer < 5:
		attack_window_open = true
		action_timer += 1
	else:
		attack_window_open = false
	
	if _fsm.get_node_by_state(_previous_state).has_method("is_stationary_state"):
		velocity *= 0.7
		_mario.set_forward_velocity(velocity)
		perform_ground_q_steps()
	else:
		if _mario.forward_velocity >= 0.0:
			apply_slope_decel(0.5)
		else:
			_mario.forward_velocity += 8.0
			if _mario.forward_velocity >= 0.0:
				_mario.forward_velocity = 0.0
			apply_slope_accel()
		
		match perform_ground_q_steps():
			GROUND_STEP_LEFT_GROUND:
				_fsm.change_state("free falling")
			GROUND_STEP_NONE:
				pass #m->particleFlags |= PARTICLE_DUST

func get_flags() -> int:
	var flags = ACT_FLAG_ATTACKING
	if action_timer == 0: # regular punch
		flags |= ACT_FLAG_MOVING
	else:
		flags |= ACT_FLAG_STATIONARY
	
	return flags
