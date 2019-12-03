extends Spatial

var lod_resolution
var lod_levels
var lod_scale
var lod_morphing_levels
var lod_material

var grid_geometry
var grid_outside_geometry

var prev_lod_resolution

func _init(res, levels, scale, morph):
	lod_resolution = res
	lod_levels = levels
	lod_scale = scale
	lod_morphing_levels = morph
	
	lod_levels = max(1, round(lod_levels))
	lod_scale = max(1, lod_scale)
	lod_resolution = max(1, lod_resolution)
	lod_resolution = nearest_po2(lod_resolution)
	lod_morphing_levels = clamp(round(lod_morphing_levels), 0, 2)

func generate(material):
	lod_material = material
	
	#prev_lod_resolution = lod_resolution
	grid_geometry = generate_lod_geom(lod_resolution, false)
	grid_outside_geometry = generate_lod_geom(lod_resolution, true)
	
	generate_levels()

func generate_levels():
	for i in get_children():
		remove_child(i)
	
	var current_scale = lod_scale
	for i in range(lod_levels):
		var geometry = grid_geometry if i == 0 else grid_outside_geometry
		add_child(generate_lod_mesh(geometry, lod_material, current_scale, i))
		current_scale *= 2

func generate_lod_mesh(geom, mat, scale, level):
	var lod_mat = mat.duplicate()
	lod_mat.set_shader_param('lod_scale', scale)
	lod_mat.set_shader_param('level', level)
	var mesh_inst = MeshInstance.new()
	mesh_inst.mesh = geom
	mesh_inst.material_override = lod_mat
	return mesh_inst

func generate_lod_geom(resolution, is_outside):
	
	var half_size = round(resolution * 0.5)
	
	var geometry = SurfaceTool.new()
	geometry.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(-half_size-1, half_size + 2):
		for z in range(-half_size-1, half_size + 2):
			geometry.add_vertex(Vector3(x, 0, z) / resolution)
	geometry.add_vertex(Vector3(1,1,1)*pow(2,16))
	geometry.add_vertex(-Vector3(1,1,1)*pow(2,16))
	
	var width = resolution + 3
	var inside_low = resolution / 4
	var inside_high = inside_low * 3
	for x in range(resolution+2):
		var left = x
		var right = x + 1
		var inside_x_hole = x > inside_low and x <= inside_high
		for z in range(resolution+2):
			var front = z
			var back = z + 1
			var inside_z_hole = z > inside_low and z <= inside_high
			
			if is_outside and inside_x_hole and inside_z_hole: continue
			
			var a = width * left + back
			var b = width * right + back
			var c = width * right + front
			var d = width * left + front
			
			geometry.add_index(d); geometry.add_index(b); geometry.add_index(a)
			geometry.add_index(c); geometry.add_index(b); geometry.add_index(d)
	return geometry.commit()
