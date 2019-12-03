tool
extends "water.gd"

export(int) var resolution = 20 setget set_resolution

var wave_bump

func _enter_tree():
	water_material = preload("../material/low_poly.material").duplicate()
	water_surface.set_surface_material(0, water_material)
	
	var wave_map = water_material.get_shader_param("wave_bump")
	wave_bump = wave_map.get_data()
	wave_bump.decompress()
	
	set_resolution(resolution)
	set_color(color)
	set_fog_density(fog_density)
	set_speed(speed)
	set_frequency(frequency)
	set_amplitude(amplitude)
	set_velocity(velocity)

func get_height(coord):
	if water_material:
		var _coord = coord if typeof(coord) == TYPE_VECTOR2 else Vector2(coord.x, coord.z)
		
		var uv = _coord * frequency / 10.0;
		var height = texture(wave_bump, uv - time * water_material.get_shader_param("wave_dir1")).r * 2.0 - 1.0;
		height += texture(wave_bump, (uv + Vector2(0.25, 0.25)) - time * water_material.get_shader_param("wave_dir2")).g * 2.0 - 1.0;
		height += texture(wave_bump, (uv - Vector2(0.25, 0.25)) - time * water_material.get_shader_param("wave_dir3")).b * 2.0 - 1.0;
		return height * amplitude;
	else:
		return amplitude / 2.0;

func texture(tex, uv):
	var img = tex
	if img is Texture: img = img.get_data()
	
	var size = Vector2(img.get_width(), img.get_height())
	
	var _uv = uv*size
	_uv.x = wrapi(_uv.x, 0, size.x)
	_uv.y = wrapi(_uv.y, 0, size.y)
	
	img.lock()
	var color = img.get_pixel(_uv.x, _uv.y)
	img.unlock()
	
	return color

func set_resolution(value):
	resolution = value
	if water_surface.mesh:
		water_surface.mesh.subdivide_width = resolution
		water_surface.mesh.subdivide_depth = resolution