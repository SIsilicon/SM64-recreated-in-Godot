tool
extends MeshInstance

export(Vector2) var size setget set_size

export(Texture) var dirt setget set_dirt
export(Texture) var wet_map setget set_wet
export(Texture) var wave_norm setget set_wave

export(bool) var invert_wet_map setget set_invert
export(float) var wet_map_strength setget set_wet_strength
export(float) var wet_map_bias setget set_bias

export(Vector2) var wind_dir1 setget set_dir1
export(float) var wave_size1 setget set_size1
export(Vector2) var wind_dir2 setget set_dir2
export(float) var wave_size2 setget set_size2

export(float) var wave_strength setget set_wave_strength

export(bool) var ripples setget set_ripples
export(float) var ripple_density = 1.0 setget set_ripple_density

onready var initialized = true

func _process(delta):
	$Particles.draw_pass_1.material.set_shader_param('translation', Vector2(translation.x, translation.z))

func set_size(vec2):
	size = vec2
	mesh.size = vec2
	
	if not initialized: return
	
	$Particles.amount = ripple_density * size.x * size.y
	$Particles.visibility_aabb = AABB(Vector3(-vec2.x, -0.2, -vec2.y)/2.0, \
		Vector3(vec2.x, 0.1, vec2.y))
	$Particles.process_material.emission_box_extents = Vector3(vec2.x, 0.0, vec2.y)/2.0 \
		- Vector3(0.2,0,0.2)
	$Particles.draw_pass_1.material.set_shader_param('wet_dirt_size', vec2)

func set_dirt(tex):
	dirt = tex
	material_override.set_shader_param('dirt_tex', tex)

func set_wet(tex):
	wet_map = tex
	material_override.set_shader_param('wet_map', tex)
	
	if not initialized: return
	$Particles.draw_pass_1.material.set_shader_param('wet_map', tex)

func set_wave(tex):
	wave_norm = tex
	material_override.set_shader_param('wave', tex)

func set_invert(bol):
	invert_wet_map = bol
	material_override.set_shader_param('invert_wet_map', bol)
	
	if not initialized: return
	$Particles.draw_pass_1.material.set_shader_param('invert_wet_map', bol)

func set_wet_strength(flt):
	wet_map_strength = flt
	material_override.set_shader_param('wet_map_strength', flt)
	
	if not initialized: return
	$Particles.draw_pass_1.material.set_shader_param('wet_map_strength', flt)

func set_bias(flt):
	wet_map_bias = flt
	material_override.set_shader_param('wet_map_bias', -flt)
	
	if not initialized: return
	$Particles.draw_pass_1.material.set_shader_param('wet_map_bias', -flt)

func set_dir1(vec2):
	wind_dir1 = vec2
	material_override.set_shader_param('wind_dir1', vec2)

func set_size1(flt):
	wave_size1 = flt
	material_override.set_shader_param('wave_size1', flt)

func set_dir2(vec2):
	wind_dir2 = vec2
	material_override.set_shader_param('wind_dir2', vec2)

func set_size2(flt):
	wave_size2 = flt
	material_override.set_shader_param('wave_size2', flt)

func set_wave_strength(flt):
	wave_strength = flt
	material_override.set_shader_param('wave_strength', flt)

func set_ripples(bol):
	ripples = bol
	
	if not initialized: return
	$Particles.emitting = bol

func set_ripple_density(value):
	ripple_density = value
	if not initialized: return
	$Particles.amount = ripple_density * size.x * size.y