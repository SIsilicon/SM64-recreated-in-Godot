extends AirState

func _enter() -> void:
	_mario.rotation.x = 0
	_mario.rotation.z = 0
	
	_mario.play_anim("mario-jump")
	match randi() % 3:
		0: _mario.play_mario_sound(_mario.SOUND_WA)
		1: _mario.play_mario_sound(_mario.SOUND_WOO)
		2: _mario.play_mario_sound(_mario.SOUND_YA)

func _update(delta : float):
	if _mario.forward_velocity < 15.0:
		_mario.set_forward_velocity(15.0)
	
	match perform_air_q_steps(AIR_CHECK_LEDGE_GRAB):
		AIR_STEP_LANDED:
			Global.camera.set_camera("open camera", 0.5)
			return "landing"
		AIR_STEP_HIT_WALL:
			_mario.set_forward_velocity(15.0)
		AIR_STEP_GRABBED_LEDGE:
			Global.camera.set_camera("open camera", 0.5)
			return "ledge grab"

func get_flags() -> int:
	return ACT_FLAG_AIR