extends EditorSpatialGizmoPlugin

const BouyancyBody = preload("bouyancy_body.gd")
const Gizmo = preload("buoyancy_gizmo.gd")

var plugin

func _init(plugin):
	self.plugin = plugin

func get_name():
	return "BouyancyPoints"

func create_gizmo(spatial):
	if spatial is BouyancyBody:
		return Gizmo.new(plugin, spatial)
	else:
		return null