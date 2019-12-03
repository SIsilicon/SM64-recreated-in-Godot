tool
extends "water.gd"

var LOD : GDScript = load("res://addons/water_pack/script/LODPlane.gd")

const NUMBER_OF_WAVES = 15

const RESOLUTION = 64
const LEVELS = 10
const SCALE = 256.0
const MORPHING_LEVELS = 2

var lod
var initialized = false

export(float, 0, 1) var steepness = 0.01 setget set_steepness
var wind_direction = Vector2(1, 0)
var wind_align = 0.0

export(bool) var noise_enabled = true setget set_noise_enabled
export(float) var noise_amplitude = 0.12 setget set_noise_amplitude
export(float) var noise_frequency = 0.008 setget set_noise_frequency
export(float) var noise_speed = 0.44 setget set_noise_speed

export(float, 0.0, 50.0) var foam_strength = 0.8 setget set_foam_strength

export(int) var seed_value = 0 setget set_seed

var waves = []
var waves_in_tex = ImageTexture.new()

func _ready():
	
	# Prepare the LOD material and geometries
	var shader_mat = preload("../material/ocean.material").duplicate()
	shader_mat.set_shader_param("resolution", RESOLUTION)
	shader_mat.set_shader_param("morph_levels", MORPHING_LEVELS)
	shader_mat.set_shader_param("noise", preload("../texture/noise_perlin.jpg"))
	shader_mat.set_shader_param("noise_params", get_noise_params())
	shader_mat.set_shader_param("foam", preload("../texture/foam.png"))
	
	lod = LOD.new(RESOLUTION, LEVELS, SCALE, MORPHING_LEVELS)
	lod.generate(shader_mat)
	add_child(lod, true)
	
	#Get the waves ready
	waves_in_tex = ImageTexture.new()
	update_waves()
	
	remove_child(water_surface)
	water_surface = null
	water_material = null
	
	set_size(size)
	set_velocity(velocity)
	set_fog_density(fog_density)
	set_color(color)

func _process(delta):
	._process(delta)
	set_shader_param("time_offset", time)
	initialized = true

func set_size(value):
	size = Vector2(-1, -1)
	
	if fog_material:
		fog_material.set_shader_param("water_size", size)

func set_frequency(value):
	frequency = value
	if initialized:
		update_waves()

func set_steepness(value):
	steepness = value
	if initialized:
		update_waves()

func set_amplitude(value):
	amplitude = value
	if initialized:
		update_waves()

func set_velocity(value):
	.set_velocity(value)
	
	wind_direction = value.normalized() if value.length() > 0.0 else Vector2(1, 0)
	wind_align = 2.0 * atan(value.length()) / PI
	if initialized:
		update_waves()

func set_seed(value):
	seed_value = value
	if initialized:
		update_waves()

func set_speed(value):
	speed = value
	set_shader_param("speed", value)

func set_foam_strength(value):
	foam_strength = value
	set_shader_param("foam_strength", value)

func set_noise_enabled(value):
	noise_enabled = value
	if not initialized: return
	
	var old_noise_params = get_shader_param("noise_params", 0)
	if old_noise_params:
		old_noise_params.d = 1 if value else 0
		set_shader_param("noise_params", old_noise_params)
	else:
		set_shader_param("noise_params", get_noise_params())

func set_noise_amplitude(value):
	noise_amplitude = value
	if not initialized: return
	
	var old_noise_params = get_shader_param("noise_params", 0)
	if old_noise_params:
		old_noise_params.x = value
		set_shader_param("noise_params", old_noise_params)
	else:
		set_shader_param("noise_params", get_noise_params())

func set_noise_frequency(value):
	noise_frequency = value
	if not initialized: return
	
	var old_noise_params = get_shader_param("noise_params", 0)
	if old_noise_params:
		old_noise_params.y = value
		set_shader_param("noise_params", old_noise_params)
	else:
		set_shader_param("noise_params", get_noise_params())

func set_noise_speed(value):
	noise_speed = value
	if not initialized: return
	
	var old_noise_params = get_shader_param("noise_params", 0)
	if old_noise_params:
		old_noise_params.z = value
		set_shader_param("noise_params", old_noise_params)
	else:
		set_shader_param("noise_params", get_noise_params())

func set_color(value):
	.set_color(value)
	set_shader_param("color", color)

func set_fog_density(value):
	.set_fog_density(value)
	set_shader_param("density", fog_density)

func get_displace(position):
#	vec3 wave(vec2 pos, float time, bool use_noise) {
#	highp vec3 new_p = vec3(pos.x, 0.0, pos.y);
#
#	highp float amp, w, steep, phase;
#	highp vec2 dir;
#	for(int i = 0; i < textureSize(waves, 0).y; i++) {
#		amp = texelFetch(waves, ivec2(0, i), 0).r;
#
#		dir = vec2(texelFetch(waves, ivec2(2, i), 0).r, texelFetch(waves, ivec2(3, i), 0).r);
#		w = texelFetch(waves, ivec2(4, i), 0).r;
#		steep = texelFetch(waves, ivec2(1, i), 0).r /(w*amp);
#		phase = 2.0 * w;
#
#		float W = dot(w*dir, pos) + phase*time;
#
#		new_p.xz += steep*amp * dir * cos(W);
#		new_p.y += amp * sin(W);
#	}
#	new_p += perlin(pos, time);
#
#	return new_p;
#}
	var pos
	if typeof(position) == TYPE_VECTOR3:
		pos = Vector2(position.x, position.z)
	elif typeof(position) == TYPE_VECTOR2:
		pos = Vector2(position.x, position.y)
	else:
		printerr("Position is not a vector!")
		breakpoint
	var new_p = Vector3(pos.x, 0, pos.y);
	var w; var amp; var steep; var phase; var dir
	for i in waves:
		amp = i["amplitude"]
		if amp == 0.0: continue
		
		dir = Vector2(i["wind_directionX"], i["wind_directionY"])
		w = i["frequency"]
		steep = i["steepness"] / float(w*amp)
		phase = 2.0 * w
		var W = pos.dot(w*dir) + phase * time
		
		new_p.x += steep*amp * dir.x * cos(W)
		new_p.z += steep*amp * dir.y * cos(W)
		new_p.y += amp * sin(W)
	return new_p;

func get_height(coord):
	return get_displace(coord).y

func update_waves():
	#Generate Waves..
	seed(seed_value)
	var amp_length_ratio = amplitude * frequency
	waves.clear()
	for i in range(NUMBER_OF_WAVES):
		var _frequency = rand_range(frequency/6.0, frequency)
		var _wind_direction = wind_direction.rotated(rand_range(-PI, PI)*(1.0 - wind_align))
		
		waves.append({
			"amplitude":amp_length_ratio / _frequency,
			"steepness": rand_range(0, steepness),
			"wind_directionX": _wind_direction.x,
			"wind_directionY": _wind_direction.y,
			"frequency": sqrt(0.098 * TAU*_frequency)
		})
	#Put Waves in Texture..
	var img = Image.new()
	img.create(5, NUMBER_OF_WAVES, false, Image.FORMAT_RF)
	img.lock()
	for i in range(NUMBER_OF_WAVES):
		var wv = waves[i]
		img.set_pixel(0, i, Color(wv.amplitude, 0,0,0))
		img.set_pixel(1, i, Color(wv.steepness, 0,0,0))
		img.set_pixel(2, i, Color(wv.wind_directionX, 0,0,0))
		img.set_pixel(3, i, Color(wv.wind_directionY, 0,0,0))
		img.set_pixel(4, i, Color(wv.frequency, 0,0,0))
	img.unlock()
	waves_in_tex.create_from_image(img, 0)
	
	set_shader_param("waves", waves_in_tex)

func get_noise_params():
	return Plane(noise_amplitude, noise_frequency, noise_speed, noise_enabled)

func set_shader_param(uniform, value):
	if lod:
		for i in lod.get_children():
			i.material_override.set_shader_param(uniform, value)

func get_shader_param(uniform, indx):
	if lod:
		return lod.get_child(indx).material_override.get_shader_param(uniform)