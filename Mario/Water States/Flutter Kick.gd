extends WaterState

func _enter() -> void:
	_mario.play_anim("mario-flutterkick")
	_mario.anim_player.seek(0.25)
	action_timer = 0

func _update(delta : float):
	
	if Input.is_action_just_pressed("punch"):
		return "water punch"
	
	if not Input.is_action_pressed("jump"):
		if action_timer == 0 and _mario.terminal_swim_speed < 280:
			_mario.terminal_swim_speed
		return "swimming end"
	
	_mario.forward_velocity = Utils.approach_signed(_mario.forward_velocity, 12.0, 0.1, 0.15)
	action_timer = 1
	
	_mario.terminal_swim_speed = 160
	if _mario.forward_velocity < 14.0:
		pass #func_802713A8(m);
	
	common_swimming_step(160)