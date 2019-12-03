extends AudioStreamPlayer3D
class_name SoundParticle

func _init(stream : AudioStream, position : Vector3, volume := 1.0, offset := 0.0) -> void:
	self.stream = stream
	self.unit_db = linear2db(volume)
	translation = position
	call_deferred("play", offset)
	connect("finished", self, "_on_Sound_Particle_finished")

func _on_Sound_Particle_finished():
	queue_free()
