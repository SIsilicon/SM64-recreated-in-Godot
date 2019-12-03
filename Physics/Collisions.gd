tool
extends Node

enum {COLLISION_STATIC = 1 << 0, COLLISION_DYNAMIC = 1 << 1,
		COLLISION_MARIO = 1 << 2, COLLISION_ENTITY = 1 << 3,
		COLLISION_CAMERA = 1 << 4, COLLISION_WATER = 1 << 6
}

var mask_stack := []

var debug := false and not Engine.is_editor_hint()
var debug_mesh : ImmediateGeometry
var building_mesh := false

var ray_cast : RayCast

func _init() -> void:
	if get_child_count() == 2:
		remove_child(get_child(1))
	
	ray_cast = RayCast.new()
	add_child(ray_cast)
	
	if debug:
		debug_mesh = ImmediateGeometry.new()
		debug_mesh.material_override = preload("debug_collision_rays.material")
		add_child(debug_mesh)
		VisualServer.connect("frame_pre_draw", self, "_pre_draw")
		set_process_priority(-127)

func _process(delta : float) -> void:
	if debug and not building_mesh:
		building_mesh = true
		debug_mesh.clear()
		debug_mesh.begin(Mesh.PRIMITIVE_LINES)

func _pre_draw() -> void:
	if debug and building_mesh:
		building_mesh = false
		debug_mesh.end()

func find_wall_collisions(var coords : Vector3, var offset : float, var radius : float) -> Dictionary:
	var surface_list : Array
	
	if coords.x <= -Constants.LEVEL_BOUNDARY || coords.x >= Constants.LEVEL_BOUNDARY:
		return {"x": coords.x, "z": coords.z, "num_walls": 0, "walls": []}
	if coords.z <= -Constants.LEVEL_BOUNDARY || coords.z >= Constants.LEVEL_BOUNDARY:
		return {"x": coords.x, "z": coords.z, "num_walls": 0, "walls": []}
	
	ray_cast.translation = coords + Vector3(0, offset, 0)
	var dirs := [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
	var num_walls := 0
	var walls := []
	var new_coords := coords
	for i in dirs.size():
		ray_cast.cast_to = dirs[i] * radius
		ray_cast.force_raycast_update()
		
		if debug and building_mesh:
			debug_mesh.set_color(Color.green)
			debug_mesh.add_vertex(ray_cast.translation)
			debug_mesh.add_vertex(ray_cast.translation + ray_cast.cast_to)
		
		if ray_cast.is_colliding():
			var normal := get_collision_normal()
			if normal.y >= -0.01 and normal.y <= 0.01:
				var x_project := normal.x < -0.707 || normal.x > 0.707
				
				# This does a check between whether the surface is projected along x,
				# and whether the current direction is not along x.
				if int(x_project) ^ int(i > 1):
					var intersect := (ray_cast.translation - ray_cast.get_collision_point()).abs()
					if x_project:
						new_coords += normal * (radius - intersect.x)
					else:
						new_coords += normal * (radius - intersect.z)
					
					num_walls += 1
					var type = get_collider_type()
					var wall = Surface.new(normal, type, ray_cast.get_collider())
					walls.append(wall)
	
	return {"x": new_coords.x, "z": new_coords.z, "num_walls": num_walls, "walls": walls}

func find_ceil(pos : Vector3) -> Dictionary:
	var surface_list : Array
	var height := 2000.0
	
	# Parallel Universes baby! B)
	var coords := Vector3(
			wrapf(pos.x, -327.68, 327.67),
			wrapf(pos.y, -327.68, 327.67),
			wrapf(pos.z, -327.68, 327.67)
	)
	
	if coords.x <= -Constants.LEVEL_BOUNDARY || coords.x >= Constants.LEVEL_BOUNDARY:
		return {"ceil": null, "height": height}
	if coords.z <= -Constants.LEVEL_BOUNDARY || coords.z >= Constants.LEVEL_BOUNDARY:
		return {"ceil": null, "height": height}
	
	ray_cast.translation = coords + Vector3(0, 0.78, 0)
	ray_cast.cast_to = Vector3(0, 2024, 0)
	ray_cast.force_raycast_update()
	
	if debug and building_mesh:
		debug_mesh.set_color(Color.red)
		debug_mesh.add_vertex(ray_cast.translation)
		debug_mesh.add_vertex(ray_cast.translation + ray_cast.cast_to)
	
	if ray_cast.is_colliding():
		var normal := get_collision_normal()
		
		if normal.y >= -0.01:
			return {"ceil": null, "height": height}
		
		var type = get_collider_type()
		var ceil_surf := Surface.new(normal, type, ray_cast.get_collider())
		ceil_surf.normal = normal
		height = ray_cast.get_collision_point().y
		
		return {"ceil": ceil_surf, "height": height}
	else:
		return {"ceil": null, "height": height}

func find_floor(pos : Vector3) -> Dictionary:
	var surface_list : Array
	var height := -110.0
	
	# Parallel Universes baby! B)
	var coords := Vector3(
			wrapf(pos.x, -327.68, 327.67),
			wrapf(pos.y, -327.68, 327.67),
			wrapf(pos.z, -327.68, 327.67)
	)
	
	if coords.x <= -Constants.LEVEL_BOUNDARY || coords.x >= Constants.LEVEL_BOUNDARY:
		return {"floor": null, "height": height}
	if coords.z <= -Constants.LEVEL_BOUNDARY || coords.z >= Constants.LEVEL_BOUNDARY:
		return {"floor": null, "height": height}
	
	ray_cast.translation = coords + Vector3(0, 0.78, 0)
	ray_cast.cast_to = Vector3(0, -2024, 0)
	ray_cast.force_raycast_update()
	
	if debug and building_mesh:
		debug_mesh.set_color(Color.blue)
		debug_mesh.add_vertex(ray_cast.translation)
		debug_mesh.add_vertex(ray_cast.translation + ray_cast.cast_to)
	
	if ray_cast.is_colliding():
		var normal := get_collision_normal()
		
		if normal.y <= 0.01:
			return {"floor": null, "height": height}
		
		var type = get_collider_type()
		var floor_surf := Surface.new(normal, type, ray_cast.get_collider())
		floor_surf.normal = normal
		height = ray_cast.get_collision_point().y
		
		return {"floor": floor_surf, "height": height}
	else:
		return {"floor": null, "height": height}

func find_water_level(pos : Vector3) -> float:
	var water_level := -110.0
	
	ray_cast.translation = Vector3(pos.x, 110.0, pos.z)
	ray_cast.cast_to = Vector3(0, -2024, 0)
	push_collision_mask(COLLISION_WATER)
	ray_cast.collide_with_areas = true
	
	ray_cast.force_raycast_update()
	if ray_cast.get_collider():
		water_level = ray_cast.get_collider().translation.y
	
	ray_cast.collide_with_areas = false
	pop_collision_mask()
	return water_level

func trace_ray(pos : Vector3, dir : Vector3) -> float:
	ray_cast.translation = pos
	ray_cast.cast_to = dir
	ray_cast.force_raycast_update()
	
	if debug and building_mesh:
		debug_mesh.set_color(Color.white)
		debug_mesh.add_vertex(pos)
		debug_mesh.add_vertex(pos + dir)
	
	return ray_cast.get_collision_point().distance_to(pos)

func get_collider_type():
	if ray_cast.get_collider().has_meta("type"):
		return ray_cast.get_collider().get_meta("type")
	else:
		return Surface.SURFACE_DEFAULT

func get_collision_normal() -> Vector3:
	var collider : CollisionObject = ray_cast.get_collider()
	var shape := collider.shape_owner_get_shape(0, 0)
	
	if not shape is ConcavePolygonShape:
		return ray_cast.get_collision_normal()
	else:
		var triangles : PoolVector3Array = shape.get_faces()
		var point := ray_cast.get_collision_point()
		
		var index = ray_cast.get_collider_shape()
		var vert1 := triangles[index*3]
		var vert2 := triangles[index*3 + 1]
		var vert3 := triangles[index*3 + 2]
		
		return -(vert2 - vert1).cross(vert3 - vert1).normalized()
		
		breakpoint
		return Vector3()

func push_collision_mask(collision_mask : int) -> void:
	mask_stack.push_back(collision_mask)
	ray_cast.collision_mask = collision_mask

func pop_collision_mask() -> int:
	var prev_mask = mask_stack.pop_back()
	var new_mask = 0 if mask_stack.size() == 0 else mask_stack[-1]
	
	ray_cast.collision_mask = new_mask
	return prev_mask