extends Spatial
class_name Mario

# Sound constants
const SOUND_DIE = preload("res://Assets/Sounds/Mario Voices/mario-die.wav")
const SOUND_DOH = preload("res://Assets/Sounds/Mario Voices/mario-doh.wav")
const SOUND_HAHA = preload("res://Assets/Sounds/Mario Voices/mario-haha.wav")
const SOUND_HOO = preload("res://Assets/Sounds/Mario Voices/mario-hoo.wav")
const SOUND_OOF = preload("res://Assets/Sounds/Mario Voices/mario-oof.wav")
const SOUND_SCREAM = preload("res://Assets/Sounds/Mario Voices/mario-scream.wav")
const SOUND_PAIN = preload("res://Assets/Sounds/Mario Voices/mario-pain.wav")
const SOUND_WOO = preload("res://Assets/Sounds/Mario Voices/mario-woo.wav")
const SOUND_UGH = preload("res://Assets/Sounds/Mario Voices/mario-ugh.wav")
const SOUND_UNGH = preload("res://Assets/Sounds/Mario Voices/mario-ungh.wav")
const SOUND_YAHOO = preload("res://Assets/Sounds/Mario Voices/mario-yahoo.wav")
const SOUND_WOOHOO = preload("res://Assets/Sounds/Mario Voices/mario-woohoo.wav")
const SOUND_PULLUP = preload("res://Assets/Sounds/Mario Voices/mario-pullup.wav")
const SOUND_WA = preload("res://Assets/Sounds/Mario Voices/mario-wa.wav")
const SOUND_YA = preload("res://Assets/Sounds/Mario Voices/mario-ya.wav")
const SOUND_WAHA = preload("res://Assets/Sounds/Mario Voices/mario-waha.wav")
const SOUND_WHOA = preload("res://Assets/Sounds/Mario Voices/mario-whoa.wav")

# Movement variables
var face_angle := Vector3()
var forward_velocity := 0.0
var slide_yaw := 0.0
var slide_vel_x := 0.0
var slide_vel_z := 0.0
var velocity := Vector3()
var ang_velocity := Vector3()
var terminal_swim_speed := 160.0

# Animation variables
var anim_length : float
var anim_backwards : bool
onready var anim_player := $AnimationPlayer
onready var skeleton := $"Mario-rig"
var screamed := false

# Health variables
var health := 0x0880
var health_inc := 0
var health_dec := 0
var got_hurt := false

# Control stick variables
var stick_dir : Vector2 setget , get_stick_dir
var intended_mag : float
var intended_yaw : float

# Collision variables
var floor_surf : Surface
var floor_height : float
var floor_angle : float
var ceil_surf : Surface
var ceil_height : float
var wall_surf : Surface
var water_level : float

# Mario variables
var state : String setget , get_state
var last_air_state : String
var double_jump_timer : int
var peak_height : float
var squished := 0
var above_slide := false
var off_floor := false
var in_water := false
var jumped_on_entity := false

var star

# Debug variables
var debug_velocity_multiplier = 1
var debug_state_switch_count = 0

func _ready():
	Global.mario = self
	anim_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_MANUAL
	
	face_angle = rotation
	
	for state in $FSM.states:
		var node : Node = $FSM.states[state].values()[0]
		if node.get_flags() == 0:
			prints(state, "has no flags!")
	
	setup_materials()

func _process(delta : float) -> void:
	face_angle.y = wrapf(face_angle.y, -PI, PI)
	update_velocity()
	get_input_direction()
	
	Collisions.push_collision_mask(Collisions.COLLISION_STATIC | Collisions.COLLISION_DYNAMIC | Collisions.COLLISION_ENTITY)
	
	var gas_level : float
	var ceil_to_floor_dist : float
	
	var pos_dict := {"vec": translation}
	resolve_and_return_wall_collisions(pos_dict, 0.3, 0.24)
	resolve_and_return_wall_collisions(pos_dict, 0.6, 0.50)
	translation = pos_dict.vec
	
	var _floor = Collisions.find_floor(translation)
	
	var ceil_height := find_ceil(translation, _floor.height)
#    gas_level = find_poison_gas_level(pos[0], pos[2])
	water_level = Collisions.find_water_level(translation)
	
	if _floor.floor:
		floor_surf = _floor.floor
		floor_height = _floor.height
		floor_angle = atan2(floor_surf.normal.x, floor_surf.normal.z)
		
		above_slide = translation.y > water_level - 40.0 and floor_is_slippery()
		
		if floor_surf.is_dynamic() \
			or (ceil_surf and ceil_surf.is_dynamic()):
			ceil_to_floor_dist = ceil_height - floor_height
			
#			squished = 0.0 <= ceil_to_floor_dist and ceil_to_floor_dist <= 1.5
		
		
		off_floor = translation.y > floor_height + 1.0
		
		if is_on_ground():
			translation += floor_surf.get_transform_delta(translation) * delta
		
		in_water = translation.y < water_level - 0.1
		
		if not is_underwater() and translation.y < water_level - 1.0:
			plunge_into_water()
		elif is_underwater():
			if translation.y > water_level - 0.8:
				if water_level - 0.8 > floor_height:
					translation.y = water_level - 0.8
				else:
					transition_submerged_to_walking()
			
#			if health < 0x100 && !(action & (ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE))) {
#				set_mario_action(m, ACT_DROWNING, 0);
		
		
#		in_poison_gas = translation.y < gas_level - 1.0
		
		if floor_surf.type == Surface.SURFACE_DEATH_PLANE and translation.y - floor_height < 20.48:
			# Mario fell to his death! This is the app's response for now.
			get_tree().quit()
		
	else:
		breakpoint #level_trigger_warp(m, WARP_OP_DEATH)
	
	if Input.is_key_pressed(KEY_Q):
		velocity.y = 20
	debug_state_switch_count = 0
	anim_player.playback_speed = 1.0
	
	$FSM._update(delta)
	
	if double_jump_timer != 0:
		double_jump_timer -= 1
	
	if is_underwater():
		if translation.y >= water_level - 1.4:
			health += 0x1A
		else:
			health -= 1

	health += 64 * int(health_inc > 0)
	health -= 64 * int(health_dec > 0)
	health = clamp(health, 0x00ff, 0x0880)
	health_inc -= int(health_inc > 0)
	health_dec -= int(health_dec > 0)
	
	$AnimationPlayer.advance(1.0/30.0)
	update_face()
	$SquishAnimation.current_animation = "Squish"
	$SquishAnimation.seek(squished / 30.0, true)
	squished = max(squished - 1, 0)
	
	if self.state != "ground knockback" and self.state != "death":
		if $FSM.get_node_by_state(self.state).has_method("is_ground_state") and health == 0x00FF:
			$FSM.change_state("death")
	
	Collisions.pop_collision_mask()

func setup_materials() -> void:
	for mesh_inst in skeleton.get_children():
		for m in mesh_inst.get_surface_material_count():
			var material : Material = mesh_inst.mesh.surface_get_material(m)
			material.next_pass = preload("res://Mario/Mario Sillhouette.tres")
			
			if not material is ShaderMaterial and false:
				var metal : SpatialMaterial = material.duplicate()
				
				metal.albedo_texture = null
				metal.metallic = 1.0
				metal.metallic_texture = null
				metal.roughness = 0.5
				metal.roughness_texture = null
				metal.emission_enabled = false
				
				mesh_inst.set_surface_material(m, metal)

func update_face() -> void:
	skeleton.get_node("Mario-hair").visible = false
	skeleton.get_node("Mario-right-closed-eyelid").visible = false
	skeleton.get_node("Mario-left-closed-eyelid").visible = false
	skeleton.get_node("Mario-right-eyelid").visible = false
	skeleton.get_node("Mario-left-eyelid").visible = false
	
	# Jaw
	skeleton.set_bone_custom_pose(31, Transform().rotated(Vector3.RIGHT, deg2rad(12.0)))
	
	if self.state == "star dance":
		skeleton.set_bone_custom_pose(31, Transform())

func reset_custom_poses() -> void:
	for i in skeleton.get_bone_count():
		skeleton.set_bone_custom_pose(i, Transform())

func update_velocity() -> Vector3:
	velocity.x = forward_velocity * sin(face_angle.y)
	velocity.z = forward_velocity * cos(face_angle.y)
	return velocity

func get_stick_dir() -> Vector2:
	var dir := Vector2()
	if Input.is_action_pressed("move_left"):
		dir.x -= 64
	if Input.is_action_pressed("move_right"):
		dir.x += 64
	if Input.is_action_pressed("move_up"):
		dir.y += 64
	if Input.is_action_pressed("move_down"):
		dir.y -= 64
	
	if dir.length() > 64:
		dir = dir.normalized() * 64
	
	return dir

func get_input_direction() -> Vector2:
	var dir := get_stick_dir()
	
	dir /= 2.0 if squished == 0 else 8.0
	
	intended_mag = dir.length()
	
	intended_mag *= debug_velocity_multiplier
	
	if intended_mag > 0:
		intended_yaw = wrapf(dir.angle() + get_viewport().get_camera().global_transform.basis.get_euler().y + PI/2, -PI, PI)
		Input.action_press("analog", intended_mag)
	else:
		intended_yaw = face_angle.y
		Input.action_release("analog")
	
	return dir

func analog_held_back() -> bool:
	return abs(Utils.angle_diff(intended_yaw, face_angle.y)) > 1.8

func set_forward_velocity(vel : float) -> void:
	forward_velocity = vel
	
	slide_vel_x = sin(face_angle.y) * forward_velocity
	slide_vel_z = cos(face_angle.y) * forward_velocity
	
	velocity.x = slide_vel_x
	velocity.z = slide_vel_z

func hurt(damage : int, pos : Vector3) -> void:
	if not got_hurt:
		var rel_pos = translation - pos
		var dir = transform.basis.z.dot(rel_pos)
		var angle = Vector2(rel_pos.x, rel_pos.z).angle_to(Vector2.UP)
		
		got_hurt = true
		health_dec = damage
		
		forward_velocity = 16.0 * sign(dir)
		face_angle.y = Utils.angle_diff(angle, (0.5 * sign(-forward_velocity) - 0.5) * PI)
		rotation.y = face_angle.y
		$FSM.get_node_by_state("ground knockback").knockback_strength = int((2 if damage > 4 else 1) * sign(dir))
		$FSM.change_state("ground knockback")

func is_attacking(target : Vector3) -> bool:
	var state := self.state
	if state == "punch" || state == "air kick":
		if $FSM.get_node_by_state(state).attack_window_open:
			var vec_to_target := ((target - translation) * Vector3(1, 0, 1)).normalized()
			var angle_to_target := atan2(vec_to_target.x, vec_to_target.z)
			
			if abs(Utils.angle_diff(angle_to_target, face_angle.y)) < PI/4:
				return true
	elif $FSM.get_node_by_state(state).get_flags() & State.ACT_FLAG_ATTACKING:
		return true
	
	return false

func is_in_air() -> bool:
	return $FSM.get_node_by_state(self.state).has_method("is_air_state")

func is_on_ground() -> bool:
	return $FSM.get_node_by_state(self.state).has_method("is_ground_state")

func is_stationary() -> bool:
	return $FSM.get_node_by_state(self.state).has_method("is_stationary_state")

func is_underwater() -> bool:
	return $FSM.get_node_by_state(self.state).has_method("is_underwater_state")

func is_diving() -> bool:
	var state : String = self.state
	return state == "sliding" or state == "dive"

func get_state() -> String:
	return $FSM.active_state

func get_state_node() -> Node:
	return $FSM.get_node_by_state(get_state())

func get_floor_class() -> int:
	var floor_class := Surface.SURFACE_CLASS_DEFAULT
	
	if floor_surf:
		match floor_surf.type:
			Surface.SURFACE_NOT_SLIPPERY: floor_class = Surface.SURFACE_CLASS_NOT_SLIPPERY
			Surface.SURFACE_HARD_NOT_SLIPPERY: floor_class = Surface.SURFACE_CLASS_NOT_SLIPPERY
			Surface.SURFACE_SWITCH: floor_class = Surface.SURFACE_CLASS_NOT_SLIPPERY
			
			Surface.SURFACE_SLIPPERY: floor_class = Surface.SURFACE_CLASS_SLIPPERY
			Surface.SURFACE_NOISE_SLIPPERY: floor_class = Surface.SURFACE_CLASS_SLIPPERY
			Surface.SURFACE_HARD_SLIPPERY: floor_class = Surface.SURFACE_CLASS_SLIPPERY
#			Surface.SURFACE_NO_CAM_COL_SLIPPERY:
			
			Surface.SURFACE_VERY_SLIPPERY: floor_class = Surface.SURFACE_CLASS_VERY_SLIPPERY
#			Surface.SURFACE_ICE: continue
			Surface.SURFACE_HARD_VERY_SLIPPERY: floor_class = Surface.SURFACE_CLASS_VERY_SLIPPERY
#			Surface.SURFACE_NOISE_VERY_SLIPPERY_73: continue
#			Surface.SURFACE_NOISE_VERY_SLIPPERY_74: continue
			Surface.SURFACE_NOISE_VERY_SLIPPERY: floor_class = Surface.SURFACE_CLASS_VERY_SLIPPERY
#			Surface.SURFACE_NO_CAM_COL_VERY_SLIPPERY:
		
		if self.state == "crawling" and floor_surf.normal.y > 0.5 and floor_class == Surface.SURFACE_CLASS_DEFAULT:
			floor_class = Surface.SURFACE_CLASS_NOT_SLIPPERY
	
	return floor_class

func facing_downhill() -> bool:
	var face_angle_yaw = Utils.angle_diff(face_angle.y, floor_angle)
	return -PI/2 < face_angle_yaw and face_angle_yaw < PI/2

func floor_is_slope() -> bool:
	var norm_y := 0.99999
	
	match get_floor_class():
		Surface.SURFACE_CLASS_VERY_SLIPPERY:
			norm_y = 0.9961947
		Surface.SURFACE_CLASS_SLIPPERY:
			norm_y = 0.9848077
		Surface.SURFACE_CLASS_DEFAULT:
			norm_y = 0.9659258
		Surface.SURFACE_CLASS_NOT_SLIPPERY:
			norm_y = 0.9396926
	
	return floor_surf.normal.y <= norm_y

func floor_is_slippery() -> bool:
	var norm_y := 0.99999
	
	match get_floor_class():
		Surface.SURFACE_CLASS_VERY_SLIPPERY:
			norm_y = 0.9848077
		Surface.SURFACE_CLASS_SLIPPERY:
			norm_y = 0.9396926
		Surface.SURFACE_CLASS_DEFAULT:
			norm_y = 0.7880108
		Surface.SURFACE_CLASS_NOT_SLIPPERY:
			norm_y = 0.0
	
	return floor_surf.normal.y <= norm_y

func floor_is_steep() -> bool:
	var norm_y := 0.99999
	
	if not facing_downhill():
		match get_floor_class():
			Surface.SURFACE_CLASS_VERY_SLIPPERY:
				norm_y = 0.9659258
			Surface.SURFACE_CLASS_SLIPPERY:
				norm_y = 0.9396926
			Surface.SURFACE_CLASS_DEFAULT:
				norm_y = 0.8660254
			Surface.SURFACE_CLASS_NOT_SLIPPERY:
				norm_y = 0.8660254
		
		return floor_surf.normal.y <= norm_y
	else:
		return false

func find_floor_slope(offset : float) -> float:
	var x := sin(face_angle.y + offset) * 0.05
	var z := cos(face_angle.y + offset) * 0.05
	
	var forward_floor_y : float = Collisions.find_floor(translation + Vector3(x, 1.0, z)).height
	var backward_floor_y : float = Collisions.find_floor(translation + Vector3(-x, 1.0, -z)).height
	
	var forward_y_delta := forward_floor_y - translation.y
	var backward_y_delta := translation.y - backward_floor_y
	
	if forward_y_delta * forward_y_delta < backward_y_delta * backward_y_delta:
		return atan2(forward_y_delta, 5.0)
	else:
		return atan2(backward_y_delta, 5.0)

func resolve_and_return_wall_collisions(coords : Dictionary, offset : float, radius : float):
	var collisions = Collisions.find_wall_collisions(coords.vec, offset, radius)
	
	if collisions.num_walls > 0:
		coords.vec.x = collisions.x
		coords.vec.z = collisions.z
		
		return collisions.walls[collisions.num_walls - 1]

func find_ceil(coords : Vector3, height : float) -> float:
	var ceil_dict := Collisions.find_ceil(Vector3(coords.x, height + 0.8, coords.z))
	ceil_surf = ceil_dict.ceil
	
	ceil_height = ceil_dict.height
	ceil_surf = ceil_dict.ceil
	
	return ceil_dict.height

func bonk_reflection(negate_speed : bool) -> void:
	if wall_surf:
		var wall_angle := atan2(wall_surf.normal.x, wall_surf.normal.z)
		face_angle.y = Utils.angle_diff(wall_angle, Utils.angle_diff(face_angle.y, wall_angle))
	
	if negate_speed:
		set_forward_velocity(-forward_velocity)
	else:
		face_angle.y += PI
	
	face_angle.y = wrapf(face_angle.y, -PI, PI)

func plunge_into_water() -> void:
	forward_velocity = forward_velocity / 4.0
	velocity.y = velocity.y / 2.0
	translation.y = water_level - 1.0
	face_angle.z = 0.0
	ang_velocity = Vector3()
	
	if not is_diving():
		face_angle.x = 0
	
	if Global.camera.state != "above water camera":
		Global.camera.set_camera("above water camera", 1.0)
	
	$FSM.change_state("water plunge")

func transition_submerged_to_walking() -> void:
	ang_velocity = Vector3()
	
	if Global.camera.state == "above water camera":
		Global.camera.set_camera("open camera", 1.0)
	
	$FSM.change_state("running")

func play_anim(name : String, backwards := false) -> void:
	if backwards:
		$AnimationPlayer.play_backwards(name)
	else:
		$AnimationPlayer.play(name)
	anim_backwards = backwards
	anim_length = $AnimationPlayer.current_animation_length

func anim_at_end() -> bool:
	if not anim_backwards:
		return $AnimationPlayer.current_animation_position >= anim_length
	else:
		return $AnimationPlayer.current_animation_position <= 0

func play_mario_sound(sound : AudioStreamSample) -> void:
	if get_mario_sound_priority(sound) >= get_mario_sound_priority($VoicePlayer.stream) or not $VoicePlayer.playing:
		$VoicePlayer.stream = sound
		$VoicePlayer.play(0.1)

func get_mario_sound_priority(sound : AudioStreamSample) -> int:
	if sound == SOUND_DIE:
		return 2
	elif sound == SOUND_PAIN or sound == SOUND_HAHA or sound == SOUND_SCREAM:
		return 1
	return 0

func play_step_sound() -> void:
	var sound = SoundParticle.new(preload("res://Assets/Sounds/step-floor.wav"), translation, 0.5)
	get_tree().get_root().add_child(sound)

func play_heavy_landing_sound() -> void:
	var sound = SoundParticle.new(preload("res://Assets/Sounds/ground_pound.wav"), translation, 1.0, 0.1)
	get_tree().get_root().add_child(sound)

func start_slide_sound() -> void:
	if not $SlideSound.playing:
		$SlideSound.play()

func stop_slide_sound() -> void:
	$SlideSound.stop()

func _on_FSM_state_change(state):
	debug_state_switch_count += 1
