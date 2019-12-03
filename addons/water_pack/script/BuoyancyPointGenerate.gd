extends Button

var plugin

func _ready():
	plugin = get_node('/root/EditorNode/WaterPackPlugin')


func _on_Button_tree_exiting():
	plugin.remove_control_from_container(plugin.CONTAINER_SPATIAL_EDITOR_MENU, self)
