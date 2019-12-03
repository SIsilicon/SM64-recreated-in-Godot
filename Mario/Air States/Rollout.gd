extends AirState

var is_backward := false
var falling := false

func _enter() -> void:
	falling = false
	_mario.velocity.y = 30.0
	
	_mario.play_anim("mario-spinning", is_backward)
	_mario.play_mario_sound(_mario.SOUND_WOO)

func _update(delta : float):
	update_air_without_turn()
	
	match perform_air_q_steps():
		AIR_STEP_LANDED:
			_mario.play_anim("mario-freefall-land")
			_fsm.get_node_by_state("landing").action_timer = 0
			return "landing"
		AIR_STEP_HIT_WALL:
			_mario.set_forward_velocity(0.0)
	
	if not falling and _mario.anim_at_end():
		_mario.play_anim("mario-freefall")
		falling = true

func _exit() -> void:
	is_backward = false