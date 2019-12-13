extends AirState

func _enter() -> void:
	_mario.set_forward_velocity(0.0)
	_mario.play_anim("mario-freefall")

func _update(delta : float):
#	if (m->pos[1] < m->waterLevel - 130) {
#		play_sound(SOUND_ACTION_UNKNOWN430, m->marioObj->header.gfx.cameraToObject);
#		m->particleFlags |= PARTICLE_6;
#		return set_mario_action(m, ACT_STAR_DANCE_WATER, m->actionArg);
	
	if perform_air_q_steps(1) == AIR_STEP_LANDED:
		Global.camera.set_camera("star camera", 0.5)
		_mario.play_step_sound()
		_fsm.change_state("star dance")

func get_flags() -> int:
	return ACT_FLAG_AIR | ACT_FLAG_INVULNERABLE 