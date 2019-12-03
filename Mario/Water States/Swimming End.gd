extends WaterState

func _enter():
	action_timer = 0
	_mario.play_anim("mario-swim-2")

func _update(delta : float):
	if action_timer >= 15:
		return "water idle"
	
	if Input.is_action_pressed("jump") and action_timer >= 7:
		if action_timer == 7 and _mario.terminal_swim_speed < 280:
			_mario.terminal_swim_speed += 10
		return "breaststroke"
	
	if action_timer >= 7:
		_mario.terminal_swim_speed = 160
	
	action_timer += 1
	
	_mario.forward_velocity -= 0.25
	common_swimming_step(_mario.terminal_swim_speed);
