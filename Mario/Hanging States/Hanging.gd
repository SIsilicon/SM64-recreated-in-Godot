extends HangingState

var _previous_state : String

var is_left : bool

func _enter() -> void:
	if _previous_state == "hang moving":
		is_left = _fsm.get_node_by_state(_previous_state).is_left
	else:
		is_left = true

func _update(delta : float):
	
	if _mario.intended_mag > 0:
		return "hang moving"
	
	if not Input.is_action_pressed("jump"):
		return "free falling"
	
	if Input.is_action_just_pressed("crouch"):
		return "ground pound"
	
	if _mario.ceil_surf.type != Surface.SURFACE_HANGABLE:
		return "free falling"
	
#    if (m->actionArg & 1) {
#        set_mario_animation(m, MARIO_ANIM_HANDSTAND_LEFT);
#    } else {
#        set_mario_animation(m, MARIO_ANIM_HANDSTAND_RIGHT);
#    }
	
	update_hang_stationary()

func _to_free_falling() -> void:
	Global.camera.set_camera("open camera", 1.0)

func _to_ground_pound() -> void:
	Global.camera.set_camera("open camera", 1.0)

func get_flags() -> int:
	return ACT_FLAG_STATIONARY | ACT_FLAG_HANGING
