extends Area

export var glow_opacity = 0.0 setget set_glow_opacity

func _on_body_entered(body : Spatial) -> void:
	if body is Mario:
		body.get_node("FSM").change_state("star fall")
		body.star = self
		$AnimationPlayer.play("collect")
		$AudioStreamPlayer3D.play()

func set_glow_opacity(value : float) -> void:
	glow_opacity = value
	if get_node_or_null("Sprite3D"):
		$Sprite3D.material_override.set_shader_param("color", Color(0.79, 0.76, 0.54, value))

func _on_animation_started(anim_name : String) -> void:
	if anim_name == "star dance":
		$AnimationPlayer.playback_speed = 0.8
	else:
		$AnimationPlayer.playback_speed = 1.0
