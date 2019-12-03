extends Spatial

var direction := Vector3(0, 1, 0)
var moving = false

func _process(delta : float) -> void:
	set_process_priority(-10)
	if $Area.get_overlapping_bodies().size() > 0:
		moving = true
	
	translation += direction * int(moving) * 0.1

func _on_Area_body_entered(body):
	pass # Replace with function body.
