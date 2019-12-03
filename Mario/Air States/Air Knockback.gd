extends AirState

var wall_kick_timer := 0

var dir := 1

func _enter() -> void:
	_mario.rotation.y = _mario.face_angle.y
	if dir < 0:
		_mario.play_anim("mario-backward-air-kb")
	else:
		_mario.play_anim("mario-forward-air-kb")
	_mario.peak_height = _mario.translation.y

func _update(delta : float):
	if wall_kick_timer != 0:
		if Input.is_action_just_pressed("jump"):
			_mario.set_forward_velocity(-_mario.forward_velocity)
			return "wall kick"
		wall_kick_timer -= 1
	
	var action = action_knockback(2 * sign(dir), 16.0 * sign(dir))
	if action and action == "landing":
		_mario.play_mario_sound(_mario.SOUND_OOF)
	return action

func _exit() -> void:
	wall_kick_timer = 0