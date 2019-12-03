extends StationaryState

var _previous_state : String

func _enter() -> void:
	if _previous_state == "landing":
		return
	elif _previous_state == "crouch slide":
		return
	else:
		_mario.play_anim("mario-start-crouch")

func _update(delta : float):
	if should_begin_sliding():
		return "sliding"
	
	if _mario.anim_player.current_animation == "mario-crouch" and not Input.is_action_pressed("crouch"):
		return "idle"
	elif Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("crouch"):
			return set_jumping_state("backflip")
	
	stationary_ground_step()
	
	if _mario.anim_at_end():
		_mario.play_anim("mario-crouch")
