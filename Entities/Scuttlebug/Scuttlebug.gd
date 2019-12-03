tool
extends Entity

var is_alert
var alert_timer

func _ready() -> void:
	var hair_res = 5
	var hair_length = 0.03
	var hair_step = hair_length / hair_res
	
	var mat : SpatialMaterial = $"Scuttlebug-rig/Skeleton/Scuttlebug".mesh.surface_get_material(0)
	for i in hair_res:
		var hair_layer := preload("Scuttlebug_hair.material").duplicate()
		hair_layer.set_shader_param("grow", i * hair_step + hair_step)
		hair_layer.set_shader_param("max_length", hair_length)
		mat.render_priority = i - hair_res
		mat.next_pass = hair_layer
		mat = hair_layer
	
	$AnimationPlayer.play("Scuttlebug-idle")
	home = translation
	
	set_process(not Engine.editor_hint)

func _process(delta : float) -> void:
	
	if velocity.y == 26:
		breakpoint
	
	update_floor_and_walls()
	if state != 0 and false:
#        && obj_set_hitbox_and_die_if_attacked(&sScuttlebugHitbox, SOUND_OBJ_DYING_ENEMY1,
#                                              ScuttlebugUnkF4))
		state = 3
	if state != 1:
       is_alert = 0
	match state:
		0:
			if move_flags & 1:
				pass #PlaySound2(SOUND_OBJ_GOOMBA_ALERT)
			if move_flags & 3:
				home = translation
				state += 1
		1:
			forward_velocity = 5.0
			if lateral_dist_from_mario_to_home() > 10.0:
				angle_to_mario = angle_to_home()
			else:
				if is_alert == 0:
					alert_timer = 0
					angle_to_mario = angle_to_object(self, Global.mario)
					if abs(Utils.angle_diff(angle_to_mario, move_angle_yaw)) < deg2rad(11.25):
						is_alert = 1
						velocity.y = 20.0
#						PlaySound2(SOUND_OBJ2_SCUTTLEBUG_ALERT)
				elif is_alert == 1:
					forward_velocity = 15.0
					alert_timer += 1
					if alert_timer > 50:
						is_alert = 0
			
			if move_flags & OBJ_MOVE_HIT_WALL:
				angle_to_mario = wall_angle
				state = 2
			elif move_flags & OBJ_MOVE_HIT_EDGE:
				angle_to_mario = move_angle_yaw + PI
				state = 2
			rotate_yaw_toward(angle_to_mario, deg2rad(2.8125))
		2:
			forward_velocity = 5.0
			if Utils.angle_diff(move_angle_yaw, angle_to_mario) == 0:
				state = 1
			if translation.y - home.y < -2.0:
				queue_free()
			rotate_yaw_toward(angle_to_mario, deg2rad(5.625))
		3:
#			Flags &= ~8
			forward_velocity = -10.0
			velocity.y = 30.0
#			PlaySound2(SOUND_OBJ2_SCUTTLEBUG_ALERT)
			state += 1
		4:
			forward_velocity = -10.0
			if move_flags & 1:
				state += 1
				velocity.y = 0.0
				alert_timer = 0
#				Flags |= 8
#				InteractStatus = 0
		5:
			forward_velocity = 2.0
			alert_timer += 1
			if alert_timer > 30:
				state = 0
	
	if move_flags & 3:
		$AnimationPlayer.play("Scuttlebug-walk")
	
	move_standard(-50)
	rotation.y = move_angle_yaw

func _on_body_entered(body : Node) -> void:
	if not Engine.editor_hint:
		if body is Mario:
			if body.is_in_air() and body.velocity.y < 0.0 and body.translation.y > translation.y:
				body.velocity.y = 42.0
				body.jumped_on_entity = true
			elif body.is_in_air() and body.velocity.y > 0.0 and body.translation.y < translation.y:
				body.velocity.y = 0.0
				body.jumped_on_entity = true
			else:
				body.hurt(4, translation)

func get_wall_collide_radius() -> float:
	return $CollisionShape.shape.radius