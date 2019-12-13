extends GroundState

var _previous_state : String

var is_butt_slide : bool
var stop_animation : String

func _enter() -> void:
	is_butt_slide = _mario.facing_downhill()
	if _previous_state == "dive":
		is_butt_slide = false
	
	if is_butt_slide:
		stop_animation = "mario-stop-sliding"
		_mario.play_anim("mario-sliding")
	else:
		stop_animation = "mario-stop-diving"
		if _mario.anim_player.current_animation != "mario-dive":
			_mario.play_anim("mario-dive-slide")
	_mario.start_slide_sound()

func _update(delta : float):
	if action_timer >= 5:
		if not _mario.above_slide and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("punch")):
			_fsm.get_node_by_state("rollout").is_backward = _mario.forward_velocity <= 0
			_fsm.change_state(set_jumping_state("jump") if is_butt_slide else "rollout")
	else:
		action_timer += 1
	
	if update_sliding(4.0):
		return "idle"
	
	common_sliding_movement("idle")

func _exit():
	_mario.rotation.x = 0
	_mario.rotation.z = 0
	_mario.stop_slide_sound()

func get_flags() -> int:
	var flags = ACT_FLAG_MOVING | ACT_FLAG_BUTT_OR_STOMACH_SLIDE | ACT_FLAG_ATTACKING
	if not is_butt_slide:
		flags |= ACT_FLAG_DIVING
	
	return flags
