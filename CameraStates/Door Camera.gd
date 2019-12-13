extends Node

var _camera

var position : Vector3

func _enter() -> void:
	position = _camera.translation

func _update(delta : float):
	_camera.translation = position
	var mario = Global.mario
	
	_camera.look_at(mario.translation + Vector3(0, 1.2, 0), Vector3.UP)
	
	if position.distance_to(mario.translation) > 5.0:
		return "open camera"
