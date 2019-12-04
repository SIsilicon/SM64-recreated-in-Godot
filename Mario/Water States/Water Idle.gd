extends WaterState

func _enter() -> void:
	_mario.play_anim("mario-water-action-end")

func _update(delta : float):
	
#    if (m->flags & MARIO_METAL_CAP) {
#        return set_mario_action(m, ACT_METAL_WATER_FALLING, 1);
#    }
	
	if Input.is_action_just_pressed("punch"):
		return "water punch"
	
	if Input.is_action_just_pressed("jump"):
		return "breaststroke"
	
	var val := 3.0 if _mario.face_angle.x < -deg2rad(22.5) else 1.0
	
	common_idle_step()
	
	if _mario.anim_at_end():
		_mario.play_anim("mario-in-water")