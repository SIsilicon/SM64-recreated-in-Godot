extends Node

var _camera

var mario_pos : Vector3
var rel_pos : Vector3
var time : float

var zooming_in : bool

func _enter() -> void:
	mario_pos = Global.mario.translation + Vector3.UP * 1.2
	rel_pos = _camera.translation - mario_pos
	rel_pos = rel_pos * Vector3(1, 0, 1) + Vector3.UP * 2.0
	time = 0.0
	zooming_in = false

func _update(delta : float):
	if time < 1.5:
		rel_pos.y -= delta * 2.0
	if time > 1.5 and not zooming_in:
		_camera.unsteadiness = 1.0
		$"../../Tween".interpolate_property(self, "rel_pos", rel_pos, rel_pos.normalized() * 2.0 + Vector3.DOWN * 0.4, 0.5, Tween.TRANS_ELASTIC, Tween.EASE_OUT)
		$"../../Tween".start()
		zooming_in = true
	
	_camera.translation = rel_pos + mario_pos
	_camera.look_at(mario_pos, Vector3.UP)
	time += delta
	
	if time > 4.0:
		get_tree().quit()

func _exit() -> void:
	_camera.unsteadiness = 0.0