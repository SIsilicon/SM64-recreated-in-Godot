extends GroundState

onready var anim_player = $"../../AnimationPlayer"
var anim_length : float

func _enter() -> void:
	_mario.play_anim("mario-braking")

func _update(delta : float):
	if should_begin_sliding():
		return "sliding"
	
	if _mario.intended_mag > 1:
		if not _mario.analog_held_back():
			return "running"
	else:
		return "braking"
	
	if Input.is_action_just_pressed("jump"):
		return set_jumping_state("sideflip")
	
	if apply_slope_decel(2):
		return begin_walking_state(8, "finish turning")
	
	match perform_ground_q_steps():
		GROUND_STEP_LEFT_GROUND:
			return "free falling"
	
	if _mario.forward_velocity >= 18:
		_mario.play_anim("mario-braking")
	else:
		_mario.play_anim("mario-turning")
		if _mario.anim_at_end():
			if _mario.forward_velocity >= 18:
				return begin_walking_state(-_mario.forward_velocity, "running")
			else:
				return begin_walking_state(8, "running")
