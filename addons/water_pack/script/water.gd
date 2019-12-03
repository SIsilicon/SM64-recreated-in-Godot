tool
extends Spatial

const REFLECTION_MASK = 1 << 8

export(Vector2) var size = Vector2(10, 10) setget set_size

export(bool) var use_planar_reflection = false setget set_planar_reflection # use viewport camera reflection
export(Color) var color = Color(0,0.5,1) setget set_color
export(float) var fog_density = 0.13 setget set_fog_density

export(float) var speed = 0.15 setget set_speed
export(float) var frequency = 0.08 setget set_frequency
export(float) var amplitude = 0.11 setget set_amplitude

export(Vector2) var velocity = Vector2() setget set_velocity
export(float) var density = 1.0

var time = 0

var water_surface = MeshInstance.new()
var water_material
var fog_canvas = MeshInstance.new()
var fog_material

var reflect_camera
var reflect_viewport

var plugin
var ready = false

func _init():
	set_notify_transform(true)

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		if fog_material:
			var v1 = global_transform * Vector3(0, 0, 0)
			var v2 = global_transform * Vector3(1, 0, 0)
			var v3 = global_transform * Vector3(0, 0, 1)
			fog_material.set_shader_param("water_plane", Plane(v1, v2, v3))
			fog_material.set_shader_param("water_pos", global_transform.origin)

func _enter_tree():
	VisualServer.connect("frame_pre_draw", self, "update_camera")
	
	if !is_in_group("ywaby_water"):
		add_to_group("ywaby_water")
	
	water_surface.mesh = PlaneMesh.new()
	water_surface.mesh.size = size
	water_material = preload("../material/lake.material").duplicate()
	water_surface.set_surface_material(0, water_material)
	add_child(water_surface)
	
	fog_canvas.mesh = QuadMesh.new()
	fog_canvas.mesh.set_custom_aabb(AABB(-Vector3(1,1,1) * 100000, Vector3(1,1,1) * 200000))
	fog_canvas.mesh.size = Vector2(2, 2)
	fog_material = preload("../material/water_fog.material").duplicate()
	fog_canvas.set_surface_material(0, fog_material)
	add_child(fog_canvas)
	
	set_layer()
	
	set_size(size)
	set_color(color)
	set_fog_density(fog_density)
	set_velocity(velocity)
	set_speed(speed)
	set_frequency(frequency)
	set_amplitude(amplitude)

func _ready():
	ready = true
	set_planar_reflection(use_planar_reflection)

func _process(delta):
	time += delta * speed
	if water_material:
		water_material.set_shader_param("time", time)

func set_layer():
	water_surface.layers = REFLECTION_MASK
	fog_canvas.layers = REFLECTION_MASK

func mirror(origin, target):
	var own_global_trans = get_global_transform().inverse()
	
	target.transform = own_global_trans * origin.global_transform
	
	target.transform.origin.y *= -1
	target.transform.basis.y.x *= -1
	target.transform.basis.x.y *= -1
	target.transform.basis.z.y *= -1
	target.transform.basis.y.z *= -1
	
	target.transform = get_global_transform() * target.transform

func update_camera():
	var current_cam
	if use_planar_reflection:
		if is_inside_tree():
			if Engine.is_editor_hint():
				plugin = get_node_or_null("/root/EditorNode/WaterPackPlugin")
				if not plugin:
					return
				current_cam = plugin.editor_camera
				reflect_viewport.size = current_cam.get_parent().size
			else:
				current_cam = get_viewport().get_camera()
		
		if current_cam:
			mirror(current_cam, reflect_camera)
			reflect_camera.keep_aspect = current_cam.keep_aspect
			reflect_camera.projection = current_cam.projection
			reflect_camera.size = current_cam.size
			reflect_camera.fov = current_cam.fov
			reflect_camera.near = current_cam.near
			reflect_camera.far = current_cam.far
		
		$reflect_vp.render_target_update_mode = \
		Viewport.UPDATE_WHEN_VISIBLE if visible \
		else Viewport.UPDATE_DISABLED
	
	if water_material: water_material.set_shader_param("use_planar_reflect", current_cam)

func get_height(coord):
	return 0

func set_color(value):
	color = value
	if water_material:
		water_material.set_shader_param("color", value)
	
	if fog_material:
		var scatter = color
		scatter.a *= fog_density
		fog_material.set_shader_param("scatter_color", scatter)

func set_fog_density(fog):
	fog_density = max(fog, 0)
	
	if water_material:
		water_material.set_shader_param("density", fog_density)
	
	if fog_material:
		if fog_density > 0:
			fog_canvas.visible = true
			var scatter = color
			scatter.a *= fog_density
			fog_material.set_shader_param("scatter_color", scatter)
		else:
			fog_canvas.visible = false

func set_speed(value):
	speed = value
	if water_material:
		water_material.set_shader_param("speed", speed)

func set_frequency(value):
	frequency = value
	if water_material:
		water_material.set_shader_param("frequency", frequency)

func set_amplitude(value):
	amplitude = value
	if water_material:
		water_material.set_shader_param("amplitude", amplitude)

func set_size(s):
	size = s
	if water_surface.mesh:
		water_surface.mesh.size = size
	if fog_material:
		fog_material.set_shader_param("water_size", size / 2.0)

func set_velocity(value):
	velocity = value
	
	if water_material:
		for i in 3:
			var vector = Vector2(randf(), randf()) * 2.0 - Vector2(1,1)
			vector = vector.normalized()
			
			if velocity.length() > 0:
				var dir = velocity.normalized()
				vector = vector.linear_interpolate(dir, 2.0 * atan(velocity.length()) / PI)
				vector = vector.normalized()
			
			vector *= rand_range(0.8, 1.4)
			water_material.set_shader_param("wave_dir" + str(i+1), vector)

func set_planar_reflection(reflect):
	use_planar_reflection = reflect
	
	if not ready: return
	
	if reflect and not reflect_viewport:
		
		# add viewport
		reflect_viewport = Viewport.new()
		if Engine.is_editor_hint():
			plugin = get_node('/root/EditorNode/WaterPackPlugin')
			reflect_viewport.size = plugin.get_viewport().size / 2.0
		else:
			reflect_viewport.size = get_viewport().size / 2.0
		
		reflect_viewport.render_target_v_flip = true
		reflect_viewport.transparent_bg = true
		reflect_viewport.msaa = Viewport.MSAA_DISABLED
		reflect_viewport.shadow_atlas_size = 512
		reflect_viewport.name = "reflect_vp"
		# add camera
		reflect_camera = Camera.new()
		
		reflect_camera.cull_mask = ~REFLECTION_MASK
		reflect_camera.name = "reflect_cam"
		
		add_child(reflect_viewport)
		reflect_viewport.owner = self
		reflect_viewport.add_child(reflect_camera)
		reflect_camera.current = true
		
		water_material.resource_local_to_scene = true
		
		yield(get_tree(), 'idle_frame')
		yield(get_tree(), 'idle_frame')
		
		var reflect_tex = reflect_viewport.get_texture()
		reflect_tex.set_flags(Texture.FLAG_FILTER)
		if not Engine.is_editor_hint(): reflect_tex.viewport_path = "/root/" + get_node("/root").get_path_to(reflect_viewport)
		
		water_material.set_shader_param("reflect_texture", reflect_viewport.get_texture())
	elif reflect_viewport:
		
		remove_child(reflect_viewport)
		reflect_viewport.owner = null
		reflect_viewport = null
		reflect_camera = null
		water_material.set_shader_param("reflect_texture", null)