extends Spatial

onready var camera := $Node/Camera
var prev_transform : Transform
var transition := 1.0

var direction : Vector3 setget , get_direction
var state : String setget , get_state

func _init():
	Global.camera = self
	set_process_priority(6)

func _ready():
	$FSM.call_deferred("_update", 1.0)
	camera.transform = self.transform

func _process(delta : float) -> void:
	$FSM._update(delta)
	
	var new_transform = prev_transform.interpolate_with(self.transform, transition)
	camera.transform = camera.transform.interpolate_with(new_transform, 0.4)

func set_camera(state : String, duration := 0) -> void:
	$FSM.change_state(state)
	prev_transform = camera.transform
	
	$Tween.interpolate_property(self, "transition", 0.0, 1.0, duration, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()

func get_direction() -> Vector3:
	return global_transform.basis.z

func get_state() -> String:
	return $FSM.active_state

#func get_internal_velocity() -> Vector3:
#	var point_a : Vector3 = camera.transform.xform(Vector3())
#	var point_b : Vector3 = transform.xform(Vector3())
#	return point_a - point_b