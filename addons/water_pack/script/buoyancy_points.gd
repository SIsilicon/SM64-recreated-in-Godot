tool
extends Resource

enum PointModes{SINGLE_POINT, AUTO_POINTS, MANUAL_POINTS}
enum AutoShapes{ELLIPSE, RECTANGLE}

export(PointModes) var point_mode = PointModes.MANUAL_POINTS setget set_point_mode

var data = PoolVector3Array()  # [position = Vector3()]

var auto_shape = AutoShapes.RECTANGLE
var auto_resolution = Vector2(2,2)
var auto_scale = Vector2(1,1)
var auto_offset = Vector3()

signal data_changed

func _init():
	data.resize(1)

func _get(property):
	
	match point_mode:
		PointModes.SINGLE_POINT:
			if property == "buoyancy point offset":
				return data[0]
		
		PointModes.AUTO_POINTS:
			match property:
				"shape": return auto_shape
				"point resolution": return auto_resolution
				"scale": return auto_scale
				"offset": return auto_offset
		
		PointModes.MANUAL_POINTS:
			if property == "bouyancy points size":
				return data.size()
			
			for idx in range(data.size()):
				if property == "buoyancy points/position-" + str(idx):
					return data[idx]

func _set(property, value):
	
	match point_mode:
		PointModes.SINGLE_POINT:
			if property == "buoyancy point offset":
				data[0] = value
				return val_set()
		
		PointModes.AUTO_POINTS:
			match property:
				"shape": auto_shape = value
				"point resolution": auto_resolution = value
				"scale": auto_scale = value
				"offset": auto_offset = value
			
			if property.match("point resolution") or \
			property.match("shape") or \
			property.match("scale") or \
			property.match("offset"):
				set_auto_data_points()
				return val_set()
		
		PointModes.MANUAL_POINTS:
			if property =="bouyancy points size":
				var prev_size = data.size()
				data.resize(value)
				if prev_size < data.size():
					for idx in range(prev_size, data.size()):
						data[idx] = Vector3()
				return val_set()
			for idx in range(data.size()):
				if property == "buoyancy points/position-" + str(idx):
					data[idx] = value
					return val_set()
	return false

func _get_property_list():
	var custom_inpector = []
	
	match point_mode:
		PointModes.SINGLE_POINT:
			custom_inpector.append({
				"name": "buoyancy point offset",
				"type": TYPE_VECTOR3
			})
		
		PointModes.AUTO_POINTS:
			custom_inpector.append({
				"name": "shape",
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_ENUM,
				"hint_string": "Ellipse, Rectangle"
			})
			custom_inpector.append({
				"name": "point resolution",
				"type": TYPE_VECTOR2
			})
			custom_inpector.append({
				"name": "scale",
				"type": TYPE_VECTOR2
			})
			custom_inpector.append({
				"name": "offset",
				"type": TYPE_VECTOR3
			})
		
		PointModes.MANUAL_POINTS:
			custom_inpector.append({
				"name": "bouyancy points size",
				"type": TYPE_INT,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "1,256"
			})
			
			for idx in range(data.size()):
				custom_inpector.append({
					"name": "buoyancy points/position-" + str(idx),
					"type": TYPE_VECTOR3
				})
	
	return custom_inpector

func set_auto_data_points():
	
	var new_data = []
	match auto_shape:
		AutoShapes.RECTANGLE:
			for z in range(auto_resolution.y):
				for x in range(auto_resolution.x):
					var point = Vector2(x,z) / (auto_resolution - Vector2(1,1))
					point = point * 2 - Vector2(1,1)
					new_data.append(point)
		AutoShapes.ELLIPSE:
			for radius in range(auto_resolution.y):
				for theta in range(auto_resolution.x):
					var point = Vector2(0, (auto_resolution.y - radius)/auto_resolution.y).rotated(theta/auto_resolution.x * TAU)
					new_data.append(point)
	
	for i in range(new_data.size()):
		new_data[i] *= auto_scale
		new_data[i] = Vector3(new_data[i].x, 0, new_data[i].y) + auto_offset
	data = PoolVector3Array(new_data)

func set_point_mode(value):
	point_mode = value
	if value == PointModes.AUTO_POINTS:
		set_auto_data_points()
	elif value == PointModes.SINGLE_POINT:
		data.resize(1)
	val_set()

func val_set():
	emit_signal("changed")
	return true