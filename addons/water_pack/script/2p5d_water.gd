tool
extends "water.gd"

export(float) var depth = 10.0 setget set_depth

var side_water
var side_material

func _ready():
	._ready()
	
	side_water = MeshInstance.new()
	side_water.layers = preload("water.gd").REFLECTION_MASK
	side_water.mesh = QuadMesh.new()
	
	side_material = preload("res://addons/water_pack/material/2p5d_water.material").duplicate()
	side_water.set_surface_material(0, side_material)
	add_child(side_water)
	
	set_depth(depth)
	set_size(size)
	set_frequency(frequency)
	set_amplitude(amplitude)
	set_speed(speed)
	set_color(color)
	set_fog_density(fog_density)

func set_depth(value):
	depth = value
	
	if side_water:
		side_water.mesh.size = Vector2(size.x, depth)
		side_water.translation.y = -depth / 2.0
		side_material.set_shader_param("uv_scale", side_water.mesh.size * frequency)

func set_size(value):
	.set_size(value)
	
	if side_water:
		side_water.mesh.size = Vector2(size.x, depth)
		side_water.translation.z = size.y / 2.0
		side_material.set_shader_param("uv_scale", side_water.mesh.size * frequency)

func set_frequency(value):
	.set_frequency(value)
	
	if side_material:
		side_material.set_shader_param("uv_scale", side_water.mesh.size * frequency)

func set_amplitude(value):
	.set_amplitude(value)
	
	if side_material:
		side_material.set_shader_param("distort_factor", amplitude / 30.0)

func set_speed(value):
	.set_speed(value)
	
	if side_material:
		side_material.set_shader_param("distort_speed", speed)

func set_color(value):
	.set_color(value)
	
	if side_material:
		side_material.set_shader_param("water_color", value)

func set_fog_density(value):
	.set_fog_density(value)
	
	if side_material:
		side_material.set_shader_param("density", value)
