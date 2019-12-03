extends StationaryState

var _previous_state : String

func _enter() -> void:
	_mario.got_hurt = true
	
	match _previous_state:
		"ground knockback":
			match _fsm.get_node_by_state("ground knockback").knockback_strength:
				3: _mario.play_anim("mario-death-on-stomach")
				2: _mario.play_anim("mario-death-on-stomach")
				1: _mario.play_anim("mario-death-standing")
				-1: _mario.play_anim("mario-death-standing")
				-2: _mario.play_anim("mario-death-on-back")
				-3: _mario.play_anim("mario-death-on-back")
		_:
			_mario.play_anim("mario-death-standing")
	_mario.play_mario_sound(_mario.SOUND_DIE)

func _update(delta : float):
	if _mario.anim_at_end():
		get_tree().quit()