extends RigidBody

#export(NodePath) var water
export(Resource) var buoyancy_points  #TODO filter CUSTOM buoyancy_points type when support
export var buoyancy_multiplier = 1.0

export var debug = true

var water_node # This is used for single point mode buoyany points.
var anchor = translation
var base_linear_damp = 0.0
var base_angular_damp = 0.0

func _ready():
	base_linear_damp = linear_damp
	base_angular_damp = angular_damp
	
	if base_linear_damp < 0.0:
		base_linear_damp = ProjectSettings.get_setting("physics/3d/water_linear_damp")
	if base_angular_damp < 0.0:
		base_angular_damp = ProjectSettings.get_setting("physics/3d/water_angular_damp")
	
	if debug:
		var debug_geom = ImmediateGeometry.new()
		debug_geom.name = 'debug'
		add_child(debug_geom)
		debug_geom.set_as_toplevel(true)
		debug_geom.global_transform = Transform()
		
		var mat = SpatialMaterial.new()
		mat.flags_unshaded = true
		mat.flags_use_point_size = true
		#mat.flags_no_depth_test = true
		mat.params_point_size = 10
		debug_geom.material_override = mat

func _physics_process(delta):
	if buoyancy_points.point_mode == buoyancy_points.PointModes.SINGLE_POINT:
		if water_node is preload("ocean.gd"):
			translation = water_node.get_displace(anchor)
		else:
			translation.y = water_node.get_height(anchor)
	else:
		mode = RigidBody.MODE_RIGID
		set_physics_process(false)

func _integrate_forces(state):
	
	if buoyancy_points.point_mode == buoyancy_points.PointModes.SINGLE_POINT:
		water_node = get_water_body(global_transform.xform(buoyancy_points.data[0]))
		if water_node:
			mode = RigidBody.MODE_STATIC
			translation.y = water_node.get_height(global_transform.origin)
			anchor = translation
			set_physics_process(true)
	
	linear_damp = 0
	angular_damp = 0
	if buoyancy_points.data.size() != 0:
		
		var forces = []
		for point in buoyancy_points.data:
			var global_point = global_transform.xform(point)
			water_node = get_water_body(global_point)
			if not water_node:
				continue
			
			var water_normal = water_node.global_transform.basis[1]
			var water_velocity = water_node.velocity * 0.1
			var water_density = water_node.density
			
			# buoyancy
			var water_height = water_node.get_height(global_point) + water_node.global_transform.origin.y
			var depth = water_height - global_point.y
			if depth > 0:
				var force = water_normal * water_density * depth
				force += Vector3(water_velocity.x, 0, water_velocity.y)
				apply_impulse(point, force*state.step*buoyancy_multiplier)
				forces.append([global_point, force*buoyancy_multiplier])
				
				# damping
				linear_damp += water_density / buoyancy_points.data.size() * base_linear_damp
				angular_damp += water_density / buoyancy_points.data.size() * base_angular_damp
		
		if debug:
			$debug.clear()
			$debug.begin(Mesh.PRIMITIVE_POINTS)
			for point in buoyancy_points.data:
				$debug.add_vertex(global_transform.xform(point))
			$debug.end()
			
			$debug.begin(Mesh.PRIMITIVE_LINES)
			for force in forces:
				$debug.add_vertex(force[0])
				$debug.add_vertex(force[0] + force[1])
			$debug.end()

func get_water_body(point):
	var closest_body
	
	for body in get_tree().get_nodes_in_group("ywaby_water"):
		if not body.visible:
			continue
		
		if body is preload("ocean.gd"):
			closest_body = body
		
		var trans = body.global_transform
		var norm = trans.basis[1]
		var tangent = trans.basis[0] * body.size.x * 0.5
		var bitangent = trans.basis[2] * body.size.y * 0.5
		var point_a = trans.origin - tangent - bitangent
		var point_b = trans.origin + tangent - bitangent
		var point_c = trans.origin - tangent + bitangent
		var point_d = trans.origin + tangent + bitangent
		
		if typeof(Geometry.ray_intersects_triangle(point, norm, point_a, point_b, point_c)) == TYPE_VECTOR3 || \
				typeof(Geometry.ray_intersects_triangle(point, norm, point_b, point_d, point_c)) == TYPE_VECTOR3:
			closest_body = body
	
	return closest_body

func set_linear_damp(value):
	.set_linear_damp(value)
	base_linear_damp = value

func set_angular_damp(value):
	.set_angular_damp(value)
	base_angular_damp = value
