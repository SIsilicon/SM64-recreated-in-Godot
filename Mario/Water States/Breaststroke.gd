extends WaterState

var action_state = 0

func _enter() -> void:
	_mario.play_anim("mario-swim-1")
	action_state = 0
	action_timer = 0

func _update(delta : float):
	_mario.terminal_swim_speed = 160
	
#    if (m->flags & MARIO_METAL_CAP) {
#        return set_mario_action(m, ACT_METAL_WATER_FALLING, 1);
#    }
#
	
	if Input.is_action_just_pressed("punch"):
		return "water punch"
	
	action_timer += 1
	if action_timer == 14:
		return "flutter kick"
	
	if check_water_jump():
		return "water jump"
	
	if action_timer < 6:
		_mario.forward_velocity += 0.5
	if action_timer >= 9:
		_mario.forward_velocity += 1.5
	
	if action_timer >= 2:
		if action_timer < 6 and Input.is_action_just_pressed("jump"):
			action_state = 1
		
		if action_timer == 9 and action_state == 1:
			_mario.anim_player.seek(0.0, true)
			action_state = 0
			action_timer = 1
			_mario.terminal_swim_speed = 160
	
#    if (m->actionTimer == 1) {
#        play_sound(D_8032CDD4 == 160 ? SOUND_ACTION_UNKNOWN433 : SOUND_ACTION_UNKNOWN447,
#                   m->marioObj->header.gfx.cameraToObject);
#        func_8027107C(m);
#    }
	
	common_swimming_step(_mario.terminal_swim_speed)
