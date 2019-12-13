extends Node

var _camera

var yaw : float
var dist := 4.0

func _enter() -> void:
	var dir_to_mario = _camera.translation.direction_to(Global.mario.translation) * Vector3(1, 0, 1)
	yaw = atan2(dir_to_mario.x, dir_to_mario.z)
	_camera.unsteadiness = 1.0

func _update(delta : float):
	_camera.translation = (Vector3.FORWARD * dist).rotated(Vector3.UP, yaw)
	_camera.translation += Global.mario.translation + Vector3(0, 4, 0)
	_camera.look_at(Global.mario.translation, Vector3.UP)

func _exit() -> void:
	_camera.unsteadiness = 0.0