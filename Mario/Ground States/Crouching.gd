extends StationaryState

var _previous_state : String
var start_crawling : bool

func _enter() -> void:
	start_crawling = false
	match _previous_state:
		"landing":
			return
		"crouch slide":
			return
		"slide kick slide":
			_mario.play_anim("mario-stop-slide-kick")
		"crawling":
			_mario.play_anim("mario-stop-crawling")
		_:
			_mario.play_anim("mario-start-crouch")

func _update(delta : float):
	if should_begin_sliding():
		return "sliding"
	
	if _mario.anim_player.current_animation == "mario-crouch" and not Input.is_action_pressed("crouch"):
		return "idle"
	elif Input.is_action_just_pressed("jump"):
		if Input.is_action_pressed("crouch"):
			return set_jumping_state("backflip")
	
	if _mario.intended_mag > 0 and _mario.anim_player.current_animation == "mario-crouch":
		start_crawling = true
		_mario.play_anim("mario-start-crawling")
	
	if _mario.anim_at_end() and start_crawling:
		return "crawling"
	
	stationary_ground_step()
	
	if _mario.anim_at_end():
		_mario.play_anim("mario-crouch")

func get_flags() -> int:
	return ACT_FLAG_STATIONARY | ACT_FLAG_SHORT_HITBOX | ACT_FLAG_ALLOW_FIRST_PERSON | ACT_FLAG_PAUSE_EXIT