extends Area

var prev_mario_behind := false

func is_behind_door(pos : Vector3) -> bool:
	var local_pos : Vector3 = global_transform.xform_inv(pos)
	return local_pos.z > 0

func _on_body_entered(body : Spatial) -> void:
	prev_mario_behind = is_behind_door(body.translation)

func _on_body_exited(body : Spatial) -> void:
	var mario_behind = is_behind_door(body.translation)
	
	if mario_behind != prev_mario_behind:
		var cam_transform = global_transform
		cam_transform = cam_transform.translated(Vector3.UP * 1.3)
		cam_transform = cam_transform.translated(Vector3.FORWARD * (-0.2 if mario_behind else 0.2))
		
		Global.camera.teleport(cam_transform)
		Global.camera.set_camera("door camera", 0.0)
