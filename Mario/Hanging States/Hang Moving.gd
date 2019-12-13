extends HangingState

var _previous_state : String
var is_left : bool

func _enter() -> void:
	is_left = _fsm.get_node_by_state(_previous_state).is_left
	_mario.play_anim("mario-swinging-left-arm" if is_left else "mario-swinging-right-arm")

func _update(delta : float):
	if not Input.is_action_pressed("jump"):
		return "free falling"
	
	if Input.is_action_just_pressed("crouch"):
		return "ground pound"
	
	if _mario.ceil_surf.type != Surface.SURFACE_HANGABLE:
		return "free falling"
	
	if _mario.anim_at_end():
		is_left = not is_left
		return "hanging"
	
	if update_hang_moving() == HANG_LEFT_CEIL:
		_fsm.change_state("free falling")

func _to_free_falling() -> void:
	Global.camera.set_camera("open camera", 1.0)

func _to_ground_pound() -> void:
	Global.camera.set_camera("open camera", 1.0)

func get_flags() -> int:
	return ACT_FLAG_MOVING | ACT_FLAG_HANGING
