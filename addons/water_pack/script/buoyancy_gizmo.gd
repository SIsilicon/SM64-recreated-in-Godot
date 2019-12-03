tool
extends EditorSpatialGizmo
# TODO
# view only selected
# edit in spatial editor
enum {X, Y, Z}
const LINE_SIZE = 10000

var red; var green; var blue
var handle_mat
var node

var PointModes = preload('buoyancy_points.gd').PointModes

var plugin

var p_index = -1
var old_data
var constraints = []

func _init(plugin, node):
	self.node = node
	self.plugin = plugin
	
	set_spatial_node(node)
	node.buoyancy_points.connect("changed", self, "redraw")
	plugin.connect("input", self, "_input")
	
	handle_mat = SpatialMaterial.new()
	handle_mat.albedo_color = Color(1, 0.6, 0.3)
	handle_mat.flags_unshaded = true
	handle_mat.flags_use_point_size = true
	handle_mat.params_point_size = 10
	
	red = mat_solid_color(1.0, 0.0, 0.0)
	green = mat_solid_color(0.0, 1.0, 0.0)
	blue = mat_solid_color(0.0, 0.0, 1.0)

func get_handle_value(index):
	return node.buoyancy_points.data[index]

func commit_handle(index, restore, cancel=false):
	if not cancel:
		var new_data = node.buoyancy_points.data[index]
		
		if node.buoyancy_points.point_mode == PointModes.AUTO_POINTS:
			node.buoyancy_points.point_mode = PointModes.MANUAL_POINTS
		
		var undo_redo = plugin.get_undo_redo()
		undo_redo.create_action("Transform Buoyancy Point "+str(index))
		undo_redo.add_do_method(self, "set_buoyancy_point", new_data, index)
		undo_redo.add_undo_method(self, "set_buoyancy_point", old_data, index)
		undo_redo.commit_action()
	else:
		node.buoyancy_points.data[index] = old_data
	
	old_data = null
	constraints = []
	p_index = -1
	redraw()

func set_handle(index, camera, point):
	p_index = index
	
	var coord = node.buoyancy_points.data[index]
	if not old_data:
		old_data = coord
	else:
		coord = old_data
	
	var world_matrix = node.global_transform
	var camera_matrix = camera.global_transform
	
	var world_space_coord = world_matrix.xform(coord)
	var cam_space_coord = camera_matrix.xform_inv(world_space_coord)
	
	if not constraints.empty():
		var inv_constraints = invert_constraints(constraints)
		var sec_ind = wrapi(1, 0, inv_constraints.size())
		
		var project_plane = Plane(dir(inv_constraints[0]), select_vec_axis(coord, inv_constraints[0]))
		var snap_plane = Plane(dir(inv_constraints[sec_ind]), select_vec_axis(coord, inv_constraints[sec_ind]))
		
		var ray_origin = camera.project_ray_origin(point)
		var ray_dir = camera.project_ray_normal(point)
		ray_origin = world_matrix.xform_inv(ray_origin)
		ray_dir = world_matrix.basis.xform_inv(ray_dir)
		
		coord = project_plane.intersects_ray(ray_origin, ray_dir)
		if not coord: return #sometimes the projection might fail.
		coord = snap_plane.project(coord)
	else:
		var project_plane = Plane(0,0,1, cam_space_coord.z)
		var ray_dir = camera.project_local_ray_normal(point)
		var ray_origin = camera_matrix.xform_inv(camera.project_ray_origin(point))
		
		coord = project_plane.intersects_ray(ray_origin, ray_dir)
		if not coord: return #sometimes the projection might fail.
		coord = camera_matrix.xform(coord)
		coord = world_matrix.xform_inv(coord)
	
	node.buoyancy_points.data[index] = coord
	redraw()

func redraw():
	clear()
	var lines = []
	var handles = []
	var buoyancy_points = node.buoyancy_points.data
	
	if buoyancy_points.size() > 0:
		for point in buoyancy_points:
			handles.append(point)
		add_handles(handles, handle_mat)
		
		if p_index >= 0:
			var point = old_data
			for c in constraints:
				lines.clear()
				lines.append(point-dir(c) * LINE_SIZE)
				lines.append(point+dir(c) * LINE_SIZE)
				add_lines(lines, select_mat(c), false)

func set_buoyancy_point(val, ind):
	node.buoyancy_points.data[ind] = val
	redraw()

func _input(event):
	if event is InputEventKey and not event.is_pressed():
		var key = event.scancode
		
		match key:
			KEY_X:
				if constraints != [X]:
					constraints = [Y,Z] if event.shift else [X]
				else: constraints = []
			KEY_Y:
				if constraints != [Y]:
					constraints = [X,Z] if event.shift else [Y]
				else: constraints = []
			KEY_Z:
				if constraints != [Z]:
					constraints = [X,Y] if event.shift else [Z]
				else: constraints = []
		redraw()

#HELPER FUNCTIONS
func mat_solid_color(red, green, blue):
	var mat = SpatialMaterial.new()
	mat.render_priority = mat.RENDER_PRIORITY_MAX
	mat.flags_unshaded = true
	mat.flags_transparent = true
	mat.flags_no_depth_test = true
	mat.albedo_color = Color(red, green, blue)
	
	return mat

func invert_constraints(c):
	match c:
		[X]: return [Y,Z]
		[Y]: return [X,Z]
		[Z]: return [X,Y]
		[Y,Z]: return [X]
		[X,Z]: return [Y]
		[X,Y]: return [Z]
		_: printerr(str(c) + " does not contain a valid constraint combination")

func dir(axis):
	match axis:
		X: return Vector3(1,0,0)
		Y: return Vector3(0,1,0)
		Z: return Vector3(0,0,1)
		_: invalid_axis(axis)

func select_vec_axis(vector, axis):
	match axis:
		X: return vector.x
		Y: return vector.y
		Z: return vector.z
		_: invalid_axis(axis)

func select_mat(axis):
	match axis:
		X: return red
		Y: return green
		Z: return blue
		_: invalid_axis(axis)

func invalid_axis(axis): printerr(str(axis) + " is not a valid axis!")