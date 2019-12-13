extends HangingState

func _enter() -> void:
	Global.camera.set_camera("hanging camera", 1.0)
	
	action_timer = 0
	_mario.play_anim("mario-start-hanging")

func _update(delta : float):
	action_timer += 1
	
	if _mario.intended_mag > 0 and action_timer >= 31:
		return "hanging"
	
	if not Input.is_action_pressed("jump"):
		return "free falling"
	
	if Input.is_action_just_pressed("crouch"):
		return "ground pound"
	
	if _mario.ceil_surf.type != Surface.SURFACE_HANGABLE:
		return "free falling"
	
	update_hang_stationary()
	
	if _mario.anim_at_end():
		_fsm.change_state("hanging")

func _to_free_falling() -> void:
	Global.camera.set_camera("open camera", 1.0)

func _to_ground_pound() -> void:
	Global.camera.set_camera("open camera", 1.0)

func get_flags() -> int:
	return ACT_FLAG_STATIONARY | ACT_FLAG_HANGING | ACT_FLAG_PAUSE_EXIT