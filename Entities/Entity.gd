extends Spatial
class_name Entity

const OBJ_MOVE_LANDED = (1 <<  0)
const OBJ_MOVE_ON_GROUND = (1 <<  1)
const OBJ_MOVE_LEFT_GROUND = (1 <<  2)
const OBJ_MOVE_ENTERED_WATER = (1 <<  3)
const OBJ_MOVE_AT_WATER_SURFACE = (1 <<  4)
const OBJ_MOVE_UNDERWATER_OFF_GROUND = (1 <<  5)
const OBJ_MOVE_UNDERWATER_ON_GROUND = (1 <<  6)
const OBJ_MOVE_IN_AIR = (1 <<  7)
const OBJ_MOVE_8 = (1 <<  8)
const OBJ_MOVE_HIT_WALL = (1 <<  9)
const OBJ_MOVE_HIT_EDGE = (1 << 10)
const OBJ_MOVE_ABOVE_LAVA = (1 << 11)
const OBJ_MOVE_LEAVING_WATER = (1 << 12)
const OBJ_MOVE_13 = (1 << 13)
const OBJ_MOVE_ABOVE_DEATH_BARRIER = (1 << 14)

const OBJ_MOVE_MASK_ON_GROUND = OBJ_MOVE_LANDED | OBJ_MOVE_ON_GROUND
const OBJ_MOVE_MASK_33 = 0x33
const OBJ_MOVE_MASK_IN_WATER = OBJ_MOVE_ENTERED_WATER | \
		OBJ_MOVE_AT_WATER_SURFACE | OBJ_MOVE_UNDERWATER_OFF_GROUND | \
		OBJ_MOVE_UNDERWATER_ON_GROUND
const OBJ_MOVE_MASK_HIT_WALL_OR_IN_WATER = OBJ_MOVE_HIT_WALL | OBJ_MOVE_MASK_IN_WATER
const OBJ_MOVE_MASK_NOT_AIR = OBJ_MOVE_LANDED | OBJ_MOVE_ON_GROUND | \
		OBJ_MOVE_AT_WATER_SURFACE | \
		OBJ_MOVE_UNDERWATER_ON_GROUND

var home : Vector3
var move_angle_yaw := 0.0
var forward_velocity := 0.0
var velocity := Vector3()

var angle_vel_yaw := 0.0

var floor_surf : Surface
var floor_height : float
var floor_type : int

var wall_angle : float

var angle_to_mario := 0.0

var state := 0
var move_flags := 0

var gravity := -4.0
var bounce := 0.5
var buoyancy := 2.0
var drag_strength := 1.0

func detect_steep_floor(steep_angle) -> int:
	var steep_normal_y := cos(steep_angle)
	
	if forward_velocity != 0:
		var intended_pos := translation + velocity * Vector3(1,0,1) * 0.01
		var floor_dict := Collisions.find_floor(intended_pos)
		var intended_floor_height : float = floor_dict.height
		var intended_floor : Surface = floor_dict.floor
		var delta_floor_height := intended_floor_height - floor_height
		
		if intended_floor_height < -100.0:
			wall_angle = move_angle_yaw + PI
			return 2
		elif intended_floor.normal.y < steep_normal_y and delta_floor_height > 0 \
				and intended_floor_height > translation.y:
			wall_angle = atan2(intended_floor.normal.x, intended_floor.normal.z)
			return 1
		else:
			return 0
	
	return 0

func resolve_wall_collisions() -> int:
#	offset_y = 10.0
	var radius := get_wall_collide_radius()
	
	if radius > 0.0:
		var collision_data := Collisions.find_wall_collisions(translation, 0.1, radius)
		if collision_data.num_walls != 0:
			translation.x = collision_data.x
			translation.z = collision_data.z
			var wall = collision_data.walls[collision_data.num_walls - 1]
			
			wall_angle = atan2(wall.normal.x, wall.normal.z)
			if abs(Utils.angle_diff(wall_angle, move_angle_yaw)) > PI/2:
				return 1
			else:
				return 0
	
	return 0

func update_floor_height_and_get_floor() -> Surface:
	var floor_dict := Collisions.find_floor(translation)
	floor_height = floor_dict.height
	
	return floor_dict.floor

func update_floor() -> void:
	floor_surf = update_floor_height_and_get_floor()
	
	if floor_surf:
		if floor_surf.type == Surface.SURFACE_DEATH_PLANE:
			move_flags |= OBJ_MOVE_ABOVE_DEATH_BARRIER
		
		floor_type = floor_surf.type
	else:
		floor_type = 0

func update_floor_and_walls(steep_slope := PI/3) -> void:
	Collisions.push_collision_mask(Collisions.COLLISION_STATIC | Collisions.COLLISION_DYNAMIC)
	
	move_flags &= ~(OBJ_MOVE_ABOVE_DEATH_BARRIER | OBJ_MOVE_HIT_WALL)
	
	if resolve_wall_collisions():
		move_flags |= OBJ_MOVE_HIT_WALL
	
	update_floor()
	
	if translation.y > floor_height:
		move_flags |= OBJ_MOVE_IN_AIR
	
	if detect_steep_floor(steep_slope):
		move_flags |= OBJ_MOVE_HIT_WALL
	
	Collisions.pop_collision_mask()

func lateral_dist_from_mario_to_home() -> float:
	return (home * Vector3(1,0,1) - Global.mario.translation * Vector3(1,0,1)).length()

func rotate_yaw_toward(target : float, increment : float) -> bool:
	var start_yaw := move_angle_yaw
	
	var dir = Utils.angle_diff(move_angle_yaw, target)
	move_angle_yaw -= clamp(dir, -increment, increment)
	
	angle_vel_yaw = Utils.angle_diff(move_angle_yaw, start_yaw)
	return angle_vel_yaw == 0

func angle_to_home() -> float:
	var vec := home - translation
	return atan2(vec.x, vec.z)

func angle_to_object(obj1 : Spatial, obj2 : Spatial) -> float:
	var vec := obj2.translation - obj1.translation
	return atan2(vec.x, vec.z)

func compute_vel_xz() -> void:
	velocity.x = forward_velocity * sin(move_angle_yaw)
	velocity.z = forward_velocity * cos(move_angle_yaw)

func value_drag(value : float, drag : float) -> float:
	if value != 0.0:
		var decel = value * value * drag * 0.0001
		
		if value > 0:
			value -= decel
			if value < 0.001:
				value = 0.0
		else:
			value += decel
			if value > -0.001:
				value = 0.0
	
	return value

func apply_drag_xz(drag_strength : float) -> void:
	velocity.x = value_drag(velocity.x, drag_strength)
	velocity.z = value_drag(velocity.z, drag_strength)

func move_xz(steep_slope_y : float, care_about_edges_and_steep_slopes : bool) -> bool:
	var intended_pos := translation + velocity * Vector3(1,0,1) * 0.01
	
	var floor_dict := Collisions.find_floor(intended_pos)
	var intended_floor_height : float = floor_dict.height
	var intended_floor : Surface = floor_dict.floor
	var delta_floor_height = intended_floor_height - floor_height
	
	move_flags &= ~OBJ_MOVE_HIT_EDGE
	
	if intended_floor_height < -100.0:
		# Don't move into OoB
		move_flags |= OBJ_MOVE_HIT_EDGE
		return false
	elif delta_floor_height < 0.05:
		if not care_about_edges_and_steep_slopes:
			# If we don't care about edges or steep slopes, okay to move
			translation.x = intended_pos.x
			translation.z = intended_pos.z
			return true
		elif delta_floor_height < -0.5 and move_flags & OBJ_MOVE_ON_GROUND:
			# Don't walk off an edge
			move_flags |= OBJ_MOVE_HIT_EDGE
			return false
		elif intended_floor.normal.y > steep_slope_y:
			# Allow movement onto a slope, provided it's not too steep
			translation.x = intended_pos.x
			translation.z = intended_pos.z
			return true
		else:
			# We are likely trying to move onto a steep downward slope
			move_flags |= OBJ_MOVE_HIT_EDGE
			return false
	
	elif intended_floor.normal.y > steep_slope_y || translation.y > intended_floor_height:
		# Allow movement upward, provided either:
		# - The target floor is flat enough (e.g. walking up stairs)
		# - We are above the target floor (most likely in the air)
		translation.x = intended_pos.x
		translation.z = intended_pos.z
		#! Returning FALSE but moving anyway (not exploitable return value is
		#  never used)
	return false

func move_update_ground_air_flags(bounce : float) -> void:
	move_flags &= ~OBJ_MOVE_13
	
	if translation.y < floor_height:
		# On the first frame that we touch the ground, set OBJ_MOVE_LANDED.
		# On subsequent frames, set OBJ_MOVE_ON_GROUND
		if not bool(move_flags & OBJ_MOVE_ON_GROUND):
			if clear_move_flag(OBJ_MOVE_LANDED):
				move_flags |= OBJ_MOVE_ON_GROUND
			else:
				move_flags |= OBJ_MOVE_LANDED
		
		translation.y = floor_height
		
		if velocity.y < 0.0:
			velocity.y *= bounce
		
		if velocity.y > 5.0:
			#! If OBJ_MOVE_13 tracks bouncing, it overestimates, since velocity.y
			# could be > 5 here without bounce (e.g. jump into misa)
			move_flags |= OBJ_MOVE_13
	else:
		move_flags &= ~OBJ_MOVE_LANDED
		if clear_move_flag(OBJ_MOVE_ON_GROUND):
			move_flags |= OBJ_MOVE_LEFT_GROUND
	
	move_flags &= ~OBJ_MOVE_MASK_IN_WATER

func move_y_and_get_water_level(gravity : float, buoyancy : float) -> float:
	var water_level : float
	
	velocity.y += gravity + buoyancy
	velocity.y = max(velocity.y, -78.0)
	
	translation.y += velocity.y * 0.01
	water_level = Collisions.find_water_level(translation)
	
	return water_level

func move_update_underwater_flags() -> void:
	var decel_y = sqrt(velocity.y * velocity.y) * (drag_strength * 7.0) / 100.0
	
	velocity.y -= decel_y * sign(velocity.y) 
	
	if translation.y < floor_height:
		translation.y = floor_height
		move_flags |= OBJ_MOVE_UNDERWATER_ON_GROUND
	else:
		move_flags |= OBJ_MOVE_UNDERWATER_OFF_GROUND

func move_y(gravity, bounce, buoyancy) -> void:
	var water_level : float
	
	move_flags &= ~OBJ_MOVE_LEFT_GROUND
	
	if move_flags & OBJ_MOVE_AT_WATER_SURFACE:
		if velocity.y > 5.0:
			move_flags &= ~OBJ_MOVE_MASK_IN_WATER
			move_flags |= OBJ_MOVE_LEAVING_WATER
	
	if not bool(move_flags & OBJ_MOVE_MASK_IN_WATER):
		water_level = move_y_and_get_water_level(gravity, 0.0)
		if translation.y > water_level:
			#! We only handle floor collision if the object does not enter
			#  water. This allows e.g. coins to clip through floors if they
			#  enter water on the same frame.
			move_update_ground_air_flags(bounce)
		else:
			move_flags |= OBJ_MOVE_ENTERED_WATER
			move_flags &= ~OBJ_MOVE_MASK_ON_GROUND
	else:
		move_flags &= ~OBJ_MOVE_ENTERED_WATER
		
		water_level = move_y_and_get_water_level(gravity, buoyancy)
		if translation.y < water_level:
			move_update_underwater_flags()
		else:
			if translation.y < floor_height:
				translation.y = floor_height
				move_flags &= ~OBJ_MOVE_MASK_IN_WATER
			else:
				translation.y = water_level
				velocity.y = 0.0
				move_flags &= ~(OBJ_MOVE_UNDERWATER_OFF_GROUND | OBJ_MOVE_UNDERWATER_ON_GROUND)
				move_flags |= OBJ_MOVE_AT_WATER_SURFACE
	
	if move_flags & OBJ_MOVE_MASK_33:
		move_flags &= ~OBJ_MOVE_IN_AIR
	else:
		move_flags |= OBJ_MOVE_IN_AIR

func move_standard(steep_slope_angle : float) -> void:
	Collisions.push_collision_mask(Collisions.COLLISION_STATIC | Collisions.COLLISION_DYNAMIC)
	
	var steep_slope_normal_y : float
	var care_about_edges_and_steep_slopes := false
	var negative_speed := false
	
	if steep_slope_angle < 0:
		care_about_edges_and_steep_slopes = true
		steep_slope_angle *= -1
	
	steep_slope_normal_y = cos(steep_slope_angle)
	
	compute_vel_xz()
	apply_drag_xz(drag_strength)
	
	move_xz(steep_slope_normal_y, care_about_edges_and_steep_slopes)
	move_y(gravity, bounce, buoyancy)
	
	if forward_velocity < 0:
		negative_speed = true
	forward_velocity = (velocity * Vector3(1,0,1)).length()
	if negative_speed == true:
		forward_velocity = -forward_velocity
	
	Collisions.pop_collision_mask()

func clear_move_flag(flag : int) -> bool:
	if move_flags & flag:
		move_flags &= flag ^ 0xFFFFFFFF
		return true
	else:
		return false

func get_wall_collide_radius() -> float:
	return 0.0