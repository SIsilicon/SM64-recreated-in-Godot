extends Node

var _camera

var yaw : float

func _enter() -> void:
	yaw = Global.mario.rotation.y

func _update(delta : float):
	Collisions.push_collision_mask(Collisions.COLLISION_CAMERA)
	
	var prev_translation : Vector3 = _camera.translation
	
	var target_pos := Global.mario.translation
	
	target_pos.y = Global.mario.water_level
	_camera.translation.y = target_pos.y + 0.8
	
	yaw = Utils.angle_lerp(yaw, Global.mario.rotation.y, 0.3)
	
#	var dir_to_target := target_pos.direction_to(_camera.translation)
#	dir_to_target = dir_to_target.rotated(Vector3.UP, yaw - atan2(dir_to_target.x, dir_to_target.z))
#
#	var dist_to_target := target_pos.distance_to(_camera.translation)
#
#	if dist_to_target > 8.0:
#		_camera.translation += dir_to_target * (8.0 - dist_to_target)
#
	_camera.translation = target_pos + Vector3(0, 1.2, -5).rotated(Vector3.UP, yaw)
	
	target_pos.y = max(Global.mario.translation.y, target_pos.y)
	_camera.look_at(target_pos, Vector3.UP)
	
	var step = prev_translation
	for i in 4:
		step += (_camera.translation - prev_translation) * 0.25
		var floor_data := Collisions.find_floor(step)
		if floor_data.floor and _camera.translation.y < floor_data.height + 0.2:
			_camera.translation.y = floor_data.height + 0.2
	
	Collisions.pop_collision_mask()